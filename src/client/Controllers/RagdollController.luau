-- Glide/ragdoll mode: bail off the bike, steer the tumble a little, and end the run at rest.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Bike = require(Shared.Config.Bike)
local Ragdoll = require(Shared.Logic.Ragdoll)
local MapGeometry = require(Shared.Logic.MapGeometry)
local RiderPose = require(Shared.Logic.RiderPose)
local Net = require(Shared.Net)
local State = require(script.Parent.Parent.State)
local Input = require(script.Parent.Input)
local BikeController = require(script.Parent.BikeController)

local RagdollController = {}

local active = nil -- { character, core, rest, time, floorY }
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Include

local function flat(v)
	local f = Vector3.new(v.X, 0, v.Z)
	return if f.Magnitude > 1e-3 then f.Unit else Vector3.zero
end

local function bailVelocity(ride)
	if not ride then
		return Vector3.zero
	end
	local force = State.stats.bailForce
	local look = ride.chassis.CFrame.LookVector
	-- Hitting something stops the bike, not the rider: keep the speed the bike had before the hit.
	local velocity = ride.chassis.AssemblyLinearVelocity
	if State.phase == "Riding" and ride.speed > velocity.Magnitude then
		velocity = look * ride.speed
	end
	return velocity + Vector3.yAxis * force + look * force * 0.5
end

function RagdollController.bail(reason: string, extraVelocity: Vector3?)
	if not State.isRiding() then
		return
	end
	local character = State.character
	local ride = BikeController.release()
	local weld = ride and ride.chassis:FindFirstChild("RiderWeld")
	if weld then
		weld:Destroy()
	end
	RiderPose.release(character)
	Ragdoll.enable(character, Ragdoll.surface(State.stats))
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end
	Ragdoll.setVelocity(character, bailVelocity(ride) + (extraVelocity or Vector3.zero))

	local floorY = MapGeometry.floorY(MapGeometry.def(State.profile.maps.selected))
	active = { character = character, core = Ragdoll.core(character), rest = 0, time = 0, floorY = floorY }
	State.setPhase("Ragdoll")
	Players.LocalPlayer:SetAttribute("BailReason", reason)
	State.Bailed:Fire(reason)
	Net.event("Bail"):FireServer(State.run.tricks, State.run.maxSpeed)
end

function RagdollController.character()
	return active and active.character
end

local function finish()
	active = nil
	State.setPhase("Resting")
	Net.event("RunFinished"):FireServer(State.run.ragdollTricks)
end

local function onGround()
	groundParams.FilterDescendantsInstances = { workspace:FindFirstChild("World") }
	return workspace:Raycast(active.core.Position, Vector3.new(0, -Bike.Glide.GroundReach, 0), groundParams) ~= nil
end

-- Ground steering: Kneepads (slide) take it from GroundShare up to full and beyond.
local function groundControl(stats)
	local g = Bike.Glide
	return g.GroundShare + (1 - g.GroundShare) * stats.slide / g.FullGroundSlide
end

-- Air steering: Helmet airControl, topped up towards full control as speed builds.
local function airControl(stats)
	if stats.airControl >= 1 then
		return stats.airControl
	end
	local speedShare = math.clamp(active.core.AssemblyLinearVelocity.Magnitude / Bike.Glide.FullSpeed, 0, 1)
	return stats.airControl + (1 - stats.airControl) * speedShare
end

-- How much steering you get right now (see Config/Bike Glide).
local function control()
	return if onGround() then groundControl(State.stats) else airControl(State.stats)
end

-- Camera-relative steering: WASD pushes the body and makes it tumble/flail in that direction
-- (W/S flips forwards/backwards, A/D cartwheels). Strength scales with Helmet and Kneepads.
local function glide(dt)
	local move = Input.move()
	if move.Magnitude < 0.1 then
		return
	end
	local camera = workspace.CurrentCamera.CFrame
	local look, right = flat(camera.LookVector), flat(camera.RightVector)
	local strength = control()
	local direction = look * -move.Z + right * move.X
	if direction.Magnitude > 0 then
		Ragdoll.addVelocity(active.character, direction.Unit * Bike.Glide.Accel * strength * dt)
	end
	local spinAxis = right * move.Z + look * -move.X
	local spin = active.core.AssemblyAngularVelocity + spinAxis * Bike.Glide.Spin * strength * dt
	local maxSpin = Bike.Glide.MaxSpin * strength
	active.core.AssemblyAngularVelocity = if spin.Magnitude > maxSpin then spin.Unit * maxSpin else spin
end

local function step(dt)
	if not active or State.phase ~= "Ragdoll" then
		return
	end
	glide(dt)
	local speed = active.core.AssemblyLinearVelocity.Magnitude
	State.run.maxSpeed = math.max(State.run.maxSpeed, speed)
	active.time += dt
	active.rest = if speed < Bike.Rest.Speed then active.rest + dt else 0
	if active.rest >= Bike.Rest.Time or active.time >= Bike.Rest.MaxTime or active.core.Position.Y < active.floorY - Bike.Rest.FallBelowMap then
		finish()
	end
end

function RagdollController.start()
	RunService.Heartbeat:Connect(step)
	State.RequestBail:Connect(RagdollController.bail)
	Input.Began:Connect(function(name)
		if name == "Bail" and State.isRiding() then
			RagdollController.bail("player")
		end
	end)
end

return RagdollController
