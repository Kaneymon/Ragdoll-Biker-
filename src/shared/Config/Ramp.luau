-- Mega ramp start height. Each level starts you further up the slope (more speed).
-- Start = a fraction of the selected map's ramp length, so the same level is worth more
-- on bigger maps. Costs climb faster than payouts on purpose so later levels take real effort.
return {
	maxLevel = 30,
	startFraction = 0.1, -- level 0 starts 10% up the ramp
	topFraction = 0.99, -- max level starts almost at the top
	baseCost = 120,
	growth = 1.45,
}
