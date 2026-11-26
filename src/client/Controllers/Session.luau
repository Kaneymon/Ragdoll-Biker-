-- Keeps the client in sync with the server: profile, the character's bike, payout and notices.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local RiderPose = require(Shared.Logic.RiderPose)
local State = require(script.Parent.Parent.State)
local BikeController = require(script.Parent.BikeController)

local Session = {}

local player = Players.LocalPlayer

local function stopAnimations(character)
	local animate = character:FindFirstChild("Animate")
	if animate then
		animate.Enabled = false
	end
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.PlatformStand = true
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in animator:GetPlayingAnimationTracks() do
			track:Stop(0)
		end
	end
end

local function onCharacter(character)
	State.setPhase("Loading")
	State.character = character
	State.resetRun()
	local link = character:WaitForChild("Bike", 30)
	local bike = link and (link.Value or link.Changed:Wait() and link.Value)
	if not bike or State.character ~= character then
		return
	end
	stopAnimations(character)
	RiderPose.apply(character, "Ride")
	BikeController.attach(bike)
end

-- Ask the server to pay out; returns success.
function Session.cashOut()
	local ok, total = Net.func("CashOut"):InvokeServer()
	if ok then
		State.CashedOut:Fire(total)
	end
	return ok
end

function Session.start()
	Net.event("ProfileChanged").OnClientEvent:Connect(State.setProfile)
	Net.event("Notify").OnClientEvent:Connect(function(key, ...)
		State.Notify:Fire(key, ...)
	end)
	Net.event("PayoutReady").OnClientEvent:Connect(function(sheet)
		State.setPhase("Payout")
		State.Payout:Fire(sheet)
	end)
	State.setProfile(Net.func("GetProfile"):InvokeServer())

	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

return Session
