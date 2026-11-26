-- Full-screen colour flash that fades out (presets in Config/Flashes).
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ScreenFlash = {}

local DISPLAY_ORDER = 50
local frame = nil
local tween = nil

local function ensureFrame()
	if frame then
		return frame
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "ScreenFlash"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = DISPLAY_ORDER
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BorderSizePixel = 0
	frame.BackgroundTransparency = 1
	frame.Active = false
	frame.Parent = gui
	return frame
end

-- preset = { color, start, fade } (see Config/Flashes).
function ScreenFlash.flash(preset)
	local target = ensureFrame()
	if tween then
		tween:Cancel()
	end
	target.BackgroundColor3 = preset.color
	target.BackgroundTransparency = preset.start
	tween = TweenService:Create(target, TweenInfo.new(preset.fade, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 })
	tween:Play()
end

return ScreenFlash
