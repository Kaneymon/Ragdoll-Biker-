-- Modal window with a title, close button, optional tab row and a single-column scroll list.
-- Only one window is open at a time.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared.Config.Theme)
local P = require(Shared.Config.Palette)
local Assets = require(Shared.Config.UiAssets)
local Sfx = require(Shared.Services.Sfx)
local UiKit = require(script.Parent.UiKit)

local Window = {}
Window.__index = Window

local TITLE_HEIGHT = 70
local TAB_HEIGHT = 54
local openWindow = nil
local gui = nil

local function screen()
	gui = gui or UiKit.screen("Windows", 10)
	return gui
end

-- options: titleKey, banner (UiAssets.Banners colour), tabs = { { id, key } }, render(window, tabId)
function Window.new(options)
	local self = setmetatable({ options = options, tab = options.tabs and options.tabs[1].id, tabButtons = {} }, Window)
	local root = UiKit.panel({ Name = options.titleKey, Size = Theme.WindowSize, Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, Parent = screen() })
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Theme.WindowMax
	limit.Parent = root
	self.root = root

	-- curved banner from the GUI pack, sitting over the top edge of the window
	local header = Instance.new("ImageLabel")
	header.BackgroundTransparency = 1
	header.Image = Assets.Banners[options.banner or "blue"]
	header.Size = UDim2.new(0.8, 0, 0, TITLE_HEIGHT + 20)
	header.Position = UDim2.new(0.5, 0, 0, -26)
	header.AnchorPoint = Vector2.new(0.5, 0)
	header.ZIndex = 2
	header.Parent = root
	local title = UiKit.label({ key = options.titleKey, style = "Title", color = P.White, outline = true, Size = UDim2.new(1, -40, 0.7, 0), Position = UDim2.fromScale(0.5, 0.42), AnchorPoint = Vector2.new(0.5, 0.5), Parent = header })
	title.ZIndex = 3
	UiKit.closeButton({ Position = UDim2.new(1, 14, 0, -14), AnchorPoint = Vector2.new(1, 0), Parent = root, onClick = function()
		self:close()
	end })

	local top = TITLE_HEIGHT + 10
	if options.tabs then
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, -20, 0, TAB_HEIGHT)
		row.Position = UDim2.fromOffset(10, top)
		row.Parent = root
		local layout = UiKit.listLayout(row, Enum.FillDirection.Horizontal, 8)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		for i, tab in options.tabs do
			self.tabButtons[tab.id] = UiKit.button({ key = tab.key, style = "Body", color = P.Sky, LayoutOrder = i, Size = UDim2.new(1 / #options.tabs, -8, 1, 0), Parent = row, onClick = function()
				self:select(tab.id)
			end })
		end
		top += TAB_HEIGHT + 10
	end

	self.body = UiKit.scrollList({ Size = UDim2.new(1, -20, 1, -top - 10), Position = UDim2.fromOffset(10, top), Parent = root })
	return self
end

function Window:select(tabId)
	self.tab = tabId
	for id, button in self.tabButtons do
		UiKit.recolour(button, if id == tabId then P.Sun else P.Sky)
	end
	self:refresh()
end

function Window:refresh()
	if self.root.Visible then
		UiKit.clear(self.body)
		self.options.render(self, self.tab)
	end
end

function Window:open()
	local previous = openWindow
	openWindow = self
	if previous and previous ~= self then
		previous:close() -- quietly: switching windows only plays the open sound
	end
	if not self.root.Visible then
		Sfx.play("WindowOpen")
	end
	self.root.Visible = true
	if self.tab then
		self:select(self.tab)
	else
		self:refresh()
	end
	UiKit.pop(self.root)
end

function Window:close()
	if self.root.Visible and openWindow == self then
		Sfx.play("WindowClose")
	end
	self.root.Visible = false
	if openWindow == self then
		openWindow = nil
	end
end

function Window:toggle()
	if self.root.Visible then
		self:close()
	else
		self:open()
	end
end

function Window.closeAll()
	if openWindow then
		openWindow:close()
	end
end

return Window
