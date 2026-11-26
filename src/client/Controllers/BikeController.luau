-- Bike mode: pedal, brake, steer and hop on the ground; spin in the air; land or crash.
-- Ground riding sets the chassis velocity directly (arcade feel); air time is real physics.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Bike = require(Shared.Config.Bike)
local State = require(script.Parent.Parent.State)
local Input = require(script.Parent.Input)

local BikeController = {
	boostAccel = 0, -- set by GearController while boosting
}

local UP = Vector3.yAxis
local WHEEL_RADIUS = 1.25
local LEAVE_MARGIN = 1.4
local CRASH_SPEED_RATIO = 0.35
local CRASH_MIN_SPEED = 70

local ride = nil -- current bike context
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return if f.Magnitude > 1e-3 then f.Unit else Vector3.new(0, 0, 1)
end

local function cast(direction: Vector3, length: number)
	return workspace:Raycast(ride.chassis.Position, direction * length, rayParams)
end

function BikeController.chassis()
	return ride and ride.chassis
end

function BikeController.joint(name: string)
	return ride and ride.joints[name]
end

function BikeController.speed()
	return ride and ride.chassis.AssemblyLinearVelocity.Magnitude or 0
end

-- Air step ------------------------------------------------------------------
local function land(hit)
	local chassis = ride.chassis
	local cf, velocity, n = chassis.CFrame, chassis.AssemblyLinearVelocity, hit.Normal
	local look = cf.LookVector - n * cf.LookVector:Dot(n)
	local planar = velocity - n * velocity:Dot(n)
	local upright = cf.UpVector:Dot(n) >= math.cos(math.rad(Bike.CrashAngle))
	local straight = planar.Magnitude < 20 or (look.Magnitude > 0.1 and look.Unit:Dot(planar.Unit) >= math.cos(math.rad(Bike.SideslipAngle)))
	if upright and straight and not State.run.trickBusy then
		ride.heading = flat(look)
		ride.speed = math.max(0, velocity:Dot(look.Unit))
		ride.align.CFrame = CFrame.lookAt(Vector3.zero, look.Unit, n)
		ride.align.Enabled = true
		State.setPhase("Riding")
		State.Landed:Fire(-velocity:Dot(n))
	else
		State.RequestBail:Fire("crash")
	end
end

-- With no flip input the nose gently follows the flight path, so a clean jump lands clean.
local function noseFollow(cf, velocity)
	if velocity.Magnitude < 10 then
		return 0
	end
	return cf.LookVector:Cross(velocity.Unit):Dot(cf.RightVector) * Bike.AirSpin.AutoLevel
end

local function stepAir(dt)
	local chassis = ride.chassis
	local cf = chassis.CFrame
	local move = Input.move()
	local spin = State.stats.spinSpeed
	local pitch = if math.abs(move.Z) > 0.1 then move.Z * Bike.AirSpin.Pitch * spin else noseFollow(cf, chassis.AssemblyLinearVelocity)
	local roll = if math.abs(move.X) > 0.1 then move.X * Bike.AirSpin.Roll * spin else cf.RightVector.Y * Bike.AirSpin.AutoLevel
	local target = cf.RightVector * pitch + cf.LookVector * roll
	chassis.AssemblyAngularVelocity = chassis.AssemblyAngularVelocity:Lerp(target, math.min(1, dt * Bike.AirSpin.Response))
	if BikeController.boostAccel > 0 then
		chassis.AssemblyLinearVelocity += cf.LookVector * BikeController.boostAccel * dt
	end
	ride.grace -= dt
	if ride.grace <= 0 then
		local fallSpeed = math.max(0, -chassis.AssemblyLinearVelocity.Y)
		local hit = cast(-UP, Bike.Hover + 0.5 + fallSpeed * dt * 2)
		if hit then
			land(hit)
		end
	end
end

-- Ground step ---------------------------------------------------------------
-- popNormal = push off this way (hop or kicker). Kicker launches also grow with entry speed,
-- so faster runs fly much higher.
local function leaveGround(popNormal, fromKicker)
	ride.align.Enabled = false
	ride.grace = Bike.LeaveGroundGrace
	if popNormal then
		local pop = State.stats.jumpHeight + (if fromKicker then ride.speed * Bike.LaunchPopPerSpeed else 0)
		ride.chassis.AssemblyLinearVelocity += popNormal * pop
	end
	State.setPhase("Air")
	State.Launched:Fire()
end

local function checkBlocked(forward, dt)
	local actual = ride.chassis.AssemblyLinearVelocity:Dot(forward)
	if ride.speed > CRASH_MIN_SPEED and actual < ride.speed * CRASH_SPEED_RATIO then
		ride.blocked += 1
	else
		ride.blocked = 0
	end
	return ride.blocked >= 2
