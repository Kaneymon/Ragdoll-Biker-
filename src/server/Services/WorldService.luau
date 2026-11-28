-- World setup: collision groups, text table, maps, the lobby, and spawn points.
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Lighting = game:GetService("Lighting")
local Maps = require(Shared.Config.Maps)
local Environment = require(Shared.Config.Environment)
local Bike = require(Shared.Config.Bike)
local MapGeometry = require(Shared.Logic.MapGeometry)
local Localize = require(Shared.Services.Localize)
local MapBuilder = require(script.Parent.Parent.World.MapBuilder)
local LobbyBuilder = require(script.Parent.Parent.World.LobbyBuilder)

local WorldService = {}

WorldService.RIDERS_GROUP = "Riders" -- riders on the ramps: pass through each other
WorldService.SLOPE_GROUP = "Slope" -- riders past the kicker: bump into each other, not into ramp riders
local SPAWN_SPREAD = 14

local function folder(name)
	local existing = workspace:FindFirstChild(name)
	if existing then
		return existing
	end
	local new = Instance.new("Folder")
	new.Name = name
	new.Parent = workspace
	return new
end

local function setupCollisionGroups()
	PhysicsService:RegisterCollisionGroup(WorldService.RIDERS_GROUP)
	PhysicsService:RegisterCollisionGroup(WorldService.SLOPE_GROUP)
	PhysicsService:CollisionGroupSetCollidable(WorldService.RIDERS_GROUP, WorldService.RIDERS_GROUP, false)
	PhysicsService:CollisionGroupSetCollidable(WorldService.RIDERS_GROUP, WorldService.SLOPE_GROUP, false)
end

-- Maps and the lobby already baked into the place are kept (so they can be hand-edited); missing
-- ones are built.
local function buildMaps()
	local world = folder("World")
	for _, def in Maps.list do
		if not def.comingSoon and not world:FindFirstChild(def.id) then
			MapBuilder.build(def, world)
		end
	end
	if not world:FindFirstChild("Lobby") then
		LobbyBuilder.build(world)
	end
end

local function setupEnvironment()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	for key, value in Environment.Atmosphere do
		atmosphere[key] = value
	end
	atmosphere.Parent = Lighting
	for key, value in Environment.Lighting do
		Lighting[key] = value
	end
end

function WorldService.spawnCFrame(mapId, rampLevel, slot)
	local side = ((slot % 3) - 1) * SPAWN_SPREAD
	return MapGeometry.spawnCFrame(MapGeometry.def(mapId), rampLevel, Bike.Hover, side)
end

function WorldService.start()
	-- workspace.FallenPartsDestroyHeight is set to -2000 in the place (scripts can't write it).
	-- workspace.StreamingEnabled is ON in the place (scripts can't write it either): without it
	-- every client downloads all maps and the Mountain's terrain before it can start. The baked map
	-- models have LevelOfDetail = StreamingMesh (set in Studio; scripts can't write that either).
	setupCollisionGroups()
	setupEnvironment()
	Localize.publishTable()
	buildMaps()
	folder("Bikes")
end

return WorldService
