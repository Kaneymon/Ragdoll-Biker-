-- In-game money purchases: bike parts, ramp, boosters, exploders, maps. Also equip/select/settings.
-- Every price comes from Logic/Progression so the menus and the server always agree.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Progression = require(Shared.Logic.Progression)
local Template = require(Shared.Config.ProfileTemplate)
local Net = require(Shared.Net)
local DataService = require(script.Parent.DataService)

local Signal = require(Shared.Util.Signal)

-- Fired when something that changes the bike/spawn was bought or picked (ramp, gear, map).
local ShopService = { LoadoutChanged = Signal.new() }
local LOADOUT_KINDS = { ramp = true, boosters = true, exploders = true }

-- Takes the money and applies the change, or returns an error text key.
local function charge(profile, cost, apply)
	if not cost then
		return "NOTE_MAX"
	end
	if profile.money < cost then
		return "NOTE_NO_MONEY"
	end
	profile.money -= cost
	apply()
	return nil
end

local function buyGear(kind)
	return function(profile, id)
		local def = Progression.gearDef(kind, id)
		if not def then
			return "NOTE_ERROR"
		end
		local slot = profile[kind]
		local level = slot.owned[id]
		return charge(profile, Progression.gearCost(kind, def, level), function()
			slot.owned[id] = if level == nil then 0 else level + 1
			if level == nil then
				slot.equipped = id
				if slot.charges then
					slot.charges[id] = 1 -- a new exploder comes with one bomb
				end
			end
		end)
	end
end

-- Bike parts ("bike") and biker gear ("biker") level up the same way.
local function buyUpgrade(set)
	return function(profile, id)
		local def = Progression.upgrade(set, id)
		if not def then
			return "NOTE_ERROR"
		end
		local level = profile[set][id] or 0
		return charge(profile, Progression.upgradeCost(def, level), function()
			profile[set][id] = level + 1
		end)
	end
end

-- Extra bombs for an owned exploder (1x, 5x, 25x the price).
local function buyCharge(profile, id)
	local def = Progression.gearDef("exploders", id)
	if not def or profile.exploders.owned[id] == nil then
		return "NOTE_ERROR"
	end
	local charges = Progression.charges(profile, id)
	return charge(profile, Progression.chargeCost(def, charges), function()
		profile.exploders.charges[id] = charges + 1
	end)
end

local purchases = {
	bike = buyUpgrade("bike"),
	biker = buyUpgrade("biker"),
	charge = buyCharge,

	ramp = function(profile)
		return charge(profile, Progression.rampCost(profile.rampLevel), function()
			profile.rampLevel += 1
		end)
	end,

	boosters = buyGear("boosters"),
	exploders = buyGear("exploders"),

	map = function(profile, id)
		local def = Progression.map(id)
		if not def or profile.maps.owned[id] then
			return "NOTE_ERROR"
		end
		if def.comingSoon then
			return "NOTE_SOON"
		end
		if Progression.level(profile.totalEarned) < def.level then
			return "NOTE_NEED_LEVEL"
		end
		return charge(profile, def.price, function()
			profile.maps.owned[id] = true
		end)
	end,
}

local function onPurchase(player, kind, id)
	local profile = DataService.get(player)
	local handler = purchases[kind]
	if not (profile and handler) or (id ~= nil and type(id) ~= "string") then
		return false, "NOTE_ERROR"
	end
	local err = handler(profile, id)
	if err then
		return false, err
	end
	DataService.push(player)
	if LOADOUT_KINDS[kind] then
		ShopService.LoadoutChanged:Fire(player)
	end
	return true, "NOTE_BOUGHT"
end

local function onEquip(player, kind, id)
	local profile = DataService.get(player)
	if not profile or not Progression.gear(kind) or type(id) ~= "string" then
		return false
	end
	local slot = profile[kind]
	if slot.owned[id] == nil then
		return false
	end
	slot.equipped = if slot.equipped == id then "" else id
	DataService.push(player)
	ShopService.LoadoutChanged:Fire(player)
	return true
end

local function onSelectMap(player, id)
	local profile = DataService.get(player)
	if not profile or type(id) ~= "string" or not profile.maps.owned[id] then
		return false
	end
	profile.maps.selected = id
	DataService.push(player)
	ShopService.LoadoutChanged:Fire(player)
	return true
end

local function onSetSetting(player, settingKey, value)
	local profile = DataService.get(player)
	if not profile or type(settingKey) ~= "string" or type(Template.settings[settingKey]) ~= type(value) then
		return false
	end
	profile.settings[settingKey] = value
	DataService.push(player)
	return true
end

function ShopService.start()
	Net.func("Purchase").OnServerInvoke = onPurchase
	Net.func("Equip").OnServerInvoke = onEquip
	Net.func("SelectMap").OnServerInvoke = onSelectMap
	Net.func("SetSetting").OnServerInvoke = onSetSetting
end

return ShopService
