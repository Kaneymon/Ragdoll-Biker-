-- Tricks and how much they add to the run multiplier.
-- kind "rotation": detected from real bike rotation in the air (axis = pitch/roll, sign = direction)
-- kind "move": animated bike part spin (joint) triggered by an input action
-- kind "pose": rider pose triggered by an input action
return {
	StartMultiplier = 1,
	FullTurnTolerance = 0.88, -- fraction of 360 that counts as a full flip
	MaxTricksPerRun = 120,
	list = {
		{ id = "backflip", nameKey = "TRICK_BACKFLIP", kind = "rotation", axis = "pitch", sign = 1, bonus = 0.1 },
		{ id = "frontflip", nameKey = "TRICK_FRONTFLIP", kind = "rotation", axis = "pitch", sign = -1, bonus = 0.12 },
		{ id = "sideflip", nameKey = "TRICK_SIDEFLIP", kind = "rotation", axis = "roll", sign = 0, bonus = 0.12 },
		{ id = "tailwhip", nameKey = "TRICK_TAILWHIP", kind = "move", action = "Tailwhip", joint = "Whip", duration = 0.7, bonus = 0.1 },
		{ id = "barspin", nameKey = "TRICK_BARSPIN", kind = "move", action = "Barspin", joint = "Bars", duration = 0.5, bonus = 0.08 },
		{ id = "superman", nameKey = "TRICK_SUPERMAN", kind = "pose", action = "PoseSuperman", pose = "Superman", duration = 0.9, bonus = 0.15 },
		{ id = "lazyboy", nameKey = "TRICK_LAZYBOY", kind = "pose", action = "PoseLazyboy", pose = "Lazyboy", duration = 0.9, bonus = 0.15 },
	},
}
