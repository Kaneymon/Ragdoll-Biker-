-- Map hazards (Config/Hazards): touching one (on the bike or ragdolling) blows it up, which throws
-- you like an exploder. It vanishes for you for a while, then comes back.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Hazards = require(Shared.Config.Hazards)
local Exploders = require(Shared.Config.Exploders)
local Progression = require(Shared.Logic.Progression)
local Ragdoll = require(Shared.Logic.Ragdoll)
local State = require(script.Parent.Parent.State)
local BikeController = require(script.Parent.BikeController)
local RagdollController = require(script.Parent.RagdollController)
local Blast = require(script.Parent.Blast)

local HazardController = {}

local hidden = {} -- hazard model -> its parent while blown up

local function riderPart()
	local character = RagdollController.character()
	return if character then Ragdoll.core(character) else BikeController.chassis()
end

local function force(kind)
	return Progression.find(Exploders.list, kind.exploder).force
end

local function blowUp(model, kind, rider)
	local centre = model:GetPivot().Position
	local away = rider.Position - centre
	away = Vector3.new(away.X, 0, away.Z)
	local direction = ((if away.Magnitude > 0.1 then away.Unit else Vector3.zAxis) + Vector3.yAxis * kind.up).Unit
	hidden[model] = model.Parent
	model.Parent = nil
	task.delay(kind.hideSeconds, function()
		model.Parent = hidden[model]
		hidden[model] = nil
	end)
	Blast.launch(centre, force(kind), direction)
end

local function step()
	if State.phase ~= "Ragdoll" and not State.isRiding() then
		return
	end
	local rider = riderPart()
	if not rider then
		return
	end
	for _, model in CollectionService:GetTagged(Hazards.Tag) do
		local kind = Hazards.kinds[model:GetAttribute("Hazard")]
		local radius = if kind then model:GetAttribute("HazardRadius") or kind.radius else 0
		if kind and model.Parent and (model:GetPivot().Position - rider.Position).Magnitude <= radius then
			blowUp(model, kind, rider)
			return
		end
	end
end

function HazardController.start()
	RunService.Heartbeat:Connect(step)
end

return HazardController
