-- Particle service: bursts and attachable emitters built from Config/VfxPresets.
local Debris = game:GetService("Debris")
local Presets = require(script.Parent.Parent.Config.VfxPresets)

local Vfx = { enabled = true }

local SPECIAL_KEYS = { count = true, rate = true }

local function makeEmitter(name)
	local def = Presets[name]
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Vfx_" .. name
	for key, value in def do
		if not SPECIAL_KEYS[key] then
			emitter[key] = value
		end
	end
	emitter.Rate = def.rate or 0
	emitter.Enabled = false
	return emitter, def
end

local function holder(position)
	local part = Instance.new("Part")
	part.Name = "VfxHolder"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.one
	part.Position = position
	return part
end

-- One-shot burst at a world position.
function Vfx.burst(name: string, position: Vector3, scale: number?)
	if not Vfx.enabled or not Presets[name] then
		return
	end
	local part = holder(position)
	local emitter, def = makeEmitter(name)
	emitter.Parent = part
	part.Parent = workspace
	emitter:Emit(math.floor((def.count or 10) * (scale or 1)))
	Debris:AddItem(part, emitter.Lifetime.Max + 0.5)
end

-- Emitter on a part/attachment. handle:set(on), handle:destroy().
local Handle = {}
Handle.__index = Handle

function Handle:set(on: boolean)
	self.emitter.Enabled = on and Vfx.enabled
end

function Handle:destroy()
	self.emitter:Destroy()
end

function Vfx.attach(name: string, parent: Instance)
	local emitter = makeEmitter(name)
	emitter.Parent = parent
	return setmetatable({ emitter = emitter }, Handle)
end

return Vfx
