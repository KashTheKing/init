--[[
	Runs Init under Lune against fake Roblox services. No Studio needed.

		lune run tests/run            -- every test
		lune run tests/run Priority   -- only tests whose name contains "Priority"

	Each test gets a fresh DataModel and module cache, built with the rbxrequire harness
	(tests/lib, shared with Blockwork). Test modules write what happened into the `log` global.
]]
local process = require("@lune/process")
local stdio = require("@lune/stdio")
local task = require("@lune/task")

local Fakes = require("./lib/fakes")
local RbxRequire = require("./lib/rbxrequire")

type Env = {
	game: any,
	log: { string },
	errors: { string },
	prints: { string },
	players: any,
	folder: (parent: any, name: string) -> any,
	module: (parent: any, name: string, source: string, attributes: { [string]: any }?) -> any,
	service: (name: string) -> any,
	Init: any,
	pump: (seconds: number) -> (),
	await: (promise: any) -> ...any,
}

local function setup(realm: ("server" | "client")?): Env
	local root = RbxRequire.node("Game", "DataModel")
	for _, name in { "ReplicatedStorage", "ServerScriptService" } do
		RbxRequire.setParent(RbxRequire.node(name, name), root)
	end
	local initNode = RbxRequire.fromPath("src/Init", "Init")
	RbxRequire.setParent(initNode, RbxRequire.findChild(root, "ReplicatedStorage"))

	local log, errors, prints = {}, {}, {}
	-- task.spawn(error, message) is how Init reports without stopping; collect those instead
	local fakeTask = setmetatable({
		spawn = function(callback: any, ...: any)
			if callback == error then
				table.insert(errors, tostring((...)))
				return nil
			end
			return task.spawn(callback, ...)
		end,
	}, { __index = task })
	local loader = RbxRequire.loader(root, {
		log = log,
		task = fakeTask,
		print = function(...)
			table.insert(prints, table.concat({ ... }, " "))
		end,
		debug = {
			traceback = debug.traceback,
			profilebegin = function() end,
			profileend = function() end,
		},
	})
	local game = loader.game
	local players = Fakes.install(game, { realm = realm or "server" })
	local runService = game:GetService("RunService")
	runService.Stepped = Fakes.signal()
	runService.RenderStepped = Fakes.signal()

	local env = {} :: Env
	env.game, env.log, env.errors, env.prints, env.players = game, log, errors, prints, players

	function env.service(name)
		return game:GetService(name)
	end

	function env.folder(parent, name)
		local node = RbxRequire.node(name, "Folder")
		RbxRequire.setParent(node, RbxRequire.nodeOf(parent))
		return node.proxy
	end

	function env.module(parent, name, source, attributes)
		local node = RbxRequire.node(name, "ModuleScript")
		node.source = source
		node.sourcePath = name
		for key, value in attributes or {} do
			node.attributes[key] = value
		end
		RbxRequire.setParent(node, RbxRequire.nodeOf(parent))
		return node.proxy
	end

	-- Promise timers (timeouts) and Step run off Heartbeat, which only fires when we fire it
	function env.pump(seconds)
		local finish = os.clock() + seconds
		while os.clock() < finish do
			task.wait(0.01)
			runService.Heartbeat:Fire(0.01)
		end
	end

	function env.await(promise)
		local deadline = os.clock() + 5
		while promise:getStatus() == "Started" and os.clock() < deadline do
			env.pump(0.02)
		end
		return promise:expect()
	end

	env.Init = loader.require(initNode.proxy)
	return env
end

-- A module that logs its Init and Start
local function tracked(name: string, extra: string?): string
	local source = [[local M = {}
function M:Init() table.insert(log, "NAME:Init") end
function M:Start() table.insert(log, "NAME:Start") end
EXTRA
return M]]
	return (source:gsub("NAME", name):gsub("EXTRA", extra or ""))
end

local function check(condition: any, message: string)
	if not condition then
		error(message, 2)
	end
end

local function checkLog(env: Env, expected: { string })
	local actual = table.concat(env.log, ", ")
	check(actual == table.concat(expected, ", "), `log was: {actual}`)
end

local function hasError(env: Env, needle: string): boolean
	for _, message in env.errors do
		if message:find(needle, 1, true) then
			return true
		end
	end
	return false
end

local tests: { { name: string, fn: () -> () } } = {}
local function test(name: string, fn: () -> ())
	table.insert(tests, { name = name, fn = fn })
end

