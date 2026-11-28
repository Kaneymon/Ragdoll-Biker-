-- Bike mode: pedal, brake, steer and bunnyhop on the ground; spin in the air; land or crash.
-- Ground riding sets the chassis velocity directly (arcade feel); air time is real physics.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ground = require(Shared.Logic.Ground)
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

-- Stopped on the bike: waiting at the top of the ramp, or barely moving and not pedalling or
-- crouching for a hop. The rider puts a foot down (Config/Poses Stand).
function BikeController.standing(): boolean
	if not ride or ride.charge then
		return false
	end
	if State.phase == "Ready" then
		return Input.move().Z > -0.3
	end
	return State.phase == "Riding" and ride.speed < Bike.Stand.Speed and Input.move().Z > -0.1
end

-- Leaning onto the foot that's down when stopped (blends back upright when riding off).
local function stepLean(dt)
	local goal = if BikeController.standing() then Bike.Stand.Lean else 0
	ride.lean += (goal - ride.lean) * (1 - math.exp(-dt * Bike.Stand.LeanRate))
	return CFrame.Angles(0, 0, math.rad(ride.lean))
end

-- Air step ------------------------------------------------------------------
local function land(hit)
	local chassis = ride.chassis
	local cf, velocity, n = chassis.CFrame, chassis.AssemblyLinearVelocity, hit.Normal
	local look = cf.LookVector - n * cf.LookVector:Dot(n)
	local planar = velocity - n * velocity:Dot(n)
	local upright = cf.UpVector:Dot(n) >= math.cos(math.rad(Bike.CrashAngle))
	local straight = planar.Magnitude < 20 or (look.Magnitude > 0.1 and look.Unit:Dot(planar.Unit) >= math.cos(math.rad(Bike.SideslipAngle)))
	ride.hop = nil
	-- how hard it hit: the frame before touching down (contact may already have slowed the bike)
	-- or a share of the straight-down speed, so slope landings bounce too
	local before = ride.airVel or velocity
	local impact = math.max(-velocity:Dot(n), -before:Dot(n), -before.Y * Bike.LandBounce.fall, 0)
	if upright and straight and not State.run.trickBusy then
		ride.heading = flat(look)
		ride.speed = math.max(0, velocity:Dot(look.Unit))
		ride.align.CFrame = CFrame.lookAt(Vector3.zero, look.Unit, n)
		ride.align.Enabled = true
		-- sit the bike at ride height (a fast fall would otherwise sink into the deck this frame),
		-- then the suspension takes the hit and bounces back up
		chassis.CFrame += n * (Bike.Hover - (chassis.Position - hit.Position):Dot(n))
		chassis.AssemblyLinearVelocity = planar
		local spec = Bike.LandBounce
		ride.bounce = 0
		ride.bounceSpeed = math.min(impact * spec.share, spec.max)
		if ride.airTime >= spec.airTime then
			ride.bounceSpeed = math.max(ride.bounceSpeed, spec.min)
		end
		-- still holding Hop: crouch straight away for the next bunnyhop
		ride.charge = if State.rules().hop and Input.isDown("Hop") then 0 else nil
		ride.chargeMove = Input.move()
		State.setPhase("Riding")
		State.Landed:Fire(impact)
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

-- Pitch with no flip input: after a bunnyhop the front lifts first then the bike levels out
-- (a hop straight up would otherwise point the nose at the sky); off a kicker it follows the flight.
local function noseAuto(cf, velocity, dt)
	local hop = ride.hop
	if not hop then
		return noseFollow(cf, velocity)
	elseif hop.nose > 0 then
		hop.nose -= dt
		return Bike.Hop.NoseUp
	end
	return -cf.LookVector.Y * Bike.Hop.Level
end

-- Stick input in the air. Off a bunnyhop, a direction held since before the crouch (W to pedal,
-- A/D to steer) doesn't flip the bike until it's let go and pressed again.
local function airMove()
	local move = Input.move()
	local hop = ride.hop
	if hop then
		hop.lockPitch = hop.lockPitch and math.abs(move.Z) > 0.1
		hop.lockRoll = hop.lockRoll and math.abs(move.X) > 0.1
		move = Vector3.new(if hop.lockRoll then 0 else move.X, 0, if hop.lockPitch then 0 else move.Z)
	end
	return move
end

