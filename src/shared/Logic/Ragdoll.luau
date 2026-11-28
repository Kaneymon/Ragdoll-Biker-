-- Ragdoll for both rig styles (see Logic/Joints):
--  * AnimationConstraint rigs already ship with ball sockets: going limp = turning the drives off.
--  * Motor6D rigs get ball sockets added once (setup), then motors are swapped for sockets.
-- Runs on the server (so everyone sees it) and on the owning client (so it feels instant).
local Bike = require(script.Parent.Parent.Config.Bike)
local Joints = require(script.Parent.Joints)

local Ragdoll = {}

local SURFACE = Bike.RagdollPhysics
local MIN_FRICTION = 0.03
local LIMITS = { -- Motor6D rigs only: { cone angle, twist } in degrees
	Neck = { 35, 40 },
	Waist = { 25, 30 },
	default = { 70, 70 },
}

function Ragdoll.parts(character)
	local parts = {}
	for _, child in character:GetChildren() do
		if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
			table.insert(parts, child)
		end
	end
	return parts
end

local function addSocket(motor)
	local a0 = Instance.new("Attachment")
	a0.Name = "RagA0_" .. motor.Name
	a0.CFrame = motor.C0
	a0.Parent = motor.Part0
	local a1 = Instance.new("Attachment")
	a1.Name = "RagA1_" .. motor.Name
	a1.CFrame = motor.C1
	a1.Parent = motor.Part1
	local limit = LIMITS[motor.Name] or LIMITS.default
	local socket = Instance.new("BallSocketConstraint")
	socket.Name = "Rag_" .. motor.Name
	socket.Attachment0 = a0
	socket.Attachment1 = a1
	socket.LimitsEnabled = true
	socket.TwistLimitsEnabled = true
	socket.UpperAngle = limit[1]
	socket.TwistLowerAngle = -limit[2]
	socket.TwistUpperAngle = limit[2]
	socket.Enabled = false
	socket.Parent = motor.Parent
	local noCollide = Instance.new("NoCollisionConstraint")
	noCollide.Part0 = motor.Part0
	noCollide.Part1 = motor.Part1
	noCollide.Parent = socket
end

-- Call once per character, before posing it (Motor6D rigs need sockets made at the rest pose).
function Ragdoll.setup(character)
	if character:GetAttribute("RagdollReady") then
		return
	end
	for _, joint in Joints.all(character) do
		if joint:IsA("Motor6D") and joint.Part0 and joint.Part1 then
			addSocket(joint)
		end
	end
	character:SetAttribute("RagdollReady", true)
end

local function goLimp(character)
	for _, joint in Joints.all(character) do
		joint.Enabled = false
	end
	for _, item in character:GetDescendants() do
		if item:IsA("BallSocketConstraint") then
			item.Enabled = true
		end
	end
end

-- Body surface from upgrade stats: Kneepads (slide) cut friction, Body Armour (bounce) adds bounce.
function Ragdoll.surface(stats)
	local friction = math.max(MIN_FRICTION, SURFACE.Friction * (1 - (stats.slide or 0)))
	local elasticity = math.min(1, SURFACE.Elasticity + (stats.bounce or 0))
	return PhysicalProperties.new(SURFACE.Density, friction, elasticity, SURFACE.FrictionWeight, SURFACE.ElasticityWeight)
end

function Ragdoll.enable(character, surface: PhysicalProperties)
	goLimp(character)
	for _, part in Ragdoll.parts(character) do
		part.CanCollide = true
		part.Massless = false
		part.CustomPhysicalProperties = surface
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CanCollide = false
		root.Massless = true
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = true
		humanoid.AutoRotate = false
	end
	character:SetAttribute("Ragdolled", true)
end

-- Motor6D rigs pose a limp body with an AlignOrientation per joint: it turns the child part
-- towards the "RagPose_<joint>" attachment on the parent part, which Joints.pose moves.
local function poseDrive(joint)
	local part0, part1 = joint.Part0, joint.Part1
	local align = part0:FindFirstChild("RagAlign_" .. joint.Name)
	if align then
		return align
	end
	local child = Instance.new("Attachment")
	child.Name = "RagPoseChild_" .. joint.Name
	child.CFrame = joint.C1
	child.Parent = part1
	local target = Instance.new("Attachment")
	target.Name = "RagPose_" .. joint.Name
	target.CFrame = part0.CFrame:ToObjectSpace(part1.CFrame * joint.C1) -- start where the limb is now
	target.Parent = part0
	align = Instance.new("AlignOrientation")
	align.Name = "RagAlign_" .. joint.Name
	align.Mode = Enum.OrientationAlignmentMode.TwoAttachment
	align.Attachment0, align.Attachment1 = child, target
	align.ReactionTorqueEnabled = true
	align.Responsiveness = Bike.Glide.PoseResponsiveness
	align.MaxTorque = Bike.Glide.PoseTorque
	align.Enabled = false
	align.Parent = part0
	return align
end

-- Ragdoll poses: switch the pose joints' drives on (torque-limited, so the limp body still
-- tumbles) or back off. The pose itself is written by Logic/RiderPose (through Joints.pose).
-- jointNames are R15 names; joints an R6 body doesn't have are skipped. Returns true when posed.
function Ragdoll.drive(character, jointNames, on: boolean)
	local constraints = Joints.usesConstraints(character)
	local posed = false
	for _, name in jointNames do
		local joint = Joints.find(character, name)
		if not joint or Joints.isRoot(joint) then
			continue
		end
		if constraints then
			joint.IsKinematic = false
			joint.MaxTorque = Bike.Glide.PoseTorque
			joint.Enabled = on
		elseif joint.Part0 and joint.Part1 then
			poseDrive(joint).Enabled = on
		end
		posed = true
	end
	return posed
end

function Ragdoll.setVelocity(character, velocity)
	for _, part in Ragdoll.parts(character) do
		part.AssemblyLinearVelocity = velocity
	end
end

function Ragdoll.addVelocity(character, delta)
	for _, part in Ragdoll.parts(character) do
		part.AssemblyLinearVelocity += delta
	end
end

-- The part the camera and rest check follow.
function Ragdoll.core(character)
	return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
end

return Ragdoll
