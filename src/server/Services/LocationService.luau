-- Where each player is (Logic/Location): everyone starts in the Lobby, PLAY takes them to their
-- map's ramp, the LOBBY button brings them back, and the gate on the deck sends them to the obby.
-- Moving somewhere respawns the character there (riders are put on a bike by BikeService).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Lobby = require(Shared.Config.Lobby)
local Location = require(Shared.Logic.Location)
local Net = require(Shared.Net)
local Signal = require(Shared.Util.Signal)
local WorldService = require(script.Parent.WorldService)

local LocationService = { Moved = Signal.new() } -- (player, location)

local CLIENT_DESTINATIONS = { [Location.LOBBY] = true, [Location.RAMP] = true } -- the obby is via its gate
local TRAVEL_COOLDOWN = 1
local lastTravel = {}
local rng = Random.new()

local function lobbyModel()
	return workspace:WaitForChild("World"):WaitForChild("Lobby")
end

-- Sends the player somewhere and respawns them there.
function LocationService.travel(player, location)
	player:SetAttribute(Location.ATTRIBUTE, location)
	LocationService.Moved:Fire(player, location)
	player:LoadCharacter()
end

-- Where a rider's bike starts: the top of their ramp, or the start of the obby.
function LocationService.rideStart(player, profile, slot)
	if Location.of(player) == Location.OBBY then
		return lobbyModel():GetAttribute("ObbySpawn")
	end
	return WorldService.spawnCFrame(profile.maps.selected, profile.rampLevel, slot)
end

-- A random spot near the middle of the deck, facing the ramps.
local function lobbySpawn()
	local a = rng:NextNumber(0, 2 * math.pi)
	local at = Lobby.centre + Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(0, Lobby.spawnRadius) + Vector3.yAxis * 4
	return CFrame.lookAt(at, at + Vector3.zAxis)
end

local function onCharacter(player, character)
	if Location.rules(Location.of(player)).riding then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root and player.Character == character then
		character:PivotTo(lobbySpawn())
	end
end

local function onTravel(player, location)
	local now = os.clock()
	if not CLIENT_DESTINATIONS[location] or now - (lastTravel[player] or 0) < TRAVEL_COOLDOWN then
		return false
	end
	lastTravel[player] = now
	LocationService.travel(player, location)
	return true
end

-- Prompts on the lobby with a Travel attribute (the obby gate).
local function watchGates()
	local lobby = lobbyModel()
	local function hook(prompt)
		if prompt:IsA("ProximityPrompt") and prompt:GetAttribute("Travel") then
			prompt.Triggered:Connect(function(player)
				LocationService.travel(player, prompt:GetAttribute("Travel"))
			end)
		end
	end
	for _, item in lobby:GetDescendants() do
		hook(item)
	end
end

function LocationService.start()
	local function onPlayer(player)
		player:SetAttribute(Location.ATTRIBUTE, Location.LOBBY)
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastTravel[player] = nil
	end)
	Net.func("Travel").OnServerInvoke = onTravel
	task.spawn(watchGates)
end

return LocationService
