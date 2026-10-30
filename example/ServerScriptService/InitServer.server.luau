--!strict
-- Boots every server module. Put this Script in ServerScriptService (only one per game).
-- Entries load in the order listed; see https://kashtheking.com/init/docs/guides/entries
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Init = require(ReplicatedStorage.Packages.Init)

Init.start({
	-- Packet definitions first, so every packet has its id before a client can fire one
	{ Folders = { ReplicatedStorage.Network } },

	-- Services: shared ones (ReplicatedStorage) and server-only ones (ServerScriptService)
	{
		Folders = { ReplicatedStorage.Services, ServerScriptService.Services },
		Predicate = Init.matchesName("Service$"),
	},

	-- Binders: shared ones and server-only ones
	{ Folders = { ReplicatedStorage.Binders.Shared, ServerScriptService.Binders } },
}):andThen(function()
	-- Everything has started; handy for "wait until the server is ready" checks
	workspace:SetAttribute("ServerStarted", true)
end)
