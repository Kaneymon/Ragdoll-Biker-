-- In-run HUD: money/level, menu buttons, trick multiplier, speed, bail prompt, boost, injury feed, toasts.
-- Kept big and sparse: each element only shows in the phases where it matters.
-- Layout keeps clear of Roblox's own buttons (screens use CoreUISafeInsets) and of the
-- phone thumbstick (bottom left) and jump/action buttons (bottom right): info sits along the top
-- and right edge, menus on the left, prompts in the middle.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ground = require(Shared.Logic.Ground)
local P = require(Shared.Config.Palette)
local Theme = require(Shared.Config.Theme)
local Progression = require(Shared.Logic.Progression)
local Format = require(Shared.Util.Format)
local Localize = require(Shared.Services.Localize)
local State = require(script.Parent.Parent.State)
local Input = require(script.Parent.Parent.Controllers.Input)
local BikeController = require(script.Parent.Parent.Controllers.BikeController)
local GearController = require(script.Parent.Parent.Controllers.GearController)
local RagdollController = require(script.Parent.Parent.Controllers.RagdollController)
local Session = require(script.Parent.Parent.Controllers.Session)
local Location = require(Shared.Logic.Location)
local Ragdoll = require(Shared.Logic.Ragdoll)
local UiKit = require(script.Parent.UiKit)
local Window = require(script.Parent.Window)

local Hud = {}

local FEED_MAX = 6
local FEED_LIFETIME = 3
local TOAST_TIME = 2
local TRICK_TOAST_TIME = 1.2
local BAIL_LOOKAHEAD = 0.9
local FADE = TweenInfo.new(0.4)
local IN_RUN = { Riding = true, Air = true, Ragdoll = true }
local PROMPT_ORDER = 30 -- the "press W to ride" prompt draws above menus and popups

local ui = {}
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

local function anchored(props, x, y)
	props.AnchorPoint = Vector2.new(x, y)
	return props
end

