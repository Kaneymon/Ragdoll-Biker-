-- STORE: Robux gamepasses, power-ups and money packs (shown, not wired for the MVP).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local P = require(Shared.Config.Palette)
local Store = require(Shared.Config.Store)
local Net = require(Shared.Net)
local State = require(script.Parent.Parent.State)
local Window = require(script.Parent.Window)
local Card = require(script.Parent.Card)

local StoreWindow = {}

local tabs, byTab = {}, {}
for _, tab in Store.tabs do
	table.insert(tabs, { id = tab.id, key = tab.nameKey })
	byTab[tab.id] = tab
end

function StoreWindow.prompt(itemId)
	local _, noteKey = Net.func("PromptRobux"):InvokeServer(itemId)
	State.Notify:Fire(noteKey)
end

function StoreWindow.create()
	return Window.new({
		titleKey = "WIN_STORE",
		color = P.Grape,
		tabs = tabs,
		render = function(window, tabId)
			for i, item in byTab[tabId].items do
				Card.new(window.body, {
					title = { item.nameKey },
					lines = { { "BTN_ROBUX", { item.robux } } },
					buttons = { { "BTN_SOON", color = P.Money, onClick = function()
						StoreWindow.prompt(item.id)
					end } },
					order = i,
				})
			end
		end,
	})
end

return StoreWindow