end

local function stepIdle(dt)
	if ride.speed < 2 then
		ride.idle += dt
	else
		ride.idle = 0
	end
	if ride.idle >= Bike.AutoBailIdle then
		State.RequestBail:Fire("idle")
	end
end

local function stepGround(dt)
	local hit = cast(-ride.chassis.CFrame.UpVector, Bike.RayLength)
	if not hit or hit.Distance > Bike.Hover + LEAVE_MARGIN then
		local kicker = ride.groundPart and ride.groundPart:GetAttribute("Launch")
		leaveGround(if kicker then ride.normal else nil, kicker)
		return
	end
	local n = hit.Normal
	ride.normal, ride.groundPart = n, hit.Instance

	local move = Input.move()
	local turn = -move.X * Bike.TurnRate * Bike.TurnFalloff / (Bike.TurnFalloff + ride.speed)
	ride.heading = CFrame.fromAxisAngle(UP, turn * dt) * ride.heading
	local forward = (ride.heading - n * ride.heading:Dot(n)).Unit
	if checkBlocked(forward, dt) then
		State.RequestBail:Fire("crash")
		return
	end

	local accel = -workspace.Gravity * Bike.GravityScale * forward.Y - Bike.RollingDrag - Bike.AirDrag * ride.speed ^ 2
	if move.Z < -0.1 and ride.speed < State.stats.cycleSpeed then
		accel += Bike.PedalAccel * -move.Z
	elseif move.Z > 0.1 then
		accel -= Bike.BrakeDecel * move.Z
	end
	accel += BikeController.boostAccel
	ride.speed = math.clamp(ride.speed + accel * dt, 0, Bike.MaxSpeed)

	ride.chassis.AssemblyLinearVelocity = forward * ride.speed + n * (Bike.Hover - hit.Distance) * Bike.Spring
	ride.align.CFrame = CFrame.lookAt(Vector3.zero, forward, n)
	stepIdle(dt)
end

local function stepReady()
	local chassis = ride.chassis
	chassis.AssemblyLinearVelocity = (ride.hold.Position - chassis.Position) * 10
	chassis.AssemblyAngularVelocity = Vector3.zero
	if Input.move().Z < -0.3 then
		State.setPhase("Riding")
	end
end

local STEPS = { Ready = stepReady, Riding = stepGround, Air = stepAir }

local function step(dt)
	if not ride or not ride.chassis.Parent then
		return
	end
	local stepFn = STEPS[State.phase]
	if stepFn then
		local chassis = ride.chassis -- a crash inside the step can release the ride
		stepFn(dt)
		State.run.maxSpeed = math.max(State.run.maxSpeed, chassis.AssemblyLinearVelocity.Magnitude)
	end
end

local function spinWheels(dt)
	if not ride then
		return
	end
	ride.wheelAngle = (ride.wheelAngle + ride.speed / WHEEL_RADIUS * dt) % (math.pi * 2)
	local roll = CFrame.Angles(-ride.wheelAngle, 0, 0)
	ride.joints.FrontSpin.Transform = roll
	ride.joints.RearSpin.Transform = roll
end

local function onHop(name)
	if name == "Hop" and ride and State.phase == "Riding" then
		leaveGround(ride.normal)
	end
end

-- Public --------------------------------------------------------------------
function BikeController.attach(bike: Model)
	local chassis = bike:WaitForChild("Chassis")
	local frameRoot = bike:WaitForChild("FrameRoot")
	rayParams.FilterDescendantsInstances = { workspace:WaitForChild("World") }
	ride = {
		bike = bike,
		chassis = chassis,
		align = chassis:WaitForChild("Upright"),
		joints = {
			Whip = chassis:WaitForChild("Whip"),
			Bars = chassis:WaitForChild("Bars"),
			FrontSpin = frameRoot:WaitForChild("FrontSpin"),
			RearSpin = frameRoot:WaitForChild("RearSpin"),
		},
		hold = chassis.CFrame,
		heading = flat(chassis.CFrame.LookVector),
		normal = chassis.CFrame.UpVector,
		groundPart = nil,
		speed = 0,
		grace = 0,
		idle = 0,
		blocked = 0,
		wheelAngle = 0,
	}
	ride.align.CFrame = chassis.CFrame.Rotation
	ride.align.Enabled = true
	State.setPhase("Ready")
end

-- Stop driving the bike (bail). Returns the old context so the rider can inherit its motion.
function BikeController.release()
	local old = ride
	ride = nil
	if old then
		old.align.Enabled = false
	end
	return old
end

function BikeController.start()
	RunService.Heartbeat:Connect(step)
	RunService.RenderStepped:Connect(spinWheels)
	Input.Began:Connect(onHop)
end

return BikeController
