-- Blasts that launch you (off the bike, or harder while ragdolling). force = studs/s added.
-- Buying one gives 1 bomb per run; extra bombs cost price * chargeGrowth ^ owned (1x, 5x, 25x).
-- Upgrading raises the blast power of every bomb of that type.
return {
	upgradeCostScale = 0.4,
	upgradeGrowth = 1.5,
	forcePerLevel = 0.1,
	maxLevel = 10,
	maxCharges = 3,
	chargeGrowth = 5,
	list = {
		{ id = "grenade", nameKey = "EXP_GRENADE", price = 900, force = 120, color = Color3.fromRGB(70, 160, 70) },
		{ id = "landmine", nameKey = "EXP_LANDMINE", price = 6000, force = 210, color = Color3.fromRGB(120, 130, 150) },
		{ id = "rpg", nameKey = "EXP_RPG", price = 90000, force = 330, color = Color3.fromRGB(196, 140, 90) },
		{ id = "nuke", nameKey = "EXP_NUKE", price = 1200000, force = 600, color = Color3.fromRGB(255, 205, 60) },
	},
}
