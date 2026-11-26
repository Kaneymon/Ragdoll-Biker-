-- World setup: collision groups, text table, maps, and spawn points.
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Maps = require(Shared.Config.Maps)
local Bike = require(Shared.Config.Bike)
local Progression = require(Shared.Logic.Progression)
local Localize = require(Shared.Services.Localize)
local MapBuilder = require(script.Parent.Parent.World.MapBuilder)

local WorldService = {}

WorldService.RIDERS_GROUP = "Riders"
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
	PhysicsService:CollisionGroupSetCollidable(WorldService.RIDERS_GROUP, WorldService.RIDERS_GROUP, false)
end

-- Maps already baked into the place are kept (so they can be hand-edited); missing ones are built.
local function buildMaps()
	local world = folder("World")
	for _, def in Maps.list do
		if not def.comingSoon and not world:FindFirstChild(def.id) then
			MapBuilder.build(def, world)
		end
	end
end

function WorldService.spawnCFrame(mapId, rampLevel, slot)
	local def = Progression.map(mapId) or Progression.map(Maps.default)
	local side = ((slot % 3) - 1) * SPAWN_SPREAD
	return MapBuilder.spawnCFrame(def, Progression.rampStart(rampLevel), Bike.Hover, side)
end

function WorldService.start()
	-- workspace.FallenPartsDestroyHeight is set to -2000 in the place (scripts can't write it).
	setupCollisionGroups()
	Localize.publishTable()
	buildMaps()
	folder("Bikes")
end

return WorldService
