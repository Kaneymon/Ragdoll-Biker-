-- Full-screen colour flashes (client UI/ScreenFlash). start = transparency the flash begins at
-- (0 = solid colour), fade = seconds it takes to fade away. Lucky hits use these (Config/Injuries).
return {
	Lucky2 = { color = Color3.fromRGB(255, 255, 255), start = 0.15, fade = 1.2 },
	Lucky4 = { color = Color3.fromRGB(255, 200, 200), start = 0.1, fade = 2.2 },
	Lucky10 = { color = Color3.fromRGB(255, 110, 110), start = 0.05, fade = 3.6 },
}
