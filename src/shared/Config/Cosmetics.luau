-- Bike paint jobs and trails, bought with in-game money at the Lobby stalls (UI/GarageWindow).
-- Profile slots profile.paints / profile.trails ({ owned = id -> true, equipped = id }).
-- Paints: frame / accent (fork, head tube, rims, sprocket) colours and finish for World/BikeBuilder.
-- Trails: a Trail behind the rear wheel (colour from -> to, width in studs, lifetime in seconds).
-- The first paint is free and owned from the start; "" = no trail.
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

return {
	paints = {
		{ id = "classic", nameKey = "BIKE_CLASSIC", price = 0, frame = rgb(255, 110, 110), accent = rgb(255, 205, 60) },
		{ id = "midnight", nameKey = "BIKE_MIDNIGHT", price = 15000, frame = rgb(30, 34, 52), accent = rgb(90, 200, 255) },
		{ id = "lime", nameKey = "BIKE_LIME", price = 40000, frame = rgb(150, 230, 60), accent = rgb(40, 40, 46) },
		{ id = "chrome", nameKey = "BIKE_CHROME", price = 150000, frame = rgb(210, 215, 222), accent = rgb(255, 120, 40), material = Enum.Material.Metal },
		{ id = "candy", nameKey = "BIKE_CANDY", price = 600000, frame = rgb(255, 120, 200), accent = rgb(130, 230, 255) },
		{ id = "gold", nameKey = "BIKE_GOLD", price = 5000000, frame = rgb(255, 196, 40), accent = rgb(25, 25, 30), material = Enum.Material.Foil },
		{ id = "neon", nameKey = "BIKE_NEON", price = 40000000, frame = rgb(80, 255, 170), accent = rgb(170, 90, 255), material = Enum.Material.Neon },
	},
	trails = {
		{ id = "smoke", nameKey = "TRAIL_SMOKE", price = 10000, from = rgb(235, 235, 240), to = rgb(150, 150, 160), width = 1.2, lifetime = 0.6 },
		{ id = "fire", nameKey = "TRAIL_FIRE", price = 75000, from = rgb(255, 220, 60), to = rgb(255, 60, 20), width = 1.6, lifetime = 0.5, light = true },
		{ id = "ocean", nameKey = "TRAIL_OCEAN", price = 300000, from = rgb(120, 230, 255), to = rgb(20, 80, 220), width = 1.6, lifetime = 0.7, light = true },
		{ id = "toxic", nameKey = "TRAIL_TOXIC", price = 1500000, from = rgb(190, 255, 60), to = rgb(40, 160, 40), width = 2, lifetime = 0.8, light = true },
		{ id = "rainbow", nameKey = "TRAIL_RAINBOW", price = 12000000, rainbow = true, width = 2.4, lifetime = 1, light = true },
	},
}
