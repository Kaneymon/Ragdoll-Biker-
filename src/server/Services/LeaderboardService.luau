-- The lobby leaderboards (Config/Lobby.boards): each board shows the top players for one profile
-- stat. Scores go to an OrderedDataStore per board; when that isn't available (Studio without API
-- access) the board ranks the players in this server instead.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Lobby = require(Shared.Config.Lobby)
local Format = require(Shared.Util.Format)
local DataService = require(script.Parent.DataService)

local LeaderboardService = {}

local STORE_PREFIX = "Leaderboard_"
local FIRST_REFRESH = 5 -- seconds after start, once profiles have loaded
local FORMATTERS = { money = Format.money, number = Format.number }
local names = {} -- userId -> display name cache
local stores = {} -- board id -> OrderedDataStore (nil = use this server's players)

local function nameOf(userId)
	if not names[userId] then
		local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
		names[userId] = if ok then name else "?"
	end
	return names[userId]
end

local function scoreOf(profile, spec)
	return math.floor(profile.stats[spec.stat] or profile[spec.stat] or 0)
end

-- Top entries { name, score } from the global store, or nil if it can't be reached.
local function globalTop(spec)
	local store = stores[spec.id]
	if not store then
		return nil
	end
	for _, player in Players:GetPlayers() do
		local profile = DataService.get(player)
		if profile then
			pcall(store.SetAsync, store, tostring(player.UserId), scoreOf(profile, spec))
		end
	end
	local ok, pages = pcall(store.GetSortedAsync, store, false, Lobby.size)
	if not ok then
		if tostring(pages):find("Studio access") then
			stores[spec.id] = nil -- Studio API access is off: rank this server only, stop asking
		end
		return nil
	end
	local top = {}
	for _, entry in pages:GetCurrentPage() do
		table.insert(top, { name = nameOf(tonumber(entry.key)), score = entry.value })
	end
	return top
end

-- Top entries from the players in this server.
local function serverTop(spec)
	local top = {}
	for _, player in Players:GetPlayers() do
		local profile = DataService.get(player)
		if profile then
			table.insert(top, { name = player.DisplayName, score = scoreOf(profile, spec) })
		end
	end
	table.sort(top, function(a, b)
		return a.score > b.score
	end)
	return top
end

local function show(board, spec, top)
	local rows = board:FindFirstChild("Rows", true)
	for i = 1, Lobby.size do
		local entry = top[i]
		rows["Row" .. i].Text = if entry then string.format("%d. %s  %s", i, entry.name, FORMATTERS[spec.format](entry.score)) else ""
	end
end

function LeaderboardService.start()
	local lobby = workspace:WaitForChild("World"):WaitForChild("Lobby")
	local boards = lobby:WaitForChild("Boards")
	for _, spec in Lobby.boards do
		local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, STORE_PREFIX .. spec.id)
		stores[spec.id] = ok and store or nil
	end
	task.spawn(function()
		task.wait(FIRST_REFRESH)
		while true do
			for _, spec in Lobby.boards do
				local board = boards:FindFirstChild(spec.id)
				if board then
					show(board, spec, globalTop(spec) or serverTop(spec))
				end
			end
			task.wait(Lobby.refresh)
		end
	end)
end

return LeaderboardService
