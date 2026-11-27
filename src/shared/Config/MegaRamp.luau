-- How every map's mega ramp is built: wooden chipboard panels (MaterialService.Chipboard, baked by
-- tools/ramp_props_blender.py) with metal barriers along the sides. Shapes and sizes live in
-- Config/Maps; this is only the look.
return {
	surface = { material = Enum.Material.Wood, variant = "Chipboard", color = Color3.fromRGB(255, 248, 236) },
	barrier = { folder = "Ramp", mesh = "RampBarrier", length = 16, inset = 0.5 }, -- straight runs
	kickerSide = { material = Enum.Material.DiamondPlate, color = Color3.fromRGB(165, 170, 178), height = 3.6, thickness = 0.5 },
}
