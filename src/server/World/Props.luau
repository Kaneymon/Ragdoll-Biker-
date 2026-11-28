-- Map props. Most are cartoon shapes built from parts; the cars and the textured park props are
-- meshes kept in ServerStorage.Assets (see Config/MeshProps). Each returns a Model
-- pivoted at its base.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local P = require(ReplicatedStorage.Shared.Config.Palette)
local Hazards = require(ReplicatedStorage.Shared.Config.Hazards)
local MeshProps = require(ReplicatedStorage.Shared.Config.MeshProps)
local Build = require(script.Parent.Build)

local Props = {}

local BOUNCY = PhysicalProperties.new(0.7, 0.3, 1, 1, 100)

local function finish(model)
	model.WorldPivot = CFrame.new(0, 0, 0)
	return model
end

-- A textured Blender prop (Config/MeshProps entry), randomly sized within its scale range.
function Props.mesh(def, rng: Random)
	local model = ServerStorage.Assets[def.folder or MeshProps.folder][def.mesh]:Clone()
	model:ScaleTo(model:GetScale() * rng:NextNumber(def.scale[1], def.scale[2])) -- relative to the stored size
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = def.collide
			part.CanQuery = def.collide
			part.CanTouch = false
			if def.launch then
				part:SetAttribute("Launch", true) -- the bike flies off it (BikeController)
			end
		end
	end
	return model
end

function Props.tree(rng: Random)
	local model = Build.model("Tree")
	local height = rng:NextNumber(12, 22)
	Build.part({ Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(height, 2.4, 2.4), CFrame = CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.WoodDark, Parent = model })
	for i = 1, 3 do
		local size = rng:NextNumber(9, 14)
		local offset = Vector3.new(rng:NextNumber(-3, 3), height + rng:NextNumber(-1, 4), rng:NextNumber(-3, 3))
		Build.part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.one * size, CFrame = CFrame.new(offset), Color = i == 1 and P.Grass or P.GrassDark, Parent = model })
	end
	return finish(model)
end

function Props.bench()
	local model = Build.model("Bench")
	Build.part({ Name = "Seat", Size = Vector3.new(8, 0.6, 2.4), CFrame = CFrame.new(0, 2, 0), Color = P.Wood, Parent = model })
	Build.part({ Name = "Back", Size = Vector3.new(8, 2.2, 0.5), CFrame = CFrame.new(0, 3.6, 1.1), Color = P.Wood, Parent = model })
	for _, x in { -3.4, 3.4 } do
		Build.part({ Name = "Leg", Size = Vector3.new(0.6, 2, 2.2), CFrame = CFrame.new(x, 1, 0), Color = P.Metal, Parent = model })
	end
	return finish(model)
end

function Props.hay(rng: Random)
	local model = Build.model("HayBale")
	Build.part({ Name = "Bale", Shape = Enum.PartType.Cylinder, Size = Vector3.new(5, 5, 5), CFrame = CFrame.new(0, 2.5, 0) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0), Color = P.Sun, CustomPhysicalProperties = BOUNCY, Parent = model })
	return finish(model)
end

function Props.rock(rng: Random)
	local model = Build.model("Rock")
	local size = Vector3.new(rng:NextNumber(4, 10), rng:NextNumber(3, 7), rng:NextNumber(4, 10))
	local tilt = CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, math.pi), rng:NextNumber(-0.4, 0.4))
	Build.part({ Name = "Stone", Size = size, CFrame = CFrame.new(0, size.Y * 0.35, 0) * tilt, Color = P.Stone, Parent = model })
	return finish(model)
end

function Props.picnicTable()
	local model = Build.model("PicnicTable")
	Build.part({ Name = "Top", Size = Vector3.new(9, 0.6, 4), CFrame = CFrame.new(0, 3.2, 0), Color = P.Wood, Parent = model })
	for _, z in { -3, 3 } do
		Build.part({ Name = "Bench", Size = Vector3.new(9, 0.5, 1.4), CFrame = CFrame.new(0, 1.8, z), Color = P.WoodDark, Parent = model })
	end
	for _, x in { -3.6, 3.6 } do
		Build.part({ Name = "Leg", Size = Vector3.new(0.6, 3.2, 7), CFrame = CFrame.new(x, 1.6, 0), Color = P.WoodDark, Parent = model })
	end
	return finish(model)
end

function Props.fence(rng: Random)
	local model = Build.model("Fence")
	local posts = rng:NextInteger(4, 8)
	local length = (posts - 1) * 6
	for i = 0, posts - 1 do
		Build.part({ Name = "Post", Size = Vector3.new(0.8, 4.5, 0.8), CFrame = CFrame.new(i * 6 - length / 2, 2.25, 0), Color = P.White, Parent = model })
	end
	for _, y in { 1.6, 3.4 } do
		Build.part({ Name = "Rail", Size = Vector3.new(length, 0.6, 0.4), CFrame = CFrame.new(0, y, 0), Color = P.White, Parent = model })
	end
	return finish(model)
end

function Props.crate(rng: Random)
	local model = Build.model("Crate")
	local size = rng:NextNumber(4, 7)
	Build.part({ Name = "Box", Size = Vector3.one * size, CFrame = CFrame.new(0, size / 2, 0), Color = P.Wood, Parent = model })
	Build.part({ Name = "Band", Size = Vector3.new(size + 0.2, 0.6, size + 0.2), CFrame = CFrame.new(0, size / 2, 0), Color = P.WoodDark, Parent = model })
	return finish(model)
