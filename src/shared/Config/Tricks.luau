-- Tricks and how much they add to the run multiplier.
-- kind "rotation": detected from real bike rotation in the air (axis = pitch/roll, sign = direction)
-- kind "move": bike part spin (joint) started by an input action
-- kind "grab": held with an input action; adds its bonus every tick while held
-- pose = rider pose (Config/Poses) shown while doing the trick
return {
	StartMultiplier = 1,
	FullTurnTolerance = 0.88, -- fraction of 360 that counts as a full flip
	MaxTricksPerRun = 400, -- grab ticks count as entries
	TrickVariety = 1.3, -- move/grab bonus x this when it differs from the previous trick
	FlipVariety = 1.75, -- flip bonus x this when it differs from the previous flip
	GrabTick = 0.25, -- seconds per grab tick (divided by trick speed)
	GrabUpgradeShare = 0.25, -- share of the Wheels bonus each grab tick gets
	SpinPose = "Tuck", -- rider pose while flipping
	list = {
		{ id = "backflip", nameKey = "TRICK_BACKFLIP", kind = "rotation", axis = "pitch", sign = 1, bonus = 0.1 },
		{ id = "frontflip", nameKey = "TRICK_FRONTFLIP", kind = "rotation", axis = "pitch", sign = -1, bonus = 0.12 },
		{ id = "sideflip", nameKey = "TRICK_SIDEFLIP", kind = "rotation", axis = "roll", sign = 0, bonus = 0.12 },
		{ id = "tailwhip", nameKey = "TRICK_TAILWHIP", kind = "move", action = "Tailwhip", joint = "Whip", duration = 0.7, bonus = 0.1, pose = "Whip" },
		{ id = "barspin", nameKey = "TRICK_BARSPIN", kind = "move", action = "Barspin", joint = "Bars", duration = 0.5, bonus = 0.08, pose = "Barspin" },
		{ id = "superman", nameKey = "TRICK_SUPERMAN", kind = "grab", action = "PoseSuperman", pose = "Superman", bonus = 0.04 },
		{ id = "lazyboy", nameKey = "TRICK_LAZYBOY", kind = "grab", action = "PoseLazyboy", pose = "Lazyboy", bonus = 0.04 },
		{ id = "cancan", nameKey = "TRICK_CANCAN", kind = "grab", action = "PoseCanCan", pose = "CanCan", bonus = 0.03 },
	},
}
