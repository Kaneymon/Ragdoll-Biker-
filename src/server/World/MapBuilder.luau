-- Builds a map from its Config/Maps entry: mega ramp hill, kicker, landing slope, fences, props,
-- and a sealed force-field box around it all. Big shapes are tiled (parts max out at 2048 studs).
-- Maps with a `terrain` entry get Roblox terrain ground (World/TerrainBuilder) instead of the
-- part hill, ground and landing slope, and their props are dropped onto it.
-- The maths lives in Logic/MapGeometry so spawning works whether a map was built now or baked in.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local P = require(Shared.Config.Palette)
local Maps = require(Shared.Config.Maps)
local MeshProps = require(Shared.Config.MeshProps)
local Decals = require(Shared.Config.Decals)
local MapGeometry = require(Shared.Logic.MapGeometry)
local Build = require(script.Parent.Build)
local Props = require(script.Parent.Props)
local RampKit = require(script.Parent.RampKit)
local TerrainBuilder = require(script.Parent.TerrainBuilder)
local ZFight = require(script.Parent.ZFight)

local MapBuilder = {}

local KICKER_DEPTH = 40
local START_DECK = 30 -- flat deck behind the top of the mega ramp
local PARK_LENGTH = 400
local BACK_LENGTH = 100
local HILL_MARGIN = 80 -- grass either side of the mega ramp
local FLOOR_MARGIN = 600 -- valley floor beyond the force field
local WALL_THICKNESS = 100 -- thick so fast ragdolls can't pass through
local WALL_DEPTH = 500 -- how far walls reach below the ground
local CHUNK = 2000 -- force field built in chunks of this length (z)
local FENCE_INSET = 10
local MAX_FENCE_POSTS = 400
local HILL_TREES = 24 -- default trees along the mega ramp (Config/Maps hillTreeCount overrides)

-- config key -> builder; upright = stands straight up (else follows the slope);
-- facing = keep pointing downhill (else turned at random)
local PROP_BUILDERS = {
	trees = { build = Props.tree, upright = true },
	rocks = { build = Props.rock, upright = true },
	lamps = { build = Props.lamp, upright = true },
	benches = { build = Props.bench },
	hay = { build = Props.hay },
	tables = { build = Props.picnicTable },
	fences = { build = Props.fence },
	crates = { build = Props.crate },
	cars = { build = Props.car },
	rails = { build = Props.grindRail },
	launchRamps = { build = Props.launchRamp, facing = true },
}
for key, def in MeshProps.list do -- textured Blender props
	PROP_BUILDERS[key] = { build = function(rng)
		return Props.mesh(def, rng)
	end, upright = def.upright, facing = def.facing, sink = def.sink }
end
local PATH_CLEARANCE = 8 -- props keep this far from the path's edge
local FOOTPRINT_SHARE = 0.75 -- how much of a prop's width counts when keeping props apart
local END_WALL_INSET = 8 -- end wall / house fronts sit this far in front of the end fence
-- No two flat faces share a plane where they overlap (that flickers, "z-fighting"): overlapping
-- floor decals and path strips are lifted by a little more each, in turn.
local DECAL_LAYER = 0.02
local STRIP_LAYER = 0.015

-- Fills the space under a straight line from (zA, yA) to (zB, yB) (downhill or up) with wedges
-- on top and boxes below, down to floorY. Split so no piece is too big.
local function fillUnder(model, name, x, width, zA, yA, zB, yB, floorY, color, material)
	local steps = math.max(1, math.ceil(math.max(zB - zA, math.abs(yA - yB)) / CHUNK))
	for i = 0, steps - 1 do
		local z0, z1 = zA + (zB - zA) * i / steps, zA + (zB - zA) * (i + 1) / steps
		local y0, y1 = yA + (yB - yA) * i / steps, yA + (yB - yA) * (i + 1) / steps
		local depth, drop, low = z1 - z0, math.abs(y0 - y1), math.min(y0, y1)
		if drop > 0.05 then -- a wedge rises towards +Z unless turned round
			local turn = if y0 > y1 then CFrame.Angles(0, math.pi, 0) else CFrame.identity
			Build.part({ Name = name, Size = Vector3.new(width, drop, depth), CFrame = CFrame.new(x, low + drop / 2, (z0 + z1) / 2) * turn, Color = color, Material = material, Parent = model }, "WedgePart")
		end
		if low - floorY > 0.05 then
			Build.tiled({ Name = name, Size = Vector3.new(width, low - floorY, depth), CFrame = CFrame.new(x, (low + floorY) / 2, (z0 + z1) / 2), Color = color, Material = material, Parent = model })
		end
	end
