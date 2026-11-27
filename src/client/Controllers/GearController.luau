-- Boosters (hold for a short push, limited fuel) and exploders (one big blast per run).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Progression = require(Shared.Logic.Progression)
local Ragdoll = require(Shared.Logic.Ragdoll)
local Net = require(Shared.Net)
local State = require(script.Parent.Parent.State)
local Input = require(script.Parent.Input)
local BikeController = require(script.Parent.BikeController)
local RagdollController = require(script.Parent.RagdollController)
local Blast = require(script.Parent.Blast)

local GearController = {}

local BOOST_PHASES = { Riding = true, Air = true, Ragdoll = true }
local EXPLODE_UP = 0.75

local fuel = 0
local boosting = false
local bombsLeft = 0

local function corePart()
	local character = RagdollController.character()
	return if character then Ragdoll.core(character) else BikeController.chassis()
end

local function refill()
	local stats = State.profile and Progression.equippedBooster(State.profile)
	fuel = stats and stats.fuel or 0
	bombsLeft = if State.profile then select(3, Progression.equippedExploder(State.profile)) else 0
	State.BoostChanged:Fire(false, if stats then 1 else 0)
end

local function setBoosting(on, stats)
	if on ~= boosting then
		boosting = on
		State.BoostChanged:Fire(on, if stats then fuel / stats.fuel else 0)
	end
end

local function step(dt)
	local stats = State.profile and Progression.equippedBooster(State.profile)
	local on = stats ~= nil and fuel > 0 and BOOST_PHASES[State.phase] == true and State.rules().gear and Input.isDown("Boost")
	setBoosting(on, stats)
	BikeController.boostAccel = if on and State.isRiding() then stats.thrust else 0
	if not on then
		return
	end
	if not State.stats.endlessBoost then
		fuel = math.max(0, fuel - dt)
	end
	if State.phase == "Ragdoll" then
		local core = corePart()
		local direction = core and core.AssemblyLinearVelocity
		if direction and direction.Magnitude > 1 then
			Ragdoll.addVelocity(RagdollController.character(), direction.Unit * stats.thrust * dt)
		end
	end
	State.BoostChanged:Fire(true, fuel / stats.fuel)
end

local function explode()
	local force = State.profile and Progression.equippedExploder(State.profile)
	local part = corePart()
	if not force or bombsLeft <= 0 or not part or not BOOST_PHASES[State.phase] or not State.rules().gear then
		return
	end
	bombsLeft -= 1
	Net.event("BombUsed"):FireServer()
	local travel = part.AssemblyLinearVelocity
	local direction = (Vector3.yAxis * EXPLODE_UP + (if travel.Magnitude > 1 then travel.Unit else Vector3.zero)).Unit
	Blast.launch(part.Position, force, direction)
end

-- Bombs left this run (0 when no exploder is equipped).
function GearController.bombsLeft()
	return bombsLeft
end

function GearController.start()
	RunService.Heartbeat:Connect(step)
	State.RunReset:Connect(refill)
	State.ProfileChanged:Connect(function()
		if State.phase == "Ready" or State.phase == "Loading" then
			refill()
		end
	end)
	Input.Began:Connect(function(name)
		if name == "Explode" then
			explode()
		end
	end)
end

return GearController
