-- Rider poses: joint rotations in degrees {x, y, z} on top of the rig's rest pose, plus where the
-- rider sits relative to the bike chassis. The client blends smoothly between poses.
-- grip = true: the hands reach for the handlebar grips (IK), whatever the arm angles say.
-- Every pose lists the same joints so blending always has a target for each one.
local function pose(offset, joints, grip)
	return { offset = offset, joints = joints, grip = grip }
end

return {
	Seat = CFrame.new(0, 2.0, 0.9),
	BlendRate = 12, -- higher = snappier pose changes
	GripSmoothTime = 0.08, -- seconds for the hands to catch up with the grips

	Ride = pose(CFrame.new(), {
		LeftHip = { 70, 0, -6 }, RightHip = { 70, 0, 6 },
		LeftKnee = { -75, 0, 0 }, RightKnee = { -75, 0, 0 },
		LeftShoulder = { 75, 0, 10 }, RightShoulder = { 75, 0, -10 },
		LeftElbow = { 15, 0, 0 }, RightElbow = { 15, 0, 0 },
		Waist = { -20, 0, 0 },
	}, true),
	Tuck = pose(CFrame.new(0, -0.3, 0.2), {
		LeftHip = { 110, 0, -10 }, RightHip = { 110, 0, 10 },
		LeftKnee = { -120, 0, 0 }, RightKnee = { -120, 0, 0 },
		LeftShoulder = { 80, 0, 20 }, RightShoulder = { 80, 0, -20 },
		LeftElbow = { 45, 0, 0 }, RightElbow = { 45, 0, 0 },
		Waist = { -35, 0, 0 },
	}, true),
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
	}),
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
	}, true),
}