end

local function buildRamp(def, g, model, floorY)
	local ramp, theme = def.ramp, def.theme
	RampKit.deck(model, "StartDeck", g.origin - Vector3.zAxis * START_DECK, Vector3.zAxis, Vector3.yAxis, START_DECK, ramp.width, ramp.thickness)
	RampKit.deck(model, "Ramp", g.origin, g.down, g.normal, ramp.length, ramp.width, ramp.thickness)
	if not def.terrain then -- (on terrain maps the terrain is the hill)
		local hillWidth = ramp.width + HILL_MARGIN * 2
		fillUnder(model, "Hill", g.origin.X, hillWidth, g.origin.Z, g.origin.Y - 0.4, g.bottom.Z, g.bottom.Y - 0.4, floorY, theme.ground, theme.material)
		fillUnder(model, "HillTop", g.origin.X, hillWidth, g.origin.Z - HILL_MARGIN, g.origin.Y - 0.4, g.origin.Z, g.origin.Y - 0.4, floorY, theme.ground, theme.material)
	end
end

local function buildKicker(def, g, model)
	local kicker, width = def.kicker, def.ramp.width
	RampKit.deck(model, "Runout", g.bottom, Vector3.zAxis, Vector3.yAxis, def.runout, width, def.ramp.thickness)
	RampKit.kicker(model, g.kickStart, Vector3.zAxis, width, kicker.radius, kicker.endAngle, kicker.segments, KICKER_DEPTH)
end

local function buildGround(def, g, model, floorY)
	local theme, width = def.theme, def.landing.width
	local backZ, parkEnd = g.origin.Z - BACK_LENGTH, g.landEnd.Z + PARK_LENGTH
	-- flat ground around the kicker, solid down to the floor
	fillUnder(model, "Ground", g.origin.X, width, backZ, g.bottom.Y - 0.4, g.landStart.Z, g.bottom.Y - 0.4, floorY, theme.groundDark, theme.material)
	-- the landing slope (and its dips), solid down to the floor
	for _, seg in MapGeometry.landSegments(g) do
		local a, b = MapGeometry.landPoint(g, seg[1]), MapGeometry.landPoint(g, seg[2])
		fillUnder(model, "LandingHill", g.origin.X, width, a.Z, a.Y, b.Z, b.Y, floorY, theme.ground, theme.material)
	end
	-- valley floor (also the park at the bottom of the slope)
	Build.tiled({ Name = "Floor", Size = Vector3.new(width + FLOOR_MARGIN * 2, 20, parkEnd - backZ + FLOOR_MARGIN), CFrame = CFrame.new(g.origin.X, floorY - 10, (backZ + parkEnd) / 2), Color = theme.ground, Material = theme.material, Parent = model })
end