local function buildTopLeft(gui)
	ui.money = UiKit.panel({ Size = UDim2.fromOffset(240, 60), Position = UDim2.fromOffset(16, 16), BackgroundColor3 = P.Money, Parent = gui })
	UiKit.icon("coin", { Size = UDim2.fromOffset(70, 70), Position = UDim2.new(0, -18, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Parent = ui.money })
	ui.moneyText = UiKit.label({ text = "$0", style = "Heading", color = P.White, outline = true, Size = UDim2.new(1, -56, 1, 0), Position = UDim2.fromOffset(52, 0), Parent = ui.money })
	ui.level = UiKit.panel({ Size = UDim2.fromOffset(140, 60), Position = UDim2.fromOffset(270, 16), BackgroundColor3 = P.Grape, Parent = gui })
	UiKit.icon("star", { Size = UDim2.fromOffset(64, 64), Position = UDim2.new(0, -14, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Parent = ui.level })
	ui.levelText = UiKit.label({ key = "HUD_LEVEL", args = { 1 }, style = "Heading", color = P.White, outline = true, Size = UDim2.new(1, -46, 1, 0), Position = UDim2.fromOffset(44, 0), Parent = ui.level })
end

local function buildMenu(gui, windows)
	ui.menu = Instance.new("Frame")
	ui.menu.BackgroundTransparency = 1
	ui.menu.Size = UDim2.fromOffset(280, 520)
	ui.menu.Position = UDim2.fromOffset(16, 96)
	ui.menu.Parent = gui
	UiKit.listLayout(ui.menu, nil, 14, Enum.HorizontalAlignment.Left)
	-- PLAY in the lobby takes you to your ramp; LOBBY on the ramp (or obby) takes you back
	ui.play = UiKit.button({ key = "BTN_PLAY", color = P.Money, style = "Title", Size = UDim2.fromOffset(280, 100), LayoutOrder = 0, Parent = ui.menu, onClick = function()
		Session.travel(Location.RAMP)
	end })
	ui.lobby = UiKit.button({ key = "BTN_LOBBY", color = P.Orange, Size = UDim2.fromOffset(230, 70), LayoutOrder = 4, Parent = ui.menu, onClick = function()
		Session.travel(Location.LOBBY)
	end })
	UiKit.button({ key = "BTN_UPGRADES", color = P.Sun, style = "Title", Size = UDim2.fromOffset(280, 110), LayoutOrder = 1, Parent = ui.menu, onClick = function()
		windows.upgrades:toggle()
	end })
	UiKit.button({ key = "BTN_STORE", color = P.Grape, Size = UDim2.fromOffset(230, 70), LayoutOrder = 2, Parent = ui.menu, onClick = function()
		windows.store:toggle()
	end })
	UiKit.button({ key = "BTN_SETTINGS", color = P.Sky, Size = UDim2.fromOffset(230, 70), LayoutOrder = 3, Parent = ui.menu, onClick = function()
		windows.settings:toggle()
	end })
end

local function buildCentre(gui)
	ui.mult = UiKit.label(anchored({ text = "x1", style = "Huge", color = P.Sun, outline = true, Size = UDim2.fromOffset(400, 90), Position = UDim2.new(0.5, 0, 0, 20), Parent = gui }, 0.5, 0))
	ui.trick = UiKit.label(anchored({ text = "", style = "Heading", color = P.White, outline = true, Size = UDim2.fromOffset(500, 44), Position = UDim2.new(0.5, 0, 0, 110), Parent = gui }, 0.5, 0))
	ui.start = UiKit.label(anchored({ key = "HUD_START", style = "Title", color = P.White, outline = true, Size = UDim2.fromOffset(700, 60), Position = UDim2.new(0.5, 0, 1, -24), Parent = UiKit.screen("StartPrompt", PROMPT_ORDER) }, 0.5, 1))
	ui.bail = UiKit.panel(anchored({ Size = UDim2.fromOffset(620, 96), Position = UDim2.fromScale(0.5, 0.55), BackgroundColor3 = P.Coral, Visible = false, Parent = gui }, 0.5, 0.5))
	ui.bailText = UiKit.label({ key = "HUD_BAIL", style = "Title", color = P.White, outline = true, Size = UDim2.fromScale(1, 1), Parent = ui.bail })
	ui.toast = UiKit.panel(anchored({ Size = UDim2.fromOffset(520, 64), Position = UDim2.new(0.5, 0, 0, 160), BackgroundColor3 = P.Panel, Visible = false, Parent = gui }, 0.5, 0))
	ui.toastText = UiKit.label({ text = "", style = "Heading", Size = UDim2.fromScale(1, 1), Parent = ui.toast })
end

local function buildBottom(gui)
	ui.speed = UiKit.panel(anchored({ Size = UDim2.fromOffset(180, 90), Position = UDim2.new(1, -16, 0, 16), BackgroundColor3 = P.Sky, Parent = gui }, 1, 0))
	ui.speedText = UiKit.label({ text = "0", style = "Title", color = P.White, outline = true, Size = UDim2.new(1, 0, 0.65, 0), Parent = ui.speed })
	UiKit.label({ key = "HUD_SPEED", style = "Small", color = P.White, outline = true, Size = UDim2.new(1, 0, 0.35, 0), Position = UDim2.fromScale(0, 0.62), Parent = ui.speed })

	ui.gear = Instance.new("Frame")
	ui.gear.BackgroundTransparency = 1
	ui.gear.Size = UDim2.fromOffset(260, 100)
	ui.gear.Position = UDim2.new(1, -16, 0, 120)
	ui.gear.AnchorPoint = Vector2.new(1, 0)
	ui.gear.Parent = gui
	UiKit.label({ key = "HUD_BOOST", style = "Small", color = P.White, outline = true, Size = UDim2.new(1, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Right, Parent = ui.gear })
	ui.boostBar, ui.setBoost = UiKit.bar({ Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, 26), color = P.Orange, Parent = ui.gear })
	ui.boom = UiKit.label({ key = "HUD_BOOM", args = { 1 }, style = "Heading", color = P.Sun, outline = true, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 58), TextXAlignment = Enum.TextXAlignment.Right, Parent = ui.gear })
end

local function buildFeed(gui)
	ui.feed = Instance.new("Frame")
	ui.feed.BackgroundTransparency = 1
	ui.feed.Size = UDim2.fromOffset(300, 420)
	ui.feed.Position = UDim2.new(1, -16, 0, 230)
	ui.feed.AnchorPoint = Vector2.new(1, 0)
	ui.feed.Parent = gui
	UiKit.listLayout(ui.feed, nil, 8, Enum.HorizontalAlignment.Right)
end

-- Updates --------------------------------------------------------------------
local function refreshProfile(profile)
	ui.moneyText.Text = Format.money(profile.money)
	UiKit.setText(ui.levelText, "HUD_LEVEL", (Progression.level(profile.totalEarned)))
	local booster = Progression.equippedBooster(profile)
	ui.boostBar.Visible = booster ~= nil
	ui.gear.Visible = State.rules().gear == true and (booster ~= nil or (Progression.equippedExploder(profile)) ~= nil)
end

local function refreshPhase(phase)
	if phase == "Riding" then
		Window.closeAll() -- riding off closes any open menu
	end
	if State.profile then
		refreshProfile(State.profile) -- what's shown can depend on where you are (gear on the obby)
	end
	ui.menu.Visible = phase == "Ready" or phase == "Lobby"
	ui.play.Visible = phase == "Lobby"
	ui.lobby.Visible = phase == "Ready"
	ui.start.Visible = phase == "Ready"
	ui.speed.Visible = IN_RUN[phase] == true
	ui.mult.Visible = IN_RUN[phase] == true and #State.run.tricks > 0
	ui.feed.Visible = phase == "Ragdoll" or phase == "Resting"
	if phase ~= "Air" then
		ui.bail.Visible = false
	end
	if phase == "Ready" then
		UiKit.clear(ui.feed)
		UiKit.setText(ui.start, if Input.device() == "touch" then "HUD_START_TOUCH" else "HUD_START")
	end
end

-- Hide a label after a delay, unless it was shown again in the meantime.
local function hideLater(label, delay)
	local shownAt = os.clock()
	label:SetAttribute("ShownAt", shownAt)
	task.delay(delay, function()
		if label:GetAttribute("ShownAt") == shownAt then
			label.Visible = false
		end
	end)
end

local function onTrick(def, bonus, multiplier)
	ui.mult.Text = Localize.get("HUD_MULT", Format.mult(multiplier))
	ui.mult.Visible = true
	UiKit.pop(ui.mult)
	ui.trick.Text = Localize.get("HUD_TRICK", Localize.get(def.nameKey), Format.mult(bonus))
	ui.trick.Visible = true
	UiKit.pop(ui.trick)
	hideLater(ui.trick, TRICK_TOAST_TIME)
end

local function onImpact(_part, _speed, result)
	if not result.injury then
		return
	end
	local entry = UiKit.panel({ Size = UDim2.fromOffset(280, 48), BackgroundColor3 = P.Panel, LayoutOrder = -math.floor(os.clock() * 100), corner = Theme.SmallCorner })
	local label = UiKit.label({ key = result.injury.nameKey, style = "Body", color = if result.severity >= 1 then P.Danger else P.Ink, Size = UDim2.fromScale(1, 1), Parent = entry })
	entry.Parent = ui.feed
	UiKit.pop(entry)
	task.delay(FEED_LIFETIME, function()
		TweenService:Create(entry, FADE, { ImageTransparency = 1 }):Play()
		TweenService:Create(label, FADE, { TextTransparency = 1 }):Play()
		task.wait(FADE.Time)
		entry:Destroy()
	end)
	local entries = {}
	for _, child in ui.feed:GetChildren() do
		if child:IsA("Frame") then
			table.insert(entries, child)
		end
	end
	if #entries > FEED_MAX then
		table.sort(entries, function(a, b)
			return a.LayoutOrder > b.LayoutOrder
		end)
		entries[1]:Destroy()
	end
end

local toastId = 0
local function onNotify(key, ...)
	toastId += 1
	local id = toastId
	ui.toastText.Text = Localize.get(key, ...)
	ui.toast.Visible = true
	UiKit.pop(ui.toast)
	task.delay(TOAST_TIME, function()
		if toastId == id then
			ui.toast.Visible = false
		end
	end)
end

local function bailPromptKey()
	local device = Input.device()
	return if device == "touch" then "HUD_BAIL_TOUCH" elseif device == "console" then "HUD_BAIL_PAD" else "HUD_BAIL"
end

local function nearGround(chassis)
	local velocity = chassis.AssemblyLinearVelocity
	if velocity.Y >= 0 then
		return false
	end
	rayParams.FilterDescendantsInstances = Ground.instances()
	return workspace:Raycast(chassis.Position, velocity * BAIL_LOOKAHEAD, rayParams) ~= nil
end

local function step()
	local phase = State.phase
	if IN_RUN[phase] then
		local character = RagdollController.character()
		local moving = BikeController.chassis() or (character and Ragdoll.core(character))
		ui.speedText.Text = Format.number(if moving then moving.AssemblyLinearVelocity.Magnitude else 0)
	end
	if phase == "Air" then
		local chassis = BikeController.chassis()
		local show = chassis ~= nil and nearGround(chassis)
		if show and not ui.bail.Visible then
			UiKit.setText(ui.bailText, bailPromptKey())
			UiKit.pop(ui.bail)
		end
		ui.bail.Visible = show
	end
	local bombs = GearController.bombsLeft()
	UiKit.setText(ui.boom, if bombs > 0 then "HUD_BOOM" else "HUD_BOOM_USED", bombs)
end

function Hud.create(windows)
	local gui = UiKit.screen("Hud", 1)
	buildTopLeft(gui)
	buildMenu(gui, windows)
	buildCentre(gui)
	buildBottom(gui)
	buildFeed(gui)
	refreshPhase(State.phase)
	if State.profile then
		refreshProfile(State.profile)
	end

	State.ProfileChanged:Connect(refreshProfile)
	State.PhaseChanged:Connect(refreshPhase)
	State.Trick:Connect(onTrick)
	State.Impact:Connect(onImpact)
	State.Notify:Connect(onNotify)
	State.LuckyHit:Connect(function(lucky, nameKey, extra)
		onNotify("LUCKY_NOTE", Localize.get(nameKey), lucky.mult, Format.money(extra))
	end)
	State.BoostChanged:Connect(function(_, fraction)
		ui.setBoost(fraction)
	end)
	State.RunReset:Connect(function()
		ui.mult.Text = Localize.get("HUD_MULT", 1)
	end)
	RunService.RenderStepped:Connect(step)
end

return Hud
