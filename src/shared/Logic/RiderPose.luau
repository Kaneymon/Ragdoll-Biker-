-- Rider poses from Config/Poses, for R15 and R6 bodies (see Logic/Joints).
--  * apply(): snaps a pose. On the server this replicates for Motor6D rigs (joint C0).
--  * track()/blend(): client side, smoothly blends joints and the seat weld toward a target pose
--    every frame right before physics (AnimationConstraint rigs get it through Transform,
--    as Roblox recommends for procedural animation).
--  * Reach: poses with grip = true pull the hands onto the handlebar grips, and poses with feet
--    keep the feet on the pedals as the cranks turn. R15 arms use IKControls; R15 legs are solved
--    here as two bones (hip + knee, knees bending forward towards Poses.KneePole) so they respect
--    the knee's hinge; R6 limbs are single parts, so they are swung to point at the target.
--    Hands and feet blend on and off the bike instead of snapping.
--  * The seat is fitted to each body (seatFit), so tall, short and R6 avatars reach the bike.
local RunService = game:GetService("RunService")

local Poses = require(script.Parent.Parent.Config.Poses)
local Joints = require(script.Parent.Joints)

local RiderPose = {}

-- character -> { target, weld, r6, fit, current = { [jointName] = CFrame }, joints = cache, limbs = { limb } }
local tracked = {}

-- Reach points. Arms: chain = R15 IK chain. Legs: hip/knee/ankle joints and the foot part.
-- r6/r6End = the R6 joint and the point on the limb that touches the target.
local LIMBS = {
	{ kind = "grip", side = "Left", target = "LeftGrip", chain = { "LeftUpperArm", "LeftHand" }, r6 = "LeftShoulder", r6End = "LeftGripAttachment" },
	{ kind = "grip", side = "Right", target = "RightGrip", chain = { "RightUpperArm", "RightHand" }, r6 = "RightShoulder", r6End = "RightGripAttachment" },
	{ kind = "feet", side = "Left", target = "LeftPedal", hip = "LeftHip", knee = "LeftKnee", ankle = "LeftAnkle", foot = "LeftFoot", r6 = "LeftHip", r6End = "LeftFootAttachment" },
	{ kind = "feet", side = "Right", target = "RightPedal", hip = "RightHip", knee = "RightKnee", ankle = "RightAnkle", foot = "RightFoot", r6 = "RightHip", r6End = "RightFootAttachment" },
}
-- R6 limbs are one part each: knees and elbows fold into the hip/shoulder above them.
local R6_FOLD = { LeftKnee = "LeftHip", RightKnee = "RightHip", LeftElbow = "LeftShoulder", RightElbow = "RightShoulder" }

local function degrees(rot)
	return CFrame.Angles(math.rad(rot[1]), math.rad(rot[2]), math.rad(rot[3]))
end

-- The pose's joint rotations for this body, cached per pose and rig.
local cache = { [false] = {}, [true] = {} }
local function rotations(poseName, r6: boolean)
	local cached = cache[r6][poseName]
	if cached then
		return cached
	end
	local joints = Poses[poseName].joints
	cached = {}
	for name, rot in joints do
		if not r6 then
			cached[name] = degrees(rot)
		elseif not R6_FOLD[name] then
			local total = table.clone(rot)
			for child, parent in R6_FOLD do
				local bend = joints[child]
				if parent == name and bend then
					for i = 1, 3 do
						total[i] += bend[i] * Poses.R6FoldShare
					end
				end
			end
			cached[name] = degrees(total)
		end
	end
	cache[r6][poseName] = cached
	return cached
end

-- Weld C0 (chassis space) that puts the rider's root where this pose wants it.
-- fit = this body's seat adjustment (see seatFit).
function RiderPose.seat(poseName, fit: CFrame?)
	return Poses.Seat * (fit or CFrame.identity) * Poses[poseName].offset
end

function RiderPose.apply(character, poseName)
	for name, rotation in rotations(poseName, Joints.isR6(character)) do
		local joint = Joints.find(character, name)
		if joint then
			Joints.pose(joint, rotation)
		end
	end
end

local function reaches(pose, limb)
	if limb.kind == "grip" then
		return pose.grip == true
	end
	return pose.feet == true or pose.feet == limb.side
end

