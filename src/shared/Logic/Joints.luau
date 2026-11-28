-- Character joints for every rig Roblox hands out:
--  * R15 and R6 bodies
--  * AnimationConstraint joints (Avatar Joint Upgrade, the default for new places) or classic Motor6Ds
-- Everything that poses or ragdolls a character goes through here. Poses and ragdoll code use
-- R15 joint names; on R6 bodies find() maps them to the R6 joint ("LeftHip" -> "Left Hip").
local Joints = {}

local ROOT_JOINTS = { Root = true, RootJoint = true }
local R6_NAMES = {
	LeftHip = { "Left Hip" },
	RightHip = { "Right Hip" },
	LeftShoulder = { "Left Shoulder" },
	RightShoulder = { "Right Shoulder" },
	Neck = { "Neck" },
	Waist = { "RootJoint", "Root" }, -- R6 has no waist: lean the whole torso instead
}

local function isJoint(instance)
	return instance:IsA("AnimationConstraint") or instance:IsA("Motor6D")
end

function Joints.isRoot(joint)
	return ROOT_JOINTS[joint.Name] == true
end

-- R6 bodies: one Torso and four single-part limbs (no knees, elbows or waist).
function Joints.isR6(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		return humanoid.RigType == Enum.HumanoidRigType.R6
	end
	return character:FindFirstChild("Torso") ~= nil
end

-- All non-root joints, by name.
function Joints.all(character)
	local joints = {}
	for _, item in character:GetDescendants() do
		if isJoint(item) and not Joints.isRoot(item) then
			joints[item.Name] = item
		end
	end
	return joints
end

local function findNamed(character, name)
	local found = character:FindFirstChild(name, true)
	return if found and isJoint(found) then found else nil
end

-- name is an R15 joint name; R6 bodies get the matching R6 joint (nil when R6 has none).
function Joints.find(character, name)
	local found = findNamed(character, name)
	if found or not Joints.isR6(character) then
		return found
	end
	for _, alias in R6_NAMES[name] or {} do
		found = findNamed(character, alias)
		if found then
			return found
		end
	end
	return nil
end

-- Every joint (root included), keyed by the part it moves.
function Joints.byChild(character)
	local joints = {}
	for _, item in character:GetDescendants() do
		if isJoint(item) then
			local _, part1 = Joints.parts(item)
			if part1 then
				joints[part1] = item
			end
		end
	end
	return joints
end

function Joints.usesConstraints(character)
	return character:FindFirstChildWhichIsA("AnimationConstraint", true) ~= nil
end

-- The two parts a joint connects (works for both joint types).
function Joints.parts(joint)
	if joint:IsA("Motor6D") then
		return joint.Part0, joint.Part1
	end
	return joint.Attachment0 and joint.Attachment0.Parent, joint.Attachment1 and joint.Attachment1.Parent
end

-- The joint's rest frames in Part0 and Part1 space: Part1 = Part0 * frame0 * Transform * frame1:Inverse().
-- Motor6D C0s get posed (RiderPose), so their rest C0 is kept in the BaseC0 attribute.
function Joints.frames(joint)
	if joint:IsA("Motor6D") then
		local base = joint:GetAttribute("BaseC0")
		if not base then
			base = joint.C0
			joint:SetAttribute("BaseC0", base)
		end
		return base, joint.C1
	end
	return joint.Attachment0.CFrame, joint.Attachment1.CFrame
end

-- Where `point` (in `part` space) sits relative to the HumanoidRootPart when the rig stands at rest.
-- byChild = Joints.byChild(character). Returns nil if the part isn't joined up to the root.
function Joints.restPoint(byChild, part, point: Vector3): Vector3?
	local frame = CFrame.new(point)
	while part.Name ~= "HumanoidRootPart" do
		local joint = byChild[part]
		if not joint then
			return nil
		end
		local frame0, frame1 = Joints.frames(joint)
		frame = frame0 * frame1:Inverse() * frame
		part = Joints.parts(joint)
		if not part then
			return nil
		end
	end
	return frame.Position
end

-- Turn the joint so the child part is rotated by `rotation` (in Part0 space, round the joint's
-- pivot) from its rest pose. Rigs orient their joint frames differently (R15 frames are axis
-- aligned, R6 hips and shoulders are turned 90 degrees), so this converts the rotation into the
-- joint's own frame first: the same pose then bends every rig the same way.
-- A Motor6D that the ragdoll switched off is posed through its ragdoll pose drive instead.
function Joints.pose(joint, rotation: CFrame)
	local frame0 = Joints.frames(joint)
	local axes = frame0.Rotation
	local transform = axes:Inverse() * rotation * axes
	if joint:IsA("Motor6D") then
		local drive = not joint.Enabled and joint.Part0 and joint.Part0:FindFirstChild("RagPose_" .. joint.Name)
		if drive then
			drive.CFrame = frame0 * transform
		end
		joint.C0 = frame0 * transform
	else
		joint.Transform = transform
	end
end

return Joints
