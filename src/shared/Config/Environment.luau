-- Sky and air. Light haze only, so the other maps stay visible far away.
-- (StreamingEnabled is off in the place for the same reason: every map and rider is always loaded.)
return {
	Atmosphere = { Density = 0.06, Offset = 0, Haze = 0.4, Glare = 0 },
	Lighting = { FogEnd = 1e6 },
}
