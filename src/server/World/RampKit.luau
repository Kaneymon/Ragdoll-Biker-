-- Wooden mega ramp pieces in the Config/MegaRamp look (chipboard decks, metal barriers, curved
-- kickers with metal side walls). Used for the maps' mega ramps and the lobby obby.
-- Directions: `forward` = the way riders go along the piece, `up` = the riding surface's normal.
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MegaRamp = require(ReplicatedStorage.Shared.Config.MegaRamp)
local Build = require(script.Parent.Build)

local RampKit = {}

local OVERLAP = 0.4 -- pieces overlap a little so there are no cracks between them

-- A chipboard part (tiled = split if too big for one part).
function RampKit.wood(props, tiled)
	local look = MegaRamp.surface
	props.Material, props.MaterialVariant, props.Color = look.material, look.variant, look.color
	return if tiled then Build.tiled(props) else Build.part(props)
end

local function barrierFolder(parent)
	return parent:FindFirstChild("Barriers") or Build.model("Barriers", parent)
end

-- Metal barrier sections along a straight line from `from`, `length` studs along `forward`.
function RampKit.barrierLine(parent, from, forward, up, length)
	local spec = MegaRamp.barrier
	local folder = barrierFolder(parent)
	local count = math.max(1, math.ceil(length / spec.length - 0.25))
	local step = length / count
	for i = 1, count do
		local barrier = ServerStorage.Assets[spec.folder][spec.mesh]:Clone()
		barrier:PivotTo(CFrame.lookAt(from + forward * (step * (i - 0.5)), from + forward * (step * i), up))
		barrier.Parent = folder
	end
end

-- A straight deck whose top surface starts at `from` and runs `length` studs along `forward`
-- (which may slope), with barriers down both sides. Returns where the top surface ends.
function RampKit.deck(parent, name, from, forward, up, length, width, thickness)
	local right = up:Cross(forward).Unit
	local centre = from + forward * (length / 2) - up * (thickness / 2)
	RampKit.wood({ Name = name, Size = Vector3.new(width, thickness, length + OVERLAP), CFrame = CFrame.fromMatrix(centre, right, up), Parent = parent }, true)
	for _, side in { -1, 1 } do
		RampKit.barrierLine(parent, from + right * (side * (width / 2 + MegaRamp.barrier.inset)), forward, up, length)
	end
	return from + forward * length
end

-- A curved launch kicker starting flat at `start` heading `forward` (horizontal), bending up to
-- `endAngle` degrees on a circle of `radius`. Segments are tagged Launch (the bike flies off).
-- Returns the lip (top edge) and the launch direction.
function RampKit.kicker(parent, start, forward, width, radius, endAngle, segments, depth)
	local side = MegaRamp.kickerSide
	local right = Vector3.yAxis:Cross(forward).Unit
	local centre = start + Vector3.yAxis * radius
	local e = math.rad(endAngle)
	local function arcPoint(phi)
		return centre - Vector3.yAxis * (radius * math.cos(phi)) + forward * (radius * math.sin(phi))
	end
	for i = 0, segments - 1 do
		local a, b = arcPoint(e * i / segments), arcPoint(e * (i + 1) / segments)
		local along = (b - a).Unit
		local up = along:Cross(right)
		local mid = (a + b) / 2
		local length = (b - a).Magnitude + OVERLAP
		local segment = RampKit.wood({ Name = "Kicker", Size = Vector3.new(width, depth, length), CFrame = CFrame.fromMatrix(mid - up * (depth / 2), right, up), Parent = parent })
		segment:SetAttribute("Launch", true)
		for _, x in { -1, 1 } do -- metal side walls follow the curve
			local offset = right * (x * (width / 2 + side.thickness / 2))
			Build.part({ Name = "KickerSide", Size = Vector3.new(side.thickness, side.height, length), CFrame = CFrame.fromMatrix(mid + offset + up * (side.height / 2), right, up), Material = side.material, Color = side.color, Parent = parent })
		end
	end
	local lip = arcPoint(e)
	return lip, (forward * math.cos(e) + Vector3.yAxis * math.sin(e)).Unit
end

return RampKit
