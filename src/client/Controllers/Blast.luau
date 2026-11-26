-- Throws the rider with an explosion: off the bike if riding, harder if already ragdolling.
-- Used by exploders (GearController) and map hazards (HazardController).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ragdoll = require(Shared.Logic.Ragdoll)
local State = require(script.Parent.Parent.State)
local RagdollController = require(script.Parent.RagdollController)
local DamageDetector = require(script.Parent.DamageDetector)

local Blast = {}

-- origin = where it went off (effects), force = studs/s added along direction (a unit vector).
function Blast.launch(origin: Vector3, force: number, direction: Vector3)
	if State.phase ~= "Ragdoll" and not State.isRiding() then
		return
	end
	State.Exploded:Fire(origin, force)
	if State.phase == "Ragdoll" then
		Ragdoll.addVelocity(RagdollController.character(), direction * force)
		DamageDetector.reset()
	else
		RagdollController.bail("explode", direction * force)
	end
end

return Blast
