-- Reusable UI building blocks. Every screen is made from these so shapes, fonts and colours match.
-- Text always comes from a Localize key ("key" + "args") unless "text" is given for numbers.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared.Config.Theme)
local Assets = require(Shared.Config.UiAssets)
local P = require(Shared.Config.Palette)
local Localize = require(Shared.Services.Localize)
local Sfx = require(Shared.Services.Sfx)

local UiKit = {}

local PRESS_TWEEN = TweenInfo.new(0.08)
local POP_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- Decorators -----------------------------------------------------------------
function UiKit.corner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or Theme.Corner
	corner.Parent = instance
	return corner
end

function UiKit.stroke(instance, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or P.Ink
	stroke.Thickness = thickness or Theme.Stroke
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = instance
	return stroke
end

function UiKit.padding(instance, pixels)
	local padding = Instance.new("UIPadding")
	local p = UDim.new(0, pixels or Theme.Padding)
	padding.PaddingTop, padding.PaddingBottom, padding.PaddingLeft, padding.PaddingRight = p, p, p, p
	padding.Parent = instance
	return padding
end

function UiKit.listLayout(instance, direction, gap, align)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction or Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, gap or Theme.Padding)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = align or Enum.HorizontalAlignment.Center
	layout.Parent = instance
	return layout
end

local function apply(instance, props)
	for key, value in props do
		instance[key] = value
	end
	return instance
end

-- Scales a whole screen with the window height so pixel sizes look the same on phones and PCs.
function UiKit.autoScale(gui)
	local scale = Instance.new("UIScale")
	scale.Parent = gui
	local function update()
		local height = workspace.CurrentCamera.ViewportSize.Y
		scale.Scale = math.clamp(height / Theme.DesignHeight, Theme.MinScale, Theme.MaxScale)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	update()
	return scale
end

-- Elements -------------------------------------------------------------------
function UiKit.screen(name: string, order: number?)
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets -- never under Roblox's own buttons
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = order or 0
	UiKit.autoScale(gui)
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

-- 9-slice image setup. cornerPx = how big the rounded corners should look on screen.
local function sliced(image, asset, cornerPx)
	image.BackgroundTransparency = 1
	image.ScaleType = Enum.ScaleType.Slice
	image.SliceCenter = asset.slice
	image.SliceScale = cornerPx / asset.radius
end

-- Panel from the GUI pack's rounded box, tinted with BackgroundColor3 (default: panel white).
function UiKit.panel(props)
	local box = Instance.new("ImageLabel")
	box.Image = Assets.Box.image
	sliced(box, Assets.Box, props.cornerPx or Theme.PanelCorner)
	box.ImageColor3 = props.BackgroundColor3 or P.Panel
	props.BackgroundColor3, props.corner, props.stroke, props.cornerPx = nil, nil, nil, nil
	return apply(box, props)
end

-- Plain rounded, outlined shape (for drawings such as the skeleton and bars).
function UiKit.shape(props)
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = P.Panel
	frame.BorderSizePixel = 0
	UiKit.corner(frame, props.corner)
	if props.stroke ~= false then
		UiKit.stroke(frame, nil, props.strokeThickness)
	end
	props.corner, props.stroke, props.strokeThickness = nil, nil, nil
	return apply(frame, props)
end

-- An icon from the GUI pack (Config/UiAssets.Icons).
function UiKit.icon(name, props)
	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Image = Assets.Icons[name]
	icon.ScaleType = Enum.ScaleType.Fit
	return apply(icon, props)
end

-- Ready-made pill colours from the pack; any other colour tints the white pill.
local PILLS = { [P.Money] = "green", [P.Grass] = "green", [P.Sky] = "blue", [P.Orange] = "orange", [P.Sun] = "orange", [P.Disabled] = "grey" }

local buttonColours = setmetatable({}, { __mode = "k" })

local function setPillColour(button, color)
	local ready = PILLS[color]
	button.Image = if ready then Assets.Pills[ready] else Assets.Pill.image
	button.ImageColor3 = if ready then P.White else color
end

-- Change a button's colour (keeps the grey "disabled" look working).
function UiKit.recolour(button, color)
	buttonColours[button] = color
	if not button:GetAttribute("Disabled") then
		setPillColour(button, color)
	end
end

local function styleText(label, style, color)
	label.BackgroundTransparency = 1
	label.Font = if style == "Body" or style == "Small" then Theme.Font.Body else Theme.Font.Title
	label.TextSize = Theme.TextSize[style or "Body"]
	label.TextColor3 = color or P.Ink
	label.TextWrapped = true
	label.TextScaled = false
end

