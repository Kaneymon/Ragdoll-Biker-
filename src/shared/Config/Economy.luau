-- Money, levels and saving.
return {
	Level = { base = 150, growth = 1.5 }, -- money earned needed for each next level
	MaxPayoutPerRun = 1e12,
	AutosaveSeconds = 120,
	DataStoreName = "RagdollBiker_v1",
	DoubleMoneyRobux = 10,
	-- Testing mode (Settings > Effects): everything is free and level locks are skipped.
	-- Only offered in Studio, to the place owner and to the listed user ids.
	TestMode = { inStudio = true, owner = true, userIds = {} },
}
