-- Rider poses: joint rotations in degrees {x, y, z} on top of the rig's rest pose, plus where the
-- rider sits relative to the bike chassis. The client blends smoothly between poses.
-- Angles are in the parent part's space (R15 names; R6 bodies fold knees and elbows into hips and
-- shoulders, see Logic/RiderPose), so the same pose bends R15 and R6 riders alike.
-- grip = true: the hands reach for the handlebar grips (IK), whatever the arm angles say.
-- feet = true (or "Left"/"Right" for one foot): the feet stay on the pedals (IK) as the cranks turn.
-- footDown = "Left"/"Right": that foot reaches for the ground beside the bike (Poses.FootDown).
-- Every pose lists the same joints so blending always has a target for each one.
local function pose(offset, joints, grip, feet, footDown)
	return { offset = offset, joints = joints, grip = grip, feet = feet, footDown = footDown }
end

return {
	Seat = CFrame.new(0, 2.0, 0.9),
	BlendRate = 12, -- higher = snappier pose changes
	GripSmoothTime = 0.08, -- seconds for the hands to catch up with the grips
	ReachBlendRate = 10, -- how fast hands/feet let go of or grab the bike when the pose changes
	KneePole = Vector3.new(0.6, 1.5, -2.5), -- chassis space (x mirrored per side): the knees point at it, forward and up
	R6FoldShare = 0.5, -- R6 limbs are one part: they take this share of the knee/elbow angle
	-- The seat moves up or down per body so the pedals suit the rider's legs: the lowest pedal sits
	-- this share of the leg's length from the hip (R15 legs bend for the top of the stroke; R6 legs
	-- can't, so their stroke is centred on the leg length instead).
	PedalReach = { R15 = 0.95, R6 = 1.2 },
	SeatLiftRange = { -0.4, 1.5 }, -- studs the seat may move for very short or very tall bodies
	R6SeatForward = 0.7, -- R6 arms are short and can't bend: R6 riders stand further forward, nearer the bars
	-- Where a foot put down goes, in chassis space for the left foot (x mirrored for the right):
	-- just out from the bike and a little ahead of the seat, at ground level (Bike.Hover below the
	-- chassis, a touch less since the bike leans onto that side, Bike.Stand).
	FootDown = Vector3.new(-1.35, -2.05, 0.4),

	Ride = pose(CFrame.new(), {
		LeftHip = { 70, 0, -6 }, RightHip = { 70, 0, 6 },
		LeftKnee = { -75, 0, 0 }, RightKnee = { -75, 0, 0 },
		LeftShoulder = { 75, 0, 10 }, RightShoulder = { 75, 0, -10 },
		LeftElbow = { 15, 0, 0 }, RightElbow = { 15, 0, 0 },
		Waist = { -20, 0, 0 },
	}, true, true),
	-- Stopped: left foot down on the ground, right foot on its pedal, hands on the bars, hips
	-- shifted towards the foot that's down and the body kept upright against the bike's lean.
	Stand = pose(CFrame.new(-0.3, -0.45, 0.1) * CFrame.Angles(0, 0, math.rad(-6)), {
		LeftHip = { 15, 0, -12 }, RightHip = { 70, 0, 6 },
		LeftKnee = { -10, 0, 0 }, RightKnee = { -80, 0, 0 },
		LeftShoulder = { 70, 0, 10 }, RightShoulder = { 70, 0, -10 },
		LeftElbow = { 20, 0, 0 }, RightElbow = { 20, 0, 0 },
		Waist = { -10, 0, 0 },
	}, true, "Right", "Left"),
	Tuck = pose(CFrame.new(0, -0.3, 0.2), {
		LeftHip = { 110, 0, -10 }, RightHip = { 110, 0, 10 },
		LeftKnee = { -120, 0, 0 }, RightKnee = { -120, 0, 0 },
		LeftShoulder = { 80, 0, 20 }, RightShoulder = { 80, 0, -20 },
		LeftElbow = { 45, 0, 0 }, RightElbow = { 45, 0, 0 },
		Waist = { -35, 0, 0 },
	}, true, true),
	Whip = pose(CFrame.new(0, 0.9, 0.3), {
		LeftHip = { 100, 0, -25 }, RightHip = { 100, 0, 25 },
		LeftKnee = { -110, 0, 0 }, RightKnee = { -110, 0, 0 },
		LeftShoulder = { 85, 0, 10 }, RightShoulder = { 85, 0, -10 },
		LeftElbow = { 10, 0, 0 }, RightElbow = { 10, 0, 0 },
		Waist = { -10, 0, 0 },
	}, true),
	Barspin = pose(CFrame.new(0, 0.3, 0.2), {
		LeftHip = { 75, 0, -8 }, RightHip = { 75, 0, 8 },
		LeftKnee = { -80, 0, 0 }, RightKnee = { -80, 0, 0 },
		LeftShoulder = { 40, 0, 60 }, RightShoulder = { 40, 0, -60 },
		LeftElbow = { 30, 0, 0 }, RightElbow = { 30, 0, 0 },
		Waist = { -5, 0, 0 },
	}, false, true),
	Superman = pose(CFrame.new(0, 1.2, 2.4) * CFrame.Angles(math.rad(-75), 0, 0), {
		LeftHip = { 0, 0, -8 }, RightHip = { 0, 0, 8 },
		LeftKnee = { 0, 0, 0 }, RightKnee = { 0, 0, 0 },
		LeftShoulder = { 150, 0, 10 }, RightShoulder = { 150, 0, -10 },
		LeftElbow = { 0, 0, 0 }, RightElbow = { 0, 0, 0 },
		Waist = { 0, 0, 0 },
	}, true),
	Lazyboy = pose(CFrame.new(0, 0.4, 1.6) * CFrame.Angles(math.rad(65), 0, 0), {
		LeftHip = { 95, 0, -10 }, RightHip = { 95, 0, 10 },
		LeftKnee = { 0, 0, 0 }, RightKnee = { 0, 0, 0 },
		LeftShoulder = { 170, 0, 20 }, RightShoulder = { 170, 0, -20 },
		LeftElbow = { -60, 0, 0 }, RightElbow = { -60, 0, 0 },
		Waist = { 0, 0, 0 },
	}),
	CanCan = pose(CFrame.new(0, 0.5, 0.3), {
		LeftHip = { 60, 0, -70 }, RightHip = { 70, 0, -40 },
		LeftKnee = { -10, 0, 0 }, RightKnee = { -75, 0, 0 },
		LeftShoulder = { 80, 0, 10 }, RightShoulder = { 80, 0, -10 },
		LeftElbow = { 10, 0, 0 }, RightElbow = { 10, 0, 0 },
		Waist = { -10, 0, 15 },
	}, true, "Right"),
}
