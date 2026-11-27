-- After each cash out: a random Store item at its normal Robux price (Robux prices are fixed per
-- product on the Creator Dashboard, so there are no random discounts).
-- The item is the big headline; below it: buy (Robux price), UPGRADES or PLAY.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local P = require(Shared.Config.Palette)
local Store = require(Shared.Config.Store)
local Localize = require(Shared.Services.Localize)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.UiKit)
local StoreWindow = require(script.Parent.StoreWindow)

local OfferPopup = {}

local root, dealLabel, buyButton
local current = nil
local allItems = {}
for _, tab in Store.tabs do
	for _, item in tab.items do
		table.insert(allItems, item)
	end
end

local function show()
	current = allItems[math.random(1, #allItems)]
	UiKit.setText(dealLabel, "OFFER_ITEM", Localize.get(current.nameKey))
	UiKit.setText(buyButton, "BTN_ROBUX", current.robux)
	root.Visible = true
	UiKit.pop(root)
end

local function hide()
	root.Visible = false
end

-- windows = the menu windows from Main (the UPGRADES button opens windows.upgrades).
function OfferPopup.create(windows)
	local gui = UiKit.screen("Offer", 15)
	root = UiKit.panel({ Size = UDim2.fromOffset(560, 360), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, Parent = gui })
	local header = UiKit.panel({ Size = UDim2.new(1, 0, 0, 170), BackgroundColor3 = P.Orange, Parent = root })
	UiKit.padding(header, 14)
	dealLabel = UiKit.label({ text = "", style = "Huge", color = P.White, outline = true, Size = UDim2.fromScale(1, 1), Parent = header })
	dealLabel.TextScaled = true
	local maxSize = Instance.new("UITextSizeConstraint")
	maxSize.MaxTextSize = 72
	maxSize.Parent = dealLabel

	buyButton = UiKit.button({ key = "BTN_ROBUX", args = { 0 }, color = P.Money, style = "Title", Size = UDim2.new(0.86, 0, 0, 70), Position = UDim2.new(0.5, 0, 0, 225), AnchorPoint = Vector2.new(0.5, 0.5), Parent = root, onClick = function()
		StoreWindow.prompt(current.id)
	end })
	UiKit.button({ key = "BTN_UPGRADES", color = P.Orange, style = "Heading", Size = UDim2.new(0.42, 0, 0, 56), Position = UDim2.new(0.28, 0, 0, 310), AnchorPoint = Vector2.new(0.5, 0.5), Parent = root, onClick = function()
		hide()
		windows.upgrades:open()
	end })
	UiKit.button({ key = "BTN_PLAY", color = P.Sky, style = "Heading", Size = UDim2.new(0.42, 0, 0, 56), Position = UDim2.new(0.72, 0, 0, 310), AnchorPoint = Vector2.new(0.5, 0.5), Parent = root, onClick = hide })

	State.CashedOut:Connect(function()
		local connection
		connection = State.PhaseChanged:Connect(function(phase)
			if phase == "Ready" then
				connection.Disconnect()
				show()
			end
		end)
	end)
	State.PhaseChanged:Connect(function(phase)
		if phase == "Riding" then
			hide()
		end
	end)
end

return OfferPopup
