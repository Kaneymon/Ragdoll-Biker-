-- Player profiles: load, reconcile with the template, save, and push snapshots to clients.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Template = require(Shared.Config.ProfileTemplate)
local Economy = require(Shared.Config.Economy)
local Net = require(Shared.Net)
local Signal = require(Shared.Util.Signal)

local DataService = { Loaded = Signal.new() }

local profiles = {} -- player -> profile
local canSave = {} -- player -> bool (false when the load failed, so we never overwrite real data)
local store = nil

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value do
		copy[k] = deepCopy(v)
	end
	return copy
end

local function reconcile(data, template)
	for key, value in template do
		if data[key] == nil then
			data[key] = deepCopy(value)
		elseif type(value) == "table" and type(data[key]) == "table" then
			reconcile(data[key], value)
		end
	end
	return data
end

local function key(player)
	return "u_" .. player.UserId
end

local function load(player)
	if not store then
		return deepCopy(Template), false
	end
	for attempt = 1, 3 do
		local ok, result = pcall(store.GetAsync, store, key(player))
		if ok then
			return reconcile(result or {}, Template), true
		end
		warn("[DataService] load failed:", result)
		if tostring(result):find("Studio access") then
			break -- not a temporary error: Studio API access is off for this place
		end
		task.wait(attempt)
	end
	return deepCopy(Template), false
end

local function save(player)
	local profile = profiles[player]
	if not (store and profile and canSave[player]) then
		return
	end
	local ok, err = pcall(store.SetAsync, store, key(player), profile)
	if not ok then
		warn("[DataService] save failed:", err)
	end
end

function DataService.get(player)
	return profiles[player]
end

function DataService.push(player)
	local profile = profiles[player]
	if profile then
		Net.event("ProfileChanged"):FireClient(player, profile)
	end
end

-- Change a profile and send the new snapshot to the player.
function DataService.update(player, change)
	local profile = profiles[player]
	if profile then
		change(profile)
		DataService.push(player)
	end
end

function DataService.waitFor(player)
	while player.Parent and not profiles[player] do
		task.wait()
	end
	return profiles[player]
end

local function onPlayerAdded(player)
	local profile, ok = load(player)
	if not player.Parent then
		return
	end
	profiles[player] = profile
	canSave[player] = ok
	DataService.Loaded:Fire(player, profile)
	DataService.push(player)
end

local function onPlayerRemoving(player)
	save(player)
	profiles[player] = nil
	canSave[player] = nil
end

function DataService.start()
	local ok, result = pcall(DataStoreService.GetDataStore, DataStoreService, Economy.DataStoreName)
	store = ok and result or nil
	if not store then
		warn("[DataService] DataStore unavailable, progress will not save:", result)
	end

	Net.func("GetProfile").OnServerInvoke = DataService.waitFor
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			save(player)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(Economy.AutosaveSeconds)
			for _, player in Players:GetPlayers() do
				task.spawn(save, player)
			end
		end
	end)
end

return DataService
