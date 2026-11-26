-- Money, levels, saving and post-run offers.
return {
	Level = { base = 150, growth = 1.5 }, -- money earned needed for each next level
	MaxPayoutPerRun = 1e12,
	AutosaveSeconds = 120,
	DataStoreName = "RagdollBiker_v1",
	Offer = { minDiscount = 5, maxDiscount = 25, megaDiscount = 80, megaChance = 1 / 250 },
	DoubleMoneyRobux = 10,
}