-- R15 arms: an IKControl per arm, starting at weight 0 (step blends it in).
local function ikLimb(character, def, target)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root, tip = character:FindFirstChild(def.chain[1]), character:FindFirstChild(def.chain[2])
	if not (humanoid and root and tip) then
		return nil
	end
	local ik = Instance.new("IKControl")
	ik.Name = "Grip" .. def.side
	ik.Type = Enum.IKControlType.Position
	ik.ChainRoot, ik.EndEffector, ik.Target = root, tip, target
	ik.SmoothTime = Poses.GripSmoothTime
	ik.Weight = 0
	ik.Parent = humanoid
	return { def = def, ik = ik, weight = 0 }
end

-- The sole of a foot (R15 foot or R6 leg), in that part's space.
local function solePoint(part)
	local sole = part:FindFirstChild(if string.find(part.Name, "Left") then "LeftFootAttachment" else "RightFootAttachment")
	return if sole and sole:IsA("Attachment") then sole.Position else Vector3.new(0, -part.Size.Y / 2, 0)
end

-- R15 legs: rest geometry in the hip's parent (LowerTorso) space for the two-bone solve.
local function legLimb(character, def, target, chassis)
	local hip, knee, ankle = Joints.find(character, def.hip), Joints.find(character, def.knee), Joints.find(character, def.ankle)
	local foot = character:FindFirstChild(def.foot)
	if not (hip and knee and ankle and foot and chassis) then
		return nil
	end
	local hip0, hip1 = Joints.frames(hip)
	local knee0, knee1 = Joints.frames(knee)
	local ankle0, ankle1 = Joints.frames(ankle)
	local thigh = hip0 * hip1:Inverse() -- upper leg at rest
	local shin = thigh * knee0 * knee1:Inverse()
	local footRest = shin * ankle0 * ankle1:Inverse()
	local side = if def.side == "Left" then -1 else 1
	return {
		def = def,
		weight = 0,
		leg = {
			hip = hip,
			knee = knee,
			target = target,
			chassis = chassis,
			pole = Poses.KneePole * Vector3.new(side, 1, 1),
			thighAxes = thigh.Rotation,
			H = hip0.Position,
			K = (thigh * knee0).Position,
			S = footRest * solePoint(foot),
		},
	}
end

-- R6: the shoulder/hip joint itself swings the limb towards the target.
local function aimLimb(character, def, target)
	local joint = Joints.find(character, def.r6)
	local limbPart = if joint then select(2, Joints.parts(joint)) else nil
	if not limbPart then
		return nil
	end
	local tip = limbPart:FindFirstChild(def.r6End)
	local tipLocal = if tip and tip:IsA("Attachment") then tip.Position else Vector3.new(0, -limbPart.Size.Y / 2, 0)
	return { def = def, aim = { joint = joint, tip = tipLocal, target = target }, weight = 0 }
end

-- Seat adjustment for this body: raised or lowered so its legs suit the pedals (tall avatars stand
-- up on the pedals, short ones sit low, Poses.PedalReach), and R6 bodies (short, unbending arms)
-- moved forward towards the bars.
local function seatFit(character, r6, bike, chassis)
	local forward = CFrame.new(0, 0, if r6 then -Poses.R6SeatForward else 0)
	local crank = bike:FindFirstChild("CrankRoot")
	local left, right = crank and crank:FindFirstChild("LeftPedal"), crank and crank:FindFirstChild("RightPedal")
	local hipJoint = Joints.find(character, "LeftHip")
	if not (chassis and left and right and hipJoint) then
		return forward
	end
	local byChild = Joints.byChild(character)
	local hipPart, legPart = Joints.parts(hipJoint)
	local hip = hipPart and Joints.restPoint(byChild, hipPart, Joints.frames(hipJoint).Position)
	local foot = if r6 then legPart else character:FindFirstChild("LeftFoot")
	local soleRest = foot and Joints.restPoint(byChild, foot, solePoint(foot))
	if not (hip and soleRest) then
		return forward
	end
	local legLength = (hip - soleRest).Magnitude
	-- the pedal circle in chassis space (the pedals are always opposite each other)
	local a, b = chassis.CFrame:PointToObjectSpace(left.WorldPosition), chassis.CFrame:PointToObjectSpace(right.WorldPosition)
	local centre = (a + b) / 2
	local radius = Vector2.new(a.Y - b.Y, a.Z - b.Z).Magnitude / 2
	local seatedHip = Poses.Seat * forward * hip
	local across = Vector2.new(math.abs(seatedHip.X) - math.abs(a.X), seatedHip.Z - centre.Z).Magnitude
	local reach = legLength * (if r6 then Poses.PedalReach.R6 else Poses.PedalReach.R15) - radius
	local height = math.sqrt(math.max(reach * reach - across * across, 0))
	return CFrame.new(0, math.clamp(height - (seatedHip.Y - centre.Y), Poses.SeatLiftRange[1], Poses.SeatLiftRange[2]), 0) * forward
