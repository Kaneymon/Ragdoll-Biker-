-- Input actions from Config/Controls (keyboard, gamepad and touch buttons in one place),
-- plus the move stick: keyboard keys directly, gamepad/touch sticks via the default controls.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Controls = require(Shared.Config.Controls)
local Localize = require(Shared.Services.Localize)
local Signal = require(Shared.Util.Signal)
local State = require(script.Parent.Parent.State)

local Input = { Began = Signal.new(), Ended = Signal.new() }

local KEYS = { -- key -> { x, z }
	[Enum.KeyCode.W] = { 0, -1 },
	[Enum.KeyCode.Up] = { 0, -1 },
	[Enum.KeyCode.S] = { 0, 1 },
	[Enum.KeyCode.Down] = { 0, 1 },
	[Enum.KeyCode.A] = { -1, 0 },
	[Enum.KeyCode.Left] = { -1, 0 },
	[Enum.KeyCode.D] = { 1, 0 },
	[Enum.KeyCode.Right] = { 1, 0 },
}

local down = {}
local bound = {} -- action name -> true while bound

local AIR_PHASES = { Air = true, Ragdoll = true }

local function handler(action)
	local name = action.name
	return function(_, inputState, input)
		-- air-only keys pass through on the ground (E reaches the lobby shop prompts); touch
		-- buttons are ours alone, so they always count
		local pass = action.airOnly and not AIR_PHASES[State.phase] and input.UserInputType ~= Enum.UserInputType.Touch
		if inputState == Enum.UserInputState.Begin then
			down[name] = true
			Input.Began:Fire(name)
		elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			down[name] = false
			Input.Ended:Fire(name)
		end
		return if pass then Enum.ContextActionResult.Pass else Enum.ContextActionResult.Sink
	end
end

local function keyboardMove()
	if UserInputService:GetFocusedTextBox() then
		return Vector3.zero
	end
	local x, z = 0, 0
	for key, dir in KEYS do
		if UserInputService:IsKeyDown(key) then
			x += dir[1]
			z += dir[2]
		end
	end
	return Vector3.new(math.clamp(x, -1, 1), 0, math.clamp(z, -1, 1))
end

-- Gamepad and touch sticks: the default controls still feed Humanoid.MoveDirection
-- (world space, camera relative), so turn it back into stick space.
local function stickMove()
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.MoveDirection.Magnitude < 0.05 then
		return Vector3.zero
	end
	local camera = workspace.CurrentCamera.CFrame
	local look = Vector3.new(camera.LookVector.X, 0, camera.LookVector.Z).Unit
	local right = Vector3.new(camera.RightVector.X, 0, camera.RightVector.Z).Unit
	return Vector3.new(humanoid.MoveDirection:Dot(right), 0, -humanoid.MoveDirection:Dot(look))
end

-- Move stick: X = steer (-1 left .. 1 right), Z = -1 forward (W) .. 1 back (S).
function Input.move(): Vector3
	local keys = keyboardMove()
	return if keys.Magnitude > 0 then keys else stickMove()
end

function Input.isDown(name: string): boolean
	return down[name] == true
end

function Input.device(): string
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "touch"
	elseif UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
		return "console"
	end
	return "pc"
end

-- Bind the riding actions the Logic/Location rules allow here (nil = none, e.g. while walking).
-- Unbound keys fall through, so Space jumps and E opens shop prompts when nothing takes them.
function Input.setRules(rules)
	for _, action in Controls.actions do
		local want = rules ~= nil and (action.rule == nil or rules[action.rule] == true)
		if want and not bound[action.name] then
			ContextActionService:BindAction(action.name, handler(action), action.touch, table.unpack(action.keys))
			if action.touch then
				ContextActionService:SetTitle(action.name, Localize.get(action.nameKey))
			end
		elseif not want and bound[action.name] then
			ContextActionService:UnbindAction(action.name)
			if down[action.name] then
				down[action.name] = false
				Input.Ended:Fire(action.name)
			end
		end
		bound[action.name] = want or nil
	end
end

function Input.start()
	Input.setRules(State.rules())
end

return Input
