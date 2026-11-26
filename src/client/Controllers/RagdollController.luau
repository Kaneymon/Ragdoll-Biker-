-- Glide/ragdoll mode: bail off the bike, steer the tumble a little, and end the run at rest.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Bike = require(Shared.Config.Bike)
local Ragdoll = require(Shared.Logic.Ragdoll)
local RiderPose = require(Shared.Logic.RiderPose)
local Net = require(Shared.Net)
local State = require(script.Parent.Parent.State)
local Input = require(script.Parent.Input)
local BikeController = require(script.Parent.BikeController)

local RagdollController = {}

local active = nil -- { character, core, rest, time }

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

	active = { character = character, core = Ragdoll.core(character), rest = 0, time = 0 }
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
	Net.event("RunFinished"):FireServer()
end

-- Camera-relative steering: WASD pushes the body and makes it tumble/flail in that direction
-- (W/S flips forwards/backwards, A/D cartwheels). Strength scales with the Helmet upgrade.
local function glide(dt)
	local move = Input.move()
	if move.Magnitude < 0.1 then
		return
	end
	local camera = workspace.CurrentCamera.CFrame
	local look, right = flat(camera.LookVector), flat(camera.RightVector)
	local control = State.stats.glideControl
	local direction = look * -move.Z + right * move.X
	if direction.Magnitude > 0 then
		Ragdoll.addVelocity(active.character, direction.Unit * Bike.Glide.Accel * control * dt)
	end
	local spinAxis = right * move.Z + look * -move.X
	local spin = active.core.AssemblyAngularVelocity + spinAxis * Bike.Glide.Spin * control * dt
	local maxSpin = Bike.Glide.MaxSpin * control
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
	if active.rest >= Bike.Rest.Time or active.time >= Bike.Rest.MaxTime or active.core.Position.Y < Bike.Rest.KillY then
		finish()
	end
end

function RagdollController.start()
	RunService.Heartbeat:Connect(step)
	State.RequestBail:Connect(RagdollController.bail)
	Input.Began:Connect(function(name)
		if name == "Hop" and State.phase == "Air" then
			RagdollController.bail("player")
		end
	end)
end

return RagdollController
