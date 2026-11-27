-- The lobby obby (Config/Lobby.obby): riders who cross the finish line get the reward once per
-- ride, and anyone who falls off the course goes back to the lobby. Crashing and stopping on the
-- course is handled by RunTracker (unpaid rides end in the lobby).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Lobby = require(Shared.Config.Lobby)
local Location = require(Shared.Logic.Location)
local Progression = require(Shared.Logic.Progression)
local Ragdoll = require(Shared.Logic.Ragdoll)
local Format = require(Shared.Util.Format)
local Net = require(Shared.Net)
local DataService = require(script.Parent.DataService)
local LocationService = require(script.Parent.LocationService)

local ObbyService = {}

local CHECK_INTERVAL = 0.25
local AFTER_FINISH = 2.5 -- seconds of glory before going back to the lobby
local finished = {} -- player -> true once they crossed the line this ride

local function reward(player)
	finished[player] = true
	local amount = 0
	DataService.update(player, function(profile)
		amount = Progression.levelReward(Lobby.obby.reward, profile)
		profile.money += amount
	end)
	Net.event("Notify"):FireClient(player, "NOTE_OBBY_DONE", Format.money(amount))
	task.delay(AFTER_FINISH, function()
		if finished[player] and Location.of(player) == Location.OBBY then
			LocationService.travel(player, Location.LOBBY)
		end
	end)
end

local function watch(lobby)
	local finishLine = lobby:WaitForChild("ObbyFinish").Value
	local lowest = lobby:GetAttribute("ObbyLowestY") - Lobby.obby.fallMargin
	while true do
		task.wait(CHECK_INTERVAL)
		for _, player in Players:GetPlayers() do
			local core = player.Character and Ragdoll.core(player.Character)
			if core and Location.of(player) == Location.OBBY then
				if core.Position.Y < lowest then
					LocationService.travel(player, Location.LOBBY)
				elseif not finished[player] and core.Position.X > finishLine.Position.X then
					reward(player)
				end
			end
		end
	end
end

function ObbyService.start()
	LocationService.Moved:Connect(function(player)
		finished[player] = nil
	end)
	Players.PlayerRemoving:Connect(function(player)
		finished[player] = nil
	end)
	task.spawn(watch, workspace:WaitForChild("World"):WaitForChild("Lobby"))
end

return ObbyService
