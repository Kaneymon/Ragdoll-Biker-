-- The one place that turns gameplay events into sounds, particles and camera shake.
-- Gameplay code only fires State events; swap or extend effects here without touching it.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Sfx = require(Shared.Services.Sfx)
local Vfx = require(Shared.Services.Vfx)
local State = require(script.Parent.Parent.State)
local BikeController = require(script.Parent.Parent.Controllers.BikeController)
local CameraController = require(script.Parent.Parent.Controllers.CameraController)

local Feedback = {}

local GROAN_CHANCE = 0.35
local wind = nil
local boost = { sound = nil, flame = nil }

local function injuryFx()
	return State.profile == nil or State.profile.settings.injuryFx
end

local function onImpact(part, _speed, result)
	if not injuryFx() then
		return
	end
	local severity = result.severity
	Sfx.play(if severity >= 1 then "BoneCrack" elseif severity >= 0.5 then "Squelch" else "Thud", part)
	if severity >= 0.5 and math.random() < GROAN_CHANCE then
		Sfx.play("Groan", part)
	end
	Vfx.burst(if severity >= 1 then "BigImpact" else "Impact", part.Position, math.clamp(severity, 0.5, 2))
	CameraController.shake(math.min(severity, 2.5))
end

local function onTrick()
	Sfx.play("Trick")
	local chassis = BikeController.chassis()
	if chassis then
		Vfx.burst("Trick", chassis.Position)
	end
end

local function onExploded(position)
	Sfx.play("Explosion")
	Vfx.burst("Explosion", position)
	CameraController.shake(3)
end

local function clearBoost()
	if boost.sound then
		boost.sound:destroy()
	end
	if boost.flame then
		boost.flame:destroy()
	end
	boost.sound, boost.flame = nil, nil
end

local function onBoost(on)
	if on and not boost.sound then
		local chassis = BikeController.chassis()
		local mount = chassis and chassis.Parent:FindFirstChild("BoosterMount")
		boost.sound = Sfx.loop("Boost", mount)
		boost.flame = if mount then Vfx.attach("Boost", mount.Nozzle) else nil
	end
	if boost.sound then
		boost.sound:set(on)
	end
	if boost.flame then
		boost.flame:set(on)
	end
end

local function onPhase(phase)
	if not wind then
		wind = Sfx.loop("Wind")
	end
	wind:set(phase == "Riding" or phase == "Air" or phase == "Ragdoll")
	if phase == "Ready" or phase == "Ragdoll" then
		clearBoost()
	end
end

local function onProfile(profile)
	Sfx.enabled = profile.settings.sfx
	Vfx.enabled = profile.settings.vfx
end

function Feedback.start()
	State.ProfileChanged:Connect(onProfile)
	State.Impact:Connect(onImpact)
	State.Trick:Connect(onTrick)
	State.Exploded:Connect(onExploded)
	State.BoostChanged:Connect(onBoost)
	State.PhaseChanged:Connect(onPhase)
	State.Launched:Connect(function()
		Sfx.play("Hop")
	end)
	State.Landed:Connect(function()
		Sfx.play("Land")
	end)
	State.Bailed:Connect(function(reason)
		Sfx.play(if reason == "crash" then "Crash" else "Bail")
	end)
	State.Payout:Connect(function()
		Sfx.play("Payout")
	end)
	State.CashedOut:Connect(function()
		Sfx.play("CashOut")
	end)
end

return Feedback
