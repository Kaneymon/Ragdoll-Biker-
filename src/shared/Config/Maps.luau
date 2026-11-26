-- Maps. Geometry values feed World/MapBuilder. Only hill_park is built for the MVP.
return {
	default = "hill_park",
	list = {
		{
			id = "hill_park",
			nameKey = "MAP_HILL_PARK",
			price = 0,
			level = 1,
			payoutMult = 1,
			origin = Vector3.new(0, 480, 0), -- top of the mega ramp; downhill is +Z
			seed = 7,
			ramp = { angle = 32, length = 680, width = 44, thickness = 6 },
			runout = 50,
			kicker = { radius = 80, endAngle = 40, segments = 10 },
			gap = 50,
			landing = { angle = 14, length = 1700, width = 420 },
			props = { trees = 70, benches = 22, hay = 30, rocks = 34, tables = 12, bouncers = 8, fences = 16 },
		},
		{ id = "skate_park", nameKey = "MAP_SKATE_PARK", price = 250000, level = 12, payoutMult = 2, comingSoon = true },
		{ id = "streets", nameKey = "MAP_STREETS", price = 2500000, level = 20, payoutMult = 4, comingSoon = true },
		{ id = "mountain", nameKey = "MAP_MOUNTAIN", price = 25000000, level = 30, payoutMult = 8, comingSoon = true },
		{ id = "space_station", nameKey = "MAP_SPACE", price = 250000000, level = 40, payoutMult = 16, comingSoon = true },
	},
}
