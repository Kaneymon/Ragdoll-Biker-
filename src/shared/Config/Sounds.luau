-- SFX hooks. Put "rbxassetid://123" strings in ids; several ids = random pick each play.
-- Empty ids play nothing, so every hook is safe to call before audio exists.
-- Sources (assets/sound effects): UI = JDSherbert Ultimate UI SFX, gore = free gore foley pack,
-- grunts = Damage Grunt (Male), everything else = Fantasy Arena SFX.
local function ids(...)
	local list = {}
	for _, id in { ... } do
		table.insert(list, "rbxassetid://" .. id)
	end
	return list
end

return {
	Click = { ids = ids("105755889781423"), volume = 0.5 }, -- UI Select 1
	Purchase = { ids = ids("134494267213862"), volume = 0.6 }, -- Arena_Power_Up
	Error = { ids = ids("91648768815102"), volume = 0.5 }, -- UI Error 1
	WindowOpen = { ids = ids("72774655718013"), volume = 0.5 }, -- UI Popup Open
	WindowClose = { ids = ids("130418978017978"), volume = 0.5 }, -- UI Popup Close
	Pedal = { ids = {}, volume = 0.4, loop = true },
	Wind = { ids = ids("78670048950508"), volume = 0.5, loop = true }, -- Magic_Wind_Loop
	Launch = { ids = ids("120617048502957"), volume = 0.5 }, -- Magic_Whoosh
	Land = { ids = ids("130723557063484"), volume = 0.6 }, -- Arena_Skid
	Crash = { ids = ids("117467964555413"), volume = 0.8 }, -- Battle_Impact_Heavy
	Trick = { ids = ids("115404170242618"), volume = 0.6 }, -- Arena_Whoosh
	Bail = { ids = ids("98663860953691"), volume = 0.7 }, -- Arena_Slow_Motion
	BoneCrack = { ids = ids("76572604561188", "137912114915187", "104146365066215", "109357400048916", "85385024338853"), volume = 0.8, pitch = { 0.9, 1.15 } }, -- gore 003/008/010/040/045
	Squelch = { ids = ids("120852587553857", "80226458676648", "121242055853531", "131954625148173"), volume = 0.7, pitch = { 0.85, 1.1 } }, -- gore 014/022/032/035
	Thud = { ids = ids("111068195938664", "98059287598452"), volume = 0.7, pitch = { 0.8, 1.2 } }, -- Battle_Thud, Magic_Thud
	Groan = { ids = ids("87768980894038", "77664630002399", "93342632400929", "104631339647053", "79075811073146", "121480205792446"), volume = 0.7, pitch = { 0.9, 1.1 } }, -- grunts 01/03/05/08/10/14
	Boost = { ids = ids("133159386079842"), volume = 0.6, loop = true }, -- Magic_Beam_Loop
	Explosion = { ids = ids("126659239623111"), volume = 0.9 }, -- Magic_Impact_Fire
	Payout = { ids = ids("127193298097640"), volume = 0.7 }, -- Arena_Confetti_Pop
	CashOut = { ids = ids("99459759624120"), volume = 0.8 }, -- Arena_Victory
	Offer = { ids = ids("72774655718013"), volume = 0.6 }, -- UI Popup Open
	Lucky = { ids = ids("108250426852713"), volume = 0.8 }, -- Magic_Shatter
	LuckyBig = { ids = ids("87535083560358"), volume = 0.9 }, -- Arena_Roar
}
