-- Sound service: every sound in the game goes through here by name (see Config/Sounds).
local SoundService = game:GetService("SoundService")
local Sounds = require(script.Parent.Parent.Config.Sounds)

local Sfx = { enabled = true }

local function create(name, parent)
	local def = Sounds[name]
	if not def or #def.ids == 0 then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = "Sfx_" .. name
	sound.SoundId = def.ids[math.random(1, #def.ids)]
	sound.Volume = def.volume or 0.5
	sound.Looped = def.loop == true
	if def.pitch then
		sound.PlaybackSpeed = def.pitch[1] + math.random() * (def.pitch[2] - def.pitch[1])
	end
	sound.Parent = parent or SoundService
	return sound
end

-- One-shot. parent = a part/attachment for 3D sound, nil for 2D.
function Sfx.play(name: string, parent: Instance?)
	if not Sfx.enabled then
		return
	end
	local sound = create(name, parent)
	if sound then
		sound.Ended:Once(function()
			sound:Destroy()
		end)
		sound:Play()
	end
end

-- Looping sound handle: handle:set(playing, speed), handle:destroy(). Safe with no ids.
local Loop = {}
Loop.__index = Loop

function Loop:set(playing: boolean, speed: number?)
	local sound = self.sound
	if not sound then
		return
	end
	playing = playing and Sfx.enabled
	if playing and not sound.IsPlaying then
		sound:Play()
	elseif not playing and sound.IsPlaying then
		sound:Stop()
	end
	if speed then
		sound.PlaybackSpeed = speed
	end
end

function Loop:destroy()
	if self.sound then
		self.sound:Destroy()
		self.sound = nil
	end
end

function Sfx.loop(name: string, parent: Instance?)
	return setmetatable({ sound = create(name, parent) }, Loop)
end

return Sfx
