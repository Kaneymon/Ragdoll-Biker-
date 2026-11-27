-- Builds the cartoon BMX from simple shapes in the equipped paint job, plus the equipped booster
-- (World/GearBuilder) and trail (Config/Cosmetics).
-- Rig (all in chassis space, -Z = forward):
--   Chassis (invisible physics root)
--     Motor6D "Whip"  -> FrameRoot (frame, fork, wheels, gear)   tailwhip spins this
--       Motor6D "FrontSpin"/"RearSpin" -> wheels                 wheel roll
--       Motor6D "Crank" -> CrankRoot (sprocket, crank arms, pedals) pedalling
--     Motor6D "Bars"  -> BarsRoot (handlebars)                   barspin spins this
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local P = require(Shared.Config.Palette)
local Bike = require(Shared.Config.Bike)
local Build = require(script.Parent.Build)
local GearBuilder = require(script.Parent.GearBuilder)

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
	boosterStrut = Vector3.new(0, 0.45, 1.3), -- where the booster's support bar meets the frame
}
local TRAIL_TRANSPARENCY = NumberSequence.new(0.15, 1)
local GRIP_OFFSET = Vector3.new(0, 0.7, 0.1) -- from the bars pivot to the bar (see barsParts)
local GRIP_SPREAD = 1.0 -- grip centre distance from the middle of the bar
local SLIPPERY = PhysicalProperties.new(1, 0, 0, 100, 100)

local function visual(props, parent)
	props.Anchored = false
	props.Massless = true
	props.Parent = parent
	return Build.decor(props)
end

local function tube(a, b, radius, color, parent, material)
	local part = Build.tube(a, b, radius, { Color = color, Material = material or Enum.Material.SmoothPlastic, Anchored = false, Massless = true, Parent = parent })
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

local function wheel(name, at, model, paint)
	local hub = visual({ Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.35, WHEEL_RADIUS * 2, WHEEL_RADIUS * 2), CFrame = CFrame.new(at), Color = P.Rubber }, model)
	local parts = {
		visual({ Name = "Rim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, WHEEL_RADIUS * 1.5, WHEEL_RADIUS * 1.5), CFrame = CFrame.new(at), Color = paint.accent }, model),
		visual({ Name = "Hub", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 0.5, 0.5), CFrame = CFrame.new(at), Color = P.Metal }, model),
		visual({ Name = "Spoke", Size = Vector3.new(0.42, WHEEL_RADIUS * 1.45, 0.18), CFrame = CFrame.new(at), Color = P.White }, model),
		visual({ Name = "Spoke", Size = Vector3.new(0.42, 0.18, WHEEL_RADIUS * 1.45), CFrame = CFrame.new(at), Color = P.White }, model),
	}
	weldAll(hub, parts)
	return hub
end

local function frameParts(model, paint)
	local p = POINTS
	local parts = {}
	local function add(part)
		table.insert(parts, part)
	end
	local frame, accent, finish = paint.frame, paint.accent, paint.material
	add(tube(p.seat, p.headTop, 0.16, frame, model, finish)) -- top tube
	add(tube(p.crank, p.headBottom, 0.18, frame, model, finish)) -- down tube
	add(tube(p.crank, p.seat, 0.16, frame, model, finish)) -- seat tube
	add(tube(p.headBottom, p.headTop, 0.2, accent, model)) -- head tube
	for _, x in { -0.28, 0.28 } do
		local offset = Vector3.new(x, 0, 0)
		add(tube(p.crank + offset, p.rear + offset, 0.11, frame, model, finish)) -- chain stays
		add(tube(p.seat + offset * 0.5, p.rear + offset, 0.11, frame, model, finish)) -- seat stays
		add(tube(p.headBottom + offset * 0.4, p.front + offset, 0.13, accent, model)) -- fork
	end
	add(visual({ Name = "Seat", Size = Vector3.new(0.7, 0.3, 1.5), CFrame = CFrame.new(p.seat + Vector3.new(0, 0.3, 0.1)), Color = P.Ink }, model))
	return parts
end

-- Sprocket, crank arms and pedals: one assembly that spins round the crank axle.
local function crankParts(model, paint)
	local p = POINTS
	local parts = {
		visual({ Name = "Sprocket", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.15, 1.1, 1.1), CFrame = CFrame.new(p.crank + Vector3.new(0.3, 0, 0)), Color = paint.accent }, model),
		visual({ Name = "Axle", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.9, 0.25, 0.25), CFrame = CFrame.new(p.crank), Color = P.Metal }, model),
	}
	for _, side in { -1, 1 } do
		local pedalAt = p.crank + Vector3.new(side * 0.65, side * 0.45, 0)
		table.insert(parts, tube(p.crank + Vector3.new(side * 0.42, 0, 0), pedalAt - Vector3.new(side * 0.2, 0, 0), 0.07, P.Metal, model)) -- crank arm
		table.insert(parts, visual({ Name = "Pedal", Size = Vector3.new(0.7, 0.2, 0.5), CFrame = CFrame.new(pedalAt), Color = P.Ink }, model))
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

