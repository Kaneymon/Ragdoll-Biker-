-- Everything about getting hurt: tuning, bone damage statuses and medical injuries.
-- Bones themselves are listed in Config/Bones (all 206).
return {
	Tuning = {
		StudsToMph = 0.626, -- 1 stud = 0.28 m
		MinHitMph = 20, -- speed change needed to hurt
		MaxHitMph = 1000, -- one hit never counts for more than this
		-- Difficulty curve on each hit's mph: up to PivotMph hits count x Below (easier to get hurt),
		-- every mph past it counts x Above (harder).
		Curve = { PivotMph = 500, Below = 1.25, Above = 0.6 },
		SeverityMph = 60, -- extra mph for injury severity 1 (picks the medical injury)
		ImpactValue = 6, -- $ per hit at severity 1
		Exponent = 1.6, -- bigger hits pay much more
		MphPerExtraBone = 120, -- every this many mph, one more bone in the body part takes the hit
		DustMph = 5000, -- cumulative mph that turns a bone to dust (darkest red)
		-- Bones are easy to hurt until EasyBones are hurt in a run; after that every hit's bone
		-- damage is scaled by (EasyBones / bones hurt) ^ HardPower (141 bones -> half, 200 -> quarter).
		EasyBones = 100,
		HardPower = 2,
		MaxImpacts = 400, -- hurts counted per run (hits + sliding + blasts)
		Cooldown = 0.12, -- seconds between hits on the same body part
	},

	-- Sliding/rolling along the ground: every Interval seconds the fastest body part touching the
	-- ground is hurt as if hit at Share of its speed (only above MinSpeed studs/s).
	Contact = { Interval = 0.3, Share = 0.15, MinSpeed = 60 },

	-- What a bone is called once its cumulative speed damage (mph) reaches minMph.
	BoneStatuses = {
		{ id = "contusion", nameKey = "BONE_ST_CONTUSION", minMph = 30, value = 1 },
		{ id = "fracture", nameKey = "BONE_ST_FRACTURE", minMph = 120, value = 3 },
		{ id = "break", nameKey = "BONE_ST_BREAK", minMph = 300, value = 6 },
		{ id = "multi_break", nameKey = "BONE_ST_MULTI", minMph = 700, value = 10 },
		{ id = "shattered", nameKey = "BONE_ST_SHATTERED", minMph = 1800, value = 18 },
		{ id = "dust", nameKey = "BONE_ST_DUST", minMph = 5000, value = 30 },
	},

	-- Rare lucky hits that multiply the money for that hit (the server rolls them, best first).
	-- A hit is a "record" when its speed change beats your best ever (and is at least MinRecordMph),
	-- "near record" when it is within NearRecord of it AND you spent SpendShare of your cash
	-- since your last payout. minMph = the hit's raw speed change needed for that modifier.
	-- flash = Config/Flashes entry shown on screen.
	Lucky = {
		MinRecordMph = 60,
		NearRecord = 0.85,
		SpendShare = 0.75,
		list = {
			{ id = "x10", nameKey = "LUCKY_X10", mult = 10, recordChance = 0.025, nearChance = 0.0625, minMph = 1500, flash = "Lucky10" },
			{ id = "x4", nameKey = "LUCKY_X4", mult = 4, recordChance = 0.05, nearChance = 0.125, minMph = 0, flash = "Lucky4" },
			{ id = "x2", nameKey = "LUCKY_X2", mult = 2, recordChance = 0.10, nearChance = 0.25, minMph = 0, flash = "Lucky2" },
		},
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
