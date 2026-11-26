-- Hold the boost button for a short push. Upgrades add thrust and fuel.
-- thrust = studs/s^2, fuel = seconds. upgrade cost = price * upgradeCostScale * upgradeGrowth^level
return {
	upgradeCostScale = 0.25,
	upgradeGrowth = 1.8,
	thrustPerLevel = 0.1,
	fuelPerLevel = 0.08,
	maxLevel = 10,
	list = {
		{ id = "desk_fan", nameKey = "BOOST_FAN", price = 1000, thrust = 45, fuel = 2, color = Color3.fromRGB(200, 220, 255) },
		{ id = "propeller", nameKey = "BOOST_PROP", price = 10000, thrust = 75, fuel = 2.5, color = Color3.fromRGB(255, 205, 60) },
		{ id = "fireworks", nameKey = "BOOST_FIREWORKS", price = 60000, thrust = 120, fuel = 1.8, color = Color3.fromRGB(255, 110, 110) },
		{ id = "tiny_jet", nameKey = "BOOST_JET", price = 400000, thrust = 165, fuel = 3, color = Color3.fromRGB(150, 110, 255) },
		{ id = "turbine", nameKey = "BOOST_TURBINE", price = 3000000, thrust = 230, fuel = 3.5, color = Color3.fromRGB(120, 130, 150) },
		{ id = "rocket", nameKey = "BOOST_ROCKET", price = 25000000, thrust = 340, fuel = 4, color = Color3.fromRGB(255, 150, 50) },
	},
}
