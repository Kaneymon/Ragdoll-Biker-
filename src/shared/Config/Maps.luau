-- Maps. Geometry feeds Logic/MapGeometry (maths) and World/MapBuilder (parts).
-- Each map: ramp length 2x the previous map, landing slope 3x the previous map.
-- origin = top of the mega ramp (downhill is +Z); all maps end near y = -250, side by side on X,
-- SPACING apart, so every map can see (and see the riders on) its neighbours.
-- props = how many of each prop per 1000 studs of landing slope (capped by PropCap).
-- propAreas = where across the slope a prop may go: { from, to } studs from the centre line
--   (either side); anything not listed can go anywhere.
-- street = draw a road down the middle, pavements either side and houses along the outside.
-- path = a brick-lined path winding down the landing slope (amplitude/wavelength in studs);
--   props keep clear of it.
-- hillTrees = prop keys planted along both sides of the mega ramp.
-- Prop keys: the part-built props in World/Props and the textured meshes in Config/MeshProps.
local P = require(script.Parent.Palette)

local SPACING = 2000 -- studs between map centres on X (each force field box is 1620 wide)

-- material = surface texture for the ground (nil = smooth plastic)
local function theme(ground, groundDark, ramp, kickerA, kickerB, rail, material)
	return { ground = ground, groundDark = groundDark, ramp = ramp, kickerA = kickerA, kickerB = kickerB, rail = rail, material = material }
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
			theme = theme(P.Grass, P.GrassDark, P.Wood, P.Coral, P.Orange, P.Coral, Enum.Material.Grass),
			props = {
				oakTrees = 14, firTrees = 10, bushes = 20, flowers = 36, parkBenches = 6,
				picnicTables = 4, parkLamps = 6, swings = 2, jungleGyms = 2,
			},
			hillTrees = { "oakTrees", "firTrees" },
			path = { width = 16, amplitude = 110, wavelength = 520, segment = 16, brick = 1.4 },
		},
		{
			id = "skate_park", nameKey = "MAP_SKATE_PARK", price = 75000, level = 12, payoutMult = 2,
			origin = Vector3.new(SPACING * 1, 1705, 0), seed = 11,
			ramp = { angle = 32, length = 1360, width = 50, thickness = 8 },
			runout = 70, kicker = { radius = 120, endAngle = 40, segments = 12 }, gap = 70,
			landing = { angle = 14, length = 5100, width = 420 },
			theme = theme(P.Concrete, P.Stone, P.Sky, P.Grape, P.Sky, P.Grape),
			props = { crates = 14, benches = 10, rocks = 12, fences = 10, rails = 10, launchRamps = 3 },
			propAreas = { launchRamps = { 0, 150 } },
		},
		{
			id = "streets", nameKey = "MAP_STREETS", price = 2500000, level = 20, payoutMult = 4,
			origin = Vector3.new(SPACING * 2, 4893, 0), seed = 23,
			ramp = { angle = 32, length = 2720, width = 56, thickness = 10 },
			runout = 90, kicker = { radius = 160, endAngle = 40, segments = 14 }, gap = 90,
			landing = { angle = 14, length = 15300, width = 420 },
			theme = theme(P.Asphalt, P.Ink, P.Orange, P.Sun, P.Orange, P.Sun),
			props = { cars = 8, lamps = 8, crates = 4, benches = 4 },
			propAreas = { cars = { 0, 95 }, lamps = { 115, 145 }, crates = { 115, 145 }, benches = { 115, 145 } },
			street = { road = 220, pavement = 40, laneDash = 30, houseX = 180, houseSpacing = 75 },
		},
		{
			id = "mountain", nameKey = "MAP_MOUNTAIN", price = 25000000, level = 30, payoutMult = 8,
			origin = Vector3.new(SPACING * 3, 13737, 0), seed = 31,
			ramp = { angle = 32, length = 5440, width = 64, thickness = 12 },
			runout = 110, kicker = { radius = 200, endAngle = 40, segments = 16 }, gap = 110,
			landing = { angle = 14, length = 45900, width = 420 },
			theme = theme(P.Snow, P.Stone, P.WoodDark, P.Sky, P.White, P.Sky),
			props = { trees = 4, rocks = 4, crates = 1 },
			hillTrees = { "trees" },
		},
		{
			id = "space_station", nameKey = "MAP_SPACE", price = 250000000, level = 40, payoutMult = 16,
			origin = Vector3.new(SPACING * 4, 38828, 0), seed = 47,
			ramp = { angle = 32, length = 10880, width = 72, thickness = 14 },
			runout = 130, kicker = { radius = 240, endAngle = 40, segments = 18 }, gap = 130,
			landing = { angle = 14, length = 137700, width = 420 },
			theme = theme(P.SpaceFloor, P.Ink, P.Metal, P.Grape, P.Coral, P.Grape),
			props = { crates = 1.5, rocks = 1.5, lamps = 1 },
		},
	},
}
