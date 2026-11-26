-- Ragdoll for both rig styles (see Logic/Joints):
--  * AnimationConstraint rigs already ship with ball sockets: going limp = turning the drives off.
--  * Motor6D rigs get ball sockets added once (setup), then motors are swapped for sockets.
-- Runs on the server (so everyone sees it) and on the owning client (so it feels instant).
local Bike = require(script.Parent.Parent.Config.Bike)
local Joints = require(script.Parent.Joints)

local Ragdoll = {}

local SURFACE = Bike.RagdollPhysics
local BODY_PHYSICS = PhysicalProperties.new(SURFACE.Density, SURFACE.Friction, SURFACE.Elasticity, SURFACE.FrictionWeight, SURFACE.ElasticityWeight)
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

function Ragdoll.enable(character)
	goLimp(character)
	for _, part in Ragdoll.parts(character) do
		part.CanCollide = true
		part.Massless = false
		part.CustomPhysicalProperties = BODY_PHYSICS
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
