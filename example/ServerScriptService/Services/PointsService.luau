--!strict
-- Example service: gives every player a Points leaderstat that goes up once a second.
local PointsService = {}

export type PointsService = typeof(PointsService)

PointsService.Points = {} :: { [Player]: IntValue }

function PointsService.OnPlayerAdded(self: PointsService, player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local points = Instance.new("IntValue")
	points.Name = "Points"
	points.Parent = leaderstats

	leaderstats.Parent = player
	self.Points[player] = points
end

function PointsService.OnPlayerRemoving(self: PointsService, player: Player)
	self.Points[player] = nil
end

local elapsed = 0
function PointsService.Step(self: PointsService, dt: number)
	elapsed += dt
	if elapsed < 1 then
		return
	end
	elapsed -= 1

	for _, points in self.Points do
		points.Value += 1
	end
end

return PointsService
