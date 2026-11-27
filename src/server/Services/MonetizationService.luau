-- Robux purchases (gamepasses, power-ups, money packs, 2x payout, post-run offers).
-- Real Robux purchases aren't wired yet: outside test mode every prompt answers "coming soon".
-- In test mode (ShopService.testing) items are free and granted straight away. Wire
-- MarketplaceService here and nowhere else: a paid receipt should end in grant() too.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Store = require(Shared.Config.Store)
local Progression = require(Shared.Logic.Progression)
local Net = require(Shared.Net)
local DataService = require(script.Parent.DataService)
local ShopService = require(script.Parent.ShopService)
local RunTracker = require(script.Parent.RunTracker)

local MonetizationService = {}

-- Gives the player a Store item. Returns false if there was nothing to give.
local function grantItem(player, item)
	if item.pass or item.duration or item.money then
		DataService.update(player, function(profile)
			if item.pass then
				profile.passes[item.id] = true
			elseif item.duration then
				profile.powerups[item.id] = math.max(os.time(), profile.powerups[item.id] or 0) + item.duration
			else
				profile.money += item.money
			end
		end)
		return true
	end
	return false
end

local function grant(player, itemId)
	if itemId == Store.DoublePayoutId then
		return RunTracker.doublePayout(player)
	end
	local item = Progression.storeItem(itemId)
	return item ~= nil and grantItem(player, item)
end

local function onPrompt(player, itemId)
	if type(itemId) ~= "string" then
		return false, "NOTE_ERROR"
	end
	if not ShopService.testing(player) then
		return false, "NOTE_SOON"
	end
	if not grant(player, itemId) then
		return false, "NOTE_ERROR"
	end
	return true, if itemId == Store.DoublePayoutId then "NOTE_PAYOUT_DOUBLED" else "NOTE_TEST_FREE"
end

-- Switches an owned pass on or off (Settings > Passes).
local function onTogglePass(player, passId)
	local profile = DataService.get(player)
	if not profile or type(passId) ~= "string" or profile.passes[passId] == nil then
		return false
	end
	DataService.update(player, function(data)
		data.passes[passId] = not data.passes[passId]
	end)
	return true
end

function MonetizationService.start()
	Net.func("PromptRobux").OnServerInvoke = onPrompt
	Net.func("TogglePass").OnServerInvoke = onTogglePass
end

return MonetizationService
