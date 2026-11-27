-- Robux catalogue. Real purchases are not wired yet (fill in gamePassId / productId once products
-- exist); in test mode every item is free and granted straight away (Services/MonetizationService).
-- What an item gives:
--   pass = owned forever, can be switched on/off in Settings; effects apply while it's on
--   duration = seconds a power-up lasts (buying again adds time); effects apply while it runs
--   money = cash added to the wallet
-- effects (combined in Logic/Progression.effects):
--   payoutMult = payouts x this, endlessBones = bones never get harder to break,
--   gravityControl = the gravity slider (GravityRange), gravityMult = gravity x this,
--   speedMult = bike pedal / top speed x this, trickSpeedMult = tricks go x this fast,
--   endlessBoost = boost fuel never runs out, freeShopping = in-game money purchases are free
return {
	GravityRange = { min = 0.25, max = 10 }, -- Gravity Controller slider (x normal gravity)
	DoublePayoutId = "double_payout", -- the 2x MONEY button on the payout sheet (price: Economy.DoubleMoneyRobux)
	tabs = {
		{
			id = "passes",
			nameKey = "TAB_PASSES",
			items = {
				{ id = "pass_2x_money", nameKey = "PASS_2X_MONEY", robux = 299, gamePassId = 0, pass = true, effects = { payoutMult = 2 } },
				{ id = "pass_infinite_bones", nameKey = "PASS_INF_BONES", robux = 199, gamePassId = 0, pass = true, effects = { endlessBones = true } },
				{ id = "pass_gravity_control", nameKey = "PASS_GRAVITY_CTRL", robux = 149, gamePassId = 0, pass = true, effects = { gravityControl = true } },
			},
		},
		{
			id = "powerups",
			nameKey = "TAB_POWERUPS",
			items = {
				{ id = "pw_gravity2", nameKey = "PW_GRAVITY2", robux = 25, productId = 0, duration = 600, effects = { gravityMult = 2 } },
				{ id = "pw_gravity5", nameKey = "PW_GRAVITY5", robux = 49, productId = 0, duration = 600, effects = { gravityMult = 5 } },
				{ id = "pw_speed3", nameKey = "PW_SPEED3", robux = 39, productId = 0, duration = 600, effects = { speedMult = 3 } },
				{ id = "pw_trick10", nameKey = "PW_TRICK10", robux = 39, productId = 0, duration = 600, effects = { trickSpeedMult = 10 } },
				{ id = "pw_fuel", nameKey = "PW_FUEL", robux = 29, productId = 0, duration = 600, effects = { endlessBoost = true } },
			},
		},
		{
			id = "money",
			nameKey = "TAB_MONEY",
			items = {
				{ id = "cash_100k", nameKey = "CASH_100K", robux = 49, productId = 0, money = 100000 },
				{ id = "cash_250k", nameKey = "CASH_250K", robux = 99, productId = 0, money = 250000 },
				{ id = "cash_500k", nameKey = "CASH_500K", robux = 179, productId = 0, money = 500000 },
				{ id = "cash_1m", nameKey = "CASH_1M", robux = 299, productId = 0, money = 1000000 },
				{ id = "cash_10m", nameKey = "CASH_10M", robux = 1999, productId = 0, money = 10000000 },
				{ id = "cash_inf", nameKey = "CASH_INF", robux = 4999, gamePassId = 0, pass = true, effects = { freeShopping = true } },
			},
		},
	},
}
