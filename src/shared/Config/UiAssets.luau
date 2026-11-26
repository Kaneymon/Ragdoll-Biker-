-- Images from the Basic GUI Bundle (assets/GUI/Basic_GUI_Bundle.zip), uploaded to Roblox.
-- slice = the stretchable middle of a 9-slice image in pixels of the uploaded image (Roblox shrinks
-- uploads to 1024 px wide: Box 1510 -> 1024, Pill 1159 -> 1024); radius = its corner size.
return {
	Box = { image = "rbxassetid://85284961757670", slice = Rect.new(95, 95, 929, 929), radius = 95 }, -- white, tinted per use
	Pill = { image = "rbxassetid://118148846335115", slice = Rect.new(159, 154, 865, 162), radius = 158 }, -- white, tinted per use
	Pills = { -- ready-made coloured buttons (same shape as Pill)
		green = "rbxassetid://97723939025294",
		blue = "rbxassetid://123977359820336",
		orange = "rbxassetid://119837585646076",
		grey = "rbxassetid://139377516166348",
	},
	Banners = { -- curved window headers
		blue = "rbxassetid://134121849765526",
		green = "rbxassetid://106388791932569",
		orange = "rbxassetid://123375814550165",
		red = "rbxassetid://96068567202568",
	},
	Icons = {
		coin = "rbxassetid://100176258221276",
		star = "rbxassetid://124379504804882",
		lock = "rbxassetid://129332880753717",
		cross = "rbxassetid://109481817701636",
		closeCircle = "rbxassetid://82920361589628",
		shop = "rbxassetid://140548033078089",
		menu = "rbxassetid://125369633556860",
	},
}
