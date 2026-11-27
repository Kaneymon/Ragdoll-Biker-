-- Where each player is (Logic/Location): everyone starts riding round the Lobby, PLAY takes them to
-- their map's ramp and the LOBBY button brings them back. Moving somewhere respawns the character
-- there, on a bike (BikeService).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Lobby = require(Shared.Config.Lobby)
local Bike = require(Shared.Config.Bike)
local Location = require(Shared.Logic.Location)
local Net = require(Shared.Net)
local Signal = require(Shared.Util.Signal)
local WorldService = require(script.Parent.WorldService)

local LocationService = { Moved = Signal.new() } -- (player, location)

local CLIENT_DESTINATIONS = { [Location.LOBBY] = true, [Location.RAMP] = true }
local TRAVEL_COOLDOWN = 1
local lastTravel = {}
local rng = Random.new()

-- Sends the player somewhere and respawns them there.
function LocationService.travel(player, location)
	player:SetAttribute(Location.ATTRIBUTE, location)
	LocationService.Moved:Fire(player, location)
	player:LoadCharacter()
end

-- A random spot near the middle of the deck, facing the ramps.
local function lobbySpawn()
	local a = rng:NextNumber(0, 2 * math.pi)
	local at = Lobby.centre + Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(0, Lobby.spawnRadius) + Vector3.yAxis * Bike.Hover
	return CFrame.lookAt(at, at + Vector3.zAxis)
end

-- Where a rider's bike starts: the top of their ramp, or the middle of the lobby.
function LocationService.rideStart(player, profile, slot)
	if Location.of(player) == Location.LOBBY then
		return lobbySpawn()
	end
	return WorldService.spawnCFrame(profile.maps.selected, profile.rampLevel, slot)
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

function LocationService.start()
	local function onPlayer(player)
		player:SetAttribute(Location.ATTRIBUTE, Location.LOBBY)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastTravel[player] = nil
	end)
	Net.func("Travel").OnServerInvoke = onTravel
end

return LocationService
