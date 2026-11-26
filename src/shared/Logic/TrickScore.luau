-- Trick lookup and multiplier maths (shared so the client HUD and server payout agree).
-- Variety rules: a move/grab worth more after a different trick, a flip worth more after a
-- different flip. Grab ticks are repeats of the same id, so only the first tick gets variety.
local Tricks = require(script.Parent.Parent.Config.Tricks)

local TrickScore = {}

local byId = {}
for _, def in Tricks.list do
	byId[def.id] = def
end

function TrickScore.def(id)
	return byId[id]
end

function TrickScore.newCombo()
	return { lastTrick = nil, lastFlip = nil }
end

-- Bonus for doing `id` next in this combo (updates the combo).
function TrickScore.award(combo, id, trickBonus)
	local def = byId[id]
	if not def then
		return 0
	end
	local upgrade = if def.kind == "grab" then trickBonus * Tricks.GrabUpgradeShare else trickBonus
	local bonus = def.bonus + upgrade
	if def.kind == "rotation" then
		if combo.lastFlip and combo.lastFlip ~= id then
			bonus *= Tricks.FlipVariety
		end
		combo.lastFlip = id
	elseif combo.lastTrick and combo.lastTrick ~= id then
		bonus *= Tricks.TrickVariety
	end
	combo.lastTrick = id
	return bonus
end

function TrickScore.multiplier(trickIds, trickBonus)
	local combo = TrickScore.newCombo()
	local mult = Tricks.StartMultiplier
	for i, id in trickIds do
		if i > Tricks.MaxTricksPerRun then
			break
		end
		mult += TrickScore.award(combo, id, trickBonus)
	end
	return math.floor(mult * 100 + 0.5) / 100
end

return TrickScore
