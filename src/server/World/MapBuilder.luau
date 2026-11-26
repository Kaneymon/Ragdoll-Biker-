-- Builds a map from its Config/Maps entry: mega ramp hill, kicker, landing hill, park props, walls.
-- geometry() is pure maths so spawning works whether the map was built now or baked into the place.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local P = require(ReplicatedStorage.Shared.Config.Palette)
local Build = require(script.Parent.Build)
local Props = require(script.Parent.Props)

local MapBuilder = {}

local KICKER_DEPTH = 40
local WALL_HEIGHT = 1200

local PROP_BUILDERS = { -- config key -> builder, upright (true) or follows the slope (false)
	trees = { Props.tree, true },
	rocks = { Props.rock, true },
	benches = { Props.bench, false },
	hay = { Props.hay, false },
	tables = { Props.picnicTable, false },
	bouncers = { Props.bouncer, false },
	fences = { Props.fence, false },
}

local function slopeVectors(angleDeg)
	local a = math.rad(angleDeg)
	return Vector3.new(0, -math.sin(a), math.cos(a)), Vector3.new(0, math.cos(a), math.sin(a))
end

function MapBuilder.geometry(def)
	local origin, ramp, kicker = def.origin, def.ramp, def.kicker
	local down, normal = slopeVectors(ramp.angle)
	local bottom = origin + down * ramp.length
	local kickStart = bottom + Vector3.new(0, 0, def.runout)
	local centre = kickStart + Vector3.new(0, kicker.radius, 0)
	local e = math.rad(kicker.endAngle)
	local lip = centre + Vector3.new(0, -kicker.radius * math.cos(e), kicker.radius * math.sin(e))
	local landDown, landNormal = slopeVectors(def.landing.angle)
	local landStart = Vector3.new(origin.X, bottom.Y, lip.Z + def.gap)
	local landEnd = landStart + landDown * def.landing.length
	return {
		origin = origin,
		down = down,
		normal = normal,
		bottom = bottom,
		kickStart = kickStart,
		kickCentre = centre,
		lip = lip,
		landDown = landDown,
		landNormal = landNormal,
		landStart = landStart,
		landEnd = landEnd,
	}
end

-- Where a rider spawns for a ramp start distance (studs up the slope from the bottom).
function MapBuilder.spawnCFrame(def, startDistance, hover, sideOffset)
	local g = MapBuilder.geometry(def)
	local distance = math.min(startDistance, def.ramp.length - 8)
	local position = g.bottom - g.down * distance + g.normal * hover + Vector3.new(sideOffset, 0, 0)
	return CFrame.lookAt(position, position + g.down, g.normal)
end

local function buildRamp(def, g, model)
	local ramp = def.ramp
	local mid = g.origin + g.down * (ramp.length / 2)
	local slab = Build.onSurface(mid - g.normal * (ramp.thickness / 2), g.normal)
	Build.part({ Name = "Ramp", Size = Vector3.new(ramp.width, ramp.thickness, ramp.length), CFrame = slab, Color = P.Wood, Parent = model })
	Build.decor({ Name = "Stripe", Size = Vector3.new(2, 0.2, ramp.length), CFrame = Build.onSurface(mid + g.normal * 0.1, g.normal), Color = P.Sun, Parent = model })
	for _, side in { -1, 1 } do
		local x = Vector3.new(side * (ramp.width / 2 + 0.6), 0, 0)
		Build.part({ Name = "Rail", Size = Vector3.new(1.2, 3, ramp.length), CFrame = Build.onSurface(mid + x + g.normal * 1.5, g.normal), Color = P.Coral, Parent = model })
	end
	-- the hill under the ramp
	local height, depth = g.origin.Y - g.bottom.Y, g.bottom.Z - g.origin.Z
	Build.part({ Name = "Hill", Size = Vector3.new(ramp.width + 160, height, depth), CFrame = CFrame.new(g.origin.X, g.origin.Y - height / 2 - 0.4, g.origin.Z + depth / 2) * CFrame.Angles(0, math.pi, 0), Color = P.Grass, Parent = model }, "WedgePart")
	Build.part({ Name = "HillTop", Size = Vector3.new(ramp.width + 160, height, 80), CFrame = CFrame.new(g.origin.X, g.origin.Y - height / 2 - 0.4, g.origin.Z - 40), Color = P.Grass, Parent = model })
	Build.part({ Name = "StartDeck", Size = Vector3.new(ramp.width, ramp.thickness, 30), CFrame = CFrame.new(g.origin + Vector3.new(0, -ramp.thickness / 2, -15)), Color = P.Wood, Parent = model })
end

