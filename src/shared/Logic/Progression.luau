-- Pure upgrade/economy maths shared by server (authoritative) and client (menus).
local Config = script.Parent.Parent.Config
local Bike = require(Config.Bike)
local BikeUpgrades = require(Config.BikeUpgrades)
local BikerUpgrades = require(Config.BikerUpgrades)
local Ramp = require(Config.Ramp)
local Boosters = require(Config.Boosters)
local Exploders = require(Config.Exploders)
local Economy = require(Config.Economy)
local Maps = require(Config.Maps)

local Progression = {}

-- Upgrade sets: profile[set][id] = level
local SETS = {
	bike = { list = BikeUpgrades, base = Bike.Base },
	biker = { list = BikerUpgrades.list, base = BikerUpgrades.Base },
}
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

-- Stat upgrades (bike parts, biker gear) --------------------------------------
function Progression.upgradeSet(set)
	return SETS[set]
end

function Progression.upgrade(set, id)
	return SETS[set] and find(SETS[set].list, id)
end

function Progression.upgradeCost(def, level)
	if level >= def.maxLevel then
		return nil
	end
	return math.floor(def.baseCost * def.growth ^ level)
end

function Progression.statValue(set, def, level)
	return SETS[set].base[def.stat] + def.perLevel * level
end

-- Every upgradable stat (bike and biker) for a profile, in one table.
function Progression.stats(profile)
	local stats = {}
	for set, info in SETS do
		for stat, value in info.base do
			stats[stat] = value
		end
		for _, def in info.list do
			stats[def.stat] = Progression.statValue(set, def, profile[set][def.id] or 0)
		end
	end
	return stats
end

-- Ramp ---------------------------------------------------------------------
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

-- Bombs per run for an owned exploder (old saves without charges count as 1).
function Progression.charges(profile, id)
	if profile.exploders.owned[id] == nil then
		return 0
	end
	return profile.exploders.charges[id] or 1
end

-- Price of the next extra bomb: price x 1, 5, 25... or nil when full.
function Progression.chargeCost(def, charges)
	if charges >= Exploders.maxCharges then
		return nil
	end
	return math.floor(def.price * Exploders.chargeGrowth ^ charges)
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

-- Returns blast force (or nil), the config def and bombs per run.
function Progression.equippedExploder(profile)
	local def, level = equipped(profile, "exploders")
	if not def then
		return nil, nil, 0
	end
	return Progression.exploderForce(def, level), def, Progression.charges(profile, def.id)
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

-- Testing mode: everything free (the server only lets allowed players turn it on).
function Progression.testMode(profile)
	return profile.settings.testMode == true
end

return Progression
