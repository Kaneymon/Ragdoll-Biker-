-- Server entry point: starts each service in dependency order.
local Services = script.Parent.Services

local ORDER = {
	"WorldService", "DataService", "ShopService", "MonetizationService", "LocationService", "BikeService", "RunTracker",
	"ObbyService", "AfkService", "LeaderboardService",
}

for _, name in ORDER do
	local service = require(Services[name])
	if service.start then
		service.start()
	end
end
