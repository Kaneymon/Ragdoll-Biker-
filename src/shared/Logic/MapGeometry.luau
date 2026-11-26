-- Pure map maths from Config/Maps: where the ramp, kicker and landing slope are, and where
-- riders spawn. Shared so the server (building, spawning) and client (out-of-map checks) agree.
local Config = script.Parent.Parent.Config
local Maps = require(Config.Maps)
local Ramp = require(Config.Ramp)

local MapGeometry = {}

local function slopeVectors(angleDeg)
	local a = math.rad(angleDeg)
	return Vector3.new(0, -math.sin(a), math.cos(a)), Vector3.new(0, math.cos(a), math.sin(a))
end

function MapGeometry.def(id)
	for _, def in Maps.list do
		if def.id == id then
			return def
		end
	end
	return MapGeometry.def(Maps.default)
end

function MapGeometry.get(def)
	local origin, ramp, kicker = def.origin, def.ramp, def.kicker
	local down, normal = slopeVectors(ramp.angle)
	local bottom = origin + down * ramp.length
	local kickStart = bottom + Vector3.new(0, 0, def.runout)
	local centre = kickStart + Vector3.new(0, kicker.radius, 0)
	local e = math.rad(kicker.endAngle)
	local lip = centre + Vector3.new(0, -kicker.radius * math.cos(e), kicker.radius * math.sin(e))
	local landDown, landNormal = slopeVectors(def.landing.angle)
	local landStart = Vector3.new(origin.X, bottom.Y, lip.Z + def.gap)
	local landEnd = landStart + landDown * def.landing.length
	return {
		origin = origin,
		down = down,
		normal = normal,
		bottom = bottom,
		kickStart = kickStart,
		kickCentre = centre,
		lip = lip,
		landDown = landDown,
		landNormal = landNormal,
		landStart = landStart,
		landEnd = landEnd,
	}
end

-- Studs up the ramp from the bottom for a ramp level (a fraction of this map's ramp).
function MapGeometry.startDistance(def, rampLevel)
	local t = math.clamp(rampLevel, 0, Ramp.maxLevel) / Ramp.maxLevel
	return def.ramp.length * (Ramp.startFraction + (Ramp.topFraction - Ramp.startFraction) * t)
end

function MapGeometry.spawnCFrame(def, rampLevel, hover, sideOffset)
	local g = MapGeometry.get(def)
	local position = g.bottom - g.down * MapGeometry.startDistance(def, rampLevel) + g.normal * hover + Vector3.new(sideOffset, 0, 0)
	return CFrame.lookAt(position, position + g.down, g.normal)
end

-- Lowest ground height of the map (the park at the bottom of the landing slope).
function MapGeometry.floorY(def)
	return MapGeometry.get(def).landEnd.Y
end

return MapGeometry
