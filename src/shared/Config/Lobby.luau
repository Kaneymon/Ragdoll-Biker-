-- The Lobby: a round floating deck in the sky behind the maps, looking down the ramps (+Z), ringed
-- with mega ramp barriers. Players start here, walk around, shop, check the leaderboards, idle in
-- the AFK corner or ride the obby; PLAY takes them to their ramp. Built by World/LobbyBuilder.
-- Angles are degrees around the deck: 0 = +X (east, where the obby leaves), 90 = +Z (towards the
-- ramps). Prop models are in ServerStorage.Assets.Lobby (tools/lobby_props_blender.py).
return {
	centre = Vector3.new(3000, 3000, -1500), -- top of the deck
	radius = 150,
	thickness = 10,
	rim = { color = Color3.fromRGB(70, 74, 82), material = Enum.Material.DiamondPlate, height = 1.2, width = 3 },
	underside = { depth = 70, color = Color3.fromRGB(88, 92, 100), material = Enum.Material.Metal },
	spawnRadius = 24, -- players appear within this of the centre, facing the ramps
	sign = { angle = 270, distance = 125, size = Vector2.new(60, 16) }, -- the big title board

	-- shops: what the prompt opens. window = Hud window id, tab = tab to open on
	stallDistance = 100,
	stallScale = 1.5,
	stallSign = { y = 11, z = -3.9, size = Vector2.new(11, 2.1) }, -- where the name goes on the ShopStall model
	stalls = {
		{ angle = 215, nameKey = "SHOP_BIKES", window = "garage", tab = "paints" },
		{ angle = 242, nameKey = "SHOP_TRAILS", window = "garage", tab = "trails" },
		{ angle = 298, nameKey = "SHOP_BIKE_UPGRADES", window = "upgrades", tab = "bike" },
		{ angle = 325, nameKey = "SHOP_BIKER_UPGRADES", window = "upgrades", tab = "biker" },
		{ angle = 180, nameKey = "SHOP_STORE", window = "store", distance = 108 },
	},

	-- leaderboards: profile field shown, top `size` players
	boardDistance = 112,
	boardWidth = 26, -- studs (the model is scaled up from its 16 stud screen)
	boardText = { y = 9, z = -0.06, size = Vector2.new(16, 10) }, -- the screen on the BoardFrame model
	refresh = 60, -- seconds between leaderboard updates
	size = 10,
	boards = {
		{ angle = 125, id = "earned", titleKey = "BOARD_EARNED", stat = "totalEarned", format = "money" },
		{ angle = 55, id = "bones", titleKey = "BOARD_BONES", stat = "totalBones", format = "number" },
	},

	-- AFK corner: stand on the rug to earn money every `interval` seconds
	afk = { angle = 150, distance = 82, radius = 22, interval = 60, reward = { base = 250, perLevel = 120 }, beanbags = 6 },

	-- the obby: a wooden ramp course running out from the east edge (+X), dropping as it goes.
	-- Pieces in order: slope = sloped deck (length, angle), kicker = launch curve, gap = air
	-- (length, drop below the kicker lip), flat = level deck (finish = the finish line is on it).
	-- Riders can't boost, bomb or bail; falling off or stopping after a crash sends them back to
	-- the lobby. Reaching the end pays `reward`.
	obby = {
		width = 30,
		thickness = 4,
		start = 40, -- flat start deck at deck height, starting at the edge
		fallMargin = 150, -- studs below the course's lowest point that count as falling off
		reward = { base = 1500, perLevel = 500 },
		pieces = {
			{ kind = "slope", length = 140, angle = 22 },
			{ kind = "kicker", radius = 30, endAngle = 28 },
			{ kind = "gap", length = 40, drop = 30 },
			{ kind = "slope", length = 220, angle = 20 },
			{ kind = "kicker", radius = 34, endAngle = 32 },
			{ kind = "gap", length = 60, drop = 40 },
			{ kind = "slope", length = 240, angle = 18 },
			{ kind = "kicker", radius = 38, endAngle = 35 },
			{ kind = "gap", length = 80, drop = 50 },
			{ kind = "slope", length = 260, angle = 16 },
			{ kind = "flat", length = 80, finish = true },
		},
	},
}
