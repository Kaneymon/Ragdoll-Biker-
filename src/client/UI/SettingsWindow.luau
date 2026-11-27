-- SETTINGS: player stats, gamepasses, effect toggles and the controls list.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local P = require(Shared.Config.Palette)
local Store = require(Shared.Config.Store)
local Controls = require(Shared.Config.Controls)
local StatsList = require(Shared.Config.StatsList)
local Format = require(Shared.Util.Format)
local Net = require(Shared.Net)
local State = require(script.Parent.Parent.State)
local Window = require(script.Parent.Window)
local Card = require(script.Parent.Card)
local StoreWindow = require(script.Parent.StoreWindow)

local SettingsWindow = {}

local TABS = {
	{ id = "stats", key = "TAB_STATS" },
	{ id = "passes", key = "TAB_PASSES" },
	{ id = "effects", key = "TAB_EFFECTS" },
	{ id = "controls", key = "TAB_CONTROLS" },
}
local TOGGLES = { "sfx", "vfx", "injuryFx" }
local LAYOUTS = { { id = "pc", key = "CTRL_PC" }, { id = "console", key = "CTRL_CONSOLE" }, { id = "touch", key = "CTRL_TOUCH" } }
local FORMATTERS = {
	number = Format.number,
	money = Format.money,
	mult = function(value)
		return "x" .. Format.mult(value)
	end,
}

local layout = "pc"
local TEST_MODE_ATTRIBUTE = "CanTestMode" -- set by the server for players allowed to use it

local renderers = {}

function renderers.stats(window)
	for i, stat in StatsList do
		local value = State.profile.stats[stat.key] or 0
		Card.new(window.body, { title = { "STAT_" .. stat.key }, lines = { { text = FORMATTERS[stat.format](value) } }, order = i })
	end
end

function renderers.passes(window)
	local passes = {}
	for _, tab in Store.tabs do
		for _, item in tab.items do
			if item.pass then
				table.insert(passes, item)
			end
		end
	end
	for i, item in passes do
		local owned = State.profile.passes[item.id] ~= nil
		local on = State.profile.passes[item.id] == true
		local button = if owned
			then { if on then "BTN_ON" else "BTN_OFF", color = if on then P.Money else P.Coral, onClick = function()
				Net.func("TogglePass"):InvokeServer(item.id)
			end }
			else { if StoreWindow.isTesting() then "BTN_FREE" else "BTN_ROBUX", { item.robux }, color = P.Money, onClick = function()
				StoreWindow.prompt(item.id)
			end }
		Card.new(window.body, { title = { item.nameKey }, buttons = { button }, order = i })
	end
end

local function toggles()
	local list = table.clone(TOGGLES)
	if Players.LocalPlayer:GetAttribute(TEST_MODE_ATTRIBUTE) then
		table.insert(list, "testMode")
	end
	return list
end

function renderers.effects(window)
	for i, key in toggles() do
		local on = State.profile.settings[key]
		Card.new(window.body, {
			title = { "SET_" .. key },
			buttons = { { if on then "BTN_ON" else "BTN_OFF", color = if on then P.Money else P.Coral, onClick = function()
				Net.func("SetSetting"):InvokeServer(key, not on)
			end } },
			order = i,
		})
	end
end

local function keyName(keyCode)
	return UserInputService:GetStringForKeyCode(keyCode) ~= "" and UserInputService:GetStringForKeyCode(keyCode) or keyCode.Name
end

function renderers.controls(window)
	local picker = {}
	for _, option in LAYOUTS do
		table.insert(picker, { option.key, color = if option.id == layout then P.Sun else P.Sky, onClick = function()
			layout = option.id
			window:refresh()
		end })
	end
	Card.new(window.body, { title = { "TAB_CONTROLS" }, buttons = picker, order = 0 })
	local order = 1
	for _, row in Controls.stick do
		Card.new(window.body, { title = { row.nameKey }, lines = { { text = row[layout] } }, order = order })
		order += 1
	end
	for _, action in Controls.actions do
		local line = if layout == "touch" then { "CTRL_BUTTON" } else { text = keyName(action.keys[if layout == "console" then 2 else 1]) }
		Card.new(window.body, { title = { action.nameKey }, lines = { line }, order = order })
		order += 1
	end
end

function SettingsWindow.create()
	local window = Window.new({
		titleKey = "WIN_SETTINGS",
		banner = "blue",
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

return SettingsWindow
