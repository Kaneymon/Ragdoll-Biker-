-- Character joints for both rig styles:
--  * AnimationConstraint rigs (Avatar Joint Upgrade, the default for new places)
--  * classic Motor6D rigs
-- Everything that poses or ragdolls a character goes through here.
local Joints = {}

local ROOT_JOINTS = { Root = true, RootJoint = true }

local function isJoint(instance)
	return instance:IsA("AnimationConstraint") or instance:IsA("Motor6D")
end

function Joints.isRoot(joint)
	return ROOT_JOINTS[joint.Name] == true
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

function Joints.find(character, name)
	local found = character:FindFirstChild(name, true)
	return if found and isJoint(found) then found else nil
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

return Joints
