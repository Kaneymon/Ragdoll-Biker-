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

-- Bonus for doing `id` next in this combo (updates the combo). ragdoll = posed while limp.
function TrickScore.award(combo, id, trickBonus, ragdoll)
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
	return if ragdoll then bonus * Tricks.RagdollShare else bonus
end

-- Riding tricks first, then poses held while ragdolling (same combo, RagdollShare of the bonus).
function TrickScore.multiplier(trickIds, trickBonus, ragdollIds)
	local combo = TrickScore.newCombo()
	local mult = Tricks.StartMultiplier
	local count = 0
	for _, list in { trickIds, ragdollIds or {} } do
		local ragdoll = list == ragdollIds
		for _, id in list do
			count += 1
			if count > Tricks.MaxTricksPerRun then
				break
			end
			mult += TrickScore.award(combo, id, trickBonus, ragdoll)
		end
	end
	return math.floor(mult * 100 + 0.5) / 100
end

return TrickScore
