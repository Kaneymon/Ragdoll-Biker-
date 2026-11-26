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
	return { bones = {}, injuries = {}, injuryOrder = {}, impactMoney = 0, impacts = 0, lucky = {}, luckyMoney = 0, hurt = 0 }
end

function InjuryModel.injury(id)
	return injuryById[id]
end

-- Speed change (studs/s) -> real mph, uncapped (records and lucky hits use this).
function InjuryModel.rawMph(speedChange)
	return speedChange * T.StudsToMph
end

-- Speed change (studs/s) -> damage mph for one hit: capped, then shaped by the difficulty curve.
function InjuryModel.mph(speedChange)
	local mph = math.min(InjuryModel.rawMph(speedChange), T.MaxHitMph)
	local curve = T.Curve
	if mph <= curve.PivotMph then
		return mph * curve.Below
	end
	return curve.PivotMph * curve.Below + (mph - curve.PivotMph) * curve.Above
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

-- Bone damage multiplier: 1 until EasyBones are hurt this run, then it falls off.
function InjuryModel.boneScale(hurt)
	if hurt < T.EasyBones then
		return 1
	end
	return (T.EasyBones / hurt) ^ T.HardPower
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
	local money = T.ImpactValue * severity ^ T.Exponent
	report.impactMoney += money

	local count = math.max(1, math.floor((1 + mph / T.MphPerExtraBone) * (bonesPerHit or 1)))
	local hitBones = pickBones(partName, count, report.impacts * 7919 + #partName * 104729)
	local boneMph = mph * InjuryModel.boneScale(report.hurt)
	for _, bone in hitBones do
		local before = report.bones[bone] or 0
		local after = math.min(T.DustMph, before + boneMph)
		report.bones[bone] = after
		if not InjuryModel.boneStatus(before) and InjuryModel.boneStatus(after) then
			report.hurt += 1
		end
	end

	local injury = pickInjury(region, severity)
	if injury then
		if not report.injuries[injury.id] then
			table.insert(report.injuryOrder, injury.id)
		end
		report.injuries[injury.id] = (report.injuries[injury.id] or 0) + 1
		money += injury.value
	end
	return { severity = severity, mph = mph, injury = injury, bones = hitBones, region = region, money = money }
end

-- A lucky hit pays its money (impact + injury) again (mult - 1) more times.
function InjuryModel.applyLucky(report, lucky, hitMoney)
	local extra = hitMoney * (lucky.mult - 1)
	report.luckyMoney += extra
	report.lucky[lucky.id] = (report.lucky[lucky.id] or 0) + 1
	return extra
end

function InjuryModel.luckyDef(id)
	for _, lucky in Injuries.Lucky.list do
		if lucky.id == id then
			return lucky
		end
	end
	return nil
end

-- Rolls for a lucky hit. rawMph = the hit's real speed change, record = best ever so far,
-- spentEnough = spent SpendShare of cash since the last payout. Returns the lucky def or nil.
function InjuryModel.rollLucky(rawMph, record, spentEnough, rng)
	local L = Injuries.Lucky
	local isRecord = rawMph > record and rawMph >= L.MinRecordMph
	local isNear = not isRecord and spentEnough and record > 0 and rawMph >= record * L.NearRecord
	if not (isRecord or isNear) then
		return nil
	end
	local roll, odds = rng:NextNumber(), 0 -- one roll, each modifier owns its own slice of chance
	for _, lucky in L.list do
		if rawMph >= lucky.minMph then
			odds += if isRecord then lucky.recordChance else lucky.nearChance
			if roll < odds then
				return lucky
			end
		end
	end
	return nil
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
	local bill = math.floor(report.impactMoney + boneMoney + injuryMoney + report.luckyMoney)
	local lucky = {}
	for _, def in Injuries.Lucky.list do
		if report.lucky[def.id] then
			table.insert(lucky, { id = def.id, count = report.lucky[def.id] })
		end
	end
	return {
		bill = bill,
		impactMoney = math.floor(report.impactMoney),
		luckyMoney = math.floor(report.luckyMoney),
		lucky = lucky,
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
