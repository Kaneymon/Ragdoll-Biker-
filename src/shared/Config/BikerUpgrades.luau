-- Rider gear (the Biker tab). Same maths as BikeUpgrades:
-- value(level) = Base[stat] + perLevel * level, cost(level) = baseCost * growth ^ level
return {
	Base = {
		glideControl = 1, -- multiplies ragdoll steering strength
		slide = 0, -- 0..1, how much ragdoll friction is removed
		bounce = 0, -- extra bounciness added to the ragdoll body
		bonesPerHit = 1, -- multiplies how many bones each hit reaches
	},
	list = {
		{ id = "helmet", nameKey = "UPG_HELMET", descKey = "UPG_HELMET_DESC", stat = "glideControl", perLevel = 0.15, maxLevel = 20, baseCost = 120, growth = 1.35, format = "mult" },
		{ id = "kneepads", nameKey = "UPG_KNEEPADS", descKey = "UPG_KNEEPADS_DESC", stat = "slide", perLevel = 0.035, maxLevel = 20, baseCost = 100, growth = 1.35, format = "percent" },
		{ id = "bodyarmour", nameKey = "UPG_ARMOUR", descKey = "UPG_ARMOUR_DESC", stat = "bounce", perLevel = 0.035, maxLevel = 20, baseCost = 140, growth = 1.36, format = "percent" },
		{ id = "boots", nameKey = "UPG_BOOTS", descKey = "UPG_BOOTS_DESC", stat = "bonesPerHit", perLevel = 0.12, maxLevel = 20, baseCost = 160, growth = 1.38, format = "mult" },
	},
}
