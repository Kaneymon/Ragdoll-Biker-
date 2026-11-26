-- UPGRADES: maps, ramp, bike parts, biker gear, boosters, exploders. Prices from Logic/Progression.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local P = require(Shared.Config.Palette)
local Maps = require(Shared.Config.Maps)
local Ramp = require(Shared.Config.Ramp)
local Progression = require(Shared.Logic.Progression)
local MapGeometry = require(Shared.Logic.MapGeometry)
local Format = require(Shared.Util.Format)
local Localize = require(Shared.Services.Localize)
local Net = require(Shared.Net)
local State = require(script.Parent.Parent.State)
local Window = require(script.Parent.Window)
local Card = require(script.Parent.Card)

local UpgradesWindow = {}

local TABS = {
	{ id = "maps", key = "TAB_MAPS" },
	{ id = "ramp", key = "TAB_RAMP" },
	{ id = "bike", key = "TAB_BIKE" },
	{ id = "biker", key = "TAB_BIKER" },
	{ id = "boosters", key = "TAB_BOOSTERS" },
	{ id = "exploders", key = "TAB_EXPLODERS" },
}

local function buy(kind, id)
	local _, noteKey = Net.func("Purchase"):InvokeServer(kind, id)
	State.Notify:Fire(noteKey)
end

local function equip(kind, id)
	Net.func("Equip"):InvokeServer(kind, id)
end

local function statText(def, value)
	if def.format == "mult" then
		return "x" .. Format.mult(value)
	elseif def.format == "plus" then
		return "+" .. Format.mult(value)
	elseif def.format == "percent" then
		return math.floor(value * 100 + 0.5) .. "%"
	end
	return Format.number(value)
end

-- Price button: shows MAX at the top level, greys out when unaffordable, FREE in testing mode.
-- key = label with the price as {1} (plain price by default).
local function moneyButton(cost, onClick, key)
	if not cost then
		return { "BTN_MAX", color = P.Disabled, disabled = true }
	end
	if Progression.testMode(State.profile) then
		return { key or "HUD_MONEY", { Localize.get("BTN_FREE") }, color = P.Grape, onClick = onClick }
	end
	return { key or "HUD_MONEY", { Format.money(cost) }, color = P.Money, onClick = onClick, disabled = State.profile.money < cost }
end

local renderers = {}

function renderers.maps(window)
	local profile = State.profile
	local level = Progression.level(profile.totalEarned)
	for i, def in Maps.list do
		local owned = profile.maps.owned[def.id]
		local button
		if def.comingSoon then
			button = { "BTN_SOON", color = P.Disabled, disabled = true }
		elseif owned then
			local selected = profile.maps.selected == def.id
			button = { if selected then "BTN_SELECTED" else "BTN_SELECT", color = if selected then P.Grape else P.Sky, disabled = selected, onClick = function()
				Net.func("SelectMap"):InvokeServer(def.id)
			end }
		elseif level < def.level and not Progression.testMode(profile) then
			button = { "BTN_LOCKED", { def.level }, color = P.Disabled, disabled = true }
		else
			button = moneyButton(def.price, function()
				buy("map", def.id)
			end)
		end
		Card.new(window.body, { title = { def.nameKey }, lines = { { "MAP_DESC", { def.payoutMult } } }, buttons = { button }, order = i })
	end
end

function renderers.ramp(window)
	local level = State.profile.rampLevel
	local nextLevel = math.min(level + 1, Ramp.maxLevel)
	local map = MapGeometry.def(State.profile.maps.selected)
	Card.new(window.body, {
		title = { "RAMP_NAME" },
		lines = {
			{ "RAMP_DESC" },
			{ "UPG_LEVEL", { level, Ramp.maxLevel } },
			{ "UPG_STAT", { Format.number(MapGeometry.startDistance(map, level)), Format.number(MapGeometry.startDistance(map, nextLevel)) } },
		},
		buttons = { moneyButton(Progression.rampCost(level), function()
			buy("ramp")
		end) },
	})
end

-- Bike parts and biker gear: one card per upgrade with its stat now and next.
local function renderUpgrades(set)
	return function(window)
		for i, def in Progression.upgradeSet(set).list do
			local level = State.profile[set][def.id] or 0
			local nextLevel = math.min(level + 1, def.maxLevel)
			Card.new(window.body, {
				title = { def.nameKey },
				lines = {
					{ def.descKey },
					{ "UPG_LEVEL", { level, def.maxLevel } },
					{ "UPG_STAT", { statText(def, Progression.statValue(set, def, level)), statText(def, Progression.statValue(set, def, nextLevel)) } },
				},
				buttons = { moneyButton(Progression.upgradeCost(def, level), function()
					buy(set, def.id)
				end) },
				order = i,
			})
		end
	end
end
renderers.bike = renderUpgrades("bike")
renderers.biker = renderUpgrades("biker")

local function gearLines(kind, def, level)
	local shown = level or 0
	if kind == "boosters" then
		local stats = Progression.boosterStats(def, shown)
		return { { "BOOST_DESC", { Format.number(stats.thrust), string.format("%.1f", stats.fuel) } } }
	end
	return { { "EXP_DESC", { Format.number(Progression.exploderForce(def, shown)) } } }
end

local function renderGear(kind)
	return function(window)
		local gear = Progression.gear(kind)
		local slot = State.profile[kind]
		for i, def in gear.list do
			local level = slot.owned[def.id]
			local lines = gearLines(kind, def, level)
			local buttons = { moneyButton(Progression.gearCost(kind, def, level), function()
				buy(kind, def.id)
			end, if level == nil then "BTN_BUY" else "BTN_UPGRADE") }
			if level ~= nil then
				table.insert(lines, { "UPG_LEVEL", { level, gear.maxLevel } })
				if kind == "exploders" then
					local charges = Progression.charges(State.profile, def.id)
					table.insert(lines, { "EXP_CHARGES", { charges, gear.maxCharges } })
					table.insert(buttons, moneyButton(Progression.chargeCost(def, charges), function()
						buy("charge", def.id)
					end, "BTN_EXTRA_BOMB"))
				end
				local using = slot.equipped == def.id
				table.insert(buttons, { if using then "BTN_EQUIPPED" else "BTN_EQUIP", color = if using then P.Grape else P.Sky, onClick = function()
					equip(kind, def.id)
				end })
			end
			Card.new(window.body, { title = { def.nameKey }, lines = lines, buttons = buttons, order = i })
		end
	end
end
renderers.boosters = renderGear("boosters")
renderers.exploders = renderGear("exploders")

function UpgradesWindow.create()
	local window = Window.new({
		titleKey = "WIN_UPGRADES",
		banner = "orange",
		tabs = TABS,
		render = function(window, tab)
			renderers[tab](window)
		end,
	})
	State.ProfileChanged:Connect(function()
		window:refresh()
	end)
	return window
end

return UpgradesWindow
