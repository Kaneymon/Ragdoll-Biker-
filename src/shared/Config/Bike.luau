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
	LaunchPopPerSpeed = 0.22, -- extra launch speed off a kicker per stud/s of entry speed
	AutoBailIdle = 3, -- seconds stopped on the bike before auto-bail
	-- Ragdoll steering: Accel pushes you camera-relative, Spin tumbles you (both x Helmet glideControl).
	-- Control grows with speed up to FullSpeed (from MinShare at a standstill) and drops to
	-- GroundShare while touching the ground.
	Glide = { Accel = 110, Spin = 16, MaxSpin = 20, FullSpeed = 250, MinShare = 0.15, GroundShare = 0.25, GroundReach = 3 },
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
