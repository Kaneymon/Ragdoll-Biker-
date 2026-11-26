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

local function handler(name)
	return function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			down[name] = true
			Input.Began:Fire(name)
		elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			down[name] = false
			Input.Ended:Fire(name)
		end
		return Enum.ContextActionResult.Sink
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

function Input.start()
	for _, action in Controls.actions do
		ContextActionService:BindAction(action.name, handler(action.name), action.touch, table.unpack(action.keys))
		if action.touch then
			ContextActionService:SetTitle(action.name, Localize.get(action.nameKey))
		end
	end
end

return Input
