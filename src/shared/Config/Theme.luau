-- UI design tokens: one source for shapes, fonts and sizes so every screen matches.
return {
	Font = {
		Title = Enum.Font.FredokaOne,
		Body = Enum.Font.FredokaOne,
	},
	TextSize = { Huge = 72, Title = 44, Heading = 30, Body = 24, Small = 18 },
	Corner = UDim.new(0, 18),
	SmallCorner = UDim.new(0, 12),
	Stroke = 4,
	Padding = 14,
	ButtonHeight = 64,
	CardHeight = 130,
	TabHeight = 54,
	PanelCorner = 18, -- on-screen corner size of image panels
	WindowSize = UDim2.new(0.62, 0, 0.8, 0),
	WindowMax = Vector2.new(760, 720),
	DesignHeight = 900, -- screen height the pixel sizes are designed for
	MinScale = 0.5,
	MaxScale = 1.25,
}
