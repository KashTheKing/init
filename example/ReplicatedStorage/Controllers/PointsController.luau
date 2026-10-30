--!strict
-- Example controller: prints the local player's points whenever they change.
local Players = game:GetService("Players")

local PointsController = {}

export type PointsController = typeof(PointsController)

-- leaderstats is made by the server, so wait for it in Start rather than Init
function PointsController.Start(self: PointsController)
	local points = Players.LocalPlayer:WaitForChild("leaderstats"):WaitForChild("Points") :: IntValue
	points.Changed:Connect(function(value)
		print(`You have {value} points`)
	end)
end

return PointsController
