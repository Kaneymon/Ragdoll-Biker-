-- Player damage detector: watches every ragdoll body part for sudden speed changes against the world.
-- Each hit is scored locally (live HUD) and sent to the server in small batches (real payout).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Injuries = require(Shared.Config.Injuries)
local InjuryModel = require(Shared.Logic.InjuryModel)
local Ragdoll = require(Shared.Logic.Ragdoll)
local Net = require(Shared.Net)
local State = require(script.Parent.Parent.State)

local DamageDetector = {}

local T = Injuries.Tuning
local SEND_INTERVAL = 0.25
local CONTACT_REACH = 2.5
local IGNORE_AFTER_RESET = 0.3
local MIN_SPEED_CHANGE = T.MinHitMph / T.StudsToMph -- studs/s

local parts = {}
local lastVelocity = {}
local lastHit = {}
local pending = {}
local sendTimer = 0
local ignoreUntil = 0
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

-- Forget speeds and ignore hits briefly: bailing and blasts change speed on purpose.
function DamageDetector.reset()
	table.clear(lastVelocity)
	ignoreUntil = os.clock() + IGNORE_AFTER_RESET
end

-- Only count a speed change if there is world geometry on the side the part was pushed away from.
local function touchingWorld(part, change)
	local reach = part.Size.Magnitude / 2 + CONTACT_REACH
	return workspace:Raycast(part.Position, -change.Unit * reach, rayParams) ~= nil
end

local function flush()
	if #pending > 0 then
		Net.event("Impacts"):FireServer(pending)
		pending = {}
	end
	sendTimer = 0
end

local function check(part, gravityStep, now)
	local velocity = part.AssemblyLinearVelocity
	local previous = lastVelocity[part]
	lastVelocity[part] = velocity
	if not previous then
		return
	end
	local change = velocity - (previous + gravityStep)
	local amount = change.Magnitude
	if amount < MIN_SPEED_CHANGE or now < ignoreUntil or now - (lastHit[part] or 0) < T.Cooldown or not touchingWorld(part, change) then
		return
	end
	lastHit[part] = now
	local result = InjuryModel.applyImpact(State.run.report, part.Name, amount, State.stats.bonesPerHit)
	if result then
		table.insert(pending, { part = part.Name, speed = amount })
		State.Impact:Fire(part, amount, result)
	end
end

local function step(dt)
	if State.phase ~= "Ragdoll" then
		return
	end
	local gravityStep = Vector3.new(0, -workspace.Gravity * dt, 0)
	local now = os.clock()
	for _, part in parts do
		check(part, gravityStep, now)
	end
	sendTimer += dt
	if sendTimer >= SEND_INTERVAL then
		flush()
	end
end

local function onPhase(phase, previous)
	if phase == "Ragdoll" and State.character then
		parts = Ragdoll.parts(State.character)
		rayParams.FilterDescendantsInstances = { workspace:WaitForChild("World") }
		table.clear(lastHit)
		DamageDetector.reset()
	elseif previous == "Ragdoll" then
		flush()
	end
end

function DamageDetector.start()
	RunService.Heartbeat:Connect(step)
	State.PhaseChanged:Connect(onPhase)
	State.Bailed:Connect(function(reason)
		if reason == "crash" then
			ignoreUntil = 0 -- a crash IS the hit, so count it straight away
		end
	end)
end

return DamageDetector