end

-- Hands on the bars, feet on the pedals.
local function makeLimbs(character, r6, bike, chassis)
	local limbs = {}
	local bars, crank = bike:FindFirstChild("BarsRoot"), bike:FindFirstChild("CrankRoot")
	local drives = {} -- part -> the Motor6D that turns it
	for _, item in bike:GetDescendants() do
		if item:IsA("Motor6D") and item.Part1 then
			drives[item.Part1] = item
		end
	end
	for _, def in LIMBS do
		local holder = if def.kind == "grip" then bars else crank
		local target = holder and holder:FindFirstChild(def.target)
		local limb = nil
		if target and r6 then
			limb = aimLimb(character, def, target)
		elseif target then
			limb = if def.kind == "grip" then ikLimb(character, def, target) else legLimb(character, def, target, chassis)
		end
		if limb then
			local solve = limb.aim or limb.leg
			if solve then
				solve.drive = drives[holder]
			end
			table.insert(limbs, limb)
		end
	end
	return limbs
end

-- Start blending this character (client). weld = the seat weld to move with the pose,
-- bars = the bike's handlebar part (BarsRoot, holding LeftGrip/RightGrip); the pedals are found
-- on the same bike (CrankRoot, holding LeftPedal/RightPedal). Both are optional.
function RiderPose.track(character, weld, poseName, bars)
	RiderPose.release(character)
	local r6 = Joints.isR6(character)
	local current = {}
	for name, rotation in rotations(poseName, r6) do
		current[name] = rotation
	end
	local bike = bars and bars.Parent
	local state = {
		target = poseName,
		weld = weld,
		r6 = r6,
		current = current,
		joints = {},
		limbs = if bike then makeLimbs(character, r6, bike, weld and weld.Part0) else {},
		fit = if bike then seatFit(character, r6, bike, weld and weld.Part0) else CFrame.identity,
	}
	for _, limb in state.limbs do -- start already holding on if the pose reaches
		limb.weight = if reaches(Poses[poseName], limb.def) then 1 else 0
	end
	tracked[character] = state
end

function RiderPose.blend(character, poseName)
	local state = tracked[character]
	if state then
		state.target = poseName
	end
end

-- Stop posing (e.g. when the rider bails and goes limp).
function RiderPose.release(character)
	local state = tracked[character]
	if state then
		for _, limb in state.limbs do
			if limb.ik then
				limb.ik:Destroy()
			end
		end
	end
	tracked[character] = nil
end

-- Shortest turn taking direction `from` onto direction `to`.
local function arc(from: Vector3, to: Vector3)
	local axis = from:Cross(to)
	if axis.Magnitude < 1e-5 then
		return CFrame.identity
	end
	return CFrame.fromAxisAngle(axis.Unit, math.acos(math.clamp(from:Dot(to), -1, 1)))
end

-- Where a bike attachment is this frame. Pedals and bars sit on parts turned by Motor6Ds (Crank,
-- Bars) whose Transform the bike controller has just set, which physics only applies after this
-- step, so the target is worked out from the motor rather than read back a frame late.
local function targetPosition(target: Attachment, drive: Motor6D?)
	if drive and drive.Part0 then
		return (drive.Part0.CFrame * drive.C0 * drive.Transform * drive.C1:Inverse()) * target.Position
	end
	return target.WorldPosition
end

-- R6: rotation (Part0 space) that points the limb's tip at its target.
local function aimRotation(aim)
	local part0 = Joints.parts(aim.joint)
	if not part0 then
		return CFrame.identity
	end
	local frame0, frame1 = Joints.frames(aim.joint)
	local pivot = frame0.Position
	local rest = (frame0 * frame1:Inverse()) * aim.tip - pivot
	local want = part0.CFrame:PointToObjectSpace(targetPosition(aim.target, aim.drive)) - pivot
	if rest.Magnitude < 1e-3 or want.Magnitude < 1e-3 then
		return CFrame.identity
	end
	return arc(rest.Unit, want.Unit)
