-- Builds booster and bomb models from the shape lists in Config/GearModels.
-- Every piece is welded to an invisible root, massless and non-colliding (pure looks).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local GearModels = require(Shared.Config.GearModels)
local Build = require(script.Parent.Build)

local GearBuilder = {}

local SHAPES = { Block = Enum.PartType.Block, Ball = Enum.PartType.Ball, Cylinder = Enum.PartType.Cylinder }
local STRUT_RADIUS = 0.12

local function decor(props, parent)
	props.Anchored = false
	props.Massless = true
	props.Parent = parent
	return Build.decor(props)
end

local function weld(root, part)
	local joint = Instance.new("WeldConstraint")
	joint.Part0 = root
	joint.Part1 = part
	joint.Parent = part
end

-- Shapes placed relative to `origin` (world CFrame), all welded to a new root named rootName.
local function assemble(shapes, origin, rootName, parent)
	local root = decor({ Name = rootName, Size = Vector3.one * 0.2, CFrame = origin, Transparency = 1 }, parent)
	for _, spec in shapes do
		local part = decor({
			Name = "Piece",
			Shape = SHAPES[spec.shape],
			Size = spec.size,
			CFrame = origin * spec.at,
			Color = spec.color,
			Material = spec.material or Enum.Material.SmoothPlastic,
		}, parent)
		weld(root, part)
	end
	return root
end

-- Booster on the bike. chassisCFrame = the bike chassis, strutFrom = bike point the strut starts at.
-- Returns the root part ("BoosterMount", with a "Nozzle" attachment and a "Flame" attribute).
function GearBuilder.booster(id, chassisCFrame, strutFrom, parent)
	local model = GearModels.boosters[id]
	if not model then
		return nil
	end
	local origin = chassisCFrame * CFrame.new(model.at)
	local root = assemble(model.parts, origin, "BoosterMount", parent)
	if model.strut then
		local strut = Build.tube(chassisCFrame * strutFrom, origin * model.strut, STRUT_RADIUS, { Color = model.parts[1].color, Anchored = false, Massless = true, Parent = parent })
		strut.CanCollide, strut.CanQuery, strut.CanTouch = false, false, false
		weld(root, strut)
	end
	local nozzle = Instance.new("Attachment")
	nozzle.Name = "Nozzle"
	nozzle.Position = model.nozzle
	nozzle.Parent = root
	root:SetAttribute("Flame", model.flame)
	return root
end

-- One bomb at a belt slot. slotCFrame = world CFrame of the slot (+Z pointing away from the body).
function GearBuilder.bomb(id, slotCFrame, parent)
	local shapes = GearModels.bombs[id]
	return shapes and assemble(shapes, slotCFrame, "Bomb", parent)
end

return GearBuilder
