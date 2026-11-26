-- Cartoon park props built from simple shapes. Each returns a Model pivoted at its base.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local P = require(ReplicatedStorage.Shared.Config.Palette)
local Build = require(script.Parent.Build)

local Props = {}

local BOUNCY = PhysicalProperties.new(0.7, 0.3, 1, 1, 100)

local function finish(model)
	model.WorldPivot = CFrame.new(0, 0, 0)
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

function Props.bouncer()
	local model = Build.model("Bouncer")
	Build.part({ Name = "Pad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 16, 16), CFrame = CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.Coral, CustomPhysicalProperties = BOUNCY, Parent = model })
	Build.part({ Name = "Ring", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 17, 17), CFrame = CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.Sky, Parent = model })
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

return Props
