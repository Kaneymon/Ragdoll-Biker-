-- Everything about getting hurt: tuning, bones, body parts and injury types.
return {
	Tuning = {
		MinImpact = 35, -- change in speed (studs/s) needed to hurt
		SeverityScale = 90, -- extra speed change for severity 1
		ImpactValue = 6, -- $ per impact at severity 1
		Exponent = 1.6, -- bigger hits pay much more
		BoneDamage = 0.45, -- bone damage per severity point (0 = fine, 1 = dust)
		BoneValue = 10, -- $ per fully broken bone
		HurtBone = 0.25, -- bone damage that counts as "hurt" on the payout sheet
		MaxImpactSpeed = 2500, -- server sanity cap
		MaxImpacts = 80,
		Cooldown = 0.12, -- seconds between impacts on the same body part
	},

	-- Skeleton bones, with where to draw them on the payout sheet:
	-- ui = { centreX, centreY, width, height, rotation } as fractions of the figure box.
	Bones = {
		{ id = "skull", nameKey = "BONE_SKULL", ui = { 0.5, 0.07, 0.2, 0.1, 0 }, round = true },
		{ id = "jaw", nameKey = "BONE_JAW", ui = { 0.5, 0.135, 0.13, 0.035, 0 } },
		{ id = "neck", nameKey = "BONE_NECK", ui = { 0.5, 0.175, 0.05, 0.05, 0 } },
		{ id = "collar_l", nameKey = "BONE_COLLAR", ui = { 0.39, 0.215, 0.18, 0.025, 8 } },
		{ id = "collar_r", nameKey = "BONE_COLLAR", ui = { 0.61, 0.215, 0.18, 0.025, -8 } },
		{ id = "ribs", nameKey = "BONE_RIBS", ui = { 0.5, 0.3, 0.28, 0.13, 0 } },
		{ id = "spine", nameKey = "BONE_SPINE", ui = { 0.5, 0.41, 0.05, 0.1, 0 } },
		{ id = "pelvis", nameKey = "BONE_PELVIS", ui = { 0.5, 0.49, 0.28, 0.06, 0 } },
		{ id = "arm_l", nameKey = "BONE_ARM", ui = { 0.25, 0.32, 0.055, 0.19, 12 } },
		{ id = "arm_r", nameKey = "BONE_ARM", ui = { 0.75, 0.32, 0.055, 0.19, -12 } },
		{ id = "forearm_l", nameKey = "BONE_FOREARM", ui = { 0.19, 0.5, 0.05, 0.17, 6 } },
		{ id = "forearm_r", nameKey = "BONE_FOREARM", ui = { 0.81, 0.5, 0.05, 0.17, -6 } },
		{ id = "hand_l", nameKey = "BONE_HAND", ui = { 0.16, 0.62, 0.07, 0.055, 0 } },
		{ id = "hand_r", nameKey = "BONE_HAND", ui = { 0.84, 0.62, 0.07, 0.055, 0 } },
		{ id = "leg_l", nameKey = "BONE_LEG", ui = { 0.41, 0.63, 0.065, 0.19, 3 } },
		{ id = "leg_r", nameKey = "BONE_LEG", ui = { 0.59, 0.63, 0.065, 0.19, -3 } },
		{ id = "shin_l", nameKey = "BONE_SHIN", ui = { 0.4, 0.83, 0.055, 0.18, 0 } },
		{ id = "shin_r", nameKey = "BONE_SHIN", ui = { 0.6, 0.83, 0.055, 0.18, 0 } },
		{ id = "foot_l", nameKey = "BONE_FOOT", ui = { 0.37, 0.95, 0.1, 0.04, 0 } },
		{ id = "foot_r", nameKey = "BONE_FOOT", ui = { 0.63, 0.95, 0.1, 0.04, 0 } },
	},

	-- Character part name -> body region and the bones it holds. Covers R15 and R6 rigs.
	BodyParts = {
		Head = { region = "head", bones = { "skull", "jaw", "neck" } },
		UpperTorso = { region = "torso", bones = { "ribs", "collar_l", "collar_r" } },
		LowerTorso = { region = "torso", bones = { "spine", "pelvis" } },
		Torso = { region = "torso", bones = { "ribs", "spine", "pelvis" } },
		LeftUpperArm = { region = "limb", bones = { "arm_l" } },
		RightUpperArm = { region = "limb", bones = { "arm_r" } },
		LeftLowerArm = { region = "limb", bones = { "forearm_l" } },
		RightLowerArm = { region = "limb", bones = { "forearm_r" } },
		LeftHand = { region = "limb", bones = { "hand_l" } },
		RightHand = { region = "limb", bones = { "hand_r" } },
		LeftUpperLeg = { region = "limb", bones = { "leg_l" } },
		RightUpperLeg = { region = "limb", bones = { "leg_r" } },
		LeftLowerLeg = { region = "limb", bones = { "shin_l" } },
		RightLowerLeg = { region = "limb", bones = { "shin_r" } },
		LeftFoot = { region = "limb", bones = { "foot_l" } },
		RightFoot = { region = "limb", bones = { "foot_r" } },
		["Left Arm"] = { region = "limb", bones = { "arm_l", "forearm_l", "hand_l" } },
		["Right Arm"] = { region = "limb", bones = { "arm_r", "forearm_r", "hand_r" } },
		["Left Leg"] = { region = "limb", bones = { "leg_l", "shin_l", "foot_l" } },
		["Right Leg"] = { region = "limb", bones = { "leg_r", "shin_r", "foot_r" } },
	},

	-- Per impact, the worst injury whose minSeverity is reached (and region matches) is given.
	list = {
		{ id = "bruise", nameKey = "INJ_BRUISE", region = "any", minSeverity = 0.05, value = 1 },
		{ id = "headache", nameKey = "INJ_HEADACHE", region = "head", minSeverity = 0.1, value = 2 },
		{ id = "contusion", nameKey = "INJ_CONTUSION", region = "torso", minSeverity = 0.2, value = 2 },
		{ id = "sprain", nameKey = "INJ_SPRAIN", region = "limb", minSeverity = 0.25, value = 3 },
		{ id = "strain", nameKey = "INJ_STRAIN", region = "limb", minSeverity = 0.4, value = 4 },
		{ id = "tear", nameKey = "INJ_TEAR", region = "limb", minSeverity = 0.55, value = 6 },
		{ id = "concussion", nameKey = "INJ_CONCUSSION", region = "head", minSeverity = 0.6, value = 11 },
		{ id = "dislocation", nameKey = "INJ_DISLOCATION", region = "limb", minSeverity = 0.75, value = 9 },
		{ id = "fracture", nameKey = "INJ_FRACTURE", region = "limb", minSeverity = 1.0, value = 15 },
		{ id = "internal_bleeding", nameKey = "INJ_INTERNAL", region = "torso", minSeverity = 1.4, value = 35 },
		{ id = "break", nameKey = "INJ_BREAK", region = "limb", minSeverity = 1.5, value = 22 },
		{ id = "hemorrhage", nameKey = "INJ_HEMORRHAGE", region = "head", minSeverity = 2.0, value = 45 },
		{ id = "compound_fracture", nameKey = "INJ_COMPOUND", region = "limb", minSeverity = 2.2, value = 40 },
	},
}
