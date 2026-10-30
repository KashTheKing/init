--[[
	Minimal fakes of the Roblox services Blockwork touches, for Lune specs.

	Fakes are plain tables marked as Instances (so `typeof(fake) == "Instance"`
	inside harness-loaded modules). They cover exactly what the runtime uses;
	anything else should be injected by the spec that needs it.
]]
local task = require("@lune/task")

local RbxRequire = require("./rbxrequire")

local Fakes = {}

export type FakeSignal = {
	Connect: (self: FakeSignal, fn: (...any) -> ()) -> { Disconnect: (any) -> (), Connected: boolean },
	Once: (self: FakeSignal, fn: (...any) -> ()) -> { Disconnect: (any) -> (), Connected: boolean },
	Fire: (self: FakeSignal, ...any) -> (),
	Wait: (self: FakeSignal) -> ...any,
}

function Fakes.signal(): FakeSignal
	local listeners: { { fn: (...any) -> (), once: boolean, connection: any } } = {}
	local signal = {}

	local function connect(fn: (...any) -> (), once: boolean)
		local entry = { fn = fn, once = once, connection = nil :: any }
		local connection = { Connected = true }
		function connection.Disconnect()
			connection.Connected = false
			local index = table.find(listeners, entry)
			if index then
				table.remove(listeners, index)
			end
		end
		entry.connection = connection
		table.insert(listeners, entry)
		return connection
	end

	function signal:Connect(fn)
		return connect(fn, false)
	end

	function signal:Once(fn)
		return connect(fn, true)
	end

	function signal:Fire(...)
		for _, entry in table.clone(listeners) do
			if entry.once then
				entry.connection:Disconnect()
			end
			entry.fn(...)
		end
	end

	function signal:Wait()
		local thread = coroutine.running()
		signal:Once(function(...)
			task.spawn(thread, ...)
		end)
		return coroutine.yield()
	end

	return signal :: any
end

--[=[
	Creates a fake Player: a harness instance (so it can be a Parent and be
	found with FindFirstChild) with UserId and Kick. Parented to `players`
	(the Players service) when given.
]=]
function Fakes.player(name: string, userId: number, players: any?): any
	local node = RbxRequire.node(name, "Player")
	local player = node.proxy
	player.UserId = userId
	player.Kick = function(_self, message: string?)
		player.kicked = message or ""
	end
	if players then
		player.Parent = players
	end
	return player
end

--[=[
	Installs RunService and Players fakes onto a harness DataModel.
	Returns helpers to drive them from a spec.
]=]
function Fakes.install(game: any, options: { realm: ("server" | "client")?, running: boolean? }?)
	local opts = options or {}
	local realm = opts.realm or "server"
	local running = if opts.running == nil then true else opts.running

	local runService = game:FindFirstChild("RunService")
	if runService == nil then
		local node = RbxRequire.node("RunService", "RunService")
		RbxRequire.setParent(node, RbxRequire.nodeOf(game))
		runService = node.proxy
	end
	runService.IsServer = function()
		return realm == "server"
	end
	runService.IsClient = function()
		return realm == "client"
	end
	runService.IsRunning = function()
		return running
	end
	runService.IsStudio = function()
		return true
	end
	runService.Heartbeat = Fakes.signal()

	local players = game:FindFirstChild("Players")
	if players == nil then
		local node = RbxRequire.node("Players", "Players")
		RbxRequire.setParent(node, RbxRequire.nodeOf(game))
		players = node.proxy
	end
	local list = {}
	local added, removing = Fakes.signal(), Fakes.signal()
	players.PlayerAdded = added
	players.PlayerRemoving = removing
	players.GetPlayers = function()
		return table.clone(list)
	end
	players.LocalPlayer = nil

	local httpService = game:FindFirstChild("HttpService")
	if httpService == nil then
		local node = RbxRequire.node("HttpService", "HttpService")
		RbxRequire.setParent(node, RbxRequire.nodeOf(game))
		httpService = node.proxy
	end
	local guidCounter = 0
	httpService.GenerateGUID = function(_self, wrap: boolean?)
		guidCounter += 1
		local guid = string.format("00000000-0000-4000-8000-%012d", guidCounter)
		return if wrap == false then guid else `\{{guid}}`
	end

	local helpers = {}

	function helpers.addPlayer(name: string, userId: number)
		local player = Fakes.player(name, userId, players)
		table.insert(list, player)
		-- reading an unset property errors on harness instances, so check the stored props
		if realm == "client" and RbxRequire.nodeOf(players).props.LocalPlayer == nil then
			players.LocalPlayer = player
		end
		added:Fire(player)
		return player
	end

	function helpers.removePlayer(player: any)
		removing:Fire(player)
		local index = table.find(list, player)
		if index then
			table.remove(list, index)
		end
		player.Parent = nil
	end

	return helpers
end

return Fakes
