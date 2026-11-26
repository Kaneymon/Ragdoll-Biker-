-- Pure upgrade/economy maths shared by server (authoritative) and client (menus).
local Config = script.Parent.Parent.Config
local Bike = require(Config.Bike)
local BikeUpgrades = require(Config.BikeUpgrades)
local Ramp = require(Config.Ramp)
local Boosters = require(Config.Boosters)
local Exploders = require(Config.Exploders)
local Economy = require(Config.Economy)
local Maps = require(Config.Maps)

local Progression = {}

local GEAR = { boosters = Boosters, exploders = Exploders }

local function find(list, id)
	for _, def in list do
		if def.id == id then
			return def
		end
	end
	return nil
end
Progression.find = find

-- Bike parts ---------------------------------------------------------------
function Progression.bikeUpgrade(id)
	return find(BikeUpgrades, id)
end

function Progression.bikeUpgradeCost(def, level)
	if level >= def.maxLevel then
		return nil
	end
	return math.floor(def.baseCost * def.growth ^ level)
end

function Progression.bikeStatValue(def, level)
	return Bike.Base[def.stat] + def.perLevel * level
end

function Progression.bikeStats(profile)
	local stats = table.clone(Bike.Base)
	for _, def in BikeUpgrades do
		stats[def.stat] = Progression.bikeStatValue(def, profile.bike[def.id] or 0)
	end
	return stats
end

-- Ramp ---------------------------------------------------------------------
function Progression.rampStart(level)
	return Ramp.startBase + Ramp.startPerLevel * math.clamp(level, 0, Ramp.maxLevel)
end

function Progression.rampCost(level)
	if level >= Ramp.maxLevel then
		return nil
	end
	return math.floor(Ramp.baseCost * Ramp.growth ^ level)
end

-- Boosters & exploders ("gear") -------------------------------------------
function Progression.gear(kind)
	return GEAR[kind]
end

function Progression.gearDef(kind, id)
	local gear = GEAR[kind]
	return gear and find(gear.list, id)
end

-- level == nil means not owned yet (price to buy), otherwise the next upgrade price.
function Progression.gearCost(kind, def, level)
	if level == nil then
		return def.price
	end
	local gear = GEAR[kind]
	if level >= gear.maxLevel then
		return nil
	end
	return math.floor(def.price * gear.upgradeCostScale * gear.upgradeGrowth ^ level)
end

function Progression.boosterStats(def, level)
	return {
		thrust = def.thrust * (1 + Boosters.thrustPerLevel * level),
		fuel = def.fuel * (1 + Boosters.fuelPerLevel * level),
	}
end

function Progression.exploderForce(def, level)
	return def.force * (1 + Exploders.forcePerLevel * level)
end

local function equipped(profile, kind)
	local slot = profile[kind]
	local level = slot.owned[slot.equipped]
	if level == nil then
		return nil, nil
	end
	return Progression.gearDef(kind, slot.equipped), level
end

-- Returns stats (or nil) and the config def.
function Progression.equippedBooster(profile)
	local def, level = equipped(profile, "boosters")
	if not def then
		return nil, nil
	end
	return Progression.boosterStats(def, level), def
end

function Progression.equippedExploder(profile)
	local def, level = equipped(profile, "exploders")
	if not def then
		return nil, nil
	end
	return Progression.exploderForce(def, level), def
end

-- Levels & maps ------------------------------------------------------------
-- Returns level, money earned into this level, money needed for the next level.
function Progression.level(totalEarned)
	local level, need, left = 1, Economy.Level.base, totalEarned
	while left >= need do
		left -= need
		level += 1
		need *= Economy.Level.growth
	end
	return level, left, need
end

function Progression.map(id)
	return find(Maps.list, id)
end

return Progression
