-- Every remote the game uses. Net.luau creates/looks these up by name.
return {
	Events = {
		"ProfileChanged", -- server -> client: full profile snapshot
		"Bail", -- client -> server: rider left the bike (trick ids)
		"Impacts", -- client -> server: batch of ragdoll hurts { part, speed, kind = nil | "contact" | "blast" }
		"RunFinished", -- client -> server: ragdoll came to rest (ragdoll pose trick ids)
		"LuckyHit", -- server -> client: a lucky hit (modifier id, name text key, extra money)
		"BombUsed", -- client -> server: an exploder bomb went off (hide one from the belt)
		"PayoutReady", -- server -> client: insurance sheet
		"Notify", -- server -> client: short message key
	},
	Functions = {
		"GetProfile",
		"Purchase",
		"Equip",
		"SelectMap",
		"SetSetting",
		"CashOut",
		"PromptRobux",
		"TogglePass", -- switch an owned gamepass on/off
		"Travel", -- go to the Lobby or your Ramp (Logic/Location)
	},
}
