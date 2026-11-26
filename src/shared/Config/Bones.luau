-- All 206 bones of the human skeleton, grouped by the Roblox body part they live in.
-- group = which shape on the payout skeleton picture shows this bone (see Groups below).
-- The short helpers only expand repeated names (left/right, numbered ribs, finger bones).
local list = {}
local byPart = {}

local function add(part, group, id, label)
	local bone = { id = id, label = label, group = group, part = part }
	table.insert(list, bone)
	byPart[part] = byPart[part] or {}
	table.insert(byPart[part], id)
end

local function numbered(part, group, prefix, label, first, last)
	for i = first, last do
		add(part, group, prefix .. i, label .. " " .. i)
	end
end

local CARPALS = { "Scaphoid", "Lunate", "Triquetrum", "Pisiform", "Trapezium", "Trapezoid", "Capitate", "Hamate" }
local TARSALS = { "Talus", "Calcaneus", "Navicular", "Cuboid", "Medial Cuneiform", "Middle Cuneiform", "Lateral Cuneiform" }

-- 5 metacarpals/metatarsals + 14 phalanges (thumb/big toe has no middle bone)
local function digits(part, group, side, short, long)
	for i = 1, 5 do
		add(part, group, side .. "_" .. short .. "_meta" .. i, side .. " " .. long .. " Metabone " .. i)
	end
	for _, row in { "Proximal", "Middle", "Distal" } do
		for i = 1, 5 do
			if not (row == "Middle" and i == 1) then
				add(part, group, side .. "_" .. short .. "_" .. row:lower() .. i, side .. " " .. long .. " " .. row .. " Bone " .. i)
			end
		end
	end
end

-- Head (36): 22 skull bones, 6 ear bones, hyoid, 7 neck vertebrae
for _, name in { "Frontal", "Occipital", "Sphenoid", "Ethmoid", "Vomer" } do
	add("Head", "skull", name:lower(), name .. " Bone")
end
for _, side in { "Left", "Right" } do
	for _, name in { "Parietal", "Temporal", "Maxilla", "Palatine", "Zygomatic", "Nasal", "Lacrimal", "Nasal Concha", "Malleus", "Incus", "Stapes" } do
		add("Head", "skull", side:lower() .. "_" .. name:lower():gsub(" ", "_"), side .. " " .. name)
	end
end
add("Head", "jaw", "mandible", "Jaw Bone")
add("Head", "neck", "hyoid", "Hyoid")
numbered("Head", "neck", "c", "Neck Vertebra", 1, 7)

-- Upper torso (41): 12 thoracic vertebrae, sternum, 24 ribs, collarbones, shoulder blades
numbered("UpperTorso", "spine", "t", "Back Vertebra", 1, 12)
add("UpperTorso", "ribs", "sternum", "Breastbone")
numbered("UpperTorso", "ribs", "rib_l", "Left Rib", 1, 12)
numbered("UpperTorso", "ribs", "rib_r", "Right Rib", 1, 12)
add("UpperTorso", "collar_l", "clavicle_l", "Left Collarbone")
add("UpperTorso", "collar_r", "clavicle_r", "Right Collarbone")
add("UpperTorso", "collar_l", "scapula_l", "Left Shoulder Blade")
add("UpperTorso", "collar_r", "scapula_r", "Right Shoulder Blade")

-- Lower torso (9): 5 lumbar vertebrae, sacrum, tailbone, hip bones
numbered("LowerTorso", "spine", "l", "Lower Back Vertebra", 1, 5)
add("LowerTorso", "pelvis", "sacrum", "Sacrum")
add("LowerTorso", "pelvis", "coccyx", "Tailbone")
add("LowerTorso", "pelvis", "hip_l", "Left Hip Bone")
add("LowerTorso", "pelvis", "hip_r", "Right Hip Bone")

