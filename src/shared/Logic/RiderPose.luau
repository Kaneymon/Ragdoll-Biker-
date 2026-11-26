-- Applies rider poses from Config/Poses to the character's joints and seat weld.
--  * Motor6D rigs: the joint C0 is rotated (replicates when done on the server).
--  * AnimationConstraint rigs: the pose is written into Transform every frame on the client,
--    right before physics, as Roblox recommends for procedural animation.
local RunService = game:GetService("RunService")

local Poses = require(script.Parent.Parent.Config.Poses)
local Joints = require(script.Parent.Joints)

local RiderPose = {}

local held = {} -- character -> { [AnimationConstraint] = CFrame }

local function rotation(rot)
	return CFrame.Angles(math.rad(rot[1]), math.rad(rot[2]), math.rad(rot[3]))
end

local function baseC0(joint)
	local base = joint:GetAttribute("BaseC0")
	if not base then
		base = joint.C0
		joint:SetAttribute("BaseC0", base)
	end
	return base
end

function RiderPose.apply(character, poseName)
	local pose = Poses[poseName]
	local transforms = {}
	for name, rot in pose.joints do
		local joint = Joints.find(character, name)
		if joint and joint:IsA("Motor6D") then
			joint.C0 = baseC0(joint) * rotation(rot)
		elseif joint then
			transforms[joint] = rotation(rot)
		end
	end
	held[character] = if next(transforms) then transforms else nil
end

-- Stop holding a pose (e.g. when the rider bails and goes limp).
function RiderPose.release(character)
	held[character] = nil
end

-- Weld C0 (chassis space) that puts the rider's root where this pose wants it.
function RiderPose.seat(poseName)
	return Poses.Seat * Poses[poseName].offset
end

if RunService:IsClient() then
	RunService.PreSimulation:Connect(function()
		for character, transforms in held do
			if not character.Parent then
				held[character] = nil
				continue
			end
			for joint, transform in transforms do
				joint.Transform = transform
			end
		end
	end)
end

return RiderPose
