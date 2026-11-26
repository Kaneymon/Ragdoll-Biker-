-- List card used by every menu: title and info lines on the left, buttons on the right.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared.Config.Theme)
local P = require(Shared.Config.Palette)
local UiKit = require(script.Parent.UiKit)

local Card = {}

local BUTTON_WIDTH = 0.36
local LINE_HEIGHT = 30

-- spec = {
--   title = { key, args } , lines = { { key, args } or { text = "..." } },
--   buttons = { { key, args, color, onClick, disabled } }, color = card colour, order = LayoutOrder
-- }
function Card.new(parent, spec)
	local buttonCount = spec.buttons and #spec.buttons or 0
	local height = math.max(Theme.CardHeight, 80 + #(spec.lines or {}) * LINE_HEIGHT, buttonCount * (Theme.ButtonHeight + 8) + 16)
	local card = UiKit.panel({ Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = spec.color or P.Card, LayoutOrder = spec.order or 0, Parent = parent })
	UiKit.padding(card, 12)

	local textWidth = if buttonCount > 0 then 1 - BUTTON_WIDTH else 1
	local column = Instance.new("Frame")
	column.BackgroundTransparency = 1
	column.Size = UDim2.new(textWidth, -10, 1, 0)
	column.Parent = card
	UiKit.listLayout(column, nil, 2, Enum.HorizontalAlignment.Left)

	UiKit.label({ key = spec.title[1], args = spec.title[2], style = "Heading", Size = UDim2.new(1, 0, 0, 38), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0, Parent = column })
	for i, line in spec.lines or {} do
		UiKit.label({ key = line[1], args = line[2], text = line.text, style = "Small", color = P.Ink, Size = UDim2.new(1, 0, 0, LINE_HEIGHT), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = i, Parent = column })
	end

	if buttonCount > 0 then
		local stack = Instance.new("Frame")
		stack.BackgroundTransparency = 1
		stack.Size = UDim2.new(BUTTON_WIDTH, 0, 1, 0)
		stack.Position = UDim2.fromScale(1 - BUTTON_WIDTH, 0)
		stack.Parent = card
		local layout = UiKit.listLayout(stack, nil, 8)
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		for i, b in spec.buttons do
			local button = UiKit.button({ key = b[1], args = b[2], color = b.color, style = "Body", LayoutOrder = i, Parent = stack, onClick = b.onClick })
			button:SetAttribute("Disabled", b.disabled == true)
		end
	end
	return card
end

return Card
