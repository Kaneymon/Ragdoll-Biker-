-- Shape of saved player data. Missing fields in old saves are filled in from here.
return {
	version = 1,
	money = 0,
	totalEarned = 0,
	rampLevel = 0,
	bike = { handles = 0, frame = 0, pedals = 0, sprocket = 0, wheels = 0, seat = 0 },
	boosters = { owned = {}, equipped = "" }, -- owned: id -> level
	exploders = { owned = {}, charges = {}, equipped = "" }, -- charges: id -> bombs per run
	biker = { helmet = 0, kneepads = 0, bodyarmour = 0, boots = 0 },
	maps = { owned = { hill_park = true }, selected = "hill_park" },
	paints = { owned = { classic = true }, equipped = "classic" }, -- bike paint jobs (Config/Cosmetics)
	trails = { owned = {}, equipped = "" }, -- bike trails (Config/Cosmetics), "" = none
	passes = {}, -- Robux gamepasses (Config/Store): id -> switched on
	powerups = {}, -- Robux power-ups: id -> os.time() when it runs out
	settings = { sfx = true, vfx = true, injuryFx = true, testMode = false, gravity = 1 }, -- gravity = Gravity Controller slider
	stats = {
		totalRuns = 0,
		totalDistance = 0,
		totalBones = 0,
		totalEarned = 0,
		highestSpeed = 0,
		furthestFall = 0,
		recordImpact = 0, -- hardest single hit ever, real mph (lucky hits)
		recordBones = 0,
		recordInjuries = 0,
		totalMultiplier = 0,
		bestMultiplier = 0,
		totalTricks = 0,
		bestTricks = 0,
	},
}
