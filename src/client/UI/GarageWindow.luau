-- GARAGE: bike paint jobs and trails (Config/Cosmetics), opened from the Lobby stalls.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local P = require(Shared.Config.Palette)
local Progression = require(Shared.Logic.Progression)
local State = require(script.Parent.Parent.State)
local Window = require(script.Parent.Window)
local Card = require(script.Parent.Card)
local Shop = require(script.Parent.Shop)

local GarageWindow = {}

local TABS = {
	{ id = "paints", key = "TAB_BIKES" },
	{ id = "trails", key = "TAB_TRAILS" },
}

-- One card per paint / trail: buy it, or wear it once owned.
local function render(window, kind)
	local slot = State.profile[kind]
	for i, def in Progression.cosmetics(kind) do
		local button
		if slot.owned[def.id] then
			local wearing = slot.equipped == def.id
			button = { if wearing then "BTN_EQUIPPED" else "BTN_EQUIP", color = if wearing then P.Grape else P.Sky, onClick = function()
				Shop.equip(kind, def.id)
			end }
		else
			button = Shop.priceButton(def.price, function()
				Shop.buy(kind, def.id)
			end, "BTN_BUY")
		end
		Card.new(window.body, { title = { def.nameKey }, lines = { { if kind == "paints" then "GARAGE_PAINT_DESC" else "GARAGE_TRAIL_DESC" } }, buttons = { button }, color = if kind == "paints" then def.frame:Lerp(P.Card, 0.75) else nil, order = i })
	end
end

function GarageWindow.create()
	local window = Window.new({
		titleKey = "WIN_GARAGE",
		banner = "blue",
		tabs = TABS,
		render = render,
	})
	State.ProfileChanged:Connect(function()
		window:refresh()
	end)
	return window
end

return GarageWindow
