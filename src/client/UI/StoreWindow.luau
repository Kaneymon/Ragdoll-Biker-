-- STORE: Robux gamepasses, power-ups and money packs. Real Robux purchases aren't wired yet;
-- in test mode every item is FREE and works straight away (Services/MonetizationService).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local P = require(Shared.Config.Palette)
local Store = require(Shared.Config.Store)
local Progression = require(Shared.Logic.Progression)
local Net = require(Shared.Net)
local State = require(script.Parent.Parent.State)
local Window = require(script.Parent.Window)
local Card = require(script.Parent.Card)

local StoreWindow = {}

local TEST_MODE_ATTRIBUTE = "CanTestMode" -- set by the server for players allowed to test

local tabs, byTab = {}, {}
for _, tab in Store.tabs do
	table.insert(tabs, { id = tab.id, key = tab.nameKey })
	byTab[tab.id] = tab
end

-- True when Robux items are free for this player (test mode on, and allowed to test).
function StoreWindow.isTesting()
	return State.profile ~= nil and Progression.testMode(State.profile) and Players.LocalPlayer:GetAttribute(TEST_MODE_ATTRIBUTE) == true
end

-- Asks the server for a Robux item; returns true if the player got it.
function StoreWindow.prompt(itemId)
	local ok, noteKey = Net.func("PromptRobux"):InvokeServer(itemId)
	State.Notify:Fire(noteKey)
	return ok == true
end

-- Whether the player already owns this pass (passes can only be bought once).
function StoreWindow.owns(item)
	return item.pass == true and State.profile.passes[item.id] ~= nil
end

local function clock(seconds)
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function card(window, item, order)
	local lines = { { "BTN_ROBUX", { item.robux } } }
	local left = if item.duration then Progression.powerupLeft(State.profile, item.id, workspace:GetServerTimeNow()) else 0
	if left > 0 then
		table.insert(lines, { "BTN_ACTIVE", { clock(math.floor(left)) } })
	end
	local button
	if StoreWindow.owns(item) then
		button = { "BTN_OWNED", color = P.Disabled, disabled = true }
	else
		button = { if StoreWindow.isTesting() then "BTN_FREE" else "BTN_SOON", color = if StoreWindow.isTesting() then P.Grape else P.Money, onClick = function()
			StoreWindow.prompt(item.id)
		end }
	end
	Card.new(window.body, { title = { item.nameKey }, lines = lines, buttons = { button }, order = order })
end

function StoreWindow.create()
	local window = Window.new({
		titleKey = "WIN_STORE",
		banner = "green",
		tabs = tabs,
		render = function(window, tabId)
			for i, item in byTab[tabId].items do
				card(window, item, i)
			end
		end,
	})
	State.ProfileChanged:Connect(function()
		window:refresh()
	end)
	return window
end

return StoreWindow
