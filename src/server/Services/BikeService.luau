-- Puts each fresh character on a bike at their ramp start, and takes them off it at bail.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Progression = require(Shared.Logic.Progression)
local Ragdoll = require(Shared.Logic.Ragdoll)
local RiderPose = require(Shared.Logic.RiderPose)
local DataService = require(script.Parent.DataService)
local WorldService = require(script.Parent.WorldService)
local BikeBuilder = require(script.Parent.Parent.World.BikeBuilder)

local BikeService = {}

local BIKE_LIFETIME_AFTER_BAIL = 6
local bikes = {} -- player -> bike model

local function setRiderPart(part)
	if part:IsA("BasePart") then
		part.Massless = true
		part.CanCollide = false
		part.CollisionGroup = WorldService.RIDERS_GROUP
	end
end

local function spawnSlot(player)
	return table.find(Players:GetPlayers(), player) or 1
end

local function gearFor(profile)
	local _, booster = Progression.equippedBooster(profile)
	local _, exploder = Progression.equippedExploder(profile)
	return { booster = booster, exploder = exploder }
end

function BikeService.get(player)
	return bikes[player]
end

function BikeService.remove(player)
	local bike = bikes[player]
	if bike then
		bike:Destroy()
		bikes[player] = nil
	end
end

local function mount(player, character)
	local profile = DataService.waitFor(player)
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	if not profile or not character.Parent then
		return
	end
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	Ragdoll.setup(character)

	BikeService.remove(player)
	local bike = BikeBuilder.build(gearFor(profile))
	bike.Name = "Bike_" .. player.UserId
	bike:PivotTo(WorldService.spawnCFrame(profile.maps.selected, profile.rampLevel, spawnSlot(player)))
	for _, part in bike:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = WorldService.RIDERS_GROUP
		end
	end
	bike.Parent = workspace.Bikes
	bikes[player] = bike

	for _, part in character:GetDescendants() do
		setRiderPart(part)
	end
	character.DescendantAdded:Connect(function(part)
		if not character:GetAttribute("Ragdolled") then
			setRiderPart(part)
		elseif part:IsA("BasePart") then
			part.CollisionGroup = WorldService.RIDERS_GROUP
		end
	end)

	RiderPose.apply(character, "Ride")
	humanoid.PlatformStand = true
	local chassis = bike.PrimaryPart
	root.CFrame = chassis.CFrame * RiderPose.seat("Ride")
	local weld = Instance.new("Weld")
	weld.Name = "RiderWeld"
	weld.Part0 = chassis
	weld.Part1 = root
	weld.C0 = RiderPose.seat("Ride")
	weld.Parent = chassis

	local link = Instance.new("ObjectValue")
	link.Name = "Bike"
	link.Value = bike
	link.Parent = character
	chassis:SetNetworkOwner(player)
end

-- Rider leaves the bike: ragdoll on the server too so everyone sees it.
function BikeService.detach(player)
	local character = player.Character
	local bike = bikes[player]
	if bike then
		local weld = bike.PrimaryPart and bike.PrimaryPart:FindFirstChild("RiderWeld")
		if weld then
			weld:Destroy()
		end
		bikes[player] = nil
		Debris:AddItem(bike, BIKE_LIFETIME_AFTER_BAIL)
	end
	if character then
		local profile = DataService.get(player)
		Ragdoll.enable(character, Ragdoll.surface(Progression.stats(profile)))
	end
end

function BikeService.start()
	local function onPlayer(player)
		player.CharacterAdded:Connect(function(character)
			mount(player, character)
		end)
		if player.Character then
			task.spawn(mount, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(BikeService.remove)
end

return BikeService
