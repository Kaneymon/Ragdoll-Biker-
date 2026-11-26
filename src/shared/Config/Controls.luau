-- Input actions. Pedal/brake/steer and flip direction come from the move stick
-- (WASD, gamepad thumbstick, touch thumbstick) so they work on every device.
-- touch = show an on-screen button on phones.
return {
	actions = {
		{ name = "Hop", keys = { Enum.KeyCode.Space, Enum.KeyCode.ButtonA }, touch = true, nameKey = "ACT_HOP_BAIL" },
		{ name = "Boost", keys = { Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonR2 }, touch = true, nameKey = "ACT_BOOST" },
		{ name = "Explode", keys = { Enum.KeyCode.X, Enum.KeyCode.ButtonY }, touch = true, nameKey = "ACT_EXPLODE" },
		{ name = "Tailwhip", keys = { Enum.KeyCode.Q, Enum.KeyCode.ButtonL1 }, touch = true, nameKey = "ACT_TAILWHIP" },
		{ name = "Barspin", keys = { Enum.KeyCode.E, Enum.KeyCode.ButtonR1 }, touch = true, nameKey = "ACT_BARSPIN" },
		{ name = "PoseSuperman", keys = { Enum.KeyCode.R, Enum.KeyCode.ButtonX }, touch = true, nameKey = "ACT_SUPERMAN" },
		{ name = "PoseLazyboy", keys = { Enum.KeyCode.F, Enum.KeyCode.ButtonB }, touch = true, nameKey = "ACT_LAZYBOY" },
		{ name = "PoseCanCan", keys = { Enum.KeyCode.G, Enum.KeyCode.DPadUp }, touch = true, nameKey = "ACT_CANCAN" },
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
