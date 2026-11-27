-- Roblox terrain for maps with a `terrain` entry in Config/Maps (the Mountain).
-- The ground is a height field: the ride line from Logic/MapGeometry (ramp face, flat shelf with
-- the kicker, landing slope, park), plus rolling bumps on the landing, valley sides rising either
-- side and an icy summit behind the start. It is laid down as triangles (two terrain wedges each)
-- on a grid, and every triangle gets a material from its height and steepness:
-- ice/snow up high, grass and mud where the ground faces up, rock where it's steep.
local Build = require(script.Parent.Build)

local Terrain = workspace.Terrain

local TerrainBuilder = {}

local function smoothstep(a, b, x)
	local t = math.clamp((x - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)
end

local function fbm(x, z, seed)
	local total, amplitude, frequency = 0, 1, 1
	for _ = 1, 3 do
		total += amplitude * math.noise(x * frequency, z * frequency, seed)
		amplitude *= 0.5
		frequency *= 2
	end
	return total
end

-- Height of the ride line along the map at z (no bumps), kept under the ramp, runout and kicker
-- parts so terrain never pokes through them (voxels round off by a few studs), then flush with
-- the landing from the kicker's lip on.
local function rideLine(g, t, z)
	if z <= g.origin.Z then
		return g.origin.Y - t.underRamp
	elseif z <= g.bottom.Z then
		local f = (z - g.origin.Z) / (g.bottom.Z - g.origin.Z)
		return g.origin.Y + (g.bottom.Y - g.origin.Y) * f - t.underRamp
	elseif z <= g.lip.Z then
		return g.bottom.Y - t.underShelf
	elseif z <= g.landStart.Z then
		return g.bottom.Y
	elseif z <= g.landEnd.Z then
		local f = (z - g.landStart.Z) / (g.landEnd.Z - g.landStart.Z)
		return g.landStart.Y + (g.landEnd.Y - g.landStart.Y) * f
	end
	return g.landEnd.Y
end

-- Height at (x across the map from its centre line, world z).
local function heightAt(def, g, x, z)
	local t = def.terrain
	local h = rideLine(g, t, z)
	local band = def.landing.width / 2
	local ax = math.abs(x)
	-- rolling bumps on the landing slope: none near the kicker, at the fence line or in the park
	local n = t.noise
	local calm = smoothstep(g.landStart.Z + n.calmStart, g.landStart.Z + n.calmStart + 500, z)
		* (1 - smoothstep(g.landEnd.Z - 400, g.landEnd.Z, z))
		* (1 - smoothstep(band - n.edgeCalm, band - n.fenceClear, ax))
	h += n.amplitude * fbm(x / n.scale, z / n.scale, def.seed) * calm
	-- valley sides rising beyond the play area, lower beside the flat shelf so it reads as a ledge
	if ax > band then
		local shelf = smoothstep(g.bottom.Z - 300, g.bottom.Z, z) * (1 - smoothstep(g.landStart.Z, g.landStart.Z + 300, z))
		local s = smoothstep(band, t.halfWidth, ax) * (1 - t.shelfFlatten * shelf)
		h += t.sideRise * s + t.sideNoise * s * fbm(x / 260, z / 260, def.seed + 7)
	end
	-- the summit behind the start
	local behind = g.origin.Z - z
	if behind > 0 then
		local s = t.summit
		local peak = math.exp(-((behind - s.behind) / (0.7 * s.behind)) ^ 2) * math.exp(-(x / s.radius) ^ 2)
		h += s.height * peak * smoothstep(0, 220, behind) * (1 + 0.15 * fbm(x / 300, z / 300, def.seed + 11))
	end
	return h
end
TerrainBuilder.heightAt = heightAt

local function material(def, g, centre, normal, x, z)
	local t, m = def.terrain, def.terrain.materials
	local slope = math.deg(math.acos(math.clamp(normal.Y, -1, 1)))
	local patch = math.noise(x / 90, z / 90, def.seed + 3)
	if centre.Y > g.origin.Y - t.iceDepth + patch * 120 then
		return if slope > t.glacierSlope then m.ice else m.snow
	end
	local onShelf = z > g.bottom.Z and z < g.landStart.Z and math.abs(x) < def.landing.width / 2
	if onShelf or slope < t.grassSlope then
		return if patch > 0.2 then m.mud else m.grass
	end
	return if patch > 0 then m.rock else m.rockAlt
end

-- Two terrain wedges filling the triangle a, b, c (`thickness` thick, below the surface).
local function fillTriangle(a, b, c, thickness, mat)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	local sink = (if right.Y > 0 then -right else right) * (thickness / 2) -- push the slab under the surface
	Terrain:FillWedge(CFrame.fromMatrix((a + b) / 2 + sink, right, up, back), Vector3.new(thickness, height, math.abs(ab:Dot(back))), mat)
	Terrain:FillWedge(CFrame.fromMatrix((a + c) / 2 + sink, -right, up, -back), Vector3.new(thickness, height, math.abs(ac:Dot(back))), mat)
end

local function extent(def, g, parkLength)
	local t = def.terrain
	local zFrom = g.origin.Z - t.summit.behind * 2.2
	local zTo = g.landEnd.Z + parkLength + t.cell * 4
	return zFrom, zTo, math.ceil((zTo - zFrom) / t.cell)
end

-- Number of grid rows (along z) the map's terrain has; build them in batches with build().
function TerrainBuilder.rows(def, g, parkLength)
	local _, _, rows = extent(def, g, parkLength)
	return rows
end

-- Lays terrain rows rowFrom..rowTo (1-based, along z).
function TerrainBuilder.build(def, g, parkLength, rowFrom, rowTo)
	local t = def.terrain
	local zFrom = extent(def, g, parkLength)
	local cols = math.ceil(2 * t.halfWidth / t.cell)
	local function point(i, j)
		local x = -t.halfWidth + i * t.cell
		local z = zFrom + j * t.cell
		local lip = if i == 0 or i == cols or j == 0 then t.skirt.lip else 0 -- outer edges turn down
		return Vector3.new(g.origin.X + x, heightAt(def, g, x, z) - lip, z)
	end
	for j = rowFrom - 1, rowTo - 1 do
		for i = 0, cols - 1 do
			local p00, p10, p01, p11 = point(i, j), point(i + 1, j), point(i, j + 1), point(i + 1, j + 1)
			for _, tri in { { p00, p10, p11 }, { p00, p11, p01 } } do
				local centre = (tri[1] + tri[2] + tri[3]) / 3
				local normal = (tri[2] - tri[1]):Cross(tri[3] - tri[1]).Unit
				if normal.Y < 0 then
					normal = -normal
				end
				fillTriangle(tri[1], tri[2], tri[3], t.shell, material(def, g, centre, normal, centre.X - g.origin.X, centre.Z))
			end
		end
	end
end

-- Whole map, BATCH rows at a time with a yield between so the server isn't frozen.
local BATCH = 40
function TerrainBuilder.buildAll(def, g, parkLength)
	local rows = TerrainBuilder.rows(def, g, parkLength)
	for from = 1, rows, BATCH do
		TerrainBuilder.build(def, g, parkLength, from, math.min(rows, from + BATCH - 1))
		task.wait()
	end
end

-- The terrain is a shell high in the sky, so rock walls run from its turned-down outer edges
-- (sides and back) to the valley floor, so it doesn't float when seen from the other maps.
-- Each wall section's top follows the edge but stays tucked behind the turned-down lip.
local function skirtBox(folder, x, width, z, depth, bottom, top, color)
	if top - bottom > 0.05 then
		Build.tiled({ Name = "Skirt", Size = Vector3.new(width, top - bottom, depth), CFrame = CFrame.new(x, (top + bottom) / 2, z), Color = color, Material = Enum.Material.Rock, Parent = folder })
	end
end

function TerrainBuilder.buildSkirts(def, g, parkLength, parent)
	local t, s = def.terrain, def.terrain.skirt
	local folder = Build.model("Skirts", parent)
	local color = Terrain:GetMaterialColor(t.materials.rock)
	local floorY = g.landEnd.Y
	local zFrom, zTo = extent(def, g, parkLength)
	local samples = 8
	-- sides: a sloped top per section (wedge) over a box down to the floor
	local inset = t.halfWidth - t.cell / 2 - s.thickness / 2
	for _, side in { -1, 1 } do
		local x = side * t.halfWidth
		for z0 = zFrom + t.cell, zTo - s.step / 2, s.step do
			local z1 = math.min(z0 + s.step, zTo)
			local h0, h1 = heightAt(def, g, x, z0), heightAt(def, g, x, z1)
			local dip = 0 -- how far the edge sags below the straight line between the ends
			for k = 1, samples - 1 do
				local f = k / samples
				dip = math.max(dip, h0 + (h1 - h0) * f - heightAt(def, g, x, z0 + (z1 - z0) * f))
			end
			local y0, y1 = h0 - dip - s.lip / 2, h1 - dip - s.lip / 2
			local low, high = math.min(y0, y1), math.max(y0, y1)
			local cx, cz, depth = g.origin.X + side * inset, (z0 + z1) / 2, z1 - z0
			skirtBox(folder, cx, s.thickness, cz, depth, floorY, low, color)
			if high - low > 0.05 then
				local turn = if y0 > y1 then CFrame.Angles(0, math.pi, 0) else CFrame.identity
				Build.part({ Name = "Skirt", Size = Vector3.new(s.thickness, high - low, depth), CFrame = CFrame.new(cx, (low + high) / 2, cz) * turn, Color = color, Material = Enum.Material.Rock, Parent = folder }, "WedgePart")
			end
		end
	end
	-- back: flat-topped sections across the map
	local backZ = zFrom + t.cell / 2 - s.thickness / 2
	for x0 = -t.halfWidth + t.cell, t.halfWidth - t.cell - 1, s.step do
		local x1 = math.min(x0 + s.step, t.halfWidth - t.cell)
		local low = math.huge
		for k = 0, samples do
			low = math.min(low, heightAt(def, g, x0 + (x1 - x0) * k / samples, zFrom))
		end
		skirtBox(folder, g.origin.X + (x0 + x1) / 2, x1 - x0, backZ, s.thickness, floorY, low - s.lip / 2, color)
	end
	return folder
end

-- Height of whatever is under (x, z) - terrain or parts - for placing props on bumpy ground.
function TerrainBuilder.groundY(position, params)
	local hit = workspace:Raycast(position + Vector3.new(0, 400, 0), Vector3.new(0, -800, 0), params)
	return if hit then hit.Position.Y else position.Y
end

return TerrainBuilder
