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
local Location = require(Shared.Logic.Location)

local State = {
	-- Phases: Loading, Ready (on bike, not moving), Riding, Air, Ragdoll, Resting, Payout
	phase = "Loading",
	profile = nil,
	stats = nil, -- all upgrade stats (bike + biker)
	gravity = workspace.Gravity, -- this rider's gravity (studs/s^2), see Controllers/RobuxEffects
	character = nil,
	run = nil,

	PhaseChanged = Signal.new(), -- (phase, previous)
	ProfileChanged = Signal.new(), -- (profile)
	StatsChanged = Signal.new(), -- (stats) upgrades, passes or power-ups changed
	RunReset = Signal.new(),
	Launched = Signal.new(), -- left the ground
	Landed = Signal.new(), -- (impactSpeed)
	Trick = Signal.new(), -- (def, bonus, multiplier)
	RequestBail = Signal.new(), -- (reason, extraVelocity?)
	Bailed = Signal.new(), -- (reason)
	Impact = Signal.new(), -- (part, speedChange, result, kind) kind = nil (hit), "contact" or "blast"
	Exploded = Signal.new(), -- (position, force)
	BoostChanged = Signal.new(), -- (boosting, fuelFraction)
	LuckyHit = Signal.new(), -- (luckyDef, nameKey, extraMoney) server rolled a lucky hit
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

-- Where the player is (Logic/Location) and what's allowed there.
function State.location()
	return Location.of(Players.LocalPlayer)
end

function State.rules()
	return Location.rules(State.location())
end

function State.isRiding()
	return State.phase == "Riding" or State.phase == "Air"
end

-- Upgrade stats plus whatever Robux passes / power-ups are running right now.
function State.refreshStats()
	State.stats = Progression.stats(State.profile, workspace:GetServerTimeNow())
	State.StatsChanged:Fire(State.stats)
end

function State.setProfile(profile)
	State.profile = profile
	State.refreshStats()
	State.ProfileChanged:Fire(profile)
end

function State.resetRun()
	State.run = {
		tricks = {},
		ragdollTricks = {}, -- grabs posed while ragdolling (score Tricks.RagdollShare)
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
