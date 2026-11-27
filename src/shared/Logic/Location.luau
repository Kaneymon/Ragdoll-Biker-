-- Where a player is: walking around the Lobby, riding their map's Ramp (for a payout) or riding the
-- lobby Obby. The server (Services/LocationService) sets it as a player attribute; both sides read
-- the riding rules from here.
local Location = {
	LOBBY = "Lobby",
	RAMP = "Ramp",
	OBBY = "Obby",
	ATTRIBUTE = "Location",
}

-- bail = can jump off on purpose, gear = boosters and exploders work, payout = the run is paid
local RULES = {
	Lobby = { riding = false },
	Ramp = { riding = true, bail = true, gear = true, payout = true },
	Obby = { riding = true, bail = false, gear = false, payout = false },
}

function Location.of(player)
	return player:GetAttribute(Location.ATTRIBUTE) or Location.LOBBY
end

function Location.rules(location)
	return RULES[location] or RULES.Lobby
end

return Location
