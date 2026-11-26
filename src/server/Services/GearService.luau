-- Rider gear everyone can see: a belt round the hips holding one bomb per exploder charge.
-- (Boosters are part of the bike, see World/BikeBuilder.)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local GearModels = require(Shared.Config.GearModels)
local Progression = require(Shared.Logic.Progression)
local Build = require(script.Parent.Parent.World.Build)
local GearBuilder = require(script.Parent.Parent.World.GearBuilder)

local GearService = {}

local BELT_NAME = "BombBelt"

local function hips(character)
	return character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
end

local function weldTo(part, root)
	local joint = Instance.new("WeldConstraint")
	joint.Part0 = part
	joint.Part1 = root
	joint.Parent = root
end

-- A belt slot on the hips: out from the torso centre along the slot direction, +Z facing outward.
local function slotCFrame(torso, direction)
	local half = torso.Size / 2 + Vector3.one * GearModels.BombMargin
	local offset = direction * half
	local facing = CFrame.lookAt(offset, offset * 2) -- lookAt points -Z outward ...
	return torso.CFrame * facing * CFrame.Angles(0, math.pi, 0) -- ... so turn round to make +Z outward
end

local function belt(torso, parent)
	local size = torso.Size
	local strap = Build.decor({
		Name = "Strap",
		Size = Vector3.new(size.X + 0.1, GearModels.Belt.thickness, size.Z + 0.1),
		CFrame = torso.CFrame,
		Color = GearModels.Belt.color,
		Anchored = false,
		Massless = true,
		Parent = parent,
	})
	weldTo(torso, strap)
end

-- Puts the belt and its bombs on a fresh character (nothing if no exploder is equipped).
function GearService.dress(character, profile)
	local _, def, charges = Progression.equippedExploder(profile)
	local torso = hips(character)
	if not def or charges <= 0 or not torso or not GearModels.bombs[def.id] then
		return
	end
	local folder = Build.model(BELT_NAME, character)
	belt(torso, folder)
	for i = 1, math.min(charges, #GearModels.BeltSlots) do
		local bomb = Build.model("Bomb" .. i, folder)
		local root = GearBuilder.bomb(def.id, slotCFrame(torso, GearModels.BeltSlots[i]), bomb)
		weldTo(torso, root)
	end
end

-- A bomb went off: the last one on the belt disappears.
function GearService.useBomb(player)
	local folder = player.Character and player.Character:FindFirstChild(BELT_NAME)
	if not folder then
		return
	end
	for i = #GearModels.BeltSlots, 1, -1 do
		local bomb = folder:FindFirstChild("Bomb" .. i)
		if bomb then
			bomb:Destroy()
			return
		end
	end
end

return GearService
