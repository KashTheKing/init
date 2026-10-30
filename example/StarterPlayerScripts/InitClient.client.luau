--!strict
-- Boots every client module. Put this LocalScript in StarterPlayer.StarterPlayerScripts (only one per game).
-- Entries load in the order listed; see https://kashtheking.com/init/docs/guides/entries
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Init = require(ReplicatedStorage.Packages.Init)

Init.start({
	-- Packet definitions first, matching the server
	{ Folders = { ReplicatedStorage.Network } },

	-- Shared services run on the client too
	{ Folders = { ReplicatedStorage.Services }, Predicate = Init.matchesName("Service$") },

	-- Controllers: client-only modules
	{ Folders = { ReplicatedStorage.Controllers }, Predicate = Init.matchesName("Controller$") },

	-- Binders: shared ones and client-only ones
	{ Folders = { ReplicatedStorage.Binders.Shared, ReplicatedStorage.Binders.Client } },
})
