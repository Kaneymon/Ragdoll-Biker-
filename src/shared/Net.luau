-- Creates (server) or finds (client) every remote listed in Config/Remotes.
local RunService = game:GetService("RunService")
local Remotes = require(script.Parent.Config.Remotes)

local Net = {}
local folder

if RunService:IsServer() then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in Remotes.Events do
		Instance.new("RemoteEvent", folder).Name = name
	end
	for _, name in Remotes.Functions do
		Instance.new("RemoteFunction", folder).Name = name
	end
	folder.Parent = script.Parent
else
	folder = script.Parent:WaitForChild("Remotes")
end

function Net.event(name: string): RemoteEvent
	return folder:WaitForChild(name)
end

function Net.func(name: string): RemoteFunction
	return folder:WaitForChild(name)
end

return Net
