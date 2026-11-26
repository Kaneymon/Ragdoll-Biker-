-- Client-wide state and event hub. Controllers fire events here; UI and Feedback listen.
-- Nothing in here plays sounds or draws UI, so gameplay code never needs to know about effects.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Signal = require(Shared.Util.Signal)
local Progression = require(Shared.Logic.Progression)
local InjuryModel = require(Shared.Logic.InjuryModel)
local TrickScore = require(Shared.Logic.TrickScore)
local Tricks = require(Shared.Config.Tricks)

local State = {
	-- Phases: Loading, Ready (on bike, not moving), Riding, Air, Ragdoll, Resting, Payout
	phase = "Loading",
	profile = nil,
	stats = nil, -- all upgrade stats (bike + biker)
	character = nil,
	run = nil,

	PhaseChanged = Signal.new(), -- (phase, previous)
	ProfileChanged = Signal.new(), -- (profile)
	RunReset = Signal.new(),
	Launched = Signal.new(), -- left the ground
	Landed = Signal.new(), -- (impactSpeed)
	Trick = Signal.new(), -- (def, bonus, multiplier)
	RequestBail = Signal.new(), -- (reason, extraVelocity?)
	Bailed = Signal.new(), -- (reason)
	Impact = Signal.new(), -- (part, speedChange, result)
	Exploded = Signal.new(), -- (position, force)
	BoostChanged = Signal.new(), -- (boosting, fuelFraction)
	Payout = Signal.new(), -- (sheet)
	CashedOut = Signal.new(), -- (total)
	Notify = Signal.new(), -- (textKey, ...)
}

function State.setPhase(phase)
	local previous = State.phase
	if previous ~= phase then
		State.phase = phase
		Players.LocalPlayer:SetAttribute("RunPhase", phase) -- visible to tools/tests
		State.PhaseChanged:Fire(phase, previous)
	end
end

function State.isRiding()
	return State.phase == "Riding" or State.phase == "Air"
end

function State.setProfile(profile)
	State.profile = profile
	State.stats = Progression.stats(profile)
	State.ProfileChanged:Fire(profile)
end

function State.resetRun()
	State.run = {
		tricks = {},
		combo = TrickScore.newCombo(),
		multiplier = Tricks.StartMultiplier,
		maxSpeed = 0,
		trickBusy = false,
		report = InjuryModel.new(),
	}
	State.RunReset:Fire()
end

State.resetRun()

return State
