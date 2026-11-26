-- Builds a map from its Config/Maps entry: mega ramp hill, kicker, landing slope, fences, props,
-- and a sealed force-field box around it all. Big shapes are tiled (parts max out at 2048 studs).
-- The maths lives in Logic/MapGeometry so spawning works whether a map was built now or baked in.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local P = require(Shared.Config.Palette)
local Maps = require(Shared.Config.Maps)
local MapGeometry = require(Shared.Logic.MapGeometry)
local Build = require(script.Parent.Build)
local Props = require(script.Parent.Props)

local MapBuilder = {}

local KICKER_DEPTH = 40
local PARK_LENGTH = 400
local BACK_LENGTH = 100
local HILL_MARGIN = 80 -- grass either side of the mega ramp
local FLOOR_MARGIN = 600 -- valley floor beyond the force field
local WALL_THICKNESS = 100 -- thick so fast ragdolls can't pass through
local WALL_DEPTH = 500 -- how far walls reach below the ground
local CHUNK = 2000 -- force field built in chunks of this length (z)
local FENCE_INSET = 10
local MAX_FENCE_POSTS = 400

local PROP_BUILDERS = { -- config key -> builder, upright (true) or follows the slope (false)
	trees = { Props.tree, true },
	rocks = { Props.rock, true },
	lamps = { Props.lamp, true },
	benches = { Props.bench, false },
	hay = { Props.hay, false },
	tables = { Props.picnicTable, false },
	bouncers = { Props.bouncer, false },
	fences = { Props.fence, false },
	crates = { Props.crate, false },
	cars = { Props.car, false },
	rails = { Props.grindRail, false },
}

-- Fills the space under a straight line from (zA, yA) down to (zB, yB) with wedges on top and
-- boxes below, down to floorY. Split so no piece is too big.
local function fillUnder(model, name, x, width, zA, yA, zB, yB, floorY, color)
	local steps = math.max(1, math.ceil(math.max(zB - zA, yA - yB) / CHUNK))
	for i = 0, steps - 1 do
		local z0, z1 = zA + (zB - zA) * i / steps, zA + (zB - zA) * (i + 1) / steps
		local y0, y1 = yA + (yB - yA) * i / steps, yA + (yB - yA) * (i + 1) / steps
		local depth, drop = z1 - z0, y0 - y1
		if drop > 0.05 then
			Build.part({ Name = name, Size = Vector3.new(width, drop, depth), CFrame = CFrame.new(x, y1 + drop / 2, (z0 + z1) / 2) * CFrame.Angles(0, math.pi, 0), Color = color, Parent = model }, "WedgePart")
		end
		if y1 - floorY > 0.05 then
			Build.tiled({ Name = name, Size = Vector3.new(width, y1 - floorY, depth), CFrame = CFrame.new(x, (y1 + floorY) / 2, (z0 + z1) / 2), Color = color, Parent = model })
		end
	end
end

local function buildRamp(def, g, model, floorY)
	local ramp, theme = def.ramp, def.theme
	local mid = g.origin + g.down * (ramp.length / 2)
	Build.tiled({ Name = "Ramp", Size = Vector3.new(ramp.width, ramp.thickness, ramp.length), CFrame = Build.onSurface(mid - g.normal * (ramp.thickness / 2), g.normal), Color = theme.ramp, Parent = model })
	for _, part in Build.tiled({ Name = "Stripe", Size = Vector3.new(2, 0.2, ramp.length), CFrame = Build.onSurface(mid + g.normal * 0.1, g.normal), Color = P.Sun, Parent = model }) do
		part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
	end
	for _, side in { -1, 1 } do
		local x = Vector3.new(side * (ramp.width / 2 + 0.6), 0, 0)
		Build.tiled({ Name = "Rail", Size = Vector3.new(1.2, 3, ramp.length), CFrame = Build.onSurface(mid + x + g.normal * 1.5, g.normal), Color = theme.rail, Parent = model })
	end
	local hillWidth = ramp.width + HILL_MARGIN * 2
	fillUnder(model, "Hill", g.origin.X, hillWidth, g.origin.Z, g.origin.Y - 0.4, g.bottom.Z, g.bottom.Y - 0.4, floorY, theme.ground)
	fillUnder(model, "HillTop", g.origin.X, hillWidth, g.origin.Z - HILL_MARGIN, g.origin.Y - 0.4, g.origin.Z, g.origin.Y - 0.4, floorY, theme.ground)
	Build.part({ Name = "StartDeck", Size = Vector3.new(ramp.width, ramp.thickness, 30), CFrame = CFrame.new(g.origin + Vector3.new(0, -ramp.thickness / 2, -15)), Color = theme.ramp, Parent = model })
end