-- A ribbon behind the rear wheel, as tall as the trail's width.
local function addTrail(def, frameRoot)
	local ends = {}
	for i, y in { -0.5, 0.5 } do
		local attachment = Instance.new("Attachment")
		attachment.Name = "Trail" .. i
		attachment.Position = frameRoot.CFrame:PointToObjectSpace(POINTS.rear + Vector3.new(0, y * def.width, 0.4))
		attachment.Parent = frameRoot
		ends[i] = attachment
	end
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = ends[1], ends[2]
	trail.Lifetime = def.lifetime
	trail.Transparency = TRAIL_TRANSPARENCY
	trail.LightEmission = if def.light then 1 else 0
	trail.FaceCamera = true
	if def.rainbow then
		local keys = {}
		for i = 0, 6 do
			table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.85, 1)))
		end
		trail.Color = ColorSequence.new(keys)
	else
		trail.Color = ColorSequence.new(def.from, def.to)
	end
	trail.Parent = frameRoot
end

-- gear = { paint = paint def, trail = trail def?, booster = booster def? } (exploder bombs ride on
-- the rider's belt, see GearService)
function BikeBuilder.build(gear)
	local model = Instance.new("Model")
	model.Name = "Bike"

	local chassis = Build.part({ Name = "Chassis", Size = Vector3.new(1.6, 1.4, 5.4), CFrame = CFrame.new(), Transparency = 1, Anchored = false, CustomPhysicalProperties = SLIPPERY, Parent = model })
	chassis.RootPriority = 10
	model.PrimaryPart = chassis

	local frameRoot = pivotPart("FrameRoot", POINTS.headTop, model)
	local frame = frameParts(model, gear.paint)
	if gear.booster then
		local booster = Build.model("Booster", model)
		table.insert(frame, GearBuilder.booster(gear.booster.id, CFrame.new(), POINTS.boosterStrut, booster))
	end
	weldAll(frameRoot, frame)
	motor("Whip", chassis, frameRoot, POINTS.headTop)
	motor("FrontSpin", frameRoot, wheel("FrontWheel", POINTS.front, model, gear.paint), POINTS.front)
	motor("RearSpin", frameRoot, wheel("RearWheel", POINTS.rear, model, gear.paint), POINTS.rear)
	if gear.trail then
		addTrail(gear.trail, frameRoot)
	end
	local crankRoot = pivotPart("CrankRoot", POINTS.crank, model)
	weldAll(crankRoot, crankParts(model, gear.paint))
	motor("Crank", frameRoot, crankRoot, POINTS.crank)

	local barsRoot = pivotPart("BarsRoot", POINTS.barsPivot, model)
	weldAll(barsRoot, barsParts(model))
	for side, x in { Left = -1, Right = 1 } do -- where the rider's hands hold the bars
		local grip = Instance.new("Attachment")
		grip.Name = side .. "Grip"
		grip.Position = barsRoot.CFrame:PointToObjectSpace(POINTS.barsPivot + GRIP_OFFSET + Vector3.new(x * GRIP_SPREAD, 0, 0))
		grip.Parent = barsRoot
	end
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
