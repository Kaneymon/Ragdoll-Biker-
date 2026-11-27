-- The lobby AFK corner (Config/Lobby.afk): players who stay on the rug (on or off their bike) get
-- paid every interval.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Lobby = require(Shared.Config.Lobby)
local Location = require(Shared.Logic.Location)
local Progression = require(Shared.Logic.Progression)
local Format = require(Shared.Util.Format)
local Net = require(Shared.Net)
local DataService = require(script.Parent.DataService)

local AfkService = {}

local TICK = 1
local HEIGHT = 12 -- how far above the rug still counts as on it
local onRugFor = {} -- player -> seconds on the rug since the last payment

local function onRug(player, rug)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or Location.of(player) ~= Location.LOBBY then
		return false
	end
	local offset = root.Position - rug.Position
	return Vector2.new(offset.X, offset.Z).Magnitude <= Lobby.afk.radius and math.abs(offset.Y) < HEIGHT
end

local function pay(player)
	local amount = 0
	DataService.update(player, function(profile)
		amount = Progression.levelReward(Lobby.afk.reward, profile)
		profile.money += amount
	end)
	Net.event("Notify"):FireClient(player, "NOTE_AFK_PAID", Format.money(amount))
end

local function watch(rug)
	while true do
		task.wait(TICK)
		for _, player in Players:GetPlayers() do
			if onRug(player, rug) then
				onRugFor[player] = (onRugFor[player] or 0) + TICK
				if onRugFor[player] >= Lobby.afk.interval then
					onRugFor[player] = 0
					pay(player)
				end
			else
				onRugFor[player] = nil
			end
		end
	end
end

function AfkService.start()
	Players.PlayerRemoving:Connect(function(player)
		onRugFor[player] = nil
	end)
	task.spawn(function()
		watch(workspace:WaitForChild("World"):WaitForChild("Lobby"):WaitForChild("Afk"):WaitForChild("AfkZone"))
	end)
end

return AfkService
