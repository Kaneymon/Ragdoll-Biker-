-- Detects tricks while in the air:
--  rotation tricks (flips) from how far the bike has actually turned,
--  move tricks (tailwhip, barspin) and pose tricks (superman, lazy boy) from button presses.
-- A trick only counts once it is finished; landing or bailing mid-trick loses it.
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
local POSE_BLEND = 0.25 -- fraction of the trick spent moving into/out of the pose

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
local active = nil -- { def, t }

local function award(def)
	local run = State.run
	table.insert(run.tricks, def.id)
	local bonus = TrickScore.bonus(def.id, State.stats.trickBonus)
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

-- Visuals for the move/pose in progress (alpha 0..1).
local function poseWeight(alpha)
	return math.clamp(math.min(alpha, 1 - alpha) / POSE_BLEND, 0, 1)
end

local function render(def, alpha)
	if def.kind == "move" then
		local joint = BikeController.joint(def.joint)
		if joint then
			joint.Transform = CFrame.Angles(0, alpha * FULL_TURN, 0)
		end
	elseif def.kind == "pose" then
		local chassis = BikeController.chassis()
		local weld = chassis and chassis:FindFirstChild("RiderWeld")
		if weld then
			weld.C0 = RiderPose.seat("Ride"):Lerp(RiderPose.seat(def.pose), poseWeight(alpha))
		end
	end
end

local function stopActive()
	if not active then
		return
	end
	render(active.def, 0)
	if active.def.kind == "pose" and State.character then
		RiderPose.apply(State.character, "Ride")
	end
	active = nil
	State.run.trickBusy = false
end

local function startMove(def)
	active = { def = def, t = 0 }
	State.run.trickBusy = true
	if def.kind == "pose" and State.character then
		RiderPose.apply(State.character, def.pose)
	end
end

local function stepActive(dt)
	if not active then
		return
	end
	active.t += dt * State.stats.trickSpeed / active.def.duration
	if active.t >= 1 then
		local def = active.def
		stopActive()
		award(def)
	else
		render(active.def, active.t)
	end
end

local function step(dt)
	if State.phase == "Air" then
		trackRotation()
		stepActive(dt)
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

local function onAction(name)
	local def = byAction[name]
	if def and State.phase == "Air" and not active then
		startMove(def)
	end
end

function TrickController.start()
	RunService.Heartbeat:Connect(step)
	State.PhaseChanged:Connect(onPhase)
	Input.Began:Connect(onAction)
end

return TrickController
