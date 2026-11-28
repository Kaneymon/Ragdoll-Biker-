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
		landLength = def.landing.length,
		dips = def.landing.dips or {},
	}
end

-- Landing slope dips (Config/Maps landing.dips): a smooth hollow `depth` studs deep and `length`
-- studs long starting `at` studs down the slope: it rolls in steeper, bottoms out, then rolls back
-- out (briefly uphill on the deep ones) onto the slope. Returns how far the ground is below the
-- plain slope there, and how fast that changes per stud down the slope.
local function dipAt(g, along: number)
	for _, dip in g.dips do
		local t = (along - dip.at) / dip.length
		if t > 0 and t < 1 then
			local w = math.pi * 2
			return dip.depth * (1 - math.cos(w * t)) / 2, dip.depth * w * math.sin(w * t) / (2 * dip.length)
		end
	end
	return 0, 0
end

-- The ground on the landing slope's centre line, `along` studs down it (dips included).
function MapGeometry.landPoint(g, along: number): Vector3
	return g.landStart + g.landDown * along - Vector3.yAxis * dipAt(g, along)
end

-- The ground's up direction there.
function MapGeometry.landNormalAt(g, along: number): Vector3
	local _, rate = dipAt(g, along)
	return (g.landDown - Vector3.yAxis * rate):Cross(Vector3.xAxis).Unit
end

-- Straight pieces that follow the landing slope: { from, to } distances down it. One piece
-- where it's plain, `perDip` pieces through each dip.
function MapGeometry.landSegments(g, perDip: number?)
	local cuts = { 0 }
	local dips = table.clone(g.dips)
	table.sort(dips, function(a, b)
		return a.at < b.at
	end)
	for _, dip in dips do
		local n = perDip or 16
		for i = 0, n do
			local at = dip.at + dip.length * i / n
			if at > cuts[#cuts] + 1e-3 and at < g.landLength then
				table.insert(cuts, at)
			end
		end
	end
	if g.landLength > cuts[#cuts] + 1e-3 then
		table.insert(cuts, g.landLength)
	end
	local segments = {}
	for i = 1, #cuts - 1 do
		table.insert(segments, { cuts[i], cuts[i + 1] })
	end
	return segments
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
