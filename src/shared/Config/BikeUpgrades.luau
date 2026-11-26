-- Bike shop parts. value(level) = Bike.Base[stat] + perLevel * level
-- cost(level) = baseCost * growth ^ level
return {
	{ id = "handles", nameKey = "UPG_HANDLES", descKey = "UPG_HANDLES_DESC", stat = "trickSpeed", perLevel = 0.1, maxLevel = 50, baseCost = 45, growth = 1.38, format = "mult" },
	{ id = "frame", nameKey = "UPG_FRAME", descKey = "UPG_FRAME_DESC", stat = "spinSpeed", perLevel = 0.08, maxLevel = 50, baseCost = 50, growth = 1.38, format = "mult" },
	{ id = "pedals", nameKey = "UPG_PEDALS", descKey = "UPG_PEDALS_DESC", stat = "jumpHeight", perLevel = 6, maxLevel = 50, baseCost = 80, growth = 1.37, format = "number" },
	{ id = "sprocket", nameKey = "UPG_SPROCKET", descKey = "UPG_SPROCKET_DESC", stat = "cycleSpeed", perLevel = 9, maxLevel = 50, baseCost = 80, growth = 1.37, format = "number" },
	{ id = "wheels", nameKey = "UPG_WHEELS", descKey = "UPG_WHEELS_DESC", stat = "trickBonus", perLevel = 0.02, maxLevel = 50, baseCost = 80, growth = 1.42, format = "plus" },
	{ id = "seat", nameKey = "UPG_SEAT", descKey = "UPG_SEAT_DESC", stat = "bailForce", perLevel = 10, maxLevel = 50, baseCost = 110, growth = 1.38, format = "number" },
}
