-- Builds the Lobby from Config/Lobby: the floating chipboard deck with its rim, railings and
-- underside, the title sign, the shop stalls, the leaderboards, the AFK corner and the obby course.
-- What other services need is left on the model: prompts carry Window/Tab (shops, client) or
-- Travel (the obby gate, server) attributes, boards carry Board, the AFK rug is named AfkZone,
-- and the model has ObbySpawn (CFrame), ObbyLowestY and ObbyFinish (the finish line part).
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Lobby = require(Shared.Config.Lobby)
local Bike = require(Shared.Config.Bike)
local P = require(Shared.Config.Palette)
local Theme = require(Shared.Config.Theme)
local MegaRamp = require(Shared.Config.MegaRamp)
local Location = require(Shared.Logic.Location)
local Localize = require(Shared.Services.Localize)
local Build = require(script.Parent.Build)
local RampKit = require(script.Parent.RampKit)

local LobbyBuilder = {}

local RIM_PIECES = 72
local CANVAS_WIDTH = 400 -- SurfaceGui pixels across a text panel (TextScaled tops out at 100px)
local OBBY_KICKER_SEGMENTS = 8
local OBBY_GATE_DISTANCE = 30 -- how far in from the edge the obby gate stands ...
local OBBY_GATE_ANGLE = -14 -- ... and where, just beside the course
local SIDEWAYS = CFrame.Angles(0, 0, math.rad(90)) -- cylinders run along X; this stands them up

local function asset(name)
	return ServerStorage.Assets.Lobby[name]:Clone()
end

-- Point on the deck top, `angle` degrees round from +X, `distance` studs out from the centre.
local function onDeck(angle, distance)
	local a = math.rad(angle)
	return Lobby.centre + Vector3.new(math.cos(a) * distance, 0, math.sin(a) * distance)
end

-- Facing the middle of the deck (models face -Z).
local function facingCentre(position)
	return CFrame.lookAt(position, Vector3.new(Lobby.centre.X, position.Y, Lobby.centre.Z))
end

local function scaled(model, factor)
	model:ScaleTo(model:GetScale() * factor)
	return model
end

-- An invisible part with a SurfaceGui on its front; fill(gui) adds the content.
local function textPanel(parent, cframe, size, fill)
	local part = Build.decor({ Name = "Text", Size = Vector3.new(size.X, size.Y, 0.1), CFrame = cframe, Transparency = 1, Parent = parent })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(CANVAS_WIDTH, CANVAS_WIDTH * size.Y / size.X)
	gui.LightInfluence = 0
	gui.Parent = part
	fill(gui)
	return part
end