local function stepAir(dt)
	local chassis = ride.chassis
	local cf = chassis.CFrame
	local move = airMove()
	local spin = State.stats.spinSpeed * (if ride.hop then Bike.Hop.Spin else 1)
	local pitch = if math.abs(move.Z) > 0.1 then move.Z * Bike.AirSpin.Pitch * spin else noseAuto(cf, chassis.AssemblyLinearVelocity, dt)
	local roll = if math.abs(move.X) > 0.1 then move.X * Bike.AirSpin.Roll * spin else cf.RightVector.Y * Bike.AirSpin.AutoLevel
	local target = cf.RightVector * pitch + cf.LookVector * roll
	chassis.AssemblyAngularVelocity = chassis.AssemblyAngularVelocity:Lerp(target, math.min(1, dt * Bike.AirSpin.Response))
	if BikeController.boostAccel > 0 then
		chassis.AssemblyLinearVelocity += cf.LookVector * BikeController.boostAccel * dt
	end
	ride.grace -= dt
	ride.airTime += dt
	if ride.grace <= 0 then
		local fallSpeed = math.max(0, -chassis.AssemblyLinearVelocity.Y)
		local hit = cast(-UP, Bike.Hover + 0.5 + fallSpeed * dt * 2)
		if hit then
			land(hit)
			return
		end
	end
	ride.airVel = chassis.AssemblyLinearVelocity
end

-- Ground step ---------------------------------------------------------------
-- popNormal = push off this way (ramps/kickers; bunnyhops are popHop). The launch is the Pedals
-- jumpHeight plus a share of entry speed, so faster runs and better pedals fly higher.
local function leaveGround(popNormal, fromKicker)
	ride.charge, ride.popQueued = nil, false
	ride.align.Enabled = false
	ride.grace = Bike.LeaveGroundGrace
	ride.airTime, ride.airVel = 0, nil
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

-- The suspension after a landing: a damped spring on the ride height.
local function stepBounce(dt)
	local spec = Bike.LandBounce
	ride.bounceSpeed += (-spec.stiffness * ride.bounce - spec.damping * ride.bounceSpeed) * dt
	ride.bounce += ride.bounceSpeed * dt
	if ride.bounce < -spec.sag then -- bottomed out: kick back up instead of sinking the wheels
		ride.bounce = -spec.sag
		ride.bounceSpeed = math.max(ride.bounceSpeed, -ride.bounceSpeed * spec.rebound)
	end
end

local function stepIdle(dt)
	if not State.rules().bail then
		return
	end
	if ride.speed < 2 then
		ride.idle += dt
	else
		ride.idle = 0
	end
	if ride.idle >= Bike.AutoBailIdle then
		State.RequestBail:Fire("idle")
	end
end

-- Bunnyhop: how far into the crouch (0..1) and the pop when Hop is let go.
local function hopCharge()
	return if ride.charge then math.min(1, ride.charge / Bike.Hop.ChargeTime) else 0
end

local function popHop(forward, n)
	local spec = Bike.Hop
	local pop = spec.Min + (spec.Max - spec.Min) * hopCharge() + State.stats.jumpHeight * spec.PedalShare
	-- directions held since the crouch began are riding (pedal, steer), not flip input
	local move, held = Input.move(), ride.chargeMove
	ride.charge, ride.popQueued = nil, false
	ride.align.Enabled = false
	ride.grace = Bike.LeaveGroundGrace
	ride.airTime, ride.airVel = 0, nil
	ride.hop = { nose = spec.NoseTime, lockPitch = move.Z * held.Z > 0.01, lockRoll = move.X * held.X > 0.01 }
	ride.chassis.AssemblyLinearVelocity = forward * ride.speed + n * pop
	State.setPhase("Air")
	State.Launched:Fire()
end

local function stepGround(dt)
	local hit = cast(-ride.chassis.CFrame.UpVector, Bike.RayLength)
	if not hit or hit.Distance > Bike.Hover + math.max(ride.bounce, 0) + LEAVE_MARGIN then
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

	local accel = -State.gravity * Bike.GravityScale * forward.Y - Bike.RollingDrag - Bike.AirDrag * ride.speed ^ 2
	if move.Z < -0.1 and ride.speed < State.stats.cycleSpeed then
		accel += Bike.PedalAccel * State.stats.speedMult * -move.Z
	elseif move.Z > 0.1 then
		accel -= Bike.BrakeDecel * move.Z
	end
	accel += BikeController.boostAccel
	ride.speed = math.clamp(ride.speed + accel * dt, 0, Bike.MaxSpeed * State.stats.speedMult)

	stepBounce(dt)
	ride.align.CFrame = CFrame.lookAt(Vector3.zero, forward, n) * stepLean(dt)
	if ride.popQueued then
		popHop(forward, n)
		return
	end
	if ride.charge then
		ride.charge += dt
	end
	local height = Bike.Hover + ride.bounce - Bike.Hop.Crouch * hopCharge()
	ride.chassis.AssemblyLinearVelocity = forward * ride.speed + n * ((height - hit.Distance) * Bike.Spring + ride.bounceSpeed)
	stepIdle(dt)
