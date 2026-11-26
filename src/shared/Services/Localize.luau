-- Text lookup by key. Uses Roblox translation when a translation exists, else the English source.
local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Text = require(script.Parent.Parent.Config.Text)

local Localize = {}
local translator = nil

local function fill(source, args)
	return (string.gsub(source, "{(%d+)}", function(index)
		local value = args[tonumber(index)]
		return if value ~= nil then tostring(value) else ""
	end))
end

-- Server: publish all text keys as a LocalizationTable so Roblox can translate them.
function Localize.publishTable()
	local entries = {}
	for key, source in Text do
		table.insert(entries, { Key = key, Source = source, Context = "", Example = "", Values = {} })
	end
	local tableInstance = Instance.new("LocalizationTable")
	tableInstance.Name = "GameText"
	tableInstance:SetEntries(entries)
	tableInstance.Parent = LocalizationService
end

-- Client: pick up the player's translator (falls back to English if unavailable).
function Localize.init()
	if RunService:IsClient() then
		local ok, result = pcall(LocalizationService.GetTranslatorForPlayerAsync, LocalizationService, Players.LocalPlayer)
		if ok then
			translator = result
		end
	end
end

function Localize.get(key: string, ...): string
	local args = { ... }
	for i, value in args do
		args[i] = tostring(value) -- the translator would otherwise reformat numbers ("1" -> "1.00")
	end
	if translator then
		local ok, translated = pcall(translator.FormatByKey, translator, key, args)
		if ok and translated then
			return translated
		end
	end
	return fill(Text[key] or key, args)
end

return Localize
