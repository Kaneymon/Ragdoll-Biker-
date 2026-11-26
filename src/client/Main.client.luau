-- Client entry point: start controllers, effects and UI in order.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Localize = require(Shared.Services.Localize)

local Client = script.Parent
local Controllers = Client.Controllers
local UI = Client.UI

Localize.init()

for _, name in { "Input", "BikeController", "TrickController", "RagdollController", "DamageDetector", "GearController", "HazardController", "CameraController" } do
	require(Controllers[name]).start()
end
require(Client.Feedback.Feedback).start()

local windows = {
	upgrades = require(UI.UpgradesWindow).create(),
	store = require(UI.StoreWindow).create(),
	settings = require(UI.SettingsWindow).create(),
}
require(UI.Hud).create(windows)
require(UI.PayoutSheet).create()
require(UI.OfferPopup).create()

-- Last: starts receiving the profile and the character's bike.
require(Controllers.Session).start()
