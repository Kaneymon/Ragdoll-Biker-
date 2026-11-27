-- Maps. Geometry feeds Logic/MapGeometry (maths) and World/MapBuilder (parts).
-- Each map: ramp length 2x the previous map, landing slope 3x the previous map.
-- origin = top of the mega ramp (downhill is +Z); all maps end near y = -250, side by side on X,
-- SPACING apart, so every map can see (and see the riders on) its neighbours (the Mountain sits on
-- the far side of the Hill Park, at -SPACING).
-- props = how many of each prop per 1000 studs of landing slope (capped by PropCap).
-- propAreas = where across the slope a prop may go: { from, to } studs from the centre line
--   (either side); anything not listed can go anywhere.
-- street = draw a road down the middle, pavements either side and houses along the outside.
-- path = a brick-lined path winding down the landing slope (amplitude/wavelength in studs),
--   starting `start` studs down it; props keep clear of it.
-- hillTrees = prop keys planted along both sides of the mega ramp (hillTreeCount of them, default 24).
-- surfaces = stripes of a different floor down the slope ({ width, color, material }, centred).
-- propGap = extra studs kept between props. fenceMesh = Config/MeshProps key used for the
--   perimeter fence (one segment every `length` studs) instead of plain rails.
-- decals = images from Config/Decals scattered on the floor ({ set, count, size, area }).
-- endWall = what closes off the bottom of the park: { wall = MeshProps key, column = MeshProps key
--   between sections (optional) } or { houses = true } for a row of house fronts.
-- terrain = the ground is Roblox terrain (World/TerrainBuilder) instead of parts: the ride line with
--   bumps on the landing, valley sides, a summit behind the start, materials by height and slope.
--   cell = grid size (studs), shell = terrain thickness, halfWidth = how far out the valley sides
--   reach, under* = how far the terrain sits below the ramp / shelf parts, iceDepth = studs below
--   the top where snow and ice stop, glacierSlope / grassSlope = degrees (steeper than grassSlope
--   is rock), shelfFlatten = how much the valley sides drop away beside the kicker shelf.
--   skirt = rock walls from the terrain's edges down to the floor: lip = how far the edges turn
--   down, thickness, step = length of each wall section.
-- Prop keys: the part-built props in World/Props and the textured meshes in Config/MeshProps.
local P = require(script.Parent.Palette)

local SPACING = 2000 -- studs between map centres on X (each force field box is 1620 wide)

-- kickerA / kickerB = colours of the small launch-ramp props; material = surface texture for the
-- ground (nil = smooth plastic). The mega ramps themselves all look the same (Config/MegaRamp).
local function theme(ground, groundDark, kickerA, kickerB, material)
	return { ground = ground, groundDark = groundDark, kickerA = kickerA, kickerB = kickerB, material = material }
end