local function label(parent, text, size, position, color, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Theme.Font.Title
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = color or P.White
	l.Size, l.Position = size, position or UDim2.new()
	for key, value in props or {} do
		l[key] = value
	end
	local stroke = Instance.new("UIStroke")
	stroke.Color = P.Ink
	stroke.Thickness = 3
	stroke.Parent = l
	l.Parent = parent
	return l
end

local function prompt(parent, cframe, actionKey, objectKey, attributes)
	local part = Build.part({ Name = "Prompt", Size = Vector3.new(4, 4, 4), CFrame = cframe, Transparency = 1, CanCollide = false, CanQuery = false, Parent = parent })
	local p = Instance.new("ProximityPrompt")
	p.ActionText = Localize.get(actionKey)
	p.ObjectText = Localize.get(objectKey)
	p.HoldDuration = 0
	p.MaxActivationDistance = 16
	p.RequiresLineOfSight = false
	for key, value in attributes do
		p:SetAttribute(key, value)
	end
	p.Parent = part
	return p
end

-- Would a piece of the edge `length` studs long, centred `angle` radians round from +X at
-- `radius`, get in the way of the obby leaving the deck?
local function inObbyGap(angle, radius, length)
	local gap = (Lobby.obby.width / 2 + 2 + length / 2) / radius
	local a = math.atan2(math.sin(angle), math.cos(angle))
	return math.abs(a) < gap
end

-- Deck ---------------------------------------------------------------------------------------------
local function buildDeck(model)
	local c, r, t = Lobby.centre, Lobby.radius, Lobby.thickness
	RampKit.wood({ Name = "Deck", Shape = Enum.PartType.Cylinder, Size = Vector3.new(t, r * 2, r * 2), CFrame = CFrame.new(c - Vector3.yAxis * (t / 2)) * SIDEWAYS, Parent = model })
	local under = Lobby.underside
	local layers = { 0.92, 0.7, 0.45, 0.2 }
	local depth = under.depth / #layers
	for i, share in layers do -- a stepped cone hanging under the deck
		Build.part({ Name = "Underside", Shape = Enum.PartType.Cylinder, Size = Vector3.new(depth, r * 2 * share, r * 2 * share), CFrame = CFrame.new(c - Vector3.yAxis * (t + depth * (i - 0.5))) * SIDEWAYS, Color = under.color, Material = under.material, Parent = model })
	end
	local rim = Lobby.rim
	local length = 2 * math.pi * r / RIM_PIECES + 0.5
	for i = 0, RIM_PIECES - 1 do
		local a = (i + 0.5) / RIM_PIECES * 2 * math.pi
		if inObbyGap(a, r, length) then
			continue
		end
		local at = c + Vector3.new(math.cos(a), 0, math.sin(a)) * (r - rim.width / 2) + Vector3.yAxis * (rim.height / 2)
		Build.part({ Name = "Rim", Size = Vector3.new(rim.width, rim.height, length), CFrame = CFrame.lookAt(at, at + Vector3.new(-math.sin(a), 0, math.cos(a))), Color = rim.color, Material = rim.material, Parent = model })
	end
end

-- Mega ramp barriers all the way round, with a gap where the obby leaves.
local function buildRailing(model)
	local folder = Build.model("Railing", model)
	local spec = MegaRamp.barrier
	local radius = Lobby.radius - Lobby.rim.width - 0.6
	local count = math.floor(2 * math.pi * radius / spec.length)
	for i = 0, count - 1 do
		local a = (i + 0.5) / count * 2 * math.pi
		if not inObbyGap(a, radius, spec.length) then
			local at = Lobby.centre + Vector3.new(math.cos(a), 0, math.sin(a)) * radius + Vector3.yAxis * Lobby.rim.height
			local barrier = ServerStorage.Assets[spec.folder][spec.mesh]:Clone()
			barrier:PivotTo(CFrame.lookAt(at, at + Vector3.new(-math.sin(a), 0, math.cos(a))))
			barrier.Parent = folder
		end
	end
end

-- Signs, shops, boards, AFK -----------------------------------------------------------------------
-- A BoardFrame stand scaled to `width` with a text screen; fill(gui) draws on the screen.
local function board(parent, name, cframe, width, fill)
	local spec = Lobby.boardText
	local factor = width / spec.size.X
	local frame = scaled(asset("BoardFrame"), factor)
	frame.Name = name
	frame:PivotTo(cframe)
	frame.Parent = parent
	textPanel(frame, cframe * CFrame.new(0, spec.y * factor, spec.z * factor), spec.size * factor, fill)
	return frame
end

local function buildSign(model)
	local sign = Lobby.sign
	board(model, "TitleSign", facingCentre(onDeck(sign.angle, sign.distance)), sign.size.X, function(gui)
		label(gui, Localize.get("LOBBY_TITLE"), UDim2.fromScale(0.92, 0.62), UDim2.fromScale(0.04, 0.06), P.Sun)
		label(gui, Localize.get("LOBBY_SUBTITLE"), UDim2.fromScale(0.9, 0.24), UDim2.fromScale(0.05, 0.7), P.White)
	end)
end

local function buildStalls(model)
	local folder = Build.model("Shops", model)
	local sign = Lobby.stallSign
	for _, spec in Lobby.stalls do
		local cframe = facingCentre(onDeck(spec.angle, spec.distance or Lobby.stallDistance))
		local s = Lobby.stallScale
		local stall = scaled(asset("ShopStall"), s)
		stall:PivotTo(cframe)
		stall.Parent = folder
		textPanel(stall, cframe * CFrame.new(0, sign.y * s, sign.z * s - 0.06), sign.size * s, function(gui)
			label(gui, Localize.get(spec.nameKey), UDim2.fromScale(0.96, 0.9), UDim2.fromScale(0.02, 0.05), P.Sun)
		end)
		prompt(stall, cframe * CFrame.new(0, 4, -6 * s), "PROMPT_SHOP", spec.nameKey, { Window = spec.window, Tab = spec.tab })
	end
end

local function buildBoards(model)
	local folder = Build.model("Boards", model)
	for _, spec in Lobby.boards do
		local frame = board(folder, spec.id, facingCentre(onDeck(spec.angle, Lobby.boardDistance)), Lobby.boardWidth, function(gui)
			label(gui, Localize.get(spec.titleKey), UDim2.fromScale(0.94, 0.14), UDim2.fromScale(0.03, 0.02), P.Sun)
			local rows = Instance.new("Frame")
			rows.Name = "Rows"
			rows.BackgroundTransparency = 1
			rows.Size = UDim2.fromScale(0.92, 0.8)
			rows.Position = UDim2.fromScale(0.04, 0.18)
			rows.Parent = gui
			for i = 1, Lobby.size do
				label(rows, "", UDim2.fromScale(1, 1 / Lobby.size), UDim2.fromScale(0, (i - 1) / Lobby.size), P.White, { Name = "Row" .. i, TextXAlignment = Enum.TextXAlignment.Left })
			end
		end)
		frame:SetAttribute("Board", spec.id)
	end
end

local function buildAfk(model)
	local spec = Lobby.afk
	local folder = Build.model("Afk", model)
	local centre = onDeck(spec.angle, spec.distance)
	local rug = Build.part({ Name = "AfkZone", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, spec.radius * 2, spec.radius * 2), CFrame = CFrame.new(centre + Vector3.yAxis * 0.2) * SIDEWAYS, Color = Color3.fromRGB(70, 80, 160), Material = Enum.Material.Fabric, CanCollide = false, Parent = folder })
	local holder = Instance.new("Attachment")
	holder.Position = Vector3.new(14, 0, 0) -- (cylinder space: X is up)
	holder.Parent = rug
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromScale(26, 7)
	billboard.LightInfluence = 0
	billboard.MaxDistance = 250
	billboard.Parent = holder
	label(billboard, Localize.get("AFK_TITLE"), UDim2.fromScale(1, 0.6), nil, P.Sun)
	label(billboard, Localize.get("AFK_SUBTITLE"), UDim2.fromScale(1, 0.4), UDim2.fromScale(0, 0.6), P.White)
	for i = 1, spec.beanbags do
		local a = (i / spec.beanbags) * 2 * math.pi
		local at = centre + Vector3.new(math.cos(a), 0, math.sin(a)) * (spec.radius * 0.7)
		local bag = scaled(asset("Beanbag"), 1.4)
		bag:PivotTo(CFrame.lookAt(at, Vector3.new(centre.X, at.Y, centre.Z)))
		bag.Parent = folder
	end
