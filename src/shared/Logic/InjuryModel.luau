-- Turns ragdoll hits into bone damage (mph per bone), bone statuses, medical injuries and money.
-- Pure, deterministic logic: the client runs it for the live HUD, the server for the real payout,
-- and both pick the same "random" bones because the picks are seeded by the hit number.
local Config = script.Parent.Parent.Config
local Injuries = require(Config.Injuries)
local Bones = require(Config.Bones)
local T = Injuries.Tuning

local InjuryModel = {}

local injuryById = {}
for _, injury in Injuries.list do
	injuryById[injury.id] = injury
end
local worstInjuryFirst = table.clone(Injuries.list)
table.sort(worstInjuryFirst, function(a, b)
	return a.minSeverity > b.minSeverity
end)
local worstStatusFirst = table.clone(Injuries.BoneStatuses)
table.sort(worstStatusFirst, function(a, b)
	return a.minMph > b.minMph
end)

function InjuryModel.new()
	return { bones = {}, injuries = {}, injuryOrder = {}, impactMoney = 0, impacts = 0 }
end

function InjuryModel.injury(id)
	return injuryById[id]
end

-- Speed change (studs/s) -> mph for one hit, capped.
function InjuryModel.mph(speedChange)
	return math.min(speedChange * T.StudsToMph, T.MaxHitMph)
end

function InjuryModel.severity(mph)
	return (mph - T.MinHitMph) / T.SeverityMph
end

-- Bone status for a cumulative mph, or nil if the bone is fine.
function InjuryModel.boneStatus(mph)
	for _, status in worstStatusFirst do
		if mph >= status.minMph then
			return status
		end
	end
	return nil
end

-- 0..1 darkness of a bone for the skeleton picture.
function InjuryModel.boneDamage(mph)
	return math.clamp(mph / T.DustMph, 0, 1)
end

local function pickInjury(region, severity)
	for _, injury in worstInjuryFirst do
		if severity >= injury.minSeverity and (injury.region == "any" or injury.region == region) then
			return injury
		end
	end
	return nil
end

-- A seeded shuffle of the part's bones; the first `count` take the hit.
local function pickBones(partName, count, seed)
	local pool = table.clone(Bones.byPart[partName])
	local rng = Random.new(seed)
	local chosen = {}
	for i = 1, math.min(count, #pool) do
		local j = rng:NextInteger(i, #pool)
		pool[i], pool[j] = pool[j], pool[i]
		table.insert(chosen, pool[i])
	end
	return chosen
end

-- bonesPerHit scales how many bones each hit reaches (Boots upgrade).
-- Returns what happened, or nil if the hit was too soft or the part is unknown.
function InjuryModel.applyImpact(report, partName, speedChange, bonesPerHit)
	local region = Bones.regions[partName]
	if not region or report.impacts >= T.MaxImpacts then
		return nil
	end
	local mph = InjuryModel.mph(speedChange)
	local severity = InjuryModel.severity(mph)
	if severity <= 0 then
		return nil
	end
	report.impacts += 1
	report.impactMoney += T.ImpactValue * severity ^ T.Exponent

	local count = math.max(1, math.floor((1 + mph / T.MphPerExtraBone) * (bonesPerHit or 1)))
	local hitBones = pickBones(partName, count, report.impacts * 7919 + #partName * 104729)
	for _, bone in hitBones do
		report.bones[bone] = math.min(T.DustMph, (report.bones[bone] or 0) + mph)
	end

	local injury = pickInjury(region, severity)
	if injury then
		if not report.injuries[injury.id] then
			table.insert(report.injuryOrder, injury.id)
		end
		report.injuries[injury.id] = (report.injuries[injury.id] or 0) + 1
	end
	return { severity = severity, mph = mph, injury = injury, bones = hitBones, region = region }
end

-- Totals for the payout sheet.
function InjuryModel.summary(report, multiplier, mapMult)
	local statusCounts, hurt, boneMoney = {}, 0, 0
	for _, mph in report.bones do
		local status = InjuryModel.boneStatus(mph)
		if status then
			hurt += 1
			boneMoney += status.value
			statusCounts[status.id] = (statusCounts[status.id] or 0) + 1
		end
	end
	local statuses = {}
	for _, status in worstStatusFirst do
		if statusCounts[status.id] then
			table.insert(statuses, { id = status.id, count = statusCounts[status.id] })
		end
	end
	local injuryMoney, injuryCount = 0, 0
	for id, count in report.injuries do
		injuryMoney += injuryById[id].value * count
		injuryCount += count
	end
	local bill = math.floor(report.impactMoney + boneMoney + injuryMoney)
	return {
		bill = bill,
		total = math.floor(bill * multiplier * mapMult),
		bonesHurt = hurt,
		statuses = statuses,
		injuryCount = injuryCount,
		multiplier = multiplier,
		mapMult = mapMult,
	}
end

-- Lookup for a status id (payout sheet labels).
function InjuryModel.status(id)
	for _, status in Injuries.BoneStatuses do
		if status.id == id then
			return status
		end
	end
	return nil
end

return InjuryModel
