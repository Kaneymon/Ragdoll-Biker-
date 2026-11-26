-- Server entry point: starts each service in dependency order.
local Services = script.Parent.Services

local ORDER = { "WorldService", "DataService", "ShopService", "MonetizationService", "BikeService", "RunTracker" }

for _, name in ORDER do
	local service = require(Services[name])
	if service.start then
		service.start()
	end
end
