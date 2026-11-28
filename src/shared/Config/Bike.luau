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
	-- Landing bounce: the suspension springs back up after a landing, as a damped spring on the
	-- ride height. Impact = the speed into the ground (the frame before touching down) or `fall`
	-- x the straight-down speed, whichever is bigger (a slope landing barely hits the slope's
	-- normal); bounce speed = share x impact, between min (after AirTime of air) and max.
	-- About 2 studs up on a hard landing, then a smaller second bounce. Coming back down it only
	-- squashes `sag` studs below ride height (the wheels never sink into the ground), then springs
	-- back up with `rebound` of the speed it came down with.
	LandBounce = { share = 0.35, fall = 0.3, min = 9, max = 20, airTime = 0.35, stiffness = 55, damping = 3.5, sag = 0.3, rebound = 0.45 },
	-- Stopped on the bike (Ready at the top of a ramp, or riding slower than Speed and not
	-- pedalling): the rider puts a foot down (Config/Poses Stand) and the bike leans that way by
	-- Lean degrees, blending at LeanRate.
	Stand = { Speed = 2.5, Lean = 9, LeanRate = 6 },
	-- After a bail the empty bike tumbles on its own: real collisions on the frame and wheels
	-- (the wheels spin freely), with these surfaces.
	Wreck = {
		Frame = { Density = 2, Friction = 0.5, Elasticity = 0.25, FrictionWeight = 1, ElasticityWeight = 1 },
		Tyre = { Density = 1.2, Friction = 0.9, Elasticity = 0.4, FrictionWeight = 1, ElasticityWeight = 1 },
	},
	-- Ragdoll steering: Accel pushes you camera-relative, Spin tumbles you (both x control).
	-- In the air, control = Helmet airControl, rising to full (1) as speed nears FullSpeed while
	-- airControl is below 1 (Helmet level 20 = always full, like the original steering).
	-- On the ground, control = GroundShare, rising with Kneepads slide: slide == FullGroundSlide
	-- (Kneepads level 20) gives full ground control; more slide keeps going up.
	-- PoseTorque = how hard a held pose bends the limp body (ragdoll poses); PoseResponsiveness = how
	-- fast it gets there on Motor6D rigs (AnimationConstraint rigs use their own drive).
	Glide = { Accel = 110, Spin = 16, MaxSpin = 20, FullSpeed = 250, GroundShare = 0.25, FullGroundSlide = 0.36, GroundReach = 3, PoseTorque = 4000, PoseResponsiveness = 40 },
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
