-- Tiny construction helpers shared by the map, prop and bike builders.
local Build = {}

local DEFAULTS = {
	Anchored = true,
	Material = Enum.Material.SmoothPlastic,
	TopSurface = Enum.SurfaceType.Smooth,
	BottomSurface = Enum.SurfaceType.Smooth,
}

-- Build.part({ Size = ..., CFrame = ..., Color = ... }, "WedgePart")
function Build.part(props, className: string?)
	local part = Instance.new(className or "Part")
	for key, value in DEFAULTS do
		part[key] = value
	end
	local parent = props.Parent
	for key, value in props do
		if key ~= "Parent" then
			part[key] = value
		end
	end
	part.Parent = parent
	return part
end

-- Parts can't be bigger than 2048 studs on any side, so big boxes are split into tiles
-- (along the box's own axes) that together fill the same space.
local MAX_TILE = 2000

function Build.tiled(props, className: string?)
	local size, cf = props.Size, props.CFrame
	local counts = Vector3.new(math.ceil(size.X / MAX_TILE), math.ceil(size.Y / MAX_TILE), math.ceil(size.Z / MAX_TILE))
	local tile = size / counts
	local parts = {}
	for i = 1, counts.X do
		for j = 1, counts.Y do
			for k = 1, counts.Z do
				local offset = Vector3.new((i - 0.5) * tile.X, (j - 0.5) * tile.Y, (k - 0.5) * tile.Z) - size / 2
				local tileProps = table.clone(props)
				tileProps.Size = tile
				tileProps.CFrame = cf * CFrame.new(offset)
				table.insert(parts, Build.part(tileProps, className))
			end
		end
	end
	return parts
end

-- Decoration that never blocks rays or bodies.
function Build.decor(props, className: string?)
	local part = Build.part(props, className)
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	return part
end

-- Cylinder from a to b (cylinders run along their X axis).
function Build.tube(a: Vector3, b: Vector3, radius: number, props)
	props.Size = Vector3.new((b - a).Magnitude, radius * 2, radius * 2)
	props.CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0)
	props.Shape = Enum.PartType.Cylinder
	return Build.part(props)
end

function Build.model(name: string, parent: Instance?)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

-- CFrame on a sloped surface: up = surface normal, +Z = downhill.
function Build.onSurface(position: Vector3, normal: Vector3)
	return CFrame.fromMatrix(position, Vector3.xAxis, normal)
end

return Build