-- Text label. props.key/args or props.text, props.style (Huge/Title/Heading/Body/Small),
-- props.color, props.outline (white text with dark edge for HUD).
function UiKit.label(props)
	local label = Instance.new("TextLabel")
	styleText(label, props.style, props.color)
	label.Text = if props.key then Localize.get(props.key, table.unpack(props.args or {})) else (props.text or "")
	if props.outline then
		local stroke = Instance.new("UIStroke")
		stroke.Color = P.Ink
		stroke.Thickness = 3
		stroke.Parent = label
	end
	props.key, props.args, props.text, props.style, props.color, props.outline = nil, nil, nil, nil, nil, nil
	return apply(label, props)
end

function UiKit.setText(label, key, ...)
	local target = if label:IsA("ImageButton") then label:FindFirstChild("Label") else label
	target.Text = Localize.get(key, ...)
end

-- Chunky button. props.key/args/text, props.color, props.onClick, props.style.
-- Returns the button; button:SetAttribute("Disabled", true) greys it out.
function UiKit.button(props)
	local button = Instance.new("ImageButton")
	button.AutoButtonColor = false
	buttonColours[button] = props.color or P.Sky
	setPillColour(button, buttonColours[button])
	button.Size = UDim2.new(1, 0, 0, Theme.ButtonHeight)
	local label = UiKit.label({
		key = props.key, args = props.args, text = props.text, style = props.style or "Heading", color = P.White, outline = true,
		Name = "Label", Size = UDim2.new(1, -24, 1, -6), Position = UDim2.fromOffset(12, 0), Parent = button,
	})
	label.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = Theme.TextSize[props.style or "Heading"]
	limit.Parent = label
	local scale = Instance.new("UIScale")
	scale.Parent = button

	local onClick = props.onClick
	button.Activated:Connect(function()
		if button:GetAttribute("Disabled") then
			Sfx.play("Error")
			return
		end
		Sfx.play("Click")
		TweenService:Create(scale, PRESS_TWEEN, { Scale = 0.92 }):Play()
		task.delay(0.08, function()
			TweenService:Create(scale, PRESS_TWEEN, { Scale = 1 }):Play()
		end)
		if onClick then
			onClick(button)
		end
	end)
	button:GetAttributeChangedSignal("Disabled"):Connect(function()
		setPillColour(button, if button:GetAttribute("Disabled") then P.Disabled else buttonColours[button])
	end)
	props.key, props.args, props.text, props.color, props.onClick, props.style = nil, nil, nil, nil, nil, nil
	apply(button, props)
	local height = if button.Size.Y.Offset > 0 then button.Size.Y.Offset else Theme.TabHeight
	sliced(button, Assets.Pill, height / 2)
	return button
end

-- Round red close button with a cross (from the GUI pack). props: Position, AnchorPoint, Parent, onClick.
function UiKit.closeButton(props)
	local button = Instance.new("ImageButton")
	button.BackgroundTransparency = 1
	button.Image = Assets.Icons.closeCircle
	button.Size = UDim2.fromOffset(62, 62)
	button.ZIndex = 4
	UiKit.icon("cross", { Size = UDim2.fromScale(0.55, 0.55), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 5, Parent = button })
	local onClick = props.onClick
	button.Activated:Connect(function()
		Sfx.play("Click")
		onClick()
	end)
	props.onClick = nil
	return apply(button, props)
end

-- Single-column scrolling list (used by every menu with lots of content).
function UiKit.scrollList(props)
	local list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 10
	list.ScrollBarImageColor3 = P.Ink
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollingDirection = Enum.ScrollingDirection.Y
	UiKit.listLayout(list)
	local padding = UiKit.padding(list, 6)
	padding.PaddingRight = UDim.new(0, 16)
	return apply(list, props)
end

function UiKit.clear(container)
	for _, child in container:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- Progress bar. Returns frame and a setter (0..1).
function UiKit.bar(props)
	local frame = UiKit.shape({ Size = props.Size, Position = props.Position, AnchorPoint = props.AnchorPoint, BackgroundColor3 = P.Ink, Parent = props.Parent, corner = Theme.SmallCorner })
	local fill = UiKit.shape({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = props.color or P.Sun, stroke = false, corner = Theme.SmallCorner, Parent = frame })
	return frame, function(fraction)
		fill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
		fill.Visible = fraction > 0.001
	end
end

-- Little "pop" animation for things that appear.
function UiKit.pop(guiObject)
	local scale = guiObject:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", guiObject)
	scale.Scale = 0.6
	TweenService:Create(scale, POP_TWEEN, { Scale = 1 }):Play()
end

return UiKit
