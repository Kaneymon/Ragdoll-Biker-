-- Trick lookup and multiplier maths (shared so the client HUD and server payout agree).
local Tricks = require(script.Parent.Parent.Config.Tricks)

local TrickScore = {}

local byId = {}
for _, def in Tricks.list do
	byId[def.id] = def
end

function TrickScore.def(id)
	return byId[id]
end

function TrickScore.bonus(id, trickBonus)
	local def = byId[id]
	return def and (def.bonus + trickBonus) or 0
end

function TrickScore.multiplier(trickIds, trickBonus)
	local mult = Tricks.StartMultiplier
	for i, id in trickIds do
		if i > Tricks.MaxTricksPerRun then
			break
		end
		mult += TrickScore.bonus(id, trickBonus)
	end
	return math.floor(mult * 100 + 0.5) / 100
end

return TrickScore
