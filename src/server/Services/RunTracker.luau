-- One run per life: Riding -> Ragdoll -> Payout -> cash out (respawn).
-- The server re-scores tricks and impacts itself; the client only reports what happened.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Bike = require(Shared.Config.Bike)
local Economy = require(Shared.Config.Economy)
local Tricks = require(Shared.Config.Tricks)
local InjuryModel = require(Shared.Logic.InjuryModel)
local TrickScore = require(Shared.Logic.TrickScore)
local Progression = require(Shared.Logic.Progression)
local Ragdoll = require(Shared.Logic.Ragdoll)
local Net = require(Shared.Net)
local DataService = require(script.Parent.DataService)
local GearService = require(script.Parent.GearService)
local BikeService = require(script.Parent.BikeService)
local ShopService = require(script.Parent.ShopService)

local RunTracker = {}

local MAX_IMPACTS_PER_BATCH = 40
local SERVER_REST_TIMEOUT = Bike.Rest.MaxTime + 10
local runs = {} -- player -> run
local luckRng = Random.new()

local function corePosition(player)
	local core = player.Character and Ragdoll.core(player.Character)
	return core and core.Position
end

local function newRun(player)
	runs[player] = {
		phase = "Riding",
		report = InjuryModel.new(),
		tricks = {},
		ragdollTricks = {},
		maxSpeed = 0,
		startPos = corePosition(player),
	}
end

-- kind = only accept tricks of this kind (ragdoll poses are grabs).
local function validTricks(list, kind)
	local tricks = {}
	if type(list) ~= "table" then
		return tricks
	end
	for i, id in list do
		if i > Tricks.MaxTricksPerRun then
			break
		end
		local def = type(id) == "string" and TrickScore.def(id)
		if def and (kind == nil or def.kind == kind) then
			table.insert(tricks, id)
		end
	end
	return tricks
end

local function buildSheet(player, run)
	local profile = DataService.get(player)
	local stats = Progression.stats(profile, os.time())
	local map = Progression.map(profile.maps.selected)
	local multiplier = TrickScore.multiplier(run.tricks, stats.trickBonus, run.ragdollTricks)
	local summary = InjuryModel.summary(run.report, multiplier, map.payoutMult)
	local finalPos = corePosition(player) or run.bailPos
	local injuries = {}
	for _, id in run.report.injuryOrder do
		table.insert(injuries, { id = id, count = run.report.injuries[id] })
	end
	return {
		bones = run.report.bones,
		injuries = injuries,
		bill = summary.bill,
		impactMoney = summary.impactMoney,
		luckyMoney = summary.luckyMoney,
		lucky = summary.lucky,
		multiplier = multiplier,
		mapMult = map.payoutMult,
		moneyMult = stats.payoutMult, -- 2x Money pass (and the 2x MONEY button, see doublePayout)
		total = math.min(summary.total, Economy.MaxPayoutPerRun) * stats.payoutMult,
		bonesHurt = summary.bonesHurt,
		statuses = summary.statuses,
		injuryCount = summary.injuryCount,
		tricks = #run.tricks + #run.ragdollTricks,
		maxSpeed = run.maxSpeed,
		distance = if finalPos and run.bailPos then (finalPos - run.bailPos).Magnitude else 0,
		fall = if finalPos and run.startPos then math.max(0, run.startPos.Y - finalPos.Y) else 0,
	}
end

local function finish(player, ragdollTricks)
	local run = runs[player]
	if not run or run.phase ~= "Ragdoll" then
		return
	end
	run.ragdollTricks = validTricks(ragdollTricks, "grab")
	run.phase = "Payout"
	run.sheet = buildSheet(player, run)
	Net.event("PayoutReady"):FireClient(player, run.sheet)
end

local function onBail(player, trickIds, maxSpeed)
	local run = runs[player]
	if not run or run.phase ~= "Riding" then
		return
	end
	run.phase = "Ragdoll"
	run.tricks = validTricks(trickIds)
	run.maxSpeed = if type(maxSpeed) == "number" then math.clamp(maxSpeed, 0, Bike.MaxSpeed * 2) else 0
	run.bailPos = corePosition(player)
	local stats = Progression.stats(DataService.get(player), os.time())
	run.bonesPerHit = stats.bonesPerHit
	run.endlessBones = stats.endlessBones
	run.spentEnough = ShopService.spentEnough(player)
	BikeService.detach(player)
	task.delay(SERVER_REST_TIMEOUT, function()
		if runs[player] == run then
			finish(player)
		end
	end)
