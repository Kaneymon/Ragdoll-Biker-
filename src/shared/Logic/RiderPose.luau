-- Rider poses from Config/Poses.
--  * apply(): snaps a pose. On the server this replicates for Motor6D rigs (joint C0).
--  * track()/blend(): client side, smoothly blends joints and the seat weld toward a target pose
--    every frame right before physics (AnimationConstraint rigs get it through Transform,
--    as Roblox recommends for procedural animation). Poses with grip = true also pull the hands
--    onto the handlebar grips with IKControls, so the arms follow the bars as they turn.
local RunService = game:GetService("RunService")

local Poses = require(script.Parent.Parent.Config.Poses)
local Joints = require(script.Parent.Joints)

local RiderPose = {}

local tracked = {} -- character -> { target, weld, current = { [jointName] = CFrame }, joints = cache, grips = { IKControl } }
local HANDS = { Left = { "LeftUpperArm", "LeftHand" }, Right = { "RightUpperArm", "RightHand" } }

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

-- Hand IK: one IKControl per arm aiming the hand at the matching grip attachment on the bars.
local function makeGrips(character, bars)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local grips = {}
	for side, chain in HANDS do
		local root, hand, target = character:FindFirstChild(chain[1]), character:FindFirstChild(chain[2]), bars:FindFirstChild(side .. "Grip")
		if humanoid and root and hand and target then
			local ik = Instance.new("IKControl")
			ik.Name = "Grip" .. side
			ik.Type = Enum.IKControlType.Position
			ik.ChainRoot, ik.EndEffector, ik.Target = root, hand, target
			ik.SmoothTime = Poses.GripSmoothTime
			ik.Parent = humanoid
			table.insert(grips, ik)
		end
	end
	return grips
end

local function setGrip(state)
	local on = Poses[state.target].grip == true
	for _, ik in state.grips do
		ik.Enabled = on
	end
end

-- Start blending this character (client). weld = the seat weld to move with the pose,
-- bars = the handlebar part holding LeftGrip/RightGrip attachments (optional).
function RiderPose.track(character, weld, poseName, bars)
	RiderPose.release(character)
	local current = {}
	for name, rot in Poses[poseName].joints do
		current[name] = rotation(rot)
	end
	local state = { target = poseName, weld = weld, current = current, joints = {}, grips = if bars then makeGrips(character, bars) else {} }
	tracked[character] = state
	setGrip(state)
end

function RiderPose.blend(character, poseName)
	local state = tracked[character]
	if state and state.target ~= poseName then
		state.target = poseName
		setGrip(state)
	end
end

-- Stop posing (e.g. when the rider bails and goes limp).
function RiderPose.release(character)
	local state = tracked[character]
	if state then
		for _, ik in state.grips do
			ik:Destroy()
		end
	end
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
