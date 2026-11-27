-- Keeps Robux effects live on this client: gravity (the Gravity Controller slider times any
-- gravity power-up) and the stats, which are refreshed the moment a timed power-up runs out.
-- Gravity is set on this client only: the rider's own bike and ragdoll are simulated here.
-- Roblox caps workspace.Gravity at ENGINE_MAX_GRAVITY, so anything above that is added to the
-- rider's own parts every physics step.
local RunService = game:GetService("RunService")

local State = require(script.Parent.Parent.State)

local RobuxEffects = {}

local CHECK_INTERVAL = 1 -- seconds between power-up expiry checks
local ENGINE_MAX_GRAVITY = 1000
local normalGravity = workspace.Gravity
local extraGravity = 0 -- the part of State.gravity the engine can't do

local function applyGravity(stats)
	State.gravity = normalGravity * stats.gravity
	workspace.Gravity = math.min(State.gravity, ENGINE_MAX_GRAVITY)
	extraGravity = State.gravity - workspace.Gravity
end

-- Pulls every loose assembly of the rider (body, ragdoll limbs, bike) down by the extra gravity.
local function pullRider(_, dt)
	local character = State.character
	if extraGravity <= 0 or not character then
		return
	end
	local pull = Vector3.new(0, -extraGravity * dt, 0)
	local done = {}
	for _, part in character:GetDescendants() do
		local root = part:IsA("BasePart") and part.AssemblyRootPart
		if root and not done[root] and not root.Anchored then
			done[root] = true
			root.AssemblyLinearVelocity += pull
		end
	end
end

-- Did any power-up run out between the two server times?
local function anyEnded(profile, from, to)
	for _, endsAt in profile.powerups do
		if endsAt > from and endsAt <= to then
			return true
		end
	end
	return false
end

local function watchExpiry()
	local last = workspace:GetServerTimeNow()
	while true do
		task.wait(CHECK_INTERVAL)
		local now = workspace:GetServerTimeNow()
		if State.profile and anyEnded(State.profile, last, now) then
			State.setProfile(State.profile)
		end
		last = now
	end
end

function RobuxEffects.start()
	State.StatsChanged:Connect(applyGravity)
	RunService.Stepped:Connect(pullRider)
	task.spawn(watchExpiry)
end

return RobuxEffects