-- Arms and legs (60 + 60)
for _, s in { { "Left", "l" }, { "Right", "r" } } do
	local side, k = s[1], s[2]
	add(side .. "UpperArm", "arm_" .. k, "humerus_" .. k, side .. " Upper Arm Bone")
	add(side .. "LowerArm", "forearm_" .. k, "radius_" .. k, side .. " Radius")
	add(side .. "LowerArm", "forearm_" .. k, "ulna_" .. k, side .. " Ulna")
	for _, name in CARPALS do
		add(side .. "Hand", "hand_" .. k, k .. "_" .. name:lower(), side .. " " .. name)
	end
	digits(side .. "Hand", "hand_" .. k, side, "hand", "Hand")

	add(side .. "UpperLeg", "leg_" .. k, "femur_" .. k, side .. " Thigh Bone")
	add(side .. "UpperLeg", "leg_" .. k, "patella_" .. k, side .. " Kneecap")
	add(side .. "LowerLeg", "shin_" .. k, "tibia_" .. k, side .. " Shin Bone")
	add(side .. "LowerLeg", "shin_" .. k, "fibula_" .. k, side .. " Fibula")
	for _, name in TARSALS do
		add(side .. "Foot", "foot_" .. k, k .. "_" .. name:lower():gsub(" ", "_"), side .. " " .. name)
	end
	digits(side .. "Foot", "foot_" .. k, side, "foot", "Foot")
end

-- Body regions (for picking medical injuries) and R6 rigs, which merge the limb parts.
local REGIONS = {
	Head = "head", UpperTorso = "torso", LowerTorso = "torso",
	LeftUpperArm = "limb", RightUpperArm = "limb", LeftLowerArm = "limb", RightLowerArm = "limb",
	LeftHand = "limb", RightHand = "limb", LeftUpperLeg = "limb", RightUpperLeg = "limb",
	LeftLowerLeg = "limb", RightLowerLeg = "limb", LeftFoot = "limb", RightFoot = "limb",
}
local R6 = {
	Torso = { "UpperTorso", "LowerTorso" },
	["Left Arm"] = { "LeftUpperArm", "LeftLowerArm", "LeftHand" },
	["Right Arm"] = { "RightUpperArm", "RightLowerArm", "RightHand" },
	["Left Leg"] = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot" },
	["Right Leg"] = { "RightUpperLeg", "RightLowerLeg", "RightFoot" },
}
for r6Part, r15Parts in R6 do
	byPart[r6Part] = {}
	for _, part in r15Parts do
		table.move(byPart[part], 1, #byPart[part], #byPart[r6Part] + 1, byPart[r6Part])
	end
	REGIONS[r6Part] = REGIONS[r15Parts[1]]
end

return {
	list = list, -- 206 bones in order
	byPart = byPart, -- body part name -> { bone ids }
	regions = REGIONS, -- body part name -> "head" | "torso" | "limb"

	-- Shapes drawn on the payout skeleton: { centreX, centreY, width, height, rotation } of the figure box.
	Groups = {
		{ id = "skull", ui = { 0.5, 0.07, 0.2, 0.1, 0 }, round = true },
		{ id = "jaw", ui = { 0.5, 0.135, 0.13, 0.035, 0 } },
		{ id = "neck", ui = { 0.5, 0.175, 0.05, 0.05, 0 } },
		{ id = "collar_l", ui = { 0.39, 0.215, 0.18, 0.025, 8 } },
		{ id = "collar_r", ui = { 0.61, 0.215, 0.18, 0.025, -8 } },
		{ id = "ribs", ui = { 0.5, 0.3, 0.28, 0.13, 0 } },
		{ id = "spine", ui = { 0.5, 0.41, 0.05, 0.1, 0 } },
		{ id = "pelvis", ui = { 0.5, 0.49, 0.28, 0.06, 0 } },
		{ id = "arm_l", ui = { 0.25, 0.32, 0.055, 0.19, 12 } },
		{ id = "arm_r", ui = { 0.75, 0.32, 0.055, 0.19, -12 } },
		{ id = "forearm_l", ui = { 0.19, 0.5, 0.05, 0.17, 6 } },
		{ id = "forearm_r", ui = { 0.81, 0.5, 0.05, 0.17, -6 } },
		{ id = "hand_l", ui = { 0.16, 0.62, 0.07, 0.055, 0 } },
		{ id = "hand_r", ui = { 0.84, 0.62, 0.07, 0.055, 0 } },
		{ id = "leg_l", ui = { 0.41, 0.63, 0.065, 0.19, 3 } },
		{ id = "leg_r", ui = { 0.59, 0.63, 0.065, 0.19, -3 } },
		{ id = "shin_l", ui = { 0.4, 0.83, 0.055, 0.18, 0 } },
		{ id = "shin_r", ui = { 0.6, 0.83, 0.055, 0.18, 0 } },
		{ id = "foot_l", ui = { 0.37, 0.95, 0.1, 0.04, 0 } },
		{ id = "foot_r", ui = { 0.63, 0.95, 0.1, 0.04, 0 } },
	},
}
