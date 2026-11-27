-- Lobby stalls: their prompts (Window / Tab attributes, World/LobbyBuilder) open the matching menu
-- window on the matching tab.
local ProximityPromptService = game:GetService("ProximityPromptService")

local ShopPrompts = {}

-- windows = the menu windows from Main, by id
function ShopPrompts.start(windows)
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local window = windows[prompt:GetAttribute("Window")]
		if window then
			window:openTab(prompt:GetAttribute("Tab"))
		end
	end)
end

return ShopPrompts
