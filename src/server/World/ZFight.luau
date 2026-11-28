-- Z-fighting clean-up: finds flat faces of block and wedge parts that lie in the same plane and
-- overlap (they flicker as the camera moves, worst on textured materials) and pulls one face of
-- each pair back by NUDGE studs, shrinking that part a hair so its other faces stay put. The
-- smaller face moves (it ends up just under the bigger one). Run on every map and the lobby once
-- they're built (MapBuilder, LobbyBuilder); MeshParts are left alone (their shapes aren't boxes).
-- Bottom faces are skipped: they sit on the ground and are never seen.
local ZFight = {}

local PLANE_TOLERANCE = 0.03 -- faces closer than this count as the same plane
local OVERLAP_MARGIN = 0.05 -- faces that only touch along an edge don't fight
local NUDGE = 0.04
local YIELD_EVERY = 2000

local AXES = { Enum.Axis.X, Enum.Axis.Y, Enum.Axis.Z }

local function q(v: number)
	return math.floor(v * 100 + 0.5)
end

local function direction(n: Vector3)
	return q(n.X) .. "," .. q(n.Y) .. "," .. q(n.Z)
end

-- Faces worth checking: all six for blocks, the flat back and sides for wedges (not the slope).
local function faces(part: BasePart)
	local list = {}
	local cf, size = part.CFrame, part.Size
	for i, axis in AXES do
		local other1, other2 = AXES[i % 3 + 1], AXES[(i + 1) % 3 + 1]
		for _, sign in { 1, -1 } do
			local isWedge = part:IsA("WedgePart")
			local skip = isWedge and (axis == Enum.Axis.Y or (axis == Enum.Axis.Z and sign < 0))
			local n = cf:VectorToWorldSpace(Vector3.FromAxis(axis) * sign)
			if not skip and n.Y > -0.7 then
				local centre = cf.Position + n * (size[axis.Name] / 2)
				table.insert(list, {
					part = part,
					n = n,
					d = n:Dot(centre),
					c = centre,
					u = cf:VectorToWorldSpace(Vector3.FromAxis(other1)),
					v = cf:VectorToWorldSpace(Vector3.FromAxis(other2)),
					hu = size[other1.Name] / 2,
					hv = size[other2.Name] / 2,
				})
			end
		end
	end
	return list
end

local function overlaps(f, g)
	local dc = g.c - f.c
	local gu = math.abs(g.hu * g.u:Dot(f.u)) + math.abs(g.hv * g.v:Dot(f.u))
	local gv = math.abs(g.hu * g.u:Dot(f.v)) + math.abs(g.hv * g.v:Dot(f.v))
	return math.abs(dc:Dot(f.u)) < f.hu + gu - OVERLAP_MARGIN and math.abs(dc:Dot(f.v)) < f.hv + gv - OVERLAP_MARGIN
end

-- Pull the face of `part` facing world direction n back by `depth` studs.
local function pullBack(part: BasePart, n: Vector3, depth: number)
	local localN = part.CFrame:VectorToObjectSpace(n)
	local axis = if math.abs(localN.X) > 0.9 then "X" elseif math.abs(localN.Y) > 0.9 then "Y" else "Z"
	if part.Size[axis] <= depth * 3 then
		return false
	end
	part.Size -= Vector3.FromAxis(Enum.Axis[axis]) * depth
	part.CFrame -= n * (depth / 2)
	return true
end

local function candidates(root: Instance)
	local parts = {}
	for _, item in root:GetDescendants() do
		if (item:IsA("Part") and item.Shape == Enum.PartType.Block or item:IsA("WedgePart"))
			and item.Transparency < 0.99 and item.Material ~= Enum.Material.ForceField then
			table.insert(parts, item)
		end
	end
	return parts
end

-- Returns how many faces were pulled back. yield = call task.wait() now and then (big maps).
function ZFight.fix(root: Instance, yield: boolean?): number
	-- faces grouped by direction, then by plane offset in 0.1 stud slots
	local buckets = {}
	for i, part in candidates(root) do
		for _, f in faces(part) do
			local dir = direction(f.n)
			local slot = math.floor(f.d * 10)
			buckets[dir] = buckets[dir] or {}
			buckets[dir][slot] = buckets[dir][slot] or {}
			table.insert(buckets[dir][slot], f)
		end
		if yield and i % YIELD_EVERY == 0 then
			task.wait()
		end
	end
	-- faces that fight are linked; each linked face then gets its own layer (0, 1, 2, ... x NUDGE
	-- back), the biggest faces staying put, so no two overlapping faces end up level again
	local nodes = {} -- part -> direction -> { face, links = {node}, layer }
	local function node(f)
		local byDir = nodes[f.part] or {}
		nodes[f.part] = byDir
		local dir = direction(f.n)
		byDir[dir] = byDir[dir] or { face = f, links = {} }
		return byDir[dir]
	end
	local function check(f, g)
		if f.part ~= g.part and math.abs(f.d - g.d) < PLANE_TOLERANCE and overlaps(f, g) then
			local a, b = node(f), node(g)
			table.insert(a.links, b)
			table.insert(b.links, a)
		end
	end
	for _, slots in buckets do
		for slot, list in slots do
			local next = slots[slot + 1] or {} -- planes just either side of a slot boundary
			for i = 1, #list do
				for j = i + 1, #list do
					check(list[i], list[j])
				end
				for _, g in next do
					check(list[i], g)
				end
			end
		end
	end
	local order = {}
	for _, byDir in nodes do
		for _, n in byDir do
			table.insert(order, n)
		end
	end
	table.sort(order, function(a, b)
		return a.face.hu * a.face.hv > b.face.hu * b.face.hv
	end)
	local fixed = 0
	for _, n in order do
		local used = {}
		for _, other in n.links do
			if other.layer then
				used[other.layer] = true
			end
		end
		local layer = 0
		while used[layer] do
			layer += 1
		end
		n.layer = layer
		if layer > 0 and pullBack(n.face.part, n.face.n, layer * NUDGE) then
			fixed += 1
		end
	end
	return fixed
end

return ZFight
