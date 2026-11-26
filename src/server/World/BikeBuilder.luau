-- Builds the cartoon BMX from simple shapes (placeholder until the Blender mesh is imported).
-- Rig (all in chassis space, -Z = forward):
--   Chassis (invisible physics root)
--     Motor6D "Whip"  -> FrameRoot (frame, fork, wheels, gear)   tailwhip spins this
--       Motor6D "FrontSpin"/"RearSpin" -> wheels                 wheel roll
--     Motor6D "Bars"  -> BarsRoot (handlebars)                   barspin spins this
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local P = require(Shared.Config.Palette)
local Bike = require(Shared.Config.Bike)
local Build = require(script.Parent.Build)

local BikeBuilder = {}

local WHEEL_RADIUS = 1.25
local AXLE_Y = WHEEL_RADIUS - Bike.Hover
local POINTS = {
	rear = Vector3.new(0, AXLE_Y, 1.95),
	front = Vector3.new(0, AXLE_Y, -1.95),
	crank = Vector3.new(0, -0.7, 0.5),
	seat = Vector3.new(0, 0.55, 0.95),
	headTop = Vector3.new(0, 0.75, -1.5),
	headBottom = Vector3.new(0, 0.05, -1.7),
	barsPivot = Vector3.new(0, 0.75, -1.5),
}
local FRAME_COLOR, ACCENT = P.Coral, P.Sun
local SLIPPERY = PhysicalProperties.new(1, 0, 0, 100, 100)

local function visual(props, parent)
	props.Anchored = false
	props.Massless = true
	props.Parent = parent
	return Build.decor(props)
end

local function tube(a, b, radius, color, parent)
	local part = Build.tube(a, b, radius, { Color = color, Anchored = false, Massless = true, Parent = parent })
	part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
	return part
end

local function weldAll(root, parts)
	for _, part in parts do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = part
		weld.Parent = part
	end
end

local function motor(name, part0, part1, pivot)
	local joint = Instance.new("Motor6D")
	joint.Name = name
	joint.Part0 = part0
	joint.Part1 = part1
	joint.C0 = part0.CFrame:ToObjectSpace(CFrame.new(pivot))
	joint.C1 = part1.CFrame:ToObjectSpace(CFrame.new(pivot))
	joint.Parent = part0
	return joint
end

local function pivotPart(name, at, parent)
	return visual({ Name = name, Size = Vector3.one * 0.2, CFrame = CFrame.new(at), Transparency = 1 }, parent)
end

local function wheel(name, at, model)
	local hub = visual({ Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.35, WHEEL_RADIUS * 2, WHEEL_RADIUS * 2), CFrame = CFrame.new(at), Color = P.Rubber }, model)
	local parts = {
		visual({ Name = "Rim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, WHEEL_RADIUS * 1.5, WHEEL_RADIUS * 1.5), CFrame = CFrame.new(at), Color = ACCENT }, model),
		visual({ Name = "Hub", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 0.5, 0.5), CFrame = CFrame.new(at), Color = P.Metal }, model),
		visual({ Name = "Spoke", Size = Vector3.new(0.42, WHEEL_RADIUS * 1.45, 0.18), CFrame = CFrame.new(at), Color = P.White }, model),
		visual({ Name = "Spoke", Size = Vector3.new(0.42, 0.18, WHEEL_RADIUS * 1.45), CFrame = CFrame.new(at), Color = P.White }, model),
	}
	weldAll(hub, parts)
	return hub
end

local function frameParts(model)
	local p = POINTS
	local parts = {}
	local function add(part)
		table.insert(parts, part)
	end
	add(tube(p.seat, p.headTop, 0.16, FRAME_COLOR, model)) -- top tube
	add(tube(p.crank, p.headBottom, 0.18, FRAME_COLOR, model)) -- down tube
	add(tube(p.crank, p.seat, 0.16, FRAME_COLOR, model)) -- seat tube
	add(tube(p.headBottom, p.headTop, 0.2, ACCENT, model)) -- head tube
	for _, x in { -0.28, 0.28 } do
		local offset = Vector3.new(x, 0, 0)
		add(tube(p.crank + offset, p.rear + offset, 0.11, FRAME_COLOR, model)) -- chain stays
		add(tube(p.seat + offset * 0.5, p.rear + offset, 0.11, FRAME_COLOR, model)) -- seat stays
		add(tube(p.headBottom + offset * 0.4, p.front + offset, 0.13, ACCENT, model)) -- fork
	end
	add(visual({ Name = "Seat", Size = Vector3.new(0.7, 0.3, 1.5), CFrame = CFrame.new(p.seat + Vector3.new(0, 0.3, 0.1)), Color = P.Ink }, model))
	add(visual({ Name = "Sprocket", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.15, 1.1, 1.1), CFrame = CFrame.new(p.crank + Vector3.new(0.3, 0, 0)), Color = ACCENT }, model))
	for _, side in { -1, 1 } do
		add(visual({ Name = "Pedal", Size = Vector3.new(0.7, 0.2, 0.5), CFrame = CFrame.new(p.crank + Vector3.new(side * 0.65, side * 0.45, 0)), Color = P.Ink }, model))
	end
	return parts