end

-- Lucky hits: rolled on record (or near record after big spending) hits; beats the record too.
local function rollLucky(player, run, speed, result)
	local stats = DataService.get(player).stats
	local rawMph = InjuryModel.rawMph(speed)
	local lucky = InjuryModel.rollLucky(rawMph, stats.recordImpact, run.spentEnough, luckRng)
	stats.recordImpact = math.max(stats.recordImpact, math.floor(rawMph))
	if lucky then
		local extra, nameKey = InjuryModel.applyLucky(run.report, lucky, result.money, luckRng)
		Net.event("LuckyHit"):FireClient(player, lucky.id, nameKey, InjuryModel.money(extra))
	end
end

local function onImpacts(player, batch)
	local run = runs[player]
	if not run or run.phase ~= "Ragdoll" or type(batch) ~= "table" then
		return
	end
	for i, impact in batch do
		if i > MAX_IMPACTS_PER_BATCH then
			break
		end
		if type(impact) == "table" and type(impact.part) == "string" and type(impact.speed) == "number" and impact.speed == impact.speed then
			local speed = math.clamp(impact.speed, 0, Bike.MaxSpeed * 4)
			local result = InjuryModel.applyImpact(run.report, impact.part, speed, run.bonesPerHit, run.endlessBones)
			if result and impact.kind == nil then -- only real hits set records and roll lucky hits
				rollLucky(player, run, speed, result)
			end
		end
	end
end

local function recordStats(profile, sheet)
	local s = profile.stats
	s.totalRuns += 1
	s.totalDistance += math.floor(sheet.distance)
	s.totalBones += sheet.bonesHurt
	s.totalEarned += sheet.total
	s.highestSpeed = math.max(s.highestSpeed, math.floor(sheet.maxSpeed))
	s.furthestFall = math.max(s.furthestFall, math.floor(sheet.fall))
	s.recordBones = math.max(s.recordBones, sheet.bonesHurt)
	s.recordInjuries = math.max(s.recordInjuries, sheet.injuryCount)
	s.totalMultiplier += sheet.multiplier - 1
	s.bestMultiplier = math.max(s.bestMultiplier, sheet.multiplier)
	s.totalTricks += sheet.tricks
	s.bestTricks = math.max(s.bestTricks, sheet.tricks)
end

local function onCashOut(player)
	local run = runs[player]
	if not run or run.phase ~= "Payout" then
		return false
	end
	run.phase = "Done"
	local sheet = run.sheet
	local levelBefore, levelAfter
	DataService.update(player, function(profile)
		levelBefore = Progression.level(profile.totalEarned)
		profile.money += sheet.total
		profile.totalEarned += sheet.total
		levelAfter = Progression.level(profile.totalEarned)
		recordStats(profile, sheet)
	end)
	ShopService.resetSpending(player)
	if levelAfter and levelAfter > levelBefore then
		Net.event("Notify"):FireClient(player, "NOTE_LEVEL_UP", levelAfter)
	end
	task.defer(player.LoadCharacter, player)
	return true, sheet.total
end

-- The 2x MONEY button: doubles the payout on the sheet the player is looking at (once per run).
function RunTracker.doublePayout(player)
	local run = runs[player]
	if not run or run.phase ~= "Payout" or run.sheet.doubled then
		return false
	end
	run.sheet.doubled = true
	run.sheet.total *= 2
	run.sheet.moneyMult *= 2
	Net.event("PayoutReady"):FireClient(player, run.sheet)
	return true
end

function RunTracker.start()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			newRun(player)
		end)
	end)
	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function()
			newRun(player)
		end)
		if player.Character then
			newRun(player)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		runs[player] = nil
	end)

	-- New ramp height or gear: respawn on a fresh bike (menus are only open before a ride starts).
	ShopService.LoadoutChanged:Connect(function(player)
		local run = runs[player]
		if run and run.phase == "Riding" then
			player:LoadCharacter()
		end
	end)

	Net.event("Bail").OnServerEvent:Connect(onBail)
	Net.event("Impacts").OnServerEvent:Connect(onImpacts)
	Net.event("RunFinished").OnServerEvent:Connect(finish)
	Net.event("BombUsed").OnServerEvent:Connect(function(player)
		local run = runs[player]
		if run and (run.phase == "Riding" or run.phase == "Ragdoll") then
			GearService.useBomb(player)
		end
	end)
	Net.func("CashOut").OnServerInvoke = onCashOut
end

return RunTracker
