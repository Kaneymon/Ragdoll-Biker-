-- Where a player is: riding round the Lobby (and its obby) or riding their map's Ramp for a payout.
-- The server (Services/LocationService) sets it as a player attribute; both sides read the riding
-- rules from here.
local Location = {
	LOBBY = "Lobby",
	RAMP = "Ramp",
	ATTRIBUTE = "Location",
}

-- tricks = the trick / bail / boost / bomb buttons work (off in the lobby so E opens the shops),
-- bail = can jump off on purpose (and stopping for a while bails you), gear = boosters and
-- exploders work, payout = the run is paid (else stopping after a crash sends you back to the
-- lobby's middle), bump = riders collide with each other from the start (on the ramps they only
-- do once they're past their kicker, see BikeService)
local RULES = {
	Lobby = { tricks = false, bail = false, gear = false, payout = false, bump = true },
	Ramp = { tricks = true, bail = true, gear = true, payout = true, bump = false },
}

function Location.of(player)
	return player:GetAttribute(Location.ATTRIBUTE) or Location.LOBBY
end

function Location.rules(location)
	return RULES[location] or RULES.Lobby
end

return Location
