-- Shared bits of the in-game money shops (UpgradesWindow, GarageWindow): asking the server to buy
-- or equip, and the price button spec for Card.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local P = require(Shared.Config.Palette)
local Progression = require(Shared.Logic.Progression)
local Format = require(Shared.Util.Format)
local Localize = require(Shared.Services.Localize)
local Net = require(Shared.Net)
local State = require(script.Parent.Parent.State)

local Shop = {}

function Shop.buy(kind, id)
	local _, noteKey = Net.func("Purchase"):InvokeServer(kind, id)
	State.Notify:Fire(noteKey)
end

function Shop.equip(kind, id)
	Net.func("Equip"):InvokeServer(kind, id)
end

-- Price button: shows MAX at the top level (cost nil), greys out when unaffordable, FREE in test
-- mode or with the Endless Money pass. key = label with the price as {1} (plain price by default).
function Shop.priceButton(cost, onClick, key)
	if not cost then
		return { "BTN_MAX", color = P.Disabled, disabled = true }
	end
	if Progression.testMode(State.profile) or State.stats.freeShopping then
		return { key or "HUD_MONEY", { Localize.get("BTN_FREE") }, color = P.Grape, onClick = onClick }
	end
	return { key or "HUD_MONEY", { Format.money(cost) }, color = P.Money, onClick = onClick, disabled = State.profile.money < cost }
end

return Shop
