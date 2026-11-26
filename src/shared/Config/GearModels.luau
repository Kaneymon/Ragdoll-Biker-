-- 3D looks for boosters (on the bike) and exploders (bombs on the rider's belt), built from parts
-- by World/GearBuilder. Every model is a list of shapes in its own space:
--   boosters: -Z = the bike's front, +Z = back (the exhaust); origin = `at` in bike chassis space
--   bombs:    +Z = away from the body; origin = a belt slot on the rider's hips
-- shape = Block | Ball | Cylinder (cylinders run along X; use Z/Y below to turn them).
-- nozzle = where the boost flame comes out; flame = Config/VfxPresets emitter;
-- strut = bottom of the model's pylon (a bar joins it to the bike's seat stays).
local P = require(script.Parent.Palette)

local Z = CFrame.Angles(0, math.rad(90), 0) -- cylinder along Z
local Y = CFrame.Angles(0, 0, math.rad(90)) -- cylinder along Y

local function at(x, y, z, turn)
	return CFrame.new(x, y, z) * (turn or CFrame.identity)
end

local function shape(kind, size, cframe, color, material)
	return { shape = kind, size = size, at = cframe, color = color, material = material }
end

-- `count` blades fanned round the Z axis at depth z, each `length` long from radius `inner`.
local function blades(count, inner, length, width, z, color, tilt)
	local list = {}
	for i = 1, count do
		local angle = math.rad(360 / count * i)
		local cframe = CFrame.new(0, 0, z) * CFrame.Angles(0, 0, angle) * CFrame.new(0, inner + length / 2, 0) * CFrame.Angles(0, math.rad(tilt or 20), 0)
		table.insert(list, shape("Block", Vector3.new(width, length, 0.06), cframe, color))
	end
	return list
end

local function join(...)
	local all = {}
	for _, list in { ... } do
		for _, item in list do
			table.insert(all, item)
		end
	end
	return all
end

local NEON = Enum.Material.Neon
local METAL = Enum.Material.Metal

