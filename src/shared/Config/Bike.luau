-- Base bike handling. Upgrades (BikeUpgrades.luau) scale the stats marked "upgradable".
return {
	Hover = 2.2, -- chassis centre height above the ground
	RayLength = 5,
	Spring = 18, -- how hard the bike sticks to the ground
	GravityScale = 1.0, -- how much slopes speed you up
	PedalAccel = 45,
	BrakeDecel = 90,
	RollingDrag = 3,
	AirDrag = 0.00012, -- quadratic drag on the ground
	MaxSpeed = 1500,
	TurnRate = 1.8, -- radians/sec at low speed
	TurnFalloff = 120, -- higher = keeps turning at speed
	AirSpin = { Pitch = 5.0, Roll = 4.2, Response = 9, AutoLevel = 3 }, -- Pitch/Roll multiplied by spinSpeed
	CrashAngle = 55, -- degrees off upright on landing = crash
	SideslipAngle = 70, -- degrees between bike and travel direction = crash
	LeaveGroundGrace = 0.25,
	-- Bunnyhop (where Logic/Location allows it, the lobby): hold Hop to crouch, let go to pop.
	-- Pop speed goes from Min (a tap) to Max (held for ChargeTime) plus PedalShare x the Pedals
	-- jumpHeight; Max is about a second of air, enough for a tailwhip or a quick flip.
	-- Crouch = studs the bike sinks at full charge, NoseUp/NoseTime = the front-wheel-first lift,
	-- Level = how fast the bike levels out after that with no flip input, Spin = flips spin this
	-- much faster off a hop (so a full hop has time for a flip).
	Hop = { Min = 45, Max = 90, ChargeTime = 0.35, PedalShare = 0.2, Crouch = 0.9, NoseUp = 5, NoseTime = 0.14, Level = 6, Spin = 2 },
	LaunchPopPerSpeed = 0.22, -- extra launch speed off a kicker per stud/s of entry speed
	PedalGearRatio = 2.2, -- wheel turns per pedal turn (pedals only spin while pedalling)
	PedalMaxSpin = 14, -- radians/sec cap so pedals stay readable at high speed
	AutoBailIdle = 3, -- seconds stopped on the bike before auto-bail (where bailing is allowed)
	-- Landing bounce: the suspension springs (studs/s of landing speed -> bounce speed, capped),
	-- as a damped spring on the ride height (a hard landing lifts it about a stud).
	LandBounce = { share = 0.25, max = 14, stiffness = 70, damping = 6 },
	-- Ragdoll steering: Accel pushes you camera-relative, Spin tumbles you (both x control).
	-- In the air, control = Helmet airControl, rising to full (1) as speed nears FullSpeed while
	-- airControl is below 1 (Helmet level 20 = always full, like the original steering).
	-- On the ground, control = GroundShare, rising with Kneepads slide: slide == FullGroundSlide
	-- (Kneepads level 20) gives full ground control; more slide keeps going up.
	-- PoseTorque = how hard a held pose bends the limp body (ragdoll poses).
	Glide = { Accel = 110, Spin = 16, MaxSpin = 20, FullSpeed = 250, GroundShare = 0.25, FullGroundSlide = 0.36, GroundReach = 3, PoseTorque = 4000 },
	Rest = { Speed = 4, Time = 1.2, MaxTime = 30, FallBelowMap = 150 },
	-- Ragdoll body surface (Kneepads lower the friction, Body Armour raises the bounce).
	RagdollPhysics = { Density = 0.9, Friction = 1.2, Elasticity = 0.15, FrictionWeight = 5, ElasticityWeight = 1 },
	-- Upgradable stats and their starting values (see BikeUpgrades.luau).
	Base = {
		trickSpeed = 1,
		spinSpeed = 1,
		jumpHeight = 35,
		cycleSpeed = 70,
		trickBonus = 0,
		bailForce = 30,
	},
}
