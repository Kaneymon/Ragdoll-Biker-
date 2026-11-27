-- Textured low-poly props modelled in Blender (tools/park_props_blender.py) and kept as Models in
-- ServerStorage.Assets.<folder>. Keys are the prop names used in Config/Maps `props`.
-- mesh = model name; scale = { min, max } random size; upright = stands straight up on slopes
-- (else tilts with the ground); collide = solid for bikes and ragdolls.
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
	},
}
