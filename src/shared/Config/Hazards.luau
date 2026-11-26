-- Things on the maps that blow up when you touch them (instead of being solid).
-- exploder = Config/Exploders entry whose blast force is used; radius = studs from the hazard's
-- centre that set it off; hideSeconds = how long it stays gone (for you) after blowing up;
-- up = how much the blast throws you upwards (0 = straight away from it, 1 = 45 degrees).
return {
	Tag = "Hazard", -- CollectionService tag on hazard models; their "Hazard" attribute names the kind
	kinds = {
		Car = { exploder = "grenade", radius = 9, hideSeconds = 10, up = 1 },
	},
}