test("loads entries in order, Priority inside an entry, every Init before any Start", function()
	local env = setup()
	local RS, SSS = env.service("ReplicatedStorage"), env.service("ServerScriptService")
	local network = env.folder(RS, "Network")
	env.module(network, "Packets", tracked("Packets"))
	local shared = env.folder(RS, "Services")
	local a = env.module(shared, "AService", tracked("A"))
	env.module(a, "ChildService", tracked("Child")) -- inside a ModuleScript: belongs to AService
	env.module(shared, "BService", tracked("B"), { Priority = -1 })
	env.module(shared, "Util", tracked("Util")) -- not a *Service
	env.module(env.folder(env.folder(SSS, "Services"), "Combat"), "CService", tracked("C"))

	local modules, count = env.await(env.Init.start({
		{ Folders = { network } },
		{ Folders = { shared, SSS.Services }, Predicate = env.Init.matchesName("Service$") },
	}))

	checkLog(env, { "Packets:Init", "B:Init", "A:Init", "C:Init", "Packets:Start", "B:Start", "A:Start", "C:Start" })
	check(count == 4, `count was {count}`)
	check(
		modules.AService and modules.BService and modules.CService and modules.Packets,
		"modules table is missing one"
	)
	check(modules.Util == nil and modules.ChildService == nil, "loaded a module it should have skipped")
	check(#env.errors == 0, `unexpected error: {env.errors[1]}`)
	check(
		env.prints[#env.prints]:find("Initialized 4 Server modules", 1, true),
		`last print: {env.prints[#env.prints]}`
	)
end)

test("the Ignore attribute skips a module", function()
	local env = setup()
	local folder = env.folder(env.service("ReplicatedStorage"), "Stuff")
	env.module(folder, "Kept", tracked("Kept"))
	env.module(folder, "Skipped", tracked("Skipped"), { Ignore = true })
	local modules = env.await(env.Init.start({ { Folders = { folder } } }))
	check(modules.Kept and not modules.Skipped, "Ignore attribute was not respected")
end)

test("a dictionary of entries (the old Entries format) runs by Order", function()
	local env = setup()
	local RS = env.service("ReplicatedStorage")
	local one, two = env.folder(RS, "One"), env.folder(RS, "Two")
	env.module(one, "First", tracked("First"))
	env.module(two, "Second", tracked("Second"))
	env.await(env.Init.start({
		Later = { Order = 2, Folders = { two } },
		Sooner = { Order = 1, Folders = { one } },
	}))
	checkLog(env, { "First:Init", "Second:Init", "First:Start", "Second:Start" })
end)

test("an Init that errors is reported, and only that module skips Start", function()
	local env = setup()
	local folder = env.folder(env.service("ReplicatedStorage"), "Services")
	env.module(
		folder,
		"BadService",
		`local M = \{} function M:Init() error("boom") end function M:Start() table.insert(log, "Bad:Start") end return M`
	)
	env.module(folder, "GoodService", tracked("Good"))
	env.await(env.Init.start({ { Folders = { folder } } }))
	checkLog(env, { "Good:Init", "Good:Start" })
	check(hasError(env, "BadService:Init() errored"), `errors: {table.concat(env.errors, " | ")}`)
	check(hasError(env, "boom"), "the original error message was lost")
end)

test("an Init that yields past InitTimeout is reported and skips Start", function()
	local env = setup()
	local folder = env.folder(env.service("ReplicatedStorage"), "Services")
	env.module(
		folder,
		"SlowService",
		`local M = \{} function M:Init() task.wait(1) end function M:Start() table.insert(log, "Slow:Start") end return M`
	)
	env.module(folder, "FastService", tracked("Fast"))
	env.await(env.Init.start({ { Folders = { folder } } }, { InitTimeout = 0.1 }))
	checkLog(env, { "Fast:Init", "Fast:Start" })
	check(hasError(env, "SlowService:Init() didn't finish within 0.1s"), `errors: {table.concat(env.errors, " | ")}`)
end)

test("a Start that yields doesn't hold up the other modules", function()
	local env = setup()
	local folder = env.folder(env.service("ReplicatedStorage"), "Services")
	env.module(
		folder,
		"AService",
		`local M = \{} function M:Start() task.wait(0.2) table.insert(log, "A:Start done") end return M`
	)
	env.module(folder, "BService", tracked("B"))
	env.await(env.Init.start({ { Folders = { folder } } }))
	checkLog(env, { "B:Init", "B:Start", "A:Start done" })
end)

test("OnPlayerAdded runs for players already in game and new ones; OnPlayerRemoving too", function()
	local env = setup()
	env.players.addPlayer("Early", 1)
	local folder = env.folder(env.service("ReplicatedStorage"), "Services")
	env.module(
		folder,
		"PlayerService",
		[[local M = {}
function M:OnPlayerAdded(player) table.insert(log, "added " .. player.Name) end
function M:OnPlayerRemoving(player) table.insert(log, "removing " .. player.Name) end
return M]]
	)
	env.await(env.Init.start({ { Folders = { folder } } }))
	local late = env.players.addPlayer("Late", 2)
	env.players.removePlayer(late)
	checkLog(env, { "added Early", "added Late", "removing Late" })
end)

test("Step runs at a fixed 60 per second", function()
	local env = setup()
	local folder = env.folder(env.service("ReplicatedStorage"), "Services")
	env.module(folder, "Ticker", `local M = \{} function M:Step(dt) table.insert(log, "step") end return M`)
	env.await(env.Init.start({ { Folders = { folder } } }))
	table.clear(env.log)
	env.service("RunService").Heartbeat:Fire(0.105) -- 6.3 steps' worth
	check(#env.log == 6, `Step ran {#env.log} times`)
end)

test("a module that errors while loading is reported and the rest still load", function()
	local env = setup()
	local folder = env.folder(env.service("ReplicatedStorage"), "Services")
	env.module(folder, "Broken", `error("syntax-ish problem")`)
	env.module(folder, "Fine", tracked("Fine"))
	local modules, count = env.await(env.Init.start({ { Folders = { folder } } }))
	check(count == 1 and modules.Fine, "Fine didn't load")
	check(hasError(env, "Broken errored while loading"), `errors: {table.concat(env.errors, " | ")}`)
end)

test("two modules with one name both run and the clash is reported", function()
	local env = setup()
	local RS = env.service("ReplicatedStorage")
	local one, two = env.folder(RS, "One"), env.folder(RS, "Two")
	env.module(one, "Shop", tracked("Shop1"))
	env.module(two, "Shop", tracked("Shop2"))
	local _, count = env.await(env.Init.start({ { Folders = { one, two } } }))
	check(count == 2, `count was {count}`)
	check(hasError(env, `Two loaded modules are named "Shop"`), "clash wasn't reported")
end)

test("bad input fails straight away with a clear message", function()
	local env = setup()
	local ok, err = pcall(env.Init.start, {}, { Verbos = true })
	check(not ok and tostring(err):find('"Verbos" isn\'t a setting', 1, true), `got: {err}`)
	ok, err = pcall(env.Init.start, { { Folder = {} } })
	check(not ok and tostring(err):find("needs a Folders list", 1, true), `got: {err}`)
end)

test("Init.start runs once per realm", function()
	local env = setup()
	env.await(env.Init.start({}))
	local ok, err = pcall(env.Init.start, {})
	check(not ok and tostring(err):find("already called", 1, true), `got: {err}`)
end)

test("client: OnCharacterAdded, OnDied and OnRenderStepped", function()
	local env = setup("client")
	local player = env.players.addPlayer("Me", 1)
	player.CharacterAdded = Fakes.signal()
	player.CharacterRemoving = Fakes.signal()
	local character = RbxRequire.node("Me", "Model")
	local humanoid = RbxRequire.node("Humanoid", "Humanoid")
	humanoid.proxy.Died = Fakes.signal()
	RbxRequire.setParent(humanoid, character)
	player.Character = character.proxy

	local folder = env.folder(env.service("ReplicatedStorage"), "Controllers")
	env.module(
		folder,
		"CharacterController",
		[[local M = {}
function M:OnCharacterAdded(character) table.insert(log, "character " .. character.Name) end
function M:OnDied() table.insert(log, "died") end
function M:OnRenderStepped(dt) table.insert(log, "render " .. dt) end
return M]]
	)
	env.await(env.Init.start({ { Folders = { folder } } }))
	humanoid.proxy.Died:Fire()
	env.service("RunService").RenderStepped:Fire(0.5)
	checkLog(env, { "character Me", "died", "render 0.5" })
end)

local filter = process.args[1]
local passed, failed = 0, 0
for _, case in tests do
	if filter and not case.name:find(filter, 1, true) then
		continue
	end
	local ok, err = pcall(case.fn)
	if ok then
		passed += 1
		print(stdio.color("green") .. "PASS " .. stdio.color("reset") .. case.name)
	else
		failed += 1
		print(stdio.color("red") .. "FAIL " .. stdio.color("reset") .. case.name .. "\n     " .. tostring(err))
	end
end
print(`{passed} passed, {failed} failed`)
process.exit(if failed > 0 then 1 else 0)
