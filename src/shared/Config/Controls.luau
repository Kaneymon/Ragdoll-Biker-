-- Input actions. Pedal/brake/steer and flip direction come from the move stick
-- (WASD, gamepad thumbstick, touch thumbstick) so they work on every device.
-- touch = show an on-screen button on phones. rule = the Logic/Location rule that turns the action
-- on (Hop and Bail share a button: Hop in the lobby, Bail on the ramps). airOnly = the key is only
-- taken in the air, so on the ground it still reaches shop prompts (E).
return {
	actions = {
		{ name = "Hop", keys = { Enum.KeyCode.Space, Enum.KeyCode.ButtonA }, touch = true, nameKey = "ACT_HOP", rule = "hop" },
		{ name = "Bail", keys = { Enum.KeyCode.Space, Enum.KeyCode.ButtonA }, touch = true, nameKey = "ACT_BAIL", rule = "bail" },
		{ name = "Boost", keys = { Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonR2 }, touch = true, nameKey = "ACT_BOOST", rule = "gear" },
		{ name = "Explode", keys = { Enum.KeyCode.X, Enum.KeyCode.ButtonY }, touch = true, nameKey = "ACT_EXPLODE", rule = "gear" },
		{ name = "Tailwhip", keys = { Enum.KeyCode.Q, Enum.KeyCode.ButtonL1 }, touch = true, nameKey = "ACT_TAILWHIP", rule = "tricks", airOnly = true },
		{ name = "Barspin", keys = { Enum.KeyCode.E, Enum.KeyCode.ButtonR1 }, touch = true, nameKey = "ACT_BARSPIN", rule = "tricks", airOnly = true },
		{ name = "PoseSuperman", keys = { Enum.KeyCode.R, Enum.KeyCode.ButtonX }, touch = true, nameKey = "ACT_SUPERMAN", rule = "tricks", airOnly = true },
		{ name = "PoseLazyboy", keys = { Enum.KeyCode.F, Enum.KeyCode.ButtonB }, touch = true, nameKey = "ACT_LAZYBOY", rule = "tricks", airOnly = true },
		{ name = "PoseCanCan", keys = { Enum.KeyCode.G, Enum.KeyCode.DPadUp }, touch = true, nameKey = "ACT_CANCAN", rule = "tricks", airOnly = true },
	},
	-- Shown in Settings > Controls. pc/console/touch are display labels.
	stick = {
		{ nameKey = "ACT_PEDAL", pc = "W", console = "L-Stick Up", touch = "Stick Up" },
		{ nameKey = "ACT_BRAKE", pc = "S", console = "L-Stick Down", touch = "Stick Down" },
		{ nameKey = "ACT_STEER", pc = "A / D", console = "L-Stick", touch = "Stick" },
		{ nameKey = "ACT_FLIP", pc = "W / S", console = "L-Stick", touch = "Stick" },
		{ nameKey = "ACT_SIDEFLIP", pc = "A / D", console = "L-Stick", touch = "Stick" },
	},
}