return {
	default = "hill_park",
	PropCap = 220, -- max of one prop type on a map
	FenceSpacing = 24, -- studs between fence posts
	BarrierHeight = 6000, -- force field ceiling height above the highest ground in each stretch
	list = {
		{
			id = "hill_park", nameKey = "MAP_HILL_PARK", price = 0, level = 1, payoutMult = 1,
			origin = Vector3.new(0, 480, 0), seed = 7,
			ramp = { angle = 32, length = 680, width = 44, thickness = 6 },
			runout = 50, kicker = { radius = 80, endAngle = 40, segments = 10 }, gap = 50,
			landing = { angle = 14, length = 1700, width = 420 },
			theme = theme(P.Grass, P.GrassDark, P.Coral, P.Orange, Enum.Material.Grass),
			props = {
				oakTrees = 14, firTrees = 10, bushes = 20, flowers = 36, parkBenches = 6,
				picnicTables = 4, parkLamps = 6, swings = 2, jungleGyms = 2,
			},
			hillTrees = { "oakTrees", "firTrees" },
			endWall = { wall = "brickWall", column = "brickColumn" },
			path = { start = 40, width = 16, amplitude = 110, wavelength = 520, segment = 16, brick = 1.4 },
		},
		{
			id = "skate_park", nameKey = "MAP_SKATE_PARK", price = 75000, level = 12, payoutMult = 2,
			origin = Vector3.new(SPACING * 1, 1705, 0), seed = 11,
			ramp = { angle = 32, length = 1360, width = 50, thickness = 8 },
			runout = 70, kicker = { radius = 120, endAngle = 40, segments = 12 }, gap = 70,
			landing = { angle = 14, length = 5100, width = 420 },
			theme = theme(P.Grass, P.GrassDark, P.Grape, P.Sky, Enum.Material.Grass),
			surfaces = { { width = 270, color = P.ConcreteFloor, material = Enum.Material.Concrete } },
			props = {
				quarterPipes = 3, skateLaunchRamps = 3, jumpBoxes = 3, hipBumps = 3,
				grindBoxes = 4, grindRails = 4, skateBenches = 3,
				-- the grass strips either side of the concrete
				oakTrees = 3, firTrees = 2, flowers = 8, bushes = 3, parkBenches = 0.8, grassClumps = 22,
			},
			propAreas = {
				quarterPipes = { 0, 105 }, skateLaunchRamps = { 0, 105 }, jumpBoxes = { 0, 105 }, hipBumps = { 0, 105 },
				grindBoxes = { 0, 110 }, grindRails = { 0, 110 }, skateBenches = { 112, 125 },
				oakTrees = { 150, 190 }, firTrees = { 150, 190 }, flowers = { 142, 192 }, bushes = { 145, 192 },
				parkBenches = { 142, 150 }, grassClumps = { 140, 194 },
			},
			propGap = 18,
			fenceMesh = { key = "chainFence", length = 11.5 },
			decals = { set = "graffiti", count = 45, size = 34, area = { 0, 120 } },
			endWall = { wall = "brickWall" },
		},
		{
			id = "streets", nameKey = "MAP_STREETS", price = 2500000, level = 20, payoutMult = 4,
			origin = Vector3.new(SPACING * 2, 4893, 0), seed = 23,
			ramp = { angle = 32, length = 2720, width = 56, thickness = 10 },
			runout = 90, kicker = { radius = 160, endAngle = 40, segments = 14 }, gap = 90,
			landing = { angle = 14, length = 15300, width = 420 },
			theme = theme(P.Asphalt, P.Ink, P.Sun, P.Orange),
			props = { cars = 8, lamps = 8, crates = 4, benches = 4 },
			propAreas = { cars = { 0, 95 }, lamps = { 115, 145 }, crates = { 115, 145 }, benches = { 115, 145 } },
			street = { road = 220, pavement = 40, laneDash = 30, houseX = 180, houseSpacing = 75 },
			endWall = { houses = true },
		},
		{
			id = "mountain", nameKey = "MAP_MOUNTAIN", price = 25000000, level = 30, payoutMult = 8,
			origin = Vector3.new(-SPACING, 13737, 0), seed = 31,
			ramp = { angle = 32, length = 5440, width = 64, thickness = 12 },
			runout = 110, kicker = { radius = 200, endAngle = 40, segments = 16 }, gap = 110,
			landing = { angle = 14, length = 45900, width = 420 },
			theme = theme(P.Snow, P.Stone, P.Sky, P.White),
			props = { pines = 4, boulders = 3 },
			propGap = 10,
			hillTrees = { "pines" },
			hillTreeCount = 160,
			terrain = {
				cell = 40, shell = 24, halfWidth = 720,
				underRamp = 14, underShelf = 14,
				noise = { amplitude = 22, scale = 190, calmStart = 250, edgeCalm = 90, fenceClear = 20 },
				sideRise = 260, sideNoise = 90, shelfFlatten = 0.85,
				summit = { height = 1100, behind = 650, radius = 620 },
				iceDepth = 2000, glacierSlope = 38, grassSlope = 17,
				skirt = { lip = 700, thickness = 30, step = 400 },
				materials = {
					ice = Enum.Material.Glacier, snow = Enum.Material.Snow,
					rock = Enum.Material.Rock, rockAlt = Enum.Material.Slate,
					grass = Enum.Material.Grass, mud = Enum.Material.Mud,
				},
			},
		},
		{
			id = "space_station", nameKey = "MAP_SPACE", price = 250000000, level = 40, payoutMult = 16,
			origin = Vector3.new(SPACING * 4, 38828, 0), seed = 47,
			ramp = { angle = 32, length = 10880, width = 72, thickness = 14 },
			runout = 130, kicker = { radius = 240, endAngle = 40, segments = 18 }, gap = 130,
			landing = { angle = 14, length = 137700, width = 420 },
			theme = theme(P.SpaceFloor, P.Ink, P.Grape, P.Coral),
			props = { crates = 1.5, rocks = 1.5, lamps = 1 },
		},
	},
}
