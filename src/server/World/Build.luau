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