end

-- R15 leg: hip and knee rotations that put the sole on the target, the knee hinging the way it
-- bends (negative X, see the knee's joint limits) and the leg turned so the knee points at the pole.
local function legRotations(leg)
	local part0 = Joints.parts(leg.hip)
	if not part0 then
		return CFrame.identity, CFrame.identity
	end
	local space = part0.CFrame
	local H, K, S = leg.H, leg.K, leg.S
	local toTarget = space:PointToObjectSpace(targetPosition(leg.target, leg.drive)) - H
	local thigh, shin = (K - H).Magnitude, (S - K).Magnitude
	if toTarget.Magnitude < 1e-3 or thigh < 1e-3 or shin < 1e-3 then
		return CFrame.identity, CFrame.identity
	end
	local reach = math.clamp(toTarget.Magnitude, math.abs(thigh - shin) + 0.01, thigh + shin)
	local restAngle = math.acos(math.clamp((H - K).Unit:Dot((S - K).Unit), -1, 1))
	local wantAngle = math.acos(math.clamp((thigh * thigh + shin * shin - reach * reach) / (2 * thigh * shin), -1, 1))
	local bend = math.max(restAngle - wantAngle, 0)
	local kneeTurn = CFrame.Angles(-bend, 0, 0) -- in upper leg space
	local bentSole = K + (leg.thighAxes * kneeTurn * leg.thighAxes:Inverse()) * (S - K)
	local axis = toTarget.Unit
	local swing = arc((bentSole - H).Unit, axis)
	-- turn round the hip->target line so the knee faces the pole
	local knee = swing * (K - H)
	local pole = space:PointToObjectSpace(leg.chassis.CFrame * leg.pole) - H
	local kneeFlat, poleFlat = knee - axis * knee:Dot(axis), pole - axis * pole:Dot(axis)
	if kneeFlat.Magnitude > 1e-3 and poleFlat.Magnitude > 1e-3 then
		swing = CFrame.fromAxisAngle(axis, math.atan2(kneeFlat:Cross(poleFlat):Dot(axis), kneeFlat:Dot(poleFlat))) * swing
	end
	return swing, kneeTurn
end

-- Blend hands/feet weights; returns { [jointName] = { rotation, weight } } for the solved joints.
local function stepLimbs(state, pose, alpha)
	local solved = {}
	for _, limb in state.limbs do
		local goal = if reaches(pose, limb.def) then 1 else 0
		limb.weight += (goal - limb.weight) * alpha
		if limb.ik then
			limb.ik.Weight = limb.weight
		elseif limb.weight > 0.001 then
			if limb.aim then
				solved[limb.def.r6] = { aimRotation(limb.aim), limb.weight }
			else
				local hipTurn, kneeTurn = legRotations(limb.leg)
				solved[limb.def.hip] = { hipTurn, limb.weight }
				solved[limb.def.knee] = { kneeTurn, limb.weight }
			end
		end
	end
	return solved
end

local function step(dt)
	local alpha = 1 - math.exp(-dt * Poses.BlendRate)
	local reachAlpha = 1 - math.exp(-dt * Poses.ReachBlendRate)
	for character, state in tracked do
		if not character.Parent then
			tracked[character] = nil
			continue
		end
		local solved = stepLimbs(state, Poses[state.target], reachAlpha)
		for name, rotation in rotations(state.target, state.r6) do
			local current = (state.current[name] or CFrame.identity):Lerp(rotation, alpha)
			state.current[name] = current
			if state.joints[name] == nil then
				state.joints[name] = Joints.find(character, name) or false
			end
			local joint = state.joints[name]
			if joint then
				local reach = solved[name]
				Joints.pose(joint, if reach then current:Lerp(reach[1], reach[2]) else current)
			end
		end
		if state.weld and state.weld.Parent then
			state.weld.C0 = state.weld.C0:Lerp(RiderPose.seat(state.target, state.fit), alpha)
		end
	end
end

if RunService:IsClient() then
	RunService.PreSimulation:Connect(step)
end

return RiderPose
