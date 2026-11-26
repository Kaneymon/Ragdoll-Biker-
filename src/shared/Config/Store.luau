-- Robux catalogue. Not wired for the MVP: fill in gamePassId / productId once products exist.
return {
	tabs = {
		{
			id = "passes",
			nameKey = "TAB_PASSES",
			items = {
				{ id = "pass_2x_money", nameKey = "PASS_2X_MONEY", robux = 299, gamePassId = 0 },
				{ id = "pass_infinite_bones", nameKey = "PASS_INF_BONES", robux = 199, gamePassId = 0 },
				{ id = "pass_double_gravity", nameKey = "PASS_2X_GRAVITY", robux = 149, gamePassId = 0 },
			},
		},
		{
			id = "powerups",
			nameKey = "TAB_POWERUPS",
			items = {
				{ id = "pw_gravity2", nameKey = "PW_GRAVITY2", robux = 25, productId = 0 },
				{ id = "pw_gravity5", nameKey = "PW_GRAVITY5", robux = 49, productId = 0 },
				{ id = "pw_speed3", nameKey = "PW_SPEED3", robux = 39, productId = 0 },
				{ id = "pw_trick10", nameKey = "PW_TRICK10", robux = 39, productId = 0 },
				{ id = "pw_fuel", nameKey = "PW_FUEL", robux = 29, productId = 0 },
			},
		},
		{
			id = "money",
			nameKey = "TAB_MONEY",
			items = {
				{ id = "cash_100k", nameKey = "CASH_100K", robux = 49, productId = 0 },
				{ id = "cash_250k", nameKey = "CASH_250K", robux = 99, productId = 0 },
				{ id = "cash_500k", nameKey = "CASH_500K", robux = 179, productId = 0 },
				{ id = "cash_1m", nameKey = "CASH_1M", robux = 299, productId = 0 },
				{ id = "cash_10m", nameKey = "CASH_10M", robux = 1999, productId = 0 },
				{ id = "cash_inf", nameKey = "CASH_INF", robux = 4999, gamePassId = 0 },
			},
		},
	},
}
