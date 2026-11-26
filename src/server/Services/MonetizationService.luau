-- Robux purchases (gamepasses, power-ups, money packs, 2x payout, post-run offers).
-- MVP stub: every prompt answers "coming soon". Wire MarketplaceService here and nowhere else.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local MonetizationService = {}

local function onPrompt(_player, _itemId)
	return false, "NOTE_SOON"
end

function MonetizationService.start()
	Net.func("PromptRobux").OnServerInvoke = onPrompt
end

return MonetizationService