local function buildKicker(def, g, model)
	local kicker, width, theme = def.kicker, def.ramp.width, def.theme
	Build.part({ Name = "Runout", Size = Vector3.new(width, def.ramp.thickness, def.runout + 1), CFrame = CFrame.new(g.bottom + Vector3.new(0, -def.ramp.thickness / 2, def.runout / 2)), Color = theme.ramp, Parent = model })
	local e = math.rad(kicker.endAngle)
	local function arcPoint(phi)
		return g.kickCentre + Vector3.new(0, -kicker.radius * math.cos(phi), kicker.radius * math.sin(phi))
	end
	for i = 0, kicker.segments - 1 do
		local a, b = arcPoint(e * i / kicker.segments), arcPoint(e * (i + 1) / kicker.segments)
		local along = (b - a).Unit
		local up = Vector3.new(0, along.Z, -along.Y)
		local mid = (a + b) / 2
		local segment = Build.part({ Name = "Kicker", Size = Vector3.new(width, KICKER_DEPTH, (b - a).Magnitude + 0.4), CFrame = Build.onSurface(mid - up * (KICKER_DEPTH / 2), up), Color = if i % 2 == 0 then theme.kickerA else theme.kickerB, Parent = model })
		segment:SetAttribute("Launch", true)
		for _, side in { -1, 1 } do
			Build.part({ Name = "Rail", Size = Vector3.new(1.2, 3, (b - a).Magnitude + 0.4), CFrame = Build.onSurface(mid + Vector3.new(side * (width / 2 + 0.6), 0, 0) + up * 1.5, up), Color = P.Sun, Parent = model })
		end
	end
end

local function buildGround(def, g, model, floorY)
	local theme, width = def.theme, def.landing.width
	local backZ, parkEnd = g.origin.Z - BACK_LENGTH, g.landEnd.Z + PARK_LENGTH
	-- flat ground around the kicker, solid down to the floor
	fillUnder(model, "Ground", g.origin.X, width, backZ, g.bottom.Y - 0.4, g.landStart.Z, g.bottom.Y - 0.4, floorY, theme.groundDark)
	-- the landing slope, solid down to the floor
	fillUnder(model, "LandingHill", g.origin.X, width, g.landStart.Z, g.landStart.Y, g.landEnd.Z, g.landEnd.Y, floorY, theme.ground)
	-- valley floor (also the park at the bottom of the slope)
	Build.tiled({ Name = "Floor", Size = Vector3.new(width + FLOOR_MARGIN * 2, 20, parkEnd - backZ + FLOOR_MARGIN), CFrame = CFrame.new(g.origin.X, floorY - 10, (backZ + parkEnd) / 2), Color = theme.ground, Parent = model })
end