return {
	BombMargin = 0.2, -- studs between the hips and a bomb
	-- Belt slots on the lower torso, as a direction from its centre (scaled to the torso size).
	BeltSlots = { Vector3.new(-1, 0, 0), Vector3.new(1, 0, 0), Vector3.new(0, 0, 1) },
	Belt = { thickness = 0.32, color = P.WoodDark },

	boosters = {
		desk_fan = {
			at = Vector3.new(0, 0.9, 2.5), nozzle = Vector3.new(0, 0, 0.8), strut = Vector3.new(0, -1.0, 0), flame = "BoostAir",
			parts = join({
				shape("Cylinder", Vector3.new(0.7, 0.7, 0.7), at(0, 0, 0, Z), P.White),
				shape("Cylinder", Vector3.new(0.12, 1.9, 1.9), at(0, 0, 0.55, Z), P.Sky, Enum.Material.ForceField),
				shape("Ball", Vector3.one * 0.34, at(0, 0, 0.6), P.Sky),
				shape("Block", Vector3.new(0.3, 0.8, 0.3), at(0, -0.6, 0), P.Metal),
			}, blades(3, 0.12, 0.75, 0.38, 0.55, P.Sky, 25)),
		},
		propeller = {
			at = Vector3.new(0, 1.0, 2.8), nozzle = Vector3.new(0, 0, 1.2), strut = Vector3.new(0, -1.1, 0), flame = "BoostAir",
			parts = join({
				shape("Cylinder", Vector3.new(1.6, 1.0, 1.0), at(0, 0, 0, Z), P.Sun),
				shape("Cylinder", Vector3.new(0.25, 1.1, 1.1), at(0, 0, -0.7, Z), P.Ink),
				shape("Ball", Vector3.one * 0.6, at(0, 0, 0.95), P.Coral),
				shape("Block", Vector3.new(0.3, 0.8, 0.5), at(0, -0.7, 0), P.Metal),
			}, blades(2, 0.2, 1.5, 0.4, 0.95, P.WoodDark, 15)),
		},
		fireworks = {
			at = Vector3.new(0, 1.0, 2.8), nozzle = Vector3.new(0, 0, 1.2), strut = Vector3.new(0, -0.58, 0), flame = "Boost",
			parts = {
				shape("Cylinder", Vector3.new(2.2, 0.5, 0.5), at(-0.28, 0.28, 0, Z), P.Coral),
				shape("Cylinder", Vector3.new(2.2, 0.5, 0.5), at(0.28, 0.28, 0, Z), P.White),
				shape("Cylinder", Vector3.new(2.2, 0.5, 0.5), at(-0.28, -0.28, 0, Z), P.White),
				shape("Cylinder", Vector3.new(2.2, 0.5, 0.5), at(0.28, -0.28, 0, Z), P.Coral),
				shape("Ball", Vector3.one * 0.5, at(-0.28, 0.28, -1.1), P.Sun),
				shape("Ball", Vector3.one * 0.5, at(0.28, 0.28, -1.1), P.Grape),
				shape("Ball", Vector3.one * 0.5, at(-0.28, -0.28, -1.1), P.Grape),
				shape("Ball", Vector3.one * 0.5, at(0.28, -0.28, -1.1), P.Sun),
				shape("Block", Vector3.new(1.15, 1.15, 0.3), at(0, 0, 0), P.Wood),
				shape("Cylinder", Vector3.new(0.5, 0.08, 0.08), at(0, 0, 1.35, Z), P.Ink),
			},
		},
		tiny_jet = { -- "tiny" by name only: a big jet engine
			at = Vector3.new(0, 1.5, 3.6), nozzle = Vector3.new(0, 0, 2.4), strut = Vector3.new(0, -1.6, 0), flame = "BoostBig",
			parts = {
				shape("Cylinder", Vector3.new(3.6, 2.0, 2.0), at(0, 0, 0, Z), P.Grape, METAL),
				shape("Cylinder", Vector3.new(0.4, 2.3, 2.3), at(0, 0, -1.8, Z), P.Metal, METAL),
				shape("Cylinder", Vector3.new(0.06, 1.9, 1.9), at(0, 0, -1.98, Z), P.Ink),
				shape("Ball", Vector3.one * 0.6, at(0, 0, -2.0), P.White),
				shape("Cylinder", Vector3.new(0.8, 1.5, 1.5), at(0, 0, 2.1, Z), P.Rubber, METAL),
				shape("Cylinder", Vector3.new(0.06, 1.1, 1.1), at(0, 0, 2.52, Z), P.Orange, NEON),
				shape("Block", Vector3.new(4.2, 0.14, 1.3), at(0, 0, 0.6), P.Grape, METAL), -- wings
				shape("Block", Vector3.new(0.14, 1.4, 1.1), at(0, 1.3, 1.3), P.Grape, METAL), -- tail fin
				shape("Cylinder", Vector3.new(0.3, 2.05, 2.05), at(0, 0, -0.6, Z), P.Sun), -- stripe
				shape("Block", Vector3.new(0.4, 1.0, 1.4), at(0, -1.1, 0), P.Metal, METAL), -- pylon
			},
		},
		turbine = { -- a huge airliner-style turbofan
			at = Vector3.new(0, 2.3, 4.4), nozzle = Vector3.new(0, 0, 3.1), strut = Vector3.new(0, -2.8, 0.4), flame = "BoostHuge",
			parts = join({
				shape("Cylinder", Vector3.new(4.2, 3.3, 3.3), at(0, 0, 0, Z), P.Metal, METAL),
				shape("Cylinder", Vector3.new(0.5, 3.6, 3.6), at(0, 0, -2.2, Z), P.White, METAL),
				shape("Cylinder", Vector3.new(0.06, 3.1, 3.1), at(0, 0, -2.3, Z), P.Ink),
				shape("Ball", Vector3.one * 1.0, at(0, 0, -2.35), P.White),
				shape("Cylinder", Vector3.new(0.4, 3.35, 3.35), at(0, 0, -0.6, Z), P.Coral),
				shape("Cylinder", Vector3.new(1.2, 2.2, 2.2), at(0, 0, 2.6, Z), P.Rubber, METAL),
				shape("Ball", Vector3.one * 1.3, at(0, 0, 3.0), P.Stone, METAL),
				shape("Cylinder", Vector3.new(0.06, 1.8, 1.8), at(0, 0, 3.22, Z), P.Orange, NEON),
				shape("Block", Vector3.new(0.5, 1.6, 2.4), at(0, -2.0, 0.4), P.Metal, METAL), -- pylon
			}, blades(10, 0.45, 1.05, 0.38, -2.25, P.Stone, 30)),
		},
		rocket = {
			at = Vector3.new(0, 1.5, 3.6), nozzle = Vector3.new(0, 0, 3.0), strut = Vector3.new(0, -1.4, -0.4), flame = "BoostBig",
			parts = {
				shape("Cylinder", Vector3.new(4.6, 1.3, 1.3), at(0, 0, 0, Z), P.White),
				shape("Ball", Vector3.one * 1.3, at(0, 0, -2.3), P.Coral),
				shape("Cylinder", Vector3.new(0.4, 1.35, 1.35), at(0, 0, -1.2, Z), P.Orange),
				shape("Cylinder", Vector3.new(0.8, 1.0, 1.0), at(0, 0, 2.6, Z), P.Rubber, METAL),
				shape("Block", Vector3.new(0.12, 1.1, 1.2), at(0, 0.95, 1.7), P.Coral),
				shape("Block", Vector3.new(0.12, 1.1, 1.2), at(0, -0.95, 1.7), P.Coral),
				shape("Block", Vector3.new(1.1, 0.12, 1.2), at(0.95, 0, 1.7), P.Coral),
				shape("Block", Vector3.new(1.1, 0.12, 1.2), at(-0.95, 0, 1.7), P.Coral),
				shape("Block", Vector3.new(0.4, 1.0, 1.4), at(0, -0.9, -0.4), P.Metal, METAL), -- pylon
			},
		},
	},

	bombs = {
		grenade = {
			shape("Ball", Vector3.one * 0.7, at(0, 0, 0.35), P.GrassDark),
			shape("Cylinder", Vector3.new(0.18, 0.3, 0.3), at(0, 0.38, 0.35, Y), P.Metal, METAL),
			shape("Block", Vector3.new(0.12, 0.55, 0.12), at(0.18, 0.15, 0.6), P.Metal, METAL),
			shape("Cylinder", Vector3.new(0.04, 0.26, 0.26), at(-0.18, 0.48, 0.35), P.Sun, METAL),
		},
		landmine = {
			shape("Cylinder", Vector3.new(0.3, 1.0, 1.0), at(0, 0, 0.15, Z), P.GrassDark, METAL),
			shape("Cylinder", Vector3.new(0.1, 1.08, 1.08), at(0, 0, 0.15, Z), P.Metal, METAL),
			shape("Cylinder", Vector3.new(0.12, 0.32, 0.32), at(0, 0, 0.35, Z), P.Danger, NEON),
		},
		rpg = {
			shape("Cylinder", Vector3.new(2.4, 0.38, 0.38), at(0, 0.2, 0.25, Y * CFrame.Angles(0, 0, math.rad(-25))), P.GrassDark, METAL),
			shape("Cylinder", Vector3.new(0.6, 0.62, 0.62), at(0.5, 1.25, 0.25, Y * CFrame.Angles(0, 0, math.rad(-25))), P.WoodDark, METAL),
			shape("Ball", Vector3.one * 0.62, at(0.65, 1.55, 0.25), P.WoodDark, METAL),
			shape("Block", Vector3.new(0.14, 0.35, 0.3), at(-0.1, -0.15, 0.45), P.Ink),
		},
		nuke = {
			shape("Cylinder", Vector3.new(0.7, 0.9, 0.9), at(0, 0, 0.45, Y), P.Sun, METAL),
			shape("Ball", Vector3.one * 0.9, at(0, 0.35, 0.45), P.Sun, METAL),
			shape("Ball", Vector3.one * 0.9, at(0, -0.35, 0.45), P.Sun, METAL),
			shape("Cylinder", Vector3.new(0.14, 0.94, 0.94), at(0, 0, 0.45, Y), P.Ink),
			shape("Block", Vector3.new(0.7, 0.35, 0.08), at(0, -0.85, 0.45), P.Ink),
			shape("Block", Vector3.new(0.08, 0.35, 0.7), at(0, -0.85, 0.45), P.Ink),
		},
	},
}