end

local function stepReady(dt)
	local chassis = ride.chassis
	chassis.AssemblyLinearVelocity = (ride.hold.Position - chassis.Position) * 10
	chassis.AssemblyAngularVelocity = Vector3.zero
	ride.align.CFrame = ride.hold.Rotation * stepLean(dt)
	if Input.move().Z < -0.3 or ride.charge then
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
	local wheelSpin = ride.speed / WHEEL_RADIUS
	ride.wheelAngle = (ride.wheelAngle + wheelSpin * dt) % (math.pi * 2)
	local roll = CFrame.Angles(-ride.wheelAngle, 0, 0)
	ride.joints.FrontSpin.Transform = roll
	ride.joints.RearSpin.Transform = roll
	-- pedals turn only while pedalling on the ground (BMX freewheel)
	if State.phase == "Riding" and Input.move().Z < -0.1 then
		local pedalSpin = math.min(math.max(wheelSpin, 4) / Bike.PedalGearRatio, Bike.PedalMaxSpin)
		ride.crankAngle = (ride.crankAngle + pedalSpin * dt) % (math.pi * 2)
	end
	ride.joints.Crank.Transform = CFrame.Angles(-ride.crankAngle, 0, 0)
end

-- Public --------------------------------------------------------------------
local PART_TIMEOUT = 10

-- Start driving a bike. isCurrent() says whether this bike still belongs to the live character:
-- quick respawns (several purchases in a row) replace bikes while older calls are still waiting.
-- Returns false when the bike went away or is no longer wanted.
function BikeController.attach(bike: Model, isCurrent: () -> boolean): boolean
	local chassis = bike:WaitForChild("Chassis", PART_TIMEOUT)
	local frameRoot = bike:WaitForChild("FrameRoot", PART_TIMEOUT)
	if not (chassis and frameRoot and bike.Parent and isCurrent()) then
		return false
	end
	rayParams.FilterDescendantsInstances = Ground.instances()
	ride = {
		bounce = 0, -- landing suspension (stepBounce)
		bounceSpeed = 0,
		bike = bike,
		chassis = chassis,
		align = chassis:WaitForChild("Upright"),
		joints = {
			Whip = chassis:WaitForChild("Whip"),
			Bars = chassis:WaitForChild("Bars"),
			FrontSpin = frameRoot:WaitForChild("FrontSpin"),
			RearSpin = frameRoot:WaitForChild("RearSpin"),
			Crank = frameRoot:WaitForChild("Crank"),
		},
		hold = chassis.CFrame,
		heading = flat(chassis.CFrame.LookVector),
		normal = chassis.CFrame.UpVector,
		groundPart = nil,
		speed = 0,
		charge = nil, -- seconds Hop has been held on the ground (crouching for a bunnyhop)
		chargeMove = Vector3.zero, -- the move stick when the crouch began
		popQueued = false, -- Hop let go: pop on the next ground step
		hop = nil, -- in the air off a bunnyhop (see noseAuto, airMove)
		grace = 0,
		airTime = 0, -- seconds in the air this jump
		airVel = nil, -- chassis velocity last air step (the landing bounce reads it)
		lean = 0, -- degrees leaned onto the foot that's down (stepLean)
		idle = 0,
		blocked = 0,
		wheelAngle = 0,
		crankAngle = 0,
	}
	ride.align.CFrame = chassis.CFrame.Rotation
	ride.align.Enabled = true
	State.setPhase("Ready")
	return true
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

local function onHopBegan(name)
	if name == "Hop" and ride and State.rules().hop and (State.phase == "Ready" or State.phase == "Riding") then
		if not ride.charge then
			ride.charge, ride.chargeMove = 0, Input.move()
		end
	end
end

local function onHopEnded(name)
	if name == "Hop" and ride and ride.charge then
		ride.popQueued = true
	end
end

function BikeController.start()
	Input.Began:Connect(onHopBegan)
	Input.Ended:Connect(onHopEnded)
	RunService.Heartbeat:Connect(step)
	RunService.RenderStepped:Connect(spinWheels)
end

return BikeController
