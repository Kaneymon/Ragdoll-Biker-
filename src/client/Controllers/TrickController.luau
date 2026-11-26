-- Detects tricks while in the air:
--  * rotation tricks (flips) from how far the bike has actually turned,
--  * move tricks (tailwhip, barspin) from a button press, counted when the spin finishes,
--  * grabs (superman, lazy boy, can-can) held with a button, counted every tick while held.
-- Landing or bailing mid-move or mid-grab loses that move. Also picks the rider's pose.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Tricks = require(Shared.Config.Tricks)
local TrickScore = require(Shared.Logic.TrickScore)
local RiderPose = require(Shared.Logic.RiderPose)
local State = require(script.Parent.Parent.State)
local Input = require(script.Parent.Input)
local BikeController = require(script.Parent.BikeController)

local TrickController = {}

local FULL_TURN = math.pi * 2
local SPIN_INPUT = 0.1

local byAction = {}
local rotationTricks = {}
for _, def in Tricks.list do
	if def.action then
		byAction[def.action] = def
	elseif def.kind == "rotation" then
		table.insert(rotationTricks, def)
	end
end

local turned = { pitch = 0, roll = 0 }
local lastCFrame = nil
local active = nil -- { def, t } for the move or grab in progress

local function award(def)
	local run = State.run
	table.insert(run.tricks, def.id)
	local bonus = TrickScore.award(run.combo, def.id, State.stats.trickBonus)
	run.multiplier = TrickScore.multiplier(run.tricks, State.stats.trickBonus)
	Players.LocalPlayer:SetAttribute("RunTricks", #run.tricks)
	State.Trick:Fire(def, bonus, run.multiplier)
end

local function rotationTrick(axis, direction)
	for _, def in rotationTricks do
		if def.axis == axis and (def.sign == 0 or def.sign == direction) then
			return def
		end
	end
	return nil
end

local function trackRotation()
	local chassis = BikeController.chassis()
	if not chassis then
		return
	end
	local cf = chassis.CFrame
	if lastCFrame then
		local rx, _, rz = lastCFrame:ToObjectSpace(cf):ToEulerAnglesXYZ()
		turned.pitch += rx
		turned.roll += rz
	end
	lastCFrame = cf
	local needed = FULL_TURN * Tricks.FullTurnTolerance
	for axis, amount in turned do
		if math.abs(amount) >= needed then
			local direction = math.sign(amount)
			turned[axis] -= direction * FULL_TURN
			local def = rotationTrick(axis, direction)
			if def then
				award(def)
			end
		end
	end
end

local function spinJoint(def, alpha)
	local joint = BikeController.joint(def.joint)
	if joint then
		joint.Transform = CFrame.Angles(0, alpha * FULL_TURN, 0)
	end
end

local function stopActive()
	if active and active.def.kind == "move" then
		spinJoint(active.def, 0)
	end
	active = nil
	State.run.trickBusy = false
end

local function start(def)
	active = { def = def, t = 0 }
	State.run.trickBusy = true
end

local function stepActive(dt)
	if not active then
		return
	end
	local def = active.def
	if def.kind == "move" then
		active.t += dt * State.stats.trickSpeed / def.duration
		if active.t >= 1 then
			stopActive()
			award(def)
		else
			spinJoint(def, active.t)
		end
	elseif def.kind == "grab" then
		active.t += dt * State.stats.trickSpeed
		while active.t >= Tricks.GrabTick do
			active.t -= Tricks.GrabTick
			award(def)
		end
	end
end

-- Rider pose: the trick in progress, a tuck while flipping, otherwise riding.
local function currentPose()
	if active and active.def.pose then
		return active.def.pose
	end
	local move = Input.move()
	if State.phase == "Air" and (math.abs(move.Z) > SPIN_INPUT or math.abs(move.X) > SPIN_INPUT) then
		return Tricks.SpinPose
	end
	return "Ride"
end

local function step(dt)
	if State.phase == "Air" then
		trackRotation()
		stepActive(dt)
	end
	if State.character and State.isRiding() then
		RiderPose.blend(State.character, currentPose())
	end
end

local function onPhase(phase)
	if phase == "Air" then
		turned.pitch, turned.roll = 0, 0
		local chassis = BikeController.chassis()
		lastCFrame = chassis and chassis.CFrame
	else
		lastCFrame = nil
		stopActive()
	end
end

local function onActionBegan(name)
	local def = byAction[name]
	if def and State.phase == "Air" and not active then
		start(def)
	end
end

local function onActionEnded(name)
	if active and active.def.kind == "grab" and active.def.action == name then
		stopActive()
	end
end

function TrickController.start()
	RunService.Heartbeat:Connect(step)
	State.PhaseChanged:Connect(onPhase)
	Input.Began:Connect(onActionBegan)
	Input.Ended:Connect(onActionEnded)
end

return TrickController
