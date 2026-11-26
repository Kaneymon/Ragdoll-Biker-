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
		{ id = "helmet", nameKey = "UPG_HELMET", descKey = "UPG_HELMET_DESC", stat = "glideControl", perLevel = 0.08, maxLevel = 50, baseCost = 120, growth = 1.39, format = "mult" },
		{ id = "kneepads", nameKey = "UPG_KNEEPADS", descKey = "UPG_KNEEPADS_DESC", stat = "slide", perLevel = 0.018, maxLevel = 50, baseCost = 100, growth = 1.39, format = "percent" },
		{ id = "bodyarmour", nameKey = "UPG_ARMOUR", descKey = "UPG_ARMOUR_DESC", stat = "bounce", perLevel = 0.016, maxLevel = 50, baseCost = 140, growth = 1.40, format = "percent" },
		{ id = "boots", nameKey = "UPG_BOOTS", descKey = "UPG_BOOTS_DESC", stat = "bonesPerHit", perLevel = 0.12, maxLevel = 50, baseCost = 160, growth = 1.42, format = "mult" },
	},
}
