-- Chase camera for bike and ragdoll: follows travel direction, widens with speed, can shake.
local RunService = game:GetService("RunService")

local State = require(script.Parent.Parent.State)
local BikeController = require(script.Parent.BikeController)
local RagdollController = require(script.Parent.RagdollController)
local Ragdoll = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Logic.Ragdoll)
local Ground = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Logic.Ground)

local CameraController = {}

local BASE = { distance = 18, height = 7, fov = 70 }
local PER_SPEED = { distance = 0.015, height = 0.006, fov = 0.02 } -- how much speed pulls the camera back
local MAX_FOV_BONUS = 12
local SHAKE_DECAY = 6
local CLEARANCE = 2
local MAX_PITCH = 0.6 -- keeps the camera from looking straight up or down

local direction = Vector3.new(0, 0, 1)
local shake = 0
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

local function subject()
	local character = RagdollController.character()
	if character then
		return Ragdoll.core(character)
	end
	local chassis = BikeController.chassis()
	if chassis then
		return chassis
	end
	return State.character and Ragdoll.core(State.character)
end

local function limitPitch(v)
	return Vector3.new(v.X, math.clamp(v.Y, -MAX_PITCH, MAX_PITCH), v.Z).Unit
end

-- Pull the camera in front of any hill or wall between it and the rider.
local function unblocked(focus, wanted)
	rayParams.FilterDescendantsInstances = Ground.instances()
	local hit = workspace:Raycast(focus, wanted - focus, rayParams)
	return if hit then hit.Position + hit.Normal * CLEARANCE else wanted
end

function CameraController.shake(amount: number)
	shake = math.max(shake, amount)
end

local function step(dt)
	local camera = workspace.CurrentCamera
	local target = subject()
	if not target or State.phase == "Loading" then
		camera.CameraType = Enum.CameraType.Custom
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable

	local velocity = target.AssemblyLinearVelocity
	local speed = velocity.Magnitude
	-- Follow the travel direction including slope, so the camera rides above ramps instead of inside them.
	if speed > 5 then
		direction = direction:Lerp(limitPitch(velocity.Unit), math.min(1, dt * 2)).Unit
	elseif State.phase == "Ready" then
		direction = limitPitch(target.CFrame.LookVector)
	end

	local distance = BASE.distance + speed * PER_SPEED.distance
	local height = BASE.height + speed * PER_SPEED.height
	local focus = target.Position + Vector3.new(0, 2, 0)
	local goal = CFrame.lookAt(unblocked(focus, focus - direction * distance + Vector3.new(0, height, 0)), focus)
	-- Position follows the rider exactly (no lag at high speed); only the direction is smoothed.
	local cf = goal
	if shake > 0.01 then
		cf *= CFrame.Angles((math.random() - 0.5) * shake * 0.05, (math.random() - 0.5) * shake * 0.05, 0)
		shake *= math.exp(-dt * SHAKE_DECAY)
	end
	camera.CFrame = cf
	camera.FieldOfView = BASE.fov + math.min(speed * PER_SPEED.fov, MAX_FOV_BONUS)
end

function CameraController.start()
	RunService:BindToRenderStep("RagdollBikerCamera", Enum.RenderPriority.Camera.Value + 1, step)
end

return CameraController
