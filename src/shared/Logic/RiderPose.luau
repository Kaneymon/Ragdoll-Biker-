-- Rider poses from Config/Poses.
--  * apply(): snaps a pose. On the server this replicates for Motor6D rigs (joint C0).
--  * track()/blend(): client side, smoothly blends joints and the seat weld toward a target pose
--    every frame right before physics (AnimationConstraint rigs get it through Transform,
--    as Roblox recommends for procedural animation).
local RunService = game:GetService("RunService")

local Poses = require(script.Parent.Parent.Config.Poses)
local Joints = require(script.Parent.Joints)

local RiderPose = {}

local tracked = {} -- character -> { target, weld, current = { [jointName] = CFrame }, joints = cache }

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

local function setJoint(joint, transform)
	if joint:IsA("Motor6D") then
		joint.C0 = baseC0(joint) * transform
	else
		joint.Transform = transform
	end
end

-- Weld C0 (chassis space) that puts the rider's root where this pose wants it.
function RiderPose.seat(poseName)
	return Poses.Seat * Poses[poseName].offset
end

function RiderPose.apply(character, poseName)
	for name, rot in Poses[poseName].joints do
		local joint = Joints.find(character, name)
		if joint then
			setJoint(joint, rotation(rot))
		end
	end
end

-- Start blending this character (client). weld = the seat weld to move with the pose.
function RiderPose.track(character, weld, poseName)
	local current = {}
	for name, rot in Poses[poseName].joints do
		current[name] = rotation(rot)
	end
	tracked[character] = { target = poseName, weld = weld, current = current, joints = {} }
end

function RiderPose.blend(character, poseName)
	local state = tracked[character]
	if state then
		state.target = poseName
	end
end

-- Stop posing (e.g. when the rider bails and goes limp).
function RiderPose.release(character)
	tracked[character] = nil
end

local function step(dt)
	local alpha = 1 - math.exp(-dt * Poses.BlendRate)
	for character, state in tracked do
		if not character.Parent then
			tracked[character] = nil
			continue
		end
		local pose = Poses[state.target]
		for name, rot in pose.joints do
			local current = (state.current[name] or CFrame.identity):Lerp(rotation(rot), alpha)
			state.current[name] = current
			state.joints[name] = state.joints[name] or Joints.find(character, name)
			if state.joints[name] then
				setJoint(state.joints[name], current)
			end
		end
		if state.weld and state.weld.Parent then
			state.weld.C0 = state.weld.C0:Lerp(RiderPose.seat(state.target), alpha)
		end
	end
end

if RunService:IsClient() then
	RunService.PreSimulation:Connect(step)
end

return RiderPose