-- Ground height along the map's centre line at a given z.
local function groundProfile(g)
	local points = {
		Vector2.new(g.origin.Z - BACK_LENGTH, g.origin.Y),
		Vector2.new(g.origin.Z, g.origin.Y),
		Vector2.new(g.bottom.Z, g.bottom.Y),
	}
	for _, seg in MapGeometry.landSegments(g, 4) do
		local p = MapGeometry.landPoint(g, seg[1])
		table.insert(points, Vector2.new(p.Z, p.Y))
	end
	table.insert(points, Vector2.new(g.landEnd.Z, g.landEnd.Y))
	table.insert(points, Vector2.new(g.landEnd.Z + PARK_LENGTH, g.landEnd.Y))
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
	local function meshLine(from, to, normal)
		local fence = def.fenceMesh
		local dir = (to - from).Unit
		local count = math.max(1, math.floor((to - from).Magnitude / fence.length))
		local step = (to - from).Magnitude / count
		for i = 0, count - 1 do
			local piece = PROP_BUILDERS[fence.key].build(Random.new(i))
			piece:PivotTo(CFrame.fromMatrix(from + dir * ((i + 0.5) * step), dir, normal))
			piece.Parent = folder
		end
	end
	local function fenceLine(from, to, normal)
		if def.fenceMesh then
			return meshLine(from, to, normal)
		end
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
	-- mesh fence pieces down the slope, end to end along the ground (through the dips too)
	local function slopeMeshLine(x)
		local fence = def.fenceMesh
		local marks, total, prev = {}, 0, MapGeometry.landPoint(g, 0)
		for along = 0, def.landing.length, 2 do
			local p = MapGeometry.landPoint(g, along)
			total += (p - prev).Magnitude
			prev = p
			table.insert(marks, { along, total })
		end
		local count = math.max(1, math.floor(total / fence.length))
		local step, m = total / count, 1
		for i = 0, count - 1 do
			local want = (i + 0.5) * step
			while m < #marks - 1 and marks[m + 1][2] < want do
				m += 1
			end
			local a, b = marks[m], marks[m + 1]
			local along = a[1] + (b[1] - a[1]) * math.clamp((want - a[2]) / math.max(b[2] - a[2], 1e-3), 0, 1)
			local dir = (MapGeometry.landPoint(g, along + 0.5) - MapGeometry.landPoint(g, along - 0.5)).Unit
			local piece = PROP_BUILDERS[fence.key].build(Random.new(i))
			piece:PivotTo(CFrame.fromMatrix(MapGeometry.landPoint(g, along) + x, dir, MapGeometry.landNormalAt(g, along)))
			piece.Parent = folder
		end
	end
	for _, side in { -1, 1 } do
		local x = Vector3.new(side * half, 0, 0)
		if def.fenceMesh then
			slopeMeshLine(x)
		else
			for _, seg in MapGeometry.landSegments(g) do
				local a, b = MapGeometry.landPoint(g, seg[1]), MapGeometry.landPoint(g, seg[2])
				fenceLine(a + x, b + x, (b - a).Unit:Cross(Vector3.xAxis).Unit)
			end
		end
		fenceLine(g.landEnd + x, g.landEnd + x + Vector3.new(0, 0, PARK_LENGTH - FENCE_INSET), Vector3.yAxis)
	end
	local endZ = Vector3.new(0, 0, PARK_LENGTH - FENCE_INSET)
	fenceLine(g.landEnd + endZ + Vector3.new(-half, 0, 0), g.landEnd + endZ + Vector3.new(half, 0, 0), Vector3.yAxis)
end

-- A surface stripe running down the slope and across the park (visual only, sits on the ground).
local function stripe(g, folder, name, x, width, color, material)
	local function piece(from, to, normal)
		local length = (to - from).Magnitude
		local frame = CFrame.fromMatrix((from + to) / 2, normal:Cross((to - from).Unit).Unit, normal)
		for _, part in Build.tiled({ Name = name, Size = Vector3.new(width, 0.2, length), CFrame = frame * CFrame.new(0, 0.12, 0), Color = color, Material = material, Parent = folder }) do
			part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
		end
	end
	local offset = Vector3.new(x, 0, 0)
	for _, seg in MapGeometry.landSegments(g) do
		local a, b = MapGeometry.landPoint(g, seg[1]), MapGeometry.landPoint(g, seg[2])
		piece(a + offset, b + offset, (b - a).Unit:Cross(Vector3.xAxis).Unit)
	end
	piece(g.landEnd + offset, g.landEnd + offset + Vector3.new(0, 0, PARK_LENGTH), Vector3.yAxis)
