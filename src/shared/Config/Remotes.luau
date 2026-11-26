-- Every remote the game uses. Net.luau creates/looks these up by name.
return {
	Events = {
		"ProfileChanged", -- server -> client: full profile snapshot
		"Bail", -- client -> server: rider left the bike (trick ids)
		"Impacts", -- client -> server: batch of ragdoll impacts
		"RunFinished", -- client -> server: ragdoll came to rest
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
	},
}
