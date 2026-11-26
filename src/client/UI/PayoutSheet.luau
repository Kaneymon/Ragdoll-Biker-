-- INSURANCE PAYOUT: a playful hospital claim form.
-- Left: the skeleton. Right: a scrolling dash list of everything that hurt (cost in green),
-- with the bill, bonuses and total pinned underneath so they are always visible.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local P = require(Shared.Config.Palette)
local Economy = require(Shared.Config.Economy)
local Bones = require(Shared.Config.Bones)
local Assets = require(Shared.Config.UiAssets)
local InjuryModel = require(Shared.Logic.InjuryModel)
local Format = require(Shared.Util.Format)
local Localize = require(Shared.Services.Localize)
local State = require(script.Parent.Parent.State)
local Session = require(script.Parent.Parent.Controllers.Session)
local UiKit = require(script.Parent.UiKit)
local Skeleton = require(script.Parent.Skeleton)
local StoreWindow = require(script.Parent.StoreWindow)

local PayoutSheet = {}

local ROW_HEIGHT = 30
local TOTALS_HEIGHT = 150
local BUTTONS_HEIGHT = 140

local root, list, totals, setBones, bonesLabel, cashButton

-- One form line: "- name" on the left, value on the right (green for money).
local function line(parent, order, text, value, valueColor, style)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, if style == "Heading" then 40 else ROW_HEIGHT)
	row.LayoutOrder = order
	row.Parent = parent
	UiKit.label({ text = text, style = style or "Body", Size = UDim2.new(0.68, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
	UiKit.label({ text = value, style = style or "Body", color = valueColor or P.Ink, Size = UDim2.new(0.32, 0, 1, 0), Position = UDim2.fromScale(0.68, 0), TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
end

local function entry(order, nameKey, count, money)
	line(list, order, "- " .. Localize.get(nameKey) .. "  " .. Localize.get("PAY_COUNT", count), Format.money(money), P.Money)
end

local function show(sheet)
	UiKit.clear(list)
	UiKit.clear(totals)
	setBones(sheet.bones)
	UiKit.setText(bonesLabel, "PAY_BONES", sheet.bonesHurt, #Bones.list)
	local order = 0
	if sheet.impactMoney > 0 then
		order += 1
		line(list, order, "- " .. Localize.get("PAY_HITS"), Format.money(sheet.impactMoney), P.Money)
	end
	for _, hit in sheet.lucky do -- lucky hits, named after what broke
		order += 1
		local name = Localize.get("PAY_LUCKY_LINE", Localize.get(hit.nameKey), InjuryModel.luckyDef(hit.id).mult)
		line(list, order, "- " .. name, Format.money(hit.money), P.Money)
	end
	for _, item in sheet.statuses do -- bones by how badly they're hurt, worst first
		order += 1
		local status = InjuryModel.status(item.id)
		entry(order, status.nameKey, item.count, InjuryModel.money(status.value * item.count))
	end
	for _, item in sheet.injuries do -- medical injuries
		order += 1
		local injury = InjuryModel.injury(item.id)
		entry(order, injury.nameKey, item.count, InjuryModel.money(injury.value * item.count))
	end
	if order == 0 then
		line(list, 1, "- " .. Localize.get("PAY_NONE"), "")
	end
	line(totals, 1, Localize.get("PAY_BILL"), Format.money(sheet.bill), P.Money)
	line(totals, 2, Localize.get("PAY_TRICKS"), "x" .. Format.mult(sheet.multiplier))
	line(totals, 3, Localize.get("PAY_MAP"), "x" .. Format.mult(sheet.mapMult))
	line(totals, 4, Localize.get("PAY_TOTAL"), Format.money(sheet.total), P.Money, "Heading")
	cashButton:SetAttribute("Disabled", false)
	root.Visible = true
	UiKit.pop(root)
end

local function cashOut()
	cashButton:SetAttribute("Disabled", true)
	if Session.cashOut() then
		root.Visible = false
	else
		cashButton:SetAttribute("Disabled", false)
	end
end

local function column(parent, size, position)
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size, frame.Position = size, position
	frame.Parent = parent
	return frame
end

function PayoutSheet.create()
	local gui = UiKit.screen("Payout", 20)
	root = UiKit.panel({ Size = UDim2.fromScale(0.72, 0.88), Position = UDim2.fromScale(0.5, 0.52), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = P.Paper, Visible = false, Parent = gui })
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(900, 780)
	limit.Parent = root

	local banner = Instance.new("ImageLabel")
	banner.BackgroundTransparency = 1
	banner.Image = Assets.Banners.red
	banner.Size = UDim2.new(0.7, 0, 0, 96)
	banner.Position = UDim2.new(0.5, 0, 0, -34)
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Parent = root
	UiKit.label({ key = "PAY_TITLE", style = "Title", color = P.White, outline = true, Size = UDim2.new(1, -40, 0.7, 0), Position = UDim2.fromScale(0.5, 0.42), AnchorPoint = Vector2.new(0.5, 0.5), Parent = banner })

	local body = column(root, UDim2.new(1, -40, 1, -(80 + BUTTONS_HEIGHT)), UDim2.fromOffset(20, 76))
	local figureColumn = column(body, UDim2.fromScale(0.36, 1), UDim2.new())
	local _figure
	_figure, setBones = Skeleton.new(figureColumn, { Size = UDim2.new(1, 0, 1, -40), Position = UDim2.new(0, 0, 0, 0) })
	bonesLabel = UiKit.label({ key = "PAY_BONES", args = { 0, #Bones.list }, style = "Body", Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 1, -36), Parent = figureColumn })

	local form = column(body, UDim2.fromScale(0.6, 1), UDim2.fromScale(0.4, 0))
	UiKit.label({ key = "PAY_FORM", style = "Heading", Size = UDim2.new(1, 0, 0, 36), TextXAlignment = Enum.TextXAlignment.Left, Parent = form })
	list = UiKit.scrollList({ Size = UDim2.new(1, 0, 1, -(40 + TOTALS_HEIGHT)), Position = UDim2.fromOffset(0, 40), Parent = form })
	list:FindFirstChildOfClass("UIListLayout").Padding = UDim.new(0, 2)
	local rule = Instance.new("Frame") -- the form's "sign here" line above the totals
	rule.BorderSizePixel = 0
	rule.BackgroundColor3 = P.Ink
	rule.Size = UDim2.new(1, 0, 0, 3)
	rule.Position = UDim2.new(0, 0, 1, -TOTALS_HEIGHT)
	rule.Parent = form
	totals = column(form, UDim2.new(1, 0, 0, TOTALS_HEIGHT - 8), UDim2.new(0, 0, 1, -(TOTALS_HEIGHT - 8)))
	UiKit.listLayout(totals, nil, 2, Enum.HorizontalAlignment.Left)

	cashButton = UiKit.button({ key = "BTN_CASH_OUT", color = P.Money, style = "Title", Size = UDim2.new(0.55, 0, 0, 72), Position = UDim2.new(0.5, 0, 1, -96), AnchorPoint = Vector2.new(0.5, 0.5), Parent = root, onClick = cashOut })
	UiKit.button({ key = "BTN_DOUBLE", args = { Economy.DoubleMoneyRobux }, color = P.Sky, style = "Body", Size = UDim2.new(0.45, 0, 0, 50), Position = UDim2.new(0.5, 0, 1, -34), AnchorPoint = Vector2.new(0.5, 0.5), Parent = root, onClick = function()
		StoreWindow.prompt("double_payout")
	end })

	State.Payout:Connect(show)
	State.PhaseChanged:Connect(function(phase)
		if phase ~= "Payout" then
			root.Visible = false
		end
	end)
end

return PayoutSheet
