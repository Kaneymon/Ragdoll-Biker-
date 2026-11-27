-- What counts as the world's ground for raycasts (bike wheels, landing, hits, camera): the built
-- maps (workspace.World) and Roblox terrain (the Mountain is terrain).
local Ground = {}

function Ground.instances()
	return { workspace:WaitForChild("World"), workspace.Terrain }
end

return Ground
