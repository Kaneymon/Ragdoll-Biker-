-- Rider poses: joint rotations in degrees {x, y, z} applied on top of the rig's rest pose,
-- plus where the rider sits relative to the bike chassis. Joint names are R15 Motor6Ds.
return {
	Seat = CFrame.new(0, 2.0, 0.9),
	Ride = {
		offset = CFrame.new(),
		joints = {
			LeftHip = { 70, 0, -6 }, RightHip = { 70, 0, 6 },
			LeftKnee = { -75, 0, 0 }, RightKnee = { -75, 0, 0 },
			LeftShoulder = { 75, 0, 10 }, RightShoulder = { 75, 0, -10 },
			LeftElbow = { 15, 0, 0 }, RightElbow = { 15, 0, 0 },
			Waist = { -20, 0, 0 },
		},
	},
	Superman = {
		offset = CFrame.new(0, 1.2, 2.4) * CFrame.Angles(math.rad(-75), 0, 0),
		joints = {
			LeftHip = { 0, 0, -8 }, RightHip = { 0, 0, 8 },
			LeftKnee = { 0, 0, 0 }, RightKnee = { 0, 0, 0 },
			LeftShoulder = { 150, 0, 10 }, RightShoulder = { 150, 0, -10 },
			LeftElbow = { 0, 0, 0 }, RightElbow = { 0, 0, 0 },
			Waist = { 0, 0, 0 },
		},
	},
	Lazyboy = {
		offset = CFrame.new(0, 0.4, 1.6) * CFrame.Angles(math.rad(65), 0, 0),
		joints = {
			LeftHip = { 95, 0, -10 }, RightHip = { 95, 0, 10 },
			LeftKnee = { 0, 0, 0 }, RightKnee = { 0, 0, 0 },
			LeftShoulder = { 170, 0, 20 }, RightShoulder = { 170, 0, -20 },
			LeftElbow = { -60, 0, 0 }, RightElbow = { -60, 0, 0 },
			Waist = { 0, 0, 0 },
		},
	},
}
