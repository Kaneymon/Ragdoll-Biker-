-- SFX hooks. Put "rbxassetid://123" strings in ids; several ids = random pick each play.
-- Empty ids play nothing, so every hook is safe to call before audio exists.
return {
	Click = { ids = {}, volume = 0.5 },
	Purchase = { ids = {}, volume = 0.6 },
	Error = { ids = {}, volume = 0.5 },
	Pedal = { ids = {}, volume = 0.4, loop = true },
	Wind = { ids = {}, volume = 0.5, loop = true },
	Hop = { ids = {}, volume = 0.5 },
	Land = { ids = {}, volume = 0.6 },
	Crash = { ids = {}, volume = 0.8 },
	Trick = { ids = {}, volume = 0.6 },
	Bail = { ids = {}, volume = 0.7 },
	BoneCrack = { ids = {}, volume = 0.8, pitch = { 0.9, 1.15 } },
	Squelch = { ids = {}, volume = 0.7, pitch = { 0.85, 1.1 } },
	Thud = { ids = {}, volume = 0.7, pitch = { 0.8, 1.2 } },
	Groan = { ids = {}, volume = 0.7, pitch = { 0.9, 1.1 } },
	Boost = { ids = {}, volume = 0.6, loop = true },
	Explosion = { ids = {}, volume = 0.9 },
	Payout = { ids = {}, volume = 0.7 },
	CashOut = { ids = {}, volume = 0.8 },
	Offer = { ids = {}, volume = 0.6 },
}
