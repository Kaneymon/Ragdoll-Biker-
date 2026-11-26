-- INSURANCE PAYOUT sheet: skeleton, injury checklist, bonuses, total, cash out.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local P = require(Shared.Config.Palette)
local Theme = require(Shared.Config.Theme)
local Economy = require(Shared.Config.Economy)
local Bones = require(Shared.Config.Bones)
local InjuryModel = require(Shared.Logic.InjuryModel)
local Format = require(Shared.Util.Format)
local State = require(script.Parent.Parent.State)
local Session = require(script.Parent.Parent.Controllers.Session)
local UiKit = require(script.Parent.UiKit)
local Skeleton = require(script.Parent.Skeleton)
local StoreWindow = require(script.Parent.StoreWindow)

local PayoutSheet = {}

local ROW_HEIGHT = 40

local root, list, setBones, bonesLabel, cashButton

local function row(order, leftKey, leftArgs, rightText, color)
	local frame = UiKit.panel({ Size = UDim2.new(1, 0, 0, ROW_HEIGHT), BackgroundColor3 = color or P.Card, LayoutOrder = order, corner = Theme.SmallCorner, Parent = list })
	frame:FindFirstChildOfClass("UIStroke").Thickness = 2
	UiKit.label({ key = leftKey, args = leftArgs, style = "Body", Size = UDim2.new(0.65, -10, 1, 0), Position = UDim2.fromOffset(12, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
	UiKit.label({ text = rightText, style = "Body", Size = UDim2.new(0.35, -12, 1, 0), Position = UDim2.fromScale(0.65, 0), TextXAlignment = Enum.TextXAlignment.Right, Parent = frame })
end

local function show(sheet)
	UiKit.clear(list)
	setBones(sheet.bones)
	UiKit.setText(bonesLabel, "PAY_BONES", sheet.bonesHurt, #Bones.list)
	local order = 0
	if #sheet.statuses == 0 and #sheet.injuries == 0 then
		row(order, "PAY_NONE", nil, "")
	end
	for _, entry in sheet.statuses do -- bones by status, worst first
		order += 1
		row(order, InjuryModel.status(entry.id).nameKey, nil, "x" .. entry.count, P.Shade)
	end
	for _, entry in sheet.injuries do -- medical injuries
		order += 1
		row(order, InjuryModel.injury(entry.id).nameKey, nil, "x" .. entry.count)
	end
	row(order + 1, "PAY_BILL", nil, Format.money(sheet.bill), P.Panel)
	row(order + 2, "PAY_TRICKS", nil, "x" .. Format.mult(sheet.multiplier), P.Panel)
	row(order + 3, "PAY_MAP", nil, "x" .. Format.mult(sheet.mapMult), P.Panel)
	row(order + 4, "PAY_TOTAL", nil, Format.money(sheet.total), P.Sun)
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

function PayoutSheet.create()
	local gui = UiKit.screen("Payout", 20)
	root = UiKit.panel({ Size = UDim2.fromScale(0.7, 0.86), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, Parent = gui })
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(860, 760)
	limit.Parent = root

	local header = UiKit.panel({ Size = UDim2.new(1, 0, 0, 74), BackgroundColor3 = P.Coral, Parent = root })
	UiKit.label({ key = "PAY_TITLE", style = "Title", color = P.White, outline = true, Size = UDim2.fromScale(1, 1), Parent = header })

	local figure
	figure, setBones = Skeleton.new(root, { Size = UDim2.new(0.34, 0, 1, -280), Position = UDim2.new(0.04, 0, 0, 90) })
	bonesLabel = UiKit.label({ key = "PAY_BONES", args = { 0, 206 }, style = "Body", Size = UDim2.new(0.36, 0, 0, 32), Position = UDim2.new(0.02, 0, 1, -182), Parent = root })

	list = UiKit.scrollList({ Size = UDim2.new(0.58, 0, 1, -280), Position = UDim2.new(0.4, 0, 0, 90), Parent = root })
	list:FindFirstChildOfClass("UIListLayout").Padding = UDim.new(0, 6)

	cashButton = UiKit.button({ key = "BTN_CASH_OUT", color = P.Money, style = "Title", Size = UDim2.new(0.6, 0, 0, 72), Position = UDim2.new(0.5, 0, 1, -100), AnchorPoint = Vector2.new(0.5, 0.5), Parent = root, onClick = cashOut })
	UiKit.button({ key = "BTN_DOUBLE", args = { Economy.DoubleMoneyRobux }, color = P.Grape, style = "Body", Size = UDim2.new(0.5, 0, 0, 48), Position = UDim2.new(0.5, 0, 1, -36), AnchorPoint = Vector2.new(0.5, 0.5), Parent = root, onClick = function()
		StoreWindow.prompt("double_payout")
	end })

	State.Payout:Connect(show)
	State.PhaseChanged:Connect(function(phase)
		if phase ~= "Payout" then
			root.Visible = false
		end
	end)
	return figure
end

return PayoutSheet