end

-- A low-poly car from the SuperLowPolyCars pack (ServerStorage.Assets.Cars, one textured MeshPart
-- "Body" each; assets/models/cars/README.md) that blows up when touched (Config/Hazards "Car"): it
-- never blocks anything. Longer cars (trucks, vans) get a bigger blast radius so their ends count.
function Props.car(rng: Random)
	local cars = ServerStorage.Assets.Cars:GetChildren()
	table.sort(cars, function(a, b)
		return a.Name < b.Name
	end) -- same seed, same cars
	local model = cars[rng:NextInteger(1, #cars)]:Clone()
	model:SetAttribute("Variant", model.Name)
	model.Name = "Car"
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
		end
	end
	local size = model:GetExtentsSize()
	model:SetAttribute("Hazard", "Car")
	model:SetAttribute("HazardRadius", math.max(Hazards.kinds.Car.radius, math.max(size.X, size.Z) / 2 + 1.5))
	CollectionService:AddTag(model, Hazards.Tag)
	return model
end

-- A little house for the edge of the street: walls, a pointy roof, door and windows.
local HOUSE_WALLS = { P.Paper, P.Shade, P.Card, P.Sun, P.Sky }
local HOUSE_ROOFS = { P.Coral, P.Grape, P.WoodDark, P.SkyDark }
function Props.house(rng: Random)
	local model = Build.model("House")
	local width, depth, height = rng:NextNumber(24, 34), rng:NextNumber(22, 30), rng:NextNumber(14, 22)
	local wall = HOUSE_WALLS[rng:NextInteger(1, #HOUSE_WALLS)]
	local roof = HOUSE_ROOFS[rng:NextInteger(1, #HOUSE_ROOFS)]
	Build.part({ Name = "Base", Size = Vector3.new(width + 2, 20, depth + 2), CFrame = CFrame.new(0, -9, 0), Color = P.Stone, Parent = model })
	Build.part({ Name = "Walls", Size = Vector3.new(width, height, depth), CFrame = CFrame.new(0, height / 2, 0), Color = wall, Parent = model })
	local roofHeight = width * 0.35
	for _, side in { -1, 1 } do -- two wedges meeting at the ridge (ridge runs along z)
		Build.part({ Name = "Roof", Size = Vector3.new(depth + 2, roofHeight, width / 2 + 1), CFrame = CFrame.new(side * (width / 4 + 0.5), height + roofHeight / 2, 0) * CFrame.Angles(0, -side * math.pi / 2, 0), Color = roof, Parent = model }, "WedgePart")
	end
	Build.decor({ Name = "Door", Size = Vector3.new(0.4, 7, 4), CFrame = CFrame.new(width / 2 + 0.1, 3.5, 0), Color = P.WoodDark, Parent = model })
	for _, z in { -depth / 4, depth / 4 } do
		Build.decor({ Name = "Window", Size = Vector3.new(0.4, 4, 4), CFrame = CFrame.new(width / 2 + 0.1, height * 0.6, z), Color = P.Sky, Parent = model })
	end
	return finish(model)
end

-- A small launch ramp for the landing slope: ride over it to fly (its top keeps the Launch tag
-- the bike looks for). The high end faces downhill (+z), so it must not be turned.
function Props.launchRamp(rng: Random, theme)
	local model = Build.model("LaunchRamp")
	local width, length, height = rng:NextNumber(20, 30), rng:NextNumber(16, 24), rng:NextNumber(4, 7)
	local ramp = Build.part({ Name = "Ramp", Size = Vector3.new(width, height, length), CFrame = CFrame.new(0, height / 2, 0), Color = theme.kickerA, Parent = model }, "WedgePart")
	ramp:SetAttribute("Launch", true)
	for _, side in { -1, 1 } do
		Build.decor({ Name = "Edge", Size = Vector3.new(0.8, height + 0.4, length), CFrame = CFrame.new(side * width / 2, height / 2, 0), Color = theme.kickerB, Parent = model })
	end
	return finish(model)
end

function Props.lamp()
	local model = Build.model("Lamp")
	Build.part({ Name = "Pole", Shape = Enum.PartType.Cylinder, Size = Vector3.new(16, 0.8, 0.8), CFrame = CFrame.new(0, 8, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.Metal, Parent = model })
	Build.part({ Name = "Light", Shape = Enum.PartType.Ball, Size = Vector3.one * 2.4, CFrame = CFrame.new(0, 16.5, 0), Color = P.Sun, Material = Enum.Material.Neon, Parent = model })
	return finish(model)
end

function Props.grindRail(rng: Random)
	local model = Build.model("GrindRail")
	local length = rng:NextNumber(14, 26)
	Build.part({ Name = "Bar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(length, 0.7, 0.7), CFrame = CFrame.new(0, 2.6, 0), Color = P.Metal, Parent = model })
	for _, x in { -length / 2 + 1, length / 2 - 1 } do
		Build.part({ Name = "Leg", Size = Vector3.new(0.5, 2.6, 0.5), CFrame = CFrame.new(x, 1.3, 0), Color = P.Metal, Parent = model })
	end
	return finish(model)
end

return Props
