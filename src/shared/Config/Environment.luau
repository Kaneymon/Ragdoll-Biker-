-- Sky and air. Light haze only, so the other maps stay visible far away.
-- (StreamingEnabled is on in the place so joining is quick; far-off maps show as low-detail meshes.)
return {
	Atmosphere = { Density = 0.06, Offset = 0, Haze = 0.4, Glare = 0 },
	Lighting = { FogEnd = 1e6 },
}
