-- The one place that turns gameplay events into sounds, particles and camera shake.
-- Gameplay code only fires State events; swap or extend effects here without touching it.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Sfx = require(Shared.Services.Sfx)
local Vfx = require(Shared.Services.Vfx)
local Flashes = require(Shared.Config.Flashes)
local State = require(script.Parent.Parent.State)
local ScreenFlash = require(script.Parent.ScreenFlash)
local BikeController = require(script.Parent.Parent.Controllers.BikeController)
local CameraController = require(script.Parent.Parent.Controllers.CameraController)

local Feedback = {}

local GROAN_CHANCE = 0.35
local NOTICE_SOUNDS = { NOTE_BOUGHT = "Purchase", NOTE_NO_MONEY = "Error", NOTE_MAX = "Error", NOTE_ERROR = "Error" }
local boost = { sound = nil, flame = nil }

local function injuryFx()
	return State.profile == nil or State.profile.settings.injuryFx
end

local function onImpact(part, _speed, result, kind)
	if not injuryFx() then
		return
	end
	local severity = result.severity
	if kind == "contact" then -- sliding: a soft scrape, no crunch or shake
		Sfx.play("Thud", part)
		Vfx.burst("Impact", part.Position, 0.5)
		return
	end
	Sfx.play(if severity >= 1 then "BoneCrack" elseif severity >= 0.5 then "Squelch" else "Thud", part)
	if severity >= 0.5 and math.random() < GROAN_CHANCE then
		Sfx.play("Groan", part)
	end
	Vfx.burst(if severity >= 1 then "BigImpact" else "Impact", part.Position, math.clamp(severity, 0.5, 2))
	CameraController.shake(math.min(severity, 2.5))
end

-- Lucky hit: a flash that is redder and fades slower for the bigger multipliers.
local function onLucky(lucky)
	Sfx.play(if lucky.mult >= 10 then "LuckyBig" else "Lucky")
	if Vfx.enabled then
		ScreenFlash.flash(Flashes[lucky.flash])
	end
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
		local mount = chassis and chassis.Parent:FindFirstChild("BoosterMount", true)
		boost.sound = Sfx.loop("Boost", mount)
		boost.flame = if mount then Vfx.attach(mount:GetAttribute("Flame") or "Boost", mount.Nozzle) else nil
	end
	if boost.sound then
		boost.sound:set(on)
	end
	if boost.flame then
		boost.flame:set(on)
	end
end

local function onPhase(phase)
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
	State.LuckyHit:Connect(onLucky)
	State.Exploded:Connect(onExploded)
	State.BoostChanged:Connect(onBoost)
	State.PhaseChanged:Connect(onPhase)
	State.Launched:Connect(function()
		Sfx.play("Launch")
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
	State.Notify:Connect(function(key)
		local sound = NOTICE_SOUNDS[key]
		if sound then
			Sfx.play(sound)
		end
	end)
end

return Feedback
