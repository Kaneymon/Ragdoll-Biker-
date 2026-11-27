-- GRAVITY CONTROLLER (Robux pass): a slider in the bottom-right corner, Store.GravityRange times
-- normal gravity. The scale is logarithmic so 1x sits in a sensible spot and low values aren't
-- squashed. Dragging changes gravity straight away; letting go saves it to the profile.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local P = require(Shared.Config.Palette)
local Store = require(Shared.Config.Store)
local Theme = require(Shared.Config.Theme)
local Format = require(Shared.Util.Format)
local Net = require(Shared.Net)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.UiKit)

local GravitySlider = {}

local RANGE = Store.GravityRange
local SNAP = 0.06 -- values this close to 1x snap to exactly 1x
local KNOB = 34

local root, label, track, fill, knob
local dragging = false

local function toFraction(gravity)
	return math.log(gravity / RANGE.min) / math.log(RANGE.max / RANGE.min)
end

local function fromFraction(t)
	local gravity = RANGE.min * (RANGE.max / RANGE.min) ^ math.clamp(t, 0, 1)
	return if math.abs(gravity - 1) < SNAP then 1 else gravity
end

local function show(gravity)
	local t = toFraction(gravity)
	fill.Size = UDim2.fromScale(t, 1)
	knob.Position = UDim2.fromScale(t, 0.5)
	UiKit.setText(label, "HUD_GRAVITY", Format.mult(gravity))
end

-- Pointer x on screen -> gravity, applied locally while dragging.
local function dragTo(x)
	local t = (x - track.AbsolutePosition.X) / track.AbsoluteSize.X
	local gravity = fromFraction(t)
	State.profile.settings.gravity = gravity
	State.refreshStats()
	show(gravity)
end

local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function build()
	local gui = UiKit.screen("GravityController", 5)
	root = UiKit.panel({ Size = UDim2.fromOffset(320, 104), Position = UDim2.new(1, -16, 1, -16), AnchorPoint = Vector2.new(1, 1), BackgroundColor3 = P.Grape, Visible = false, Parent = gui })
	label = UiKit.label({ key = "HUD_GRAVITY", args = { "1" }, style = "Heading", color = P.White, outline = true, Size = UDim2.new(1, -24, 0, 40), Position = UDim2.fromOffset(12, 6), Parent = root })
	track = UiKit.shape({ Size = UDim2.new(1, -56, 0, 16), Position = UDim2.new(0.5, 0, 0, 68), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = P.Ink, corner = Theme.SmallCorner, Parent = root })
	fill = UiKit.shape({ Size = UDim2.fromScale(0.4, 1), BackgroundColor3 = P.Sun, stroke = false, corner = Theme.SmallCorner, Parent = track })
	knob = UiKit.shape({ Size = UDim2.fromOffset(KNOB, KNOB), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = P.Panel, corner = UDim.new(0.5, 0), ZIndex = 2, Parent = track })
	local hit = Instance.new("TextButton") -- a taller invisible grab area over the track
	hit.Text = ""
	hit.BackgroundTransparency = 1
	hit.Size = UDim2.new(1, KNOB, 0, 56)
	hit.Position = UDim2.fromScale(0.5, 0.5)
	hit.AnchorPoint = Vector2.new(0.5, 0.5)
	hit.ZIndex = 3
	hit.Parent = track
	hit.InputBegan:Connect(function(input)
		if isPointer(input) then
			dragging = true
			dragTo(input.Position.X)
		end
	end)
end

function GravitySlider.create()
	build()
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			dragTo(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if dragging and isPointer(input) then
			dragging = false
			Net.func("SetSetting"):InvokeServer("gravity", State.profile.settings.gravity)
		end
	end)
	State.StatsChanged:Connect(function(stats)
		root.Visible = stats.gravityControl
		if not dragging then
			show(State.profile.settings.gravity)
		end
	end)
end

return GravitySlider