end

local function barsParts(model)
	local p = POINTS
	local top = p.headTop + Vector3.new(0, 0.55, 0.1)
	local parts = {
		tube(p.headTop, top, 0.14, P.Metal, model), -- stem
		tube(top + Vector3.new(-1.1, 0.15, 0), top + Vector3.new(1.1, 0.15, 0), 0.12, P.Metal, model), -- bar
	}
	for _, side in { -1, 1 } do
		table.insert(parts, tube(top + Vector3.new(side * 0.8, 0.15, 0), top + Vector3.new(side * 1.25, 0.15, 0), 0.17, P.Ink, model)) -- grip
	end
	return parts
end

-- Placeholder gear: coloured blocks where the booster/exploder sit on the bike.
local function gearMount(name, def, at, size, model)
	local part = visual({ Name = name, Size = size, CFrame = CFrame.new(at), Color = def.color }, model)
	local nozzle = Instance.new("Attachment")
	nozzle.Name = "Nozzle"
	nozzle.Position = Vector3.new(0, 0, size.Z / 2)
	nozzle.Parent = part
	return part
end

-- gear = { booster = def?, exploder = def? }
function BikeBuilder.build(gear)
	local model = Instance.new("Model")
	model.Name = "Bike"

	local chassis = Build.part({ Name = "Chassis", Size = Vector3.new(1.6, 1.4, 5.4), CFrame = CFrame.new(), Transparency = 1, Anchored = false, CustomPhysicalProperties = SLIPPERY, Parent = model })
	chassis.RootPriority = 10
	model.PrimaryPart = chassis

	local frameRoot = pivotPart("FrameRoot", POINTS.headTop, model)
	local frame = frameParts(model)
	if gear.booster then
		table.insert(frame, gearMount("BoosterMount", gear.booster, Vector3.new(0, 0.2, 2.9), Vector3.new(0.9, 0.9, 1.4), model))
	end
	if gear.exploder then
		table.insert(frame, gearMount("ExploderMount", gear.exploder, Vector3.new(0, -0.1, -0.45), Vector3.new(0.8, 0.8, 0.8), model))
	end
	weldAll(frameRoot, frame)
	motor("Whip", chassis, frameRoot, POINTS.headTop)
	motor("FrontSpin", frameRoot, wheel("FrontWheel", POINTS.front, model), POINTS.front)
	motor("RearSpin", frameRoot, wheel("RearWheel", POINTS.rear, model), POINTS.rear)

	local barsRoot = pivotPart("BarsRoot", POINTS.barsPivot, model)
	weldAll(barsRoot, barsParts(model))
	motor("Bars", chassis, barsRoot, POINTS.barsPivot)

	local align = Instance.new("Attachment")
	align.Name = "AlignAttachment"
	align.Parent = chassis
	local orientation = Instance.new("AlignOrientation")
	orientation.Name = "Upright"
	orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orientation.Attachment0 = align
	orientation.Responsiveness = 60
	orientation.MaxTorque = math.huge
	orientation.Enabled = false
	orientation.Parent = chassis

	return model
end

return BikeBuilder
