-- Puts each fresh character on a bike at their start (lobby or ramp, Logic/Location), and
-- takes them off it at bail. Also keeps riders from bumping into each other on the ramps: bikes
-- and bodies are in the Riders collision group until they're past their map's kicker, then in
-- the Slope group, where everyone collides (WorldService sets the groups up).
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Progression = require(Shared.Logic.Progression)
local Location = require(Shared.Logic.Location)
local MapGeometry = require(Shared.Logic.MapGeometry)
local Ragdoll = require(Shared.Logic.Ragdoll)
local BikeWreck = require(Shared.Logic.BikeWreck)
local RiderPose = require(Shared.Logic.RiderPose)
local DataService = require(script.Parent.DataService)
local WorldService = require(script.Parent.WorldService)
local LocationService = require(script.Parent.LocationService)
local GearService = require(script.Parent.GearService)
local BikeBuilder = require(script.Parent.Parent.World.BikeBuilder)

local BikeService = {}

local BIKE_LIFETIME_AFTER_BAIL = 6
local STREAM_TIMEOUT = 10 -- seconds to wait for the ground round a ride start to stream in
local ZONE_CHECK = 0.25 -- seconds between "past the kicker yet?" checks
local GROUP_ATTRIBUTE = "CollisionGroup" -- the rider's current group, for parts added later
local bikes = {} -- player -> bike model

local function groupOf(player)
	return player:GetAttribute(GROUP_ATTRIBUTE) or WorldService.RIDERS_GROUP
end

local function setRiderPart(player, part)
	if part:IsA("BasePart") then
		part.Massless = true
		part.CanCollide = false
		part.CollisionGroup = groupOf(player)
	end
end

-- Moves the rider's body and bike into a collision group.
local function setGroup(player, group)
	if player:GetAttribute(GROUP_ATTRIBUTE) == group then
		return
	end
	player:SetAttribute(GROUP_ATTRIBUTE, group)
	for _, holder in { player.Character, bikes[player] } do
		for _, part in if holder then holder:GetDescendants() else {} do
			if part:IsA("BasePart") then
				part.CollisionGroup = group
			end
		end
	end
end

local function spawnSlot(player)
	return table.find(Players:GetPlayers(), player) or 1
end

local function gearFor(profile, rules)
	local _, booster = Progression.equippedBooster(profile)
	return {
		paint = Progression.equippedCosmetic(profile, "paints"),
		trail = Progression.equippedCosmetic(profile, "trails"),
		booster = if rules.gear then booster else nil,
	}
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
	-- Quick respawns: a newer character may have spawned while this one waited; leave its bike alone.
	if not profile or not character.Parent or player.Character ~= character then
		return
	end
	local rules = Location.rules(Location.of(player))
	setGroup(player, if rules.bump then WorldService.SLOPE_GROUP else WorldService.RIDERS_GROUP)
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	Ragdoll.setup(character)

	BikeService.remove(player)
	local bike = BikeBuilder.build(gearFor(profile, rules))
	bike.Name = "Bike_" .. player.UserId
	local start = LocationService.rideStart(player, profile, spawnSlot(player))
	-- StreamingEnabled: load the ground round the start before the rider is put there
	pcall(player.RequestStreamAroundAsync, player, start.Position, STREAM_TIMEOUT)
	if not character.Parent or player.Character ~= character then
		return
	end
	bike:PivotTo(start)
	-- the owner always has their whole bike (BikeController waits for its parts)
	bike.ModelStreamingMode = Enum.ModelStreamingMode.PersistentPerPlayer
	bike:AddPersistentPlayer(player)
	for _, part in bike:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = groupOf(player)
		end
	end
	bike.Parent = workspace.Bikes
	bikes[player] = bike

	for _, part in character:GetDescendants() do
		setRiderPart(player, part)
	end
	character.DescendantAdded:Connect(function(part)
		if not character:GetAttribute("Ragdolled") then
			setRiderPart(player, part)
		elseif part:IsA("BasePart") then
			part.CollisionGroup = groupOf(player)
		end
	end)

	if rules.gear then
		GearService.dress(character, profile)
	end
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
		BikeWreck.loosen(bike)
		Debris:AddItem(bike, BIKE_LIFETIME_AFTER_BAIL)
	end
	if character then
		local profile = DataService.get(player)
		Ragdoll.enable(character, Ragdoll.surface(Progression.stats(profile, os.time())))
	end
end

-- Ramp riders past their map's kicker lip are "on the slope" and collide with each other.
local function watchZones()
	while true do
		task.wait(ZONE_CHECK)
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local core = character and Ragdoll.core(character)
			local profile = core and Location.of(player) == Location.RAMP and DataService.get(player)
			if profile then
				local lip = MapGeometry.get(MapGeometry.def(profile.maps.selected)).lip
				setGroup(player, if core.Position.Z > lip.Z then WorldService.SLOPE_GROUP else WorldService.RIDERS_GROUP)
			end
		end
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
	task.spawn(watchZones)
end

return BikeService