end

-- Floor stripes down the middle (e.g. the Skate Park's concrete between grass verges).
local function buildSurfaces(def, g, model)
	local folder = Build.model("Surfaces", model)
	for i, surface in def.surfaces do
		stripe(g, folder, "Surface" .. i, 0, surface.width, surface.color, surface.material)
	end
end

-- Images (graffiti) laid flat on the floor at random spots and angles.
local function buildDecals(def, g, model, rng)
	local spec = def.decals
	local images = Decals[spec.set]
	if #images == 0 then
		return
	end
	local folder = Build.model("Decals", model)
	for i = 1, spec.count do
		local along = rng:NextNumber(60, def.landing.length - 30)
		local x = rng:NextNumber(spec.area[1], spec.area[2]) * (if rng:NextNumber() < 0.5 then -1 else 1)
		local at = MapGeometry.landPoint(g, along) + Vector3.new(x, 0, 0)
		local holder = Build.decor({ Name = "Graffiti", Size = Vector3.new(spec.size, 0.05, spec.size / 2), Transparency = 1, CFrame = Build.onSurface(at, MapGeometry.landNormalAt(g, along)) * CFrame.new(0, 0.26 + (i % 8) * DECAL_LAYER, 0) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0), Parent = folder })
		local decal = Instance.new("Decal")
		decal.Face = Enum.NormalId.Top
		decal.Texture = images[rng:NextInteger(1, #images)]
		decal.Parent = holder
	end
end

-- Closes off the bottom of the park (Config/Maps endWall): brick wall sections with optional
-- columns between them, or a row of house fronts facing up the hill. Solid, so riders hit it.
local function buildEndWall(def, g, model)
	local spec = def.endWall
	local folder = Build.model("EndWall", model)
	local half = def.landing.width / 2 - FENCE_INSET
	local lineZ = g.landEnd.Z + PARK_LENGTH - FENCE_INSET - END_WALL_INSET
	local rng = Random.new(def.seed + 3)
	local function place(piece, x, depth)
		piece:PivotTo(CFrame.new(Vector3.new(g.origin.X + x, g.landEnd.Y, lineZ - depth / 2)) * piece:GetPivot().Rotation)
		piece.Parent = folder
	end
	local cursor = -half
	if spec.houses then
		while cursor < half do
			local house = Props.house(rng)
			house:PivotTo(CFrame.Angles(0, math.pi / 2, 0)) -- front door (+X) faces up the hill
			local size = house:GetExtentsSize()
			place(house, cursor + size.X / 2, size.Z)
			cursor += size.X + 1
		end
		return
	end
	local function column(x)
		if spec.column then
			place(PROP_BUILDERS[spec.column].build(rng), x, 0)
		end
	end
	column(cursor)
	while cursor < half do
		local wall = PROP_BUILDERS[spec.wall].build(rng)
		local length = wall:GetExtentsSize().X
		place(wall, cursor + length / 2, 0)
		cursor += length
		column(cursor)
	end
end

-- Streets: road down the middle with dashed centre line, pavements either side, houses outside.
local function buildStreet(def, g, model, rng)
	local street = def.street
	local folder = Build.model("Street", model)
	stripe(g, folder, "Road", 0, street.road, P.Asphalt)
	for _, side in { -1, 1 } do
		stripe(g, folder, "Pavement", side * (street.road + street.pavement) / 2, street.pavement, P.Concrete)
		stripe(g, folder, "Kerb", side * street.road / 2, 2, P.White)
	end
	local dashes = math.min(Maps.PropCap * 2, math.floor(def.landing.length / (street.laneDash * 2)))
	for i = 0, dashes - 1 do
		local at = g.landStart + g.landDown * ((i + 0.5) * street.laneDash * 2)
		local dash = Build.decor({ Name = "LaneDash", Size = Vector3.new(1.2, 0.2, street.laneDash), CFrame = Build.onSurface(at, g.landNormal) * CFrame.new(0, 0.25, 0), Color = P.White, Parent = folder })
		dash.CanTouch = false
	end
	local houses = math.min(Maps.PropCap, math.floor(def.landing.length / street.houseSpacing))
	for i = 0, houses - 1 do
		for _, side in { -1, 1 } do
			local along = (i + 0.5) * street.houseSpacing + rng:NextNumber(-10, 10)
			local position = g.landStart + g.landDown * along + Vector3.new(side * street.houseX, 0, 0)
			local house = Props.house(rng)
			house:PivotTo(CFrame.new(position) * CFrame.Angles(0, if side > 0 then math.pi else 0, 0)) -- front door faces the road
			house.Parent = folder
		end
	end
end

-- Centre of the winding path (x offset from the map's centre line) at a distance down the slope.
local function pathX(path, along)
	return path.amplitude * math.sin(along / path.wavelength * math.pi * 2)
end

-- A path winding down the landing slope, lined with bricks on both edges (visual only).
local function buildPath(def, g, model)
	local path = def.path
	local folder = Build.model("Path", model)
	-- a point on the centre line (side 0) or an edge (side -1/1), measured square to the path
	local function point(along, side)
		local slope = path.amplitude * math.pi * 2 / path.wavelength * math.cos(along / path.wavelength * math.pi * 2)
		local length = math.sqrt(1 + slope * slope)
		local x = pathX(path, along) + side * path.width / 2 / length
		local down = along - side * path.width / 2 * slope / length
		return g.landStart + g.landDown * down + Vector3.new(x, 0, 0)
	end
	-- strips overlap their neighbours a little (no gaps on the bends): every other one sits a
	-- touch higher so the overlaps don't flicker
	local function strip(name, a, b, width, height, color, material, layer)
		local length = (b - a).Magnitude
		local frame = CFrame.fromMatrix((a + b) / 2, g.landNormal:Cross((b - a).Unit).Unit, g.landNormal)
		local lift = (layer % 2) * STRIP_LAYER
		Build.decor({ Name = name, Size = Vector3.new(width, height + lift, length + width * 0.6), CFrame = frame * CFrame.new(0, (height + lift) / 2, 0), Color = color, Material = material, Parent = folder })
	end
	-- start a little way down the slope: right at the top the slope meets the flat ground, and a
	-- tilted strip there would stick up out of it
	local steps = math.floor((def.landing.length - path.start) / path.segment)
	for i = 0, steps - 1 do
		local a, b = path.start + i * path.segment, path.start + (i + 1) * path.segment
		strip("PathStone", point(a, 0), point(b, 0), path.width, 0.3, P.PathStone, Enum.Material.Pebble, i)
		for _, side in { -1, 1 } do
			strip("Bricks", point(a, side), point(b, side), path.brick, path.brick * 0.6, P.Brick, Enum.Material.Brick, i)
		end
	end
end

local function nearPath(def, along, x)
	return def.path ~= nil and along <= def.landing.length
		and math.abs(x - pathX(def.path, along)) < def.path.width / 2 + PATH_CLEARANCE
end

-- Footprints of props already placed (x across the slope, distance down it, radius), so new ones
-- don't grow through each other.
local function overlaps(placed, x, along, radius)
	for _, spot in placed do
		if (spot.x - x) ^ 2 + (spot.along - along) ^ 2 < (spot.radius + radius) ^ 2 then
			return true
		end
	end
	return false
end

-- On terrain maps, moves a placed prop up or down onto the bumpy ground under it, buried by
-- `sink` (share of its height, from Config/MeshProps) so it doesn't float over slopes.
local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { workspace.Terrain }
local function settle(def, prop, sink)
	if def.terrain then
		local pivot = prop:GetPivot()
		local y = TerrainBuilder.groundY(pivot.Position, terrainOnly)
		local buried = 0.6 + (sink or 0) * prop:GetExtentsSize().Y
		prop:PivotTo(pivot + Vector3.new(0, y - pivot.Position.Y - buried, 0))
	end
end

local function footprint(prop)
	local size = prop:GetExtentsSize()
	return math.max(size.X, size.Z) / 2 * FOOTPRINT_SHARE
end

local function placeProps(def, g, model)
	local rng = Random.new(def.seed)
	local folder = Build.model("Props", model)
	local half = def.landing.width / 2 - 25
	local perThousand = def.landing.length / 1000
	local placed = {}
	for key, density in def.props do
		local builder = PROP_BUILDERS[key]
		local area = def.propAreas and def.propAreas[key]
		for _ = 1, math.min(Maps.PropCap, math.floor(density * perThousand)) do
			local along = rng:NextNumber(80, def.landing.length + PARK_LENGTH - 40)
			local onSlope = along <= def.landing.length
			local position = if onSlope
				then MapGeometry.landPoint(g, along)
				else g.landEnd + Vector3.new(0, 0, along - def.landing.length)
			local x = if area
				then rng:NextNumber(area[1], math.min(area[2], half)) * (if rng:NextNumber() < 0.5 then -1 else 1)
				else rng:NextNumber(-half, half)
			if nearPath(def, along, x) then
				continue
			end
			position += Vector3.new(x, 0, 0)
			local normal = if onSlope and not builder.upright then MapGeometry.landNormalAt(g, along) else Vector3.yAxis
			local turn = if builder.facing then 0 else rng:NextNumber(0, math.pi * 2)
			local prop = builder.build(rng, def.theme)
			local radius = footprint(prop) + (def.propGap or 0) / 2
			if overlaps(placed, x, along, radius) then
				prop:Destroy()
				continue
			end
			table.insert(placed, { x = x, along = along, radius = radius })
			prop:PivotTo(Build.onSurface(position, normal) * CFrame.Angles(0, turn, 0))
			settle(def, prop, builder.sink)
			prop.Parent = folder
		end
	end
	-- trees along the sides of the mega ramp hill
	local outer = if def.terrain then def.landing.width / 2 else def.ramp.width / 2 + HILL_MARGIN - 5
	for i, key in def.hillTrees or {} do
		for n = 1, (def.hillTreeCount or HILL_TREES) / #def.hillTrees do
			local along = rng:NextNumber(40, def.ramp.length - 20)
			local side = if (n + i) % 2 == 0 then 1 else -1
			local x = side * rng:NextNumber(def.ramp.width / 2 + 12, outer)
			local tree = PROP_BUILDERS[key].build(rng, def.theme)
			tree:PivotTo(CFrame.new(g.origin + g.down * along + Vector3.new(x, -0.6, 0)))
			settle(def, tree, PROP_BUILDERS[key].sink)
			tree.Parent = folder
		end
	end
end

MapBuilder.PARK_LENGTH = PARK_LENGTH

-- options.skipTerrain = the terrain is already laid (Studio tools lay big maps in batches).
function MapBuilder.build(def, parent, options)
	local g = MapGeometry.get(def)
	local floorY = g.landEnd.Y
	local model = Build.model(def.id)
	buildRamp(def, g, model, floorY)
	buildKicker(def, g, model)
	if def.terrain then
		if not (options and options.skipTerrain) then
			TerrainBuilder.buildAll(def, g, PARK_LENGTH)
		end
		TerrainBuilder.buildSkirts(def, g, PARK_LENGTH, model)
	else
		buildGround(def, g, model, floorY)
	end
	buildBarrier(def, g, model)
	buildFences(def, g, model)
	if def.street then
		buildStreet(def, g, model, Random.new(def.seed + 1))
	end
	if def.path then
		buildPath(def, g, model)
	end
	if def.surfaces then
		buildSurfaces(def, g, model)
	end
	if def.decals then
		buildDecals(def, g, model, Random.new(def.seed + 2))
	end
	if def.endWall then
		buildEndWall(def, g, model)
	end
	placeProps(def, g, model)
	ZFight.fix(model)
	model.Parent = parent
	return model
end

return MapBuilder
