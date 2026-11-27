-- Player damage detector. Three ways the ragdoll gets hurt:
--  * hits: a body part's speed changes suddenly against the world,
--  * contact: sliding/rolling along a surface hurts a share of your speed (Injuries.Contact),
--  * blasts: an exploder hurts as much as the speed it gives you.
-- Each hurt is scored locally (live HUD) and sent to the server in small batches (real payout).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ground = require(Shared.Logic.Ground)
local Injuries = require(Shared.Config.Injuries)
local InjuryModel = require(Shared.Logic.InjuryModel)
local Ragdoll = require(Shared.Logic.Ragdoll)
local Net = require(Shared.Net)
local State = require(script.Parent.Parent.State)

local DamageDetector = {}

local T = Injuries.Tuning
local C = Injuries.Contact
local SEND_INTERVAL = 0.25
local CONTACT_REACH = 2.5
local IGNORE_AFTER_RESET = 0.3
local MIN_SPEED_CHANGE = T.MinHitMph / T.StudsToMph -- studs/s

local parts = {}
local lastVelocity = {}
local lastHit = {}
local pending = {}
local sendTimer = 0
local contactTimer = 0
local ignoreUntil = 0
local pendingBlast = nil -- blast force waiting for the ragdoll to start
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

-- Forget speeds and ignore hits briefly: bailing and blasts change speed on purpose.
function DamageDetector.reset()
	table.clear(lastVelocity)
	ignoreUntil = os.clock() + IGNORE_AFTER_RESET
end

-- Scores one hurt and queues it for the server. kind = nil (hit), "contact" or "blast".
local function hurt(part, speed, kind)
	local result = InjuryModel.applyImpact(State.run.report, part.Name, speed, State.stats.bonesPerHit)
	if result then
		table.insert(pending, { part = part.Name, speed = speed, kind = kind })
		State.Impact:Fire(part, speed, result, kind)
	end
end

-- Is there world geometry within reach of the part in this direction? At high speed a part can
-- bounce several studs away within the same frame it hit, so the reach grows with its speed.
local function worldWithin(part, direction, travel)
	local reach = part.Size.Magnitude / 2 + CONTACT_REACH + travel
	return workspace:Raycast(part.Position, direction * reach, rayParams) ~= nil
end

local function flush()
	if #pending > 0 then
		Net.event("Impacts"):FireServer(pending)
		pending = {}
	end
	sendTimer = 0
end

local function checkHit(part, gravityStep, now, dt)
	local velocity = part.AssemblyLinearVelocity
	local previous = lastVelocity[part]
	lastVelocity[part] = velocity
	if not previous then
		return
	end
	local change = velocity - (previous + gravityStep)
	local amount = change.Magnitude
	if amount < MIN_SPEED_CHANGE or now < ignoreUntil or now - (lastHit[part] or 0) < T.Cooldown then
		return
	end
	local travel = math.max(previous.Magnitude, velocity.Magnitude) * dt
	if not worldWithin(part, -change.Unit, travel) then
		return
	end
	lastHit[part] = now
	hurt(part, amount)
end

-- Sliding: the fastest body part touching the ground takes a share of its speed as damage.
local function checkContact()
	local best, bestSpeed = nil, C.MinSpeed
	for _, part in parts do
		local speed = part.AssemblyLinearVelocity.Magnitude
		if speed > bestSpeed and worldWithin(part, -Vector3.yAxis, 0) then
			best, bestSpeed = part, speed
		end
	end
	if best then
		hurt(best, bestSpeed * C.Share, "contact")
	end
end

local function step(dt)
	if State.phase ~= "Ragdoll" then
		return
	end
	local gravityStep = Vector3.new(0, -workspace.Gravity * dt, 0)
	local now = os.clock()
	for _, part in parts do
		checkHit(part, gravityStep, now, dt)
	end
	contactTimer += dt
	if contactTimer >= C.Interval then
		contactTimer = 0
		checkContact()
	end
	sendTimer += dt
	if sendTimer >= SEND_INTERVAL then
		flush()
	end
end

-- An exploder hurts the body as much as the speed it adds (on the bike it waits for the bail).
local function onExploded(_position, force)
	if State.phase == "Ragdoll" and State.character then
		hurt(Ragdoll.core(State.character), force, "blast")
	else
		pendingBlast = force
	end
end

local function onPhase(phase, previous)
	if phase == "Ragdoll" and State.character then
		parts = Ragdoll.parts(State.character)
		rayParams.FilterDescendantsInstances = Ground.instances()
		table.clear(lastHit)
		contactTimer = 0
		DamageDetector.reset()
		if pendingBlast then
			hurt(Ragdoll.core(State.character), pendingBlast, "blast")
		end
	elseif previous == "Ragdoll" then
		flush()
	end
	pendingBlast = nil
end

function DamageDetector.start()
	RunService.Heartbeat:Connect(step)
	State.PhaseChanged:Connect(onPhase)
	State.Exploded:Connect(onExploded)
	State.Bailed:Connect(function(reason)
		if reason == "crash" then
			ignoreUntil = 0 -- a crash IS the hit, so count it straight away
		end
	end)
end

return DamageDetector
