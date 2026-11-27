-- Textured low-poly props modelled and baked in Blender (tools/park_props_blender.py; texture ids in
-- assets/models/park/README.md) and kept as Models in
-- ServerStorage.Assets.<folder>. Keys are the prop names used in Config/Maps `props`.
-- mesh = model name; scale = { min, max } random size; upright = stands straight up on slopes
-- (else tilts with the ground); collide = solid for bikes and ragdolls; folder = overrides the
-- default asset folder; launch = the bike flies off it (like the kickers); facing = keeps pointing
-- downhill instead of a random turn (ramps).
return {
	folder = "Park",
	list = {
		oakTrees = { mesh = "OakTree", scale = { 1.4, 2.1 }, upright = true, collide = true },
		firTrees = { mesh = "FirTree", scale = { 1.4, 2.3 }, upright = true, collide = true },
		bushes = { mesh = "Bush", scale = { 1, 1.7 }, upright = false, collide = true },
		flowers = { mesh = "FlowerPatch", scale = { 1.3, 2.2 }, upright = false, collide = false },
		parkBenches = { mesh = "Bench", scale = { 1.3, 1.3 }, upright = false, collide = true },
		picnicTables = { mesh = "PicnicTable", scale = { 1.3, 1.3 }, upright = false, collide = true },
		parkLamps = { mesh = "Lamp", scale = { 1.3, 1.3 }, upright = true, collide = true },
		swings = { mesh = "SwingSet", scale = { 1.4, 1.4 }, upright = false, collide = true },
		jungleGyms = { mesh = "JungleGym", scale = { 1.4, 1.4 }, upright = false, collide = true },

		-- Skate Park (tools/skate_props_blender.py, ids in assets/models/skate/README.md)
		quarterPipes = { folder = "Skate", mesh = "QuarterPipe", scale = { 1.4, 1.4 }, collide = true, launch = true, facing = true },
		skateLaunchRamps = { folder = "Skate", mesh = "SkateLaunchRamp", scale = { 1.4, 1.4 }, collide = true, launch = true, facing = true },
		jumpBoxes = { folder = "Skate", mesh = "JumpBox", scale = { 1.4, 1.4 }, collide = true, launch = true, facing = true },
		hipBumps = { folder = "Skate", mesh = "HipBump", scale = { 1.3, 1.7 }, collide = true, launch = true, facing = true },
		grindBoxes = { folder = "Skate", mesh = "GrindBox", scale = { 1.4, 1.4 }, collide = true },
		grindRails = { folder = "Skate", mesh = "GrindRail", scale = { 1.4, 1.4 }, collide = true },
		skateBenches = { folder = "Skate", mesh = "SkateBench", scale = { 1.3, 1.3 }, collide = true },
		chainFence = { folder = "Skate", mesh = "ChainLinkFence", scale = { 1, 1 }, collide = true },
	},
}
