-- Mega ramp start height. Each level starts you further up the slope (more speed).
-- Costs climb faster than payouts on purpose so later levels take real effort.
return {
	maxLevel = 25,
	startBase = 70, -- studs up the slope at level 0
	startPerLevel = 22,
	baseCost = 120,
	growth = 1.42,
}
