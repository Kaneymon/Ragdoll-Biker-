-- Everything about getting hurt: tuning, bone damage statuses and medical injuries.
-- Bones themselves are listed in Config/Bones (all 206).
return {
	Tuning = {
		StudsToMph = 0.626, -- 1 stud = 0.28 m
		MinHitMph = 20, -- speed change needed to hurt
		MaxHitMph = 1000, -- one hit never counts for more than this
		SeverityMph = 60, -- extra mph for injury severity 1 (picks the medical injury)
		ImpactValue = 6, -- $ per hit at severity 1
		Exponent = 1.6, -- bigger hits pay much more
		MphPerExtraBone = 120, -- every this many mph, one more bone in the body part takes the hit
		DustMph = 5000, -- cumulative mph that turns a bone to dust (darkest red)
		MaxImpacts = 80,
		Cooldown = 0.12, -- seconds between hits on the same body part
	},

	-- What a bone is called once its cumulative speed damage (mph) reaches minMph.
	BoneStatuses = {
		{ id = "contusion", nameKey = "BONE_ST_CONTUSION", minMph = 60, value = 1 },
		{ id = "fracture", nameKey = "BONE_ST_FRACTURE", minMph = 300, value = 3 },
		{ id = "break", nameKey = "BONE_ST_BREAK", minMph = 800, value = 6 },
		{ id = "multi_break", nameKey = "BONE_ST_MULTI", minMph = 1600, value = 10 },
		{ id = "shattered", nameKey = "BONE_ST_SHATTERED", minMph = 3000, value = 18 },
		{ id = "dust", nameKey = "BONE_ST_DUST", minMph = 5000, value = 30 },
	},

	-- Per hit, the worst medical injury whose minSeverity is reached (and region matches) is given.
	list = {
		{ id = "bruise", nameKey = "INJ_BRUISE", region = "any", minSeverity = 0.05, value = 1 },
		{ id = "headache", nameKey = "INJ_HEADACHE", region = "head", minSeverity = 0.1, value = 2 },
		{ id = "contusion", nameKey = "INJ_CONTUSION", region = "torso", minSeverity = 0.2, value = 2 },
		{ id = "sprain", nameKey = "INJ_SPRAIN", region = "limb", minSeverity = 0.25, value = 3 },
		{ id = "strain", nameKey = "INJ_STRAIN", region = "limb", minSeverity = 0.4, value = 4 },
		{ id = "tear", nameKey = "INJ_TEAR", region = "limb", minSeverity = 0.55, value = 6 },
		{ id = "concussion", nameKey = "INJ_CONCUSSION", region = "head", minSeverity = 0.6, value = 11 },
		{ id = "dislocation", nameKey = "INJ_DISLOCATION", region = "limb", minSeverity = 0.75, value = 9 },
		{ id = "internal_bleeding", nameKey = "INJ_INTERNAL", region = "torso", minSeverity = 1.4, value = 35 },
		{ id = "hemorrhage", nameKey = "INJ_HEMORRHAGE", region = "head", minSeverity = 2.0, value = 45 },
	},
}
