-- Skeleton picture for the payout sheet. Each shape stands for a group of the 206 bones and
-- shows its most hurt bone: white (fine) to darkest red (turned to dust).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local P = require(Shared.Config.Palette)
local Bones = require(Shared.Config.Bones)
local InjuryModel = require(Shared.Logic.InjuryModel)
local UiKit = require(script.Parent.UiKit)

local Skeleton = {}

local FIGURE_ASPECT = 0.5 -- width / height

local groupOf = {}
for _, bone in Bones.list do
	groupOf[bone.id] = bone.group
end

function Skeleton.boneColor(damage)
	return P.Bone:Lerp(P.BoneDust, math.clamp(damage, 0, 1))
end

-- Returns the figure frame and a function set(boneMph) where boneMph = { [boneId] = mph }.
function Skeleton.new(parent, props)
	local figure = Instance.new("Frame")
	figure.BackgroundTransparency = 1
	figure.Size = props.Size
	figure.Position = props.Position or UDim2.new()
	figure.Parent = parent
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = FIGURE_ASPECT
	aspect.Parent = figure

	local shapes = {}
	for _, group in Bones.Groups do
		local x, y, w, h, rotation = table.unpack(group.ui)
		local shape = UiKit.shape({
			Name = group.id,
			Size = UDim2.fromScale(w, h),
			Position = UDim2.fromScale(x, y),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = rotation,
			BackgroundColor3 = P.Bone,
			corner = if group.round then UDim.new(0.5, 0) else UDim.new(0, 8),
			strokeThickness = 2,
			Parent = figure,
		})
		shapes[group.id] = shape
	end

	return figure, function(boneMph)
		local worst = {}
		for boneId, mph in boneMph do
			local group = groupOf[boneId]
			if group then
				worst[group] = math.max(worst[group] or 0, mph)
			end
		end
		for id, shape in shapes do
			shape.BackgroundColor3 = Skeleton.boneColor(InjuryModel.boneDamage(worst[id] or 0))
		end
	end
end

return Skeleton
