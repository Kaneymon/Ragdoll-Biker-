-- Skeleton picture for the payout sheet: each bone goes from white (fine) to dark red (dust).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local P = require(Shared.Config.Palette)
local Injuries = require(Shared.Config.Injuries)
local UiKit = require(script.Parent.UiKit)

local Skeleton = {}

local FIGURE_ASPECT = 0.5 -- width / height

function Skeleton.boneColor(damage)
	return P.Bone:Lerp(P.BoneDust, math.clamp(damage, 0, 1))
end

-- Returns the figure frame and a function set(bones) where bones = { [boneId] = damage }.
function Skeleton.new(parent, props)
	local figure = Instance.new("Frame")
	figure.BackgroundTransparency = 1
	figure.Size = props.Size
	figure.Position = props.Position or UDim2.new()
	figure.Parent = parent
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = FIGURE_ASPECT
	aspect.Parent = figure

	local bones = {}
	for _, def in Injuries.Bones do
		local x, y, w, h, rotation = table.unpack(def.ui)
		local bone = UiKit.panel({
			Name = def.id,
			Size = UDim2.fromScale(w, h),
			Position = UDim2.fromScale(x, y),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = rotation,
			BackgroundColor3 = P.Bone,
			corner = if def.round then UDim.new(0.5, 0) else UDim.new(0, 8),
			Parent = figure,
		})
		bone:FindFirstChildOfClass("UIStroke").Thickness = 2
		bones[def.id] = bone
	end

	return figure, function(damageByBone)
		for id, bone in bones do
			bone.BackgroundColor3 = Skeleton.boneColor(damageByBone[id] or 0)
		end
	end
end

return Skeleton
