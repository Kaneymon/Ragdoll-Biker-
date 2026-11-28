-- The empty bike after a bail: while ridden it's one invisible slippery box (the Chassis) with
-- non-colliding decoration welded on. loosen() turns it into a real object that tumbles: the
-- chassis stops colliding and loses its mass, the frame, bars, cranks and wheels collide with
-- their own weight and surfaces (Config/Bike Wreck), and the wheels spin freely on hinges.
-- Safe to call more than once and on both sides: the client calls it the moment it bails (it
-- owns the bike's physics), the server so everyone else sees the same bike.
local RunService = game:GetService("RunService")

local Bike = require(script.Parent.Parent.Config.Bike)

local BikeWreck = {}

local WHEELS = { FrontSpin = "FrontWheel", RearSpin = "RearWheel" }

local function physical(spec)
	return PhysicalProperties.new(spec.Density, spec.Friction, spec.Elasticity, spec.FrictionWeight, spec.ElasticityWeight)
end

-- Swap a wheel's Motor6D for a free hinge round the axle (cylinders spin round their X axis).
local function freeWheel(motor: Motor6D)
	local frame, wheel = motor.Part0, motor.Part1
	if not (frame and wheel) then
		return
	end
	local axle = wheel.CFrame
	local a0 = Instance.new("Attachment")
	a0.Name = motor.Name .. "Axle"
	a0.CFrame = frame.CFrame:ToObjectSpace(axle)
	a0.Parent = frame
	local a1 = Instance.new("Attachment")
	a1.Name = "Axle"
	a1.Parent = wheel
	local hinge = Instance.new("HingeConstraint")
	hinge.Name = motor.Name
	hinge.Attachment0, hinge.Attachment1 = a0, a1
	hinge.Parent = frame
	motor:Destroy()
end

function BikeWreck.loosen(bike: Model)
	if not bike or bike:GetAttribute("Wrecked") then
		return
	end
	local chassis = bike.PrimaryPart
	if not chassis then
		return
	end
	local frameSurface, tyreSurface = physical(Bike.Wreck.Frame), physical(Bike.Wreck.Tyre)
	local tyres = {}
	for _, name in WHEELS do
		local tyre = bike:FindFirstChild(name)
		if tyre then
			tyres[tyre] = true
		end
	end
	for _, part in bike:GetDescendants() do
		if part:IsA("BasePart") and part ~= chassis and part.Transparency < 1 then
			part.CanCollide = true
			part.Massless = false
			part.CustomPhysicalProperties = if tyres[part] then tyreSurface else frameSurface
		end
	end
	chassis.CanCollide = false
	chassis.Massless = true
	local upright = chassis:FindFirstChild("Upright")
	if upright then
		upright.Enabled = false
	end
	-- the wheel hinges replicate from the server; a client copy would be a second hinge
	if RunService:IsServer() then
		for _, item in bike:GetDescendants() do
			if item:IsA("Motor6D") and WHEELS[item.Name] then
				freeWheel(item)
			end
		end
		bike:SetAttribute("Wrecked", true)
	end
end

return BikeWreck
