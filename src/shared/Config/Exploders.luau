-- One blast per run: launches you off the bike at high speed. force = studs/s added.
return {
	upgradeCostScale = 0.4,
	upgradeGrowth = 1.5,
	forcePerLevel = 0.1,
	maxLevel = 10,
	list = {
		{ id = "grenade", nameKey = "EXP_GRENADE", price = 900, force = 120, color = Color3.fromRGB(70, 160, 70) },
		{ id = "landmine", nameKey = "EXP_LANDMINE", price = 6000, force = 210, color = Color3.fromRGB(120, 130, 150) },
		{ id = "rpg", nameKey = "EXP_RPG", price = 90000, force = 330, color = Color3.fromRGB(196, 140, 90) },
		{ id = "nuke", nameKey = "EXP_NUKE", price = 1200000, force = 600, color = Color3.fromRGB(255, 205, 60) },
	},
}