end

-- Obby ---------------------------------------------------------------------------------------------
local function finishLine(parent, from, length, width)
	local at = from + Vector3.xAxis * (length / 2)
	local line = Build.part({ Name = "ObbyFinish", Size = Vector3.new(1, 8, width), CFrame = CFrame.new(at + Vector3.yAxis * 4), Color = P.Sun, Material = Enum.Material.Neon, Transparency = 0.5, CanCollide = false, Parent = parent })
	board(parent, "FinishSign", CFrame.lookAt(at + Vector3.xAxis * (length / 2 - 4), at - Vector3.xAxis * 10), width * 0.8, function(gui)
		label(gui, Localize.get("OBBY_FINISH"), UDim2.fromScale(0.9, 0.7), UDim2.fromScale(0.05, 0.15), P.Sun)
	end)
	return line
end

local function buildObby(model)
	local spec = Lobby.obby
	local folder = Build.model("Obby", model)
	local x, y = Vector3.xAxis, Vector3.yAxis
	local start = onDeck(0, Lobby.radius - 12)
	local p = RampKit.deck(folder, "ObbyStart", start, x, y, spec.start, spec.width, spec.thickness)
	local lowest, finish = p.Y, nil
	for _, piece in spec.pieces do
		if piece.kind == "slope" then
			local a = math.rad(piece.angle)
			p = RampKit.deck(folder, "ObbySlope", p, Vector3.new(math.cos(a), -math.sin(a), 0), Vector3.new(math.sin(a), math.cos(a), 0), piece.length, spec.width, spec.thickness)
		elseif piece.kind == "kicker" then
			p = RampKit.kicker(folder, p, x, spec.width, piece.radius, piece.endAngle, OBBY_KICKER_SEGMENTS, spec.thickness * 3)
		elseif piece.kind == "gap" then
			p += x * piece.length - y * piece.drop
		elseif piece.kind == "flat" then
			local from = p
			p = RampKit.deck(folder, "ObbyFlat", p, x, y, piece.length, spec.width, spec.thickness)
			if piece.finish then
				finish = finishLine(folder, from, piece.length, spec.width)
			end
		end
		lowest = math.min(lowest, p.Y)
	end
	local spawnAt = start + x * 15 + y * Bike.Hover
	model:SetAttribute("ObbySpawn", CFrame.lookAt(spawnAt, spawnAt + x))
	model:SetAttribute("ObbyLowestY", lowest)
	-- the gate on the deck: walk up and ride
	local gate = facingCentre(onDeck(OBBY_GATE_ANGLE, Lobby.radius - OBBY_GATE_DISTANCE))
	board(folder, "ObbySign", gate * CFrame.new(0, 0, 9), 14, function(gui)
		label(gui, Localize.get("OBBY_TITLE"), UDim2.fromScale(0.9, 0.6), UDim2.fromScale(0.05, 0.08), P.Sun)
		label(gui, Localize.get("OBBY_SUBTITLE"), UDim2.fromScale(0.9, 0.26), UDim2.fromScale(0.05, 0.68), P.White)
	end)
	Build.part({ Name = "ObbyPad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 12, 12), CFrame = CFrame.new(gate.Position + y * 0.15) * SIDEWAYS, Color = P.Money, Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
	prompt(folder, CFrame.new(gate.Position + y * 3), "PROMPT_RIDE", "OBBY_TITLE", { Travel = Location.OBBY })
	return finish
end

function LobbyBuilder.build(parent)
	local model = Build.model("Lobby")
	buildDeck(model)
	buildRailing(model)
	buildSign(model)
	buildStalls(model)
	buildBoards(model)
	buildAfk(model)
	local finish = buildObby(model)
	local link = Instance.new("ObjectValue")
	link.Name = "ObbyFinish"
	link.Value = finish
	link.Parent = model
	model.Parent = parent
	return model
end

return LobbyBuilder
