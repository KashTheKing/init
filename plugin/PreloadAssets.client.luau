--!strict
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:WaitForChild("Assets")

ContentProvider:PreloadAsync(Assets:GetDescendants())

Assets.DescendantAdded:Connect(function(asset)
	ContentProvider:PreloadAsync({ asset })
end)
