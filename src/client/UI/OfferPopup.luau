-- After each cash out: a random Store item at 5-25% off (1 in 250 runs: 80% off).
-- The deal itself is the big headline; below it: buy (Robux price), UPGRADES or PLAY.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local P = require(Shared.Config.Palette)
local Store = require(Shared.Config.Store)
local Economy = require(Shared.Config.Economy)
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

local function rollOffer()
	local o = Economy.Offer
	local mega = math.random() < o.megaChance
	local discount = if mega then o.megaDiscount else math.random(o.minDiscount, o.maxDiscount)
	local item = allItems[math.random(1, #allItems)]
	return { item = item, discount = discount, mega = mega, price = math.max(1, math.floor(item.robux * (100 - discount) / 100)) }
end

local function show()
	current = rollOffer()
	UiKit.setText(dealLabel, if current.mega then "OFFER_DEAL_MEGA" else "OFFER_DEAL", current.discount, Localize.get(current.item.nameKey))
	UiKit.setText(buyButton, "BTN_ROBUX", current.price)
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
		StoreWindow.prompt(current.item.id)
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
