-- Turns ragdoll impacts into bone damage, injuries and money.
-- Pure logic: the client runs it for the live HUD, the server runs it for the real payout.
local Injuries = require(script.Parent.Parent.Config.Injuries)
local T = Injuries.Tuning

local InjuryModel = {}

local byId = {}
local worstFirst = table.clone(Injuries.list)
for _, injury in Injuries.list do
	byId[injury.id] = injury
end
table.sort(worstFirst, function(a, b)
	return a.minSeverity > b.minSeverity
end)

function InjuryModel.new()
	return { bones = {}, injuries = {}, injuryOrder = {}, impactMoney = 0, impacts = 0 }
end

function InjuryModel.injury(id)
	return byId[id]
end

function InjuryModel.severity(speedChange)
	return (math.min(speedChange, T.MaxImpactSpeed) - T.MinImpact) / T.SeverityScale
end

function InjuryModel.pickInjury(region, severity)
	for _, injury in worstFirst do
		if severity >= injury.minSeverity and (injury.region == "any" or injury.region == region) then
			return injury
		end
	end
	return nil
end

-- Returns what happened, or nil if the hit was too soft or the part is unknown.
function InjuryModel.applyImpact(report, partName, speedChange)
	local part = Injuries.BodyParts[partName]
	if not part or report.impacts >= T.MaxImpacts then
		return nil
	end
	local severity = InjuryModel.severity(speedChange)
	if severity <= 0 then
		return nil
	end
	report.impacts += 1
	report.impactMoney += T.ImpactValue * severity ^ T.Exponent
	for _, bone in part.bones do
		report.bones[bone] = math.min(1, (report.bones[bone] or 0) + severity * T.BoneDamage)
	end
	local injury = InjuryModel.pickInjury(part.region, severity)
	if injury then
		if not report.injuries[injury.id] then
			table.insert(report.injuryOrder, injury.id)
		end
		report.injuries[injury.id] = (report.injuries[injury.id] or 0) + 1
	end
	return { severity = severity, injury = injury, bones = part.bones, region = part.region }
end

function InjuryModel.summary(report, multiplier, mapMult)
	local boneSum, broken = 0, 0
	for _, damage in report.bones do
		boneSum += damage
		if damage >= T.HurtBone then
			broken += 1
		end
	end
	local injuryMoney, injuryCount = 0, 0
	for id, count in report.injuries do
		injuryMoney += byId[id].value * count
		injuryCount += count
	end
	local bill = math.floor(report.impactMoney + boneSum * T.BoneValue + injuryMoney)
	return {
		bill = bill,
		total = math.floor(bill * multiplier * mapMult),
		broken = broken,
		injuryCount = injuryCount,
		multiplier = multiplier,
		mapMult = mapMult,
	}
end

return InjuryModel