local function buildKicker(def, g, model)
	local kicker, width = def.kicker, def.ramp.width
	Build.part({ Name = "Runout", Size = Vector3.new(width, def.ramp.thickness, def.runout + 1), CFrame = CFrame.new(g.bottom + Vector3.new(0, -def.ramp.thickness / 2, def.runout / 2)), Color = P.Wood, Parent = model })
	local e = math.rad(kicker.endAngle)
	local function arcPoint(phi)
		return g.kickCentre + Vector3.new(0, -kicker.radius * math.cos(phi), kicker.radius * math.sin(phi))
	end
	for i = 0, kicker.segments - 1 do
		local a, b = arcPoint(e * i / kicker.segments), arcPoint(e * (i + 1) / kicker.segments)
		local along = (b - a).Unit
		local up = Vector3.new(0, along.Z, -along.Y)
		local mid = (a + b) / 2
		local segment = Build.part({ Name = "Kicker", Size = Vector3.new(width, KICKER_DEPTH, (b - a).Magnitude + 0.4), CFrame = Build.onSurface(mid - up * (KICKER_DEPTH / 2), up), Color = i % 2 == 0 and P.Coral or P.Orange, Parent = model })
		segment:SetAttribute("Launch", true)
		for _, side in { -1, 1 } do
			Build.part({ Name = "Rail", Size = Vector3.new(1.2, 3, (b - a).Magnitude + 0.4), CFrame = Build.onSurface(mid + Vector3.new(side * (width / 2 + 0.6), 0, 0) + up * 1.5, up), Color = P.Sun, Parent = model })
		end
	end
end

local function buildGround(def, g, model)
	local width = def.landing.width
	local groundStart, groundEnd = g.origin.Z - 80, g.landStart.Z
	Build.part({ Name = "Ground", Size = Vector3.new(width, 20, groundEnd - groundStart), CFrame = CFrame.new(g.origin.X, g.bottom.Y - 10.4, (groundStart + groundEnd) / 2), Color = P.GrassDark, Parent = model })
	local height, depth = g.landStart.Y - g.landEnd.Y, g.landEnd.Z - g.landStart.Z
	Build.part({ Name = "LandingHill", Size = Vector3.new(width, height, depth), CFrame = CFrame.new(g.origin.X, g.landStart.Y - height / 2, g.landStart.Z + depth / 2) * CFrame.Angles(0, math.pi, 0), Color = P.Grass, Parent = model }, "WedgePart")
	Build.part({ Name = "Park", Size = Vector3.new(width, 20, 400), CFrame = CFrame.new(g.origin.X, g.landEnd.Y - 10, g.landEnd.Z + 200), Color = P.Grass, Parent = model })
	Build.part({ Name = "Valley", Size = Vector3.new(4000, 20, 4000), CFrame = CFrame.new(g.origin.X, g.landEnd.Y - 10.5, (groundStart + g.landEnd.Z) / 2), Color = P.GrassDark, Parent = model })

	local zMin, zMax = groundStart - 10, g.landEnd.Z + 400
	local wallProps = { Transparency = 1, CanQuery = false, Parent = model }
	for _, side in { -1, 1 } do
		wallProps.Name = "Wall"
		wallProps.Size = Vector3.new(4, WALL_HEIGHT, zMax - zMin)
		wallProps.CFrame = CFrame.new(g.origin.X + side * (width / 2 + 2), g.landEnd.Y + WALL_HEIGHT / 2, (zMin + zMax) / 2)
		Build.part(table.clone(wallProps))
	end
	for _, z in { zMin, zMax } do
		wallProps.Size = Vector3.new(width, WALL_HEIGHT, 4)
		wallProps.CFrame = CFrame.new(g.origin.X, g.landEnd.Y + WALL_HEIGHT / 2, z)
		Build.part(table.clone(wallProps))
	end
end

local function placeProps(def, g, model)
	local rng = Random.new(def.seed)
	local folder = Build.model("Props", model)
	local half = def.landing.width / 2 - 20
	for key, count in def.props do
		local builder = PROP_BUILDERS[key]
		for _ = 1, count do
			local along = rng:NextNumber(80, def.landing.length + 300)
			local onSlope = along <= def.landing.length
			local position = if onSlope
				then g.landStart + g.landDown * along
				else g.landEnd + Vector3.new(0, 0, along - def.landing.length)
			position += Vector3.new(rng:NextNumber(-half, half), 0, 0)
			local normal = if onSlope and not builder[2] then g.landNormal else Vector3.yAxis
			local prop = builder[1](rng)
			prop:PivotTo(Build.onSurface(position, normal) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
			prop.Parent = folder
		end
	end
	-- trees along the sides of the mega ramp hill
	for i = 1, 24 do
		local along = rng:NextNumber(40, def.ramp.length - 20)
		local side = if i % 2 == 0 then 1 else -1
		local x = side * rng:NextNumber(def.ramp.width / 2 + 12, def.ramp.width / 2 + 75)
		local tree = Props.tree(rng)
		tree:PivotTo(CFrame.new(g.origin + g.down * along + Vector3.new(x, -0.6, 0)))
		tree.Parent = folder
	end
end

function MapBuilder.build(def, parent)
	local g = MapBuilder.geometry(def)
	local model = Build.model(def.id)
	buildRamp(def, g, model)
	buildKicker(def, g, model)
	buildGround(def, g, model)
	placeProps(def, g, model)
	model.Parent = parent
	return model
end

return MapBuilder
