-- After each cash out: a random Store item at 5-25% off (1 in 250 runs: 80% off).
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

local root, titleLabel, nameLabel, priceLabel
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
	UiKit.setText(titleLabel, if current.mega then "OFFER_MEGA" else "OFFER_TITLE")
	UiKit.setText(nameLabel, current.item.nameKey)
	priceLabel.Text = Localize.get("OFFER_PRICE", Localize.get("OFFER_OFF", current.discount), current.price)
	root.Visible = true
	UiKit.pop(root)
end

function OfferPopup.create()
	local gui = UiKit.screen("Offer", 15)
	root = UiKit.panel({ Size = UDim2.fromOffset(520, 330), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, Parent = gui })
	local header = UiKit.panel({ Size = UDim2.new(1, 0, 0, 70), BackgroundColor3 = P.Orange, Parent = root })
	titleLabel = UiKit.label({ key = "OFFER_TITLE", style = "Title", color = P.White, outline = true, Size = UDim2.fromScale(1, 1), Parent = header })
	nameLabel = UiKit.label({ text = "", style = "Heading", Size = UDim2.new(1, -20, 0, 50), Position = UDim2.fromOffset(10, 84), Parent = root })
	priceLabel = UiKit.label({ text = "", style = "Heading", color = P.Money, Size = UDim2.new(1, -20, 0, 44), Position = UDim2.fromOffset(10, 134), Parent = root })
	UiKit.button({ key = "BTN_SOON", color = P.Money, Size = UDim2.new(0.8, 0, 0, 60), Position = UDim2.new(0.5, 0, 0, 220), AnchorPoint = Vector2.new(0.5, 0.5), Parent = root, onClick = function()
		StoreWindow.prompt(current.item.id)
	end })
	UiKit.button({ key = "BTN_NO_THANKS", color = P.Disabled, style = "Body", Size = UDim2.new(0.5, 0, 0, 46), Position = UDim2.new(0.5, 0, 0, 290), AnchorPoint = Vector2.new(0.5, 0.5), Parent = root, onClick = function()
		root.Visible = false
	end })

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
			root.Visible = false
		end
	end)
end

return OfferPopup