-- Ground height along the map's centre line at a given z.
local function groundProfile(g)
	local points = {
		Vector2.new(g.origin.Z - BACK_LENGTH, g.origin.Y),
		Vector2.new(g.origin.Z, g.origin.Y),
		Vector2.new(g.bottom.Z, g.bottom.Y),
		Vector2.new(g.landStart.Z, g.bottom.Y),
		Vector2.new(g.landEnd.Z, g.landEnd.Y),
		Vector2.new(g.landEnd.Z + PARK_LENGTH, g.landEnd.Y),
	}
	local function heightAt(z)
		for i = 1, #points - 1 do
			local a, b = points[i], points[i + 1]
			if z <= b.X then
				return a.Y + (b.Y - a.Y) * math.clamp((z - a.X) / math.max(b.X - a.X, 1e-3), 0, 1)
			end
		end
		return points[#points].Y
	end
	-- highest and lowest ground between z0 and z1
	local function range(z0, z1)
		local hi, lo = math.max(heightAt(z0), heightAt(z1)), math.min(heightAt(z0), heightAt(z1))
		for _, p in points do
			if p.X > z0 and p.X < z1 then
				hi, lo = math.max(hi, p.Y), math.min(lo, p.Y)
			end
		end
		return hi, lo
	end
	return points[1].X, points[#points].X, range
end

-- A closed force-field box: side walls, ceiling and end walls, in z chunks that each reach from
-- below the lowest ground to BarrierHeight above the highest ground in that chunk.
local function buildBarrier(def, g, model)
	local zStart, zEnd, range = groundProfile(g)
	local half = def.landing.width / 2 + WALL_THICKNESS / 2
	local look = { Name = "ForceField", Material = Enum.Material.ForceField, Color = P.Sky, Transparency = 0.3, CastShadow = false, CanQuery = false, Parent = model }
	local function wall(size, position)
		local props = table.clone(look)
		props.Size, props.CFrame = size, CFrame.new(position)
		Build.tiled(props)
	end
	local fullWidth = def.landing.width + WALL_THICKNESS * 2
	local previousTop = nil
	local chunks = math.ceil((zEnd - zStart) / CHUNK)
	for i = 0, chunks - 1 do
		local z0, z1 = zStart + (zEnd - zStart) * i / chunks, zStart + (zEnd - zStart) * (i + 1) / chunks
		local hi, lo = range(z0, z1)
		local top, bottom = hi + Maps.BarrierHeight, lo - WALL_DEPTH
		local midZ, length = (z0 + z1) / 2, z1 - z0
		for _, side in { -1, 1 } do
			wall(Vector3.new(WALL_THICKNESS, top - bottom, length), Vector3.new(g.origin.X + side * half, (top + bottom) / 2, midZ))
		end
		wall(Vector3.new(fullWidth, WALL_THICKNESS, length), Vector3.new(g.origin.X, top + WALL_THICKNESS / 2, midZ))
		if previousTop and math.abs(previousTop - top) > 1 then -- close the step between ceilings
			local capLow, capHigh = math.min(previousTop, top), math.max(previousTop, top) + WALL_THICKNESS
			wall(Vector3.new(fullWidth, capHigh - capLow, WALL_THICKNESS), Vector3.new(g.origin.X, (capLow + capHigh) / 2, z0))
		end
		previousTop = top
		if i == 0 or i == chunks - 1 then -- end walls
			local z = if i == 0 then z0 - WALL_THICKNESS / 2 else z1 + WALL_THICKNESS / 2
			wall(Vector3.new(fullWidth, top - bottom, WALL_THICKNESS), Vector3.new(g.origin.X, (top + bottom) / 2, z))
		end
	end
end

-- Fences down both sides of the landing slope and across the bottom of the park.
local function buildFences(def, g, model)
	local folder = Build.model("Fences", model)
	local half = def.landing.width / 2 - FENCE_INSET
	local spacing = math.max(Maps.FenceSpacing, def.landing.length / MAX_FENCE_POSTS)
	local function fenceLine(from, to, normal)
		local length = (to - from).Magnitude
		local dir = (to - from).Unit
		local frame = CFrame.fromMatrix((from + to) / 2, normal:Cross(dir).Unit, normal)
		for _, y in { 1.6, 3.4 } do
			Build.tiled({ Name = "FenceRail", Size = Vector3.new(0.6, 0.6, length), CFrame = frame * CFrame.new(0, y, 0), Color = P.White, Parent = folder })
		end
		local posts = math.floor(length / spacing)
		for i = 0, posts do
			Build.part({ Name = "FencePost", Size = Vector3.new(0.9, 4.5, 0.9), CFrame = CFrame.new(from + dir * (i * length / posts) + Vector3.new(0, 2.25, 0)), Color = P.White, Parent = folder })
		end
	end
	for _, side in { -1, 1 } do
		local x = Vector3.new(side * half, 0, 0)
		fenceLine(g.landStart + x, g.landEnd + x, g.landNormal)
		fenceLine(g.landEnd + x, g.landEnd + x + Vector3.new(0, 0, PARK_LENGTH - FENCE_INSET), Vector3.yAxis)
	end
	local endZ = Vector3.new(0, 0, PARK_LENGTH - FENCE_INSET)
	fenceLine(g.landEnd + endZ + Vector3.new(-half, 0, 0), g.landEnd + endZ + Vector3.new(half, 0, 0), Vector3.yAxis)
end

local function placeProps(def, g, model)
	local rng = Random.new(def.seed)
	local folder = Build.model("Props", model)
	local half = def.landing.width / 2 - 25
	local perThousand = def.landing.length / 1000
	for key, density in def.props do
		local builder = PROP_BUILDERS[key]
		for _ = 1, math.min(Maps.PropCap, math.floor(density * perThousand)) do
			local along = rng:NextNumber(80, def.landing.length + PARK_LENGTH - 40)
			local onSlope = along <= def.landing.length
			local position = if onSlope
				then g.landStart + g.landDown * along
				else g.landEnd + Vector3.new(0, 0, along - def.landing.length)
			position += Vector3.new(rng:NextNumber(-half, half), 0, 0)
			local normal = if onSlope and not builder[2] then g.landNormal else Vector3.yAxis
			local prop = builder[1](rng, def.theme)
			prop:PivotTo(Build.onSurface(position, normal) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
			prop.Parent = folder
		end
	end
	-- trees along the sides of the mega ramp hill (hill_park style maps)
	if def.props.trees then
		for i = 1, 24 do
			local along = rng:NextNumber(40, def.ramp.length - 20)
			local side = if i % 2 == 0 then 1 else -1
			local x = side * rng:NextNumber(def.ramp.width / 2 + 12, def.ramp.width / 2 + HILL_MARGIN - 5)
			local tree = Props.tree(rng)
			tree:PivotTo(CFrame.new(g.origin + g.down * along + Vector3.new(x, -0.6, 0)))
			tree.Parent = folder
		end
	end
end

function MapBuilder.build(def, parent)
	local g = MapGeometry.get(def)
	local floorY = g.landEnd.Y
	local model = Build.model(def.id)
	buildRamp(def, g, model, floorY)
	buildKicker(def, g, model)
	buildGround(def, g, model, floorY)
	buildBarrier(def, g, model)
	buildFences(def, g, model)
	placeProps(def, g, model)
	model.Parent = parent
	return model
end

return MapBuilder
