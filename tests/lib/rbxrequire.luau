--[[
	rbxrequire: run Roblox-style Luau (`require(script.Parent.X)`) under Lune.

	Builds a virtual instance tree from the filesystem using Rojo's file
	conventions, then loads ModuleScripts with `@lune/luau`, injecting `script`,
	`require`, `game`, `task` and an Instance-aware `typeof` into each module's
	environment.

	This is how Blockwork's pure packages (spec, graph, the broker/runtime core)
	are unit tested in CI without Roblox Studio, and how the CLI reuses the exact
	same compiler source that runs inside the Game Wizard plugin.

	Rojo conventions implemented:
	- a directory is a Folder, unless it contains `init.luau` (then it is that script)
	- `x.luau` / `x.lua` is a ModuleScript, `x.server.luau` a Script, `x.client.luau` a LocalScript
	- `x.json` is a ModuleScript returning the decoded JSON
	- `*.meta.json`, `*.project.json`, `*.model.json`, `*.graph.json` and `*.nodes.json` are skipped
]]
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local task = require("@lune/task")

export type Node = {
	name: string,
	className: string,
	parent: Node?,
	children: { Node },
	source: string?,
	sourcePath: string?,
	json: boolean?,
	props: { [string]: any },
	attributes: { [string]: any },
	proxy: any,
}

local RbxRequire = {}

local nodeOf: { [any]: Node } = setmetatable({}, { __mode = "k" }) :: any
local FakeInstance: any

local SUPERCLASSES: { [string]: { string } } = {
	ModuleScript = { "LuaSourceContainer" },
	Script = { "BaseScript", "LuaSourceContainer" },
	LocalScript = { "Script", "BaseScript", "LuaSourceContainer" },
}

local SKIPPED_SUFFIXES = { ".meta.json", ".project.json", ".model.json", ".graph.json", ".nodes.json" }

local function endsWith(value: string, suffix: string): boolean
	return value:sub(-#suffix) == suffix
end

local newProxy: (node: Node) -> any

--[=[
	Creates a detached node. Used for folders, services and fakes.
]=]
function RbxRequire.node(name: string, className: string?): Node
	local node: Node = {
		name = name,
		className = className or "Folder",
		children = {},
		props = {},
		attributes = {},
		proxy = nil,
	}
	node.proxy = newProxy(node)
	return node
end

function RbxRequire.setParent(node: Node, parent: Node?)
	if node.parent then
		local siblings = node.parent.children
		local index = table.find(siblings, node)
		if index then
			table.remove(siblings, index)
		end
	end
	node.parent = parent
	if parent then
		table.insert(parent.children, node)
	end
end

function RbxRequire.findChild(node: Node, name: string): Node?
	for _, child in node.children do
		if child.name == name then
			return child
		end
	end
	return nil
end

function RbxRequire.nodeOf(proxy: any): Node?
	return nodeOf[proxy]
end

local function isA(node: Node, className: string): boolean
	if className == "Instance" or node.className == className then
		return true
	end
	local supers = SUPERCLASSES[node.className]
	return supers ~= nil and table.find(supers, className) ~= nil
end

local function fullName(node: Node): string
	local parts = {}
	local current: Node? = node
	while current and current.className ~= "DataModel" do
		table.insert(parts, 1, current.name)
		current = current.parent
	end
	return table.concat(parts, ".")
end

local methods = {}

function methods.FindFirstChild(proxy: any, name: string, recursive: boolean?): any
	local node = nodeOf[proxy]
	for _, child in node.children do
		if child.name == name then
			return child.proxy
		end
	end
	if recursive then
		for _, child in node.children do
			local found = methods.FindFirstChild(child.proxy, name, true)
			if found then
				return found
			end
		end
	end
	return nil
end

function methods.FindFirstChildOfClass(proxy: any, className: string): any
	for _, child in nodeOf[proxy].children do
		if child.className == className then
			return child.proxy
		end
	end
	return nil
end

function methods.FindFirstAncestor(proxy: any, name: string): any
	local current = nodeOf[proxy].parent
	while current do
		if current.name == name then
			return current.proxy
		end
		current = current.parent
	end
	return nil
end

function methods.WaitForChild(proxy: any, name: string, _timeout: number?): any
	local child = methods.FindFirstChild(proxy, name)
	if child == nil then
		error(`WaitForChild: {name} is not a child of {fullName(nodeOf[proxy])} (the Lune harness cannot wait)`, 2)
	end
	return child
end

function methods.GetChildren(proxy: any): { any }
	local result = {}
	for _, child in nodeOf[proxy].children do
		table.insert(result, child.proxy)
	end
	return result
end

function methods.GetDescendants(proxy: any): { any }
	local result = {}
	local function walk(node: Node)
		for _, child in node.children do
			table.insert(result, child.proxy)
			walk(child)
		end
	end
	walk(nodeOf[proxy])
	return result
end

function methods.IsA(proxy: any, className: string): boolean
	return isA(nodeOf[proxy], className)
end

function methods.IsDescendantOf(proxy: any, ancestor: any): boolean
	local target = nodeOf[ancestor]
	local current = nodeOf[proxy].parent
	while current do
		if current == target then
			return true
		end
		current = current.parent
	end
	return false
end

function methods.GetFullName(proxy: any): string
	return fullName(nodeOf[proxy])
end

function methods.GetAttribute(proxy: any, name: string): any
	return nodeOf[proxy].attributes[name]
end

function methods.SetAttribute(proxy: any, name: string, value: any)
	nodeOf[proxy].attributes[name] = value
end

function methods.GetAttributes(proxy: any): { [string]: any }
	return table.clone(nodeOf[proxy].attributes)
end

function methods.Destroy(proxy: any)
	RbxRequire.setParent(nodeOf[proxy], nil)
end

function methods.GetService(proxy: any, name: string): any
	local service = methods.FindFirstChild(proxy, name)
	if service == nil then
		error(`GetService: the Lune harness has no fake for {name}`, 2)
	end
	return service
end

local meta = {}

function meta.__index(proxy: any, key: string): any
	local node = nodeOf[proxy]
	if key == "Name" then
		return node.name
	elseif key == "ClassName" then
		return node.className
	elseif key == "Parent" then
		return if node.parent then node.parent.proxy else nil
	elseif key == "Source" and node.source then
		return node.source
	end

	local prop = node.props[key]
	if prop ~= nil then
		return prop
	end

	local method = methods[key]
	if method then
		return method
	end

	local child = methods.FindFirstChild(proxy, key)
	if child then
		return child
	end

	error(`{key} is not a valid member of {node.className} "{fullName(node)}"`, 2)
end

function meta.__newindex(proxy: any, key: string, value: any)
	local node = nodeOf[proxy]
	if key == "Name" then
		node.name = value
	elseif key == "Parent" then
		RbxRequire.setParent(node, if value then nodeOf[value] else nil)
	else
		node.props[key] = value
	end
end

function meta.__tostring(proxy: any): string
	return nodeOf[proxy].name
end

newProxy = function(node: Node): any
	local proxy = setmetatable({}, meta)
	nodeOf[proxy] = node
	return proxy
end

--[=[
	`typeof` that reports harness proxies (and fakes registered with
	`markInstance`) as "Instance", like the engine does.
]=]
local markedInstances: { [any]: boolean } = setmetatable({}, { __mode = "k" }) :: any

function RbxRequire.markInstance(value: any): any
	markedInstances[value] = true
	return value
end

function RbxRequire.typeof(value: any): string
	if nodeOf[value] or markedInstances[value] then
		return "Instance"
	end
	return typeof(value)
end

local function classify(fileName: string): (string?, string?)
	for _, suffix in SKIPPED_SUFFIXES do
		if endsWith(fileName, suffix) then
			return nil, nil
		end
	end
	for _, ext in { ".luau", ".lua" } do
		if endsWith(fileName, ".server" .. ext) then
			return fileName:sub(1, -#(".server" .. ext) - 1), "Script"
		elseif endsWith(fileName, ".client" .. ext) then
			return fileName:sub(1, -#(".client" .. ext) - 1), "LocalScript"
		elseif endsWith(fileName, ext) then
			return fileName:sub(1, -#ext - 1), "ModuleScript"
		end
	end
	if endsWith(fileName, ".json") then
		return fileName:sub(1, -6), "JsonModule"
	end
	return nil, nil
end

local INIT_FILES = {
	{ "init.luau", "ModuleScript" },
	{ "init.lua", "ModuleScript" },
	{ "init.server.luau", "Script" },
	{ "init.server.lua", "Script" },
	{ "init.client.luau", "LocalScript" },
	{ "init.client.lua", "LocalScript" },
}

--[=[
	Builds a node tree from a directory or file path, using Rojo conventions.
	`name` overrides the root node's name (like a project file key).
]=]
function RbxRequire.fromPath(path: string, name: string?): Node
	local metadata = fs.metadata(path)
	assert(metadata.exists, `rbxrequire: {path} does not exist`)

	if metadata.kind == "file" then
		local fileName = path:match("[^/\\]+$") :: string
		local baseName, className = classify(fileName)
		assert(className, `rbxrequire: {path} is not a Rojo-syncable file`)
		local node =
			RbxRequire.node(name or baseName :: string, if className == "JsonModule" then "ModuleScript" else className)
		node.sourcePath = path
		node.json = className == "JsonModule"
		node.source = fs.readFile(path)
		return node
	end

	local dirName = name or (path:match("[^/\\]+$") :: string)

	-- A folder with a default.project.json is a nested Rojo project (how Wally
	-- packages like evaera/promise map `lib/` as the package root).
	local nestedProject = `{path}/default.project.json`
	if fs.isFile(nestedProject) then
		local project = serde.decode("json", fs.readFile(nestedProject))
		local tree = project.tree or {}
		if tree["$path"] then
			local node = RbxRequire.fromPath(`{path}/{tree["$path"]}`, dirName)
			if tree["$className"] then
				node.className = tree["$className"]
			end
			return node
		end
	end

	local node: Node
	local initName: string? = nil
	for _, entry in INIT_FILES do
		if fs.isFile(`{path}/{entry[1]}`) then
			node = RbxRequire.node(dirName, entry[2])
			node.sourcePath = `{path}/{entry[1]}`
			node.source = fs.readFile(node.sourcePath :: string)
			initName = entry[1]
			break
		end
	end
	if initName == nil then
		node = RbxRequire.node(dirName, "Folder")
	end

	local entries = fs.readDir(path)
	table.sort(entries)
	for _, entry in entries do
		if entry == initName or entry:sub(1, 1) == "." then
			continue
		end
		local childPath = `{path}/{entry}`
		if fs.isDir(childPath) then
			RbxRequire.setParent(RbxRequire.fromPath(childPath), node)
		else
			local _, className = classify(entry)
			if className then
				RbxRequire.setParent(RbxRequire.fromPath(childPath), node)
			end
		end
	end

	return node
end

--[=[
	Builds a node tree from an in-memory map of `path -> source`, using the same
	conventions as `fromPath`. Used by the bundled CLI binary.
]=]
function RbxRequire.fromSources(name: string, sources: { [string]: string }): Node
	local root = RbxRequire.node(name, "Folder")
	local dirs: { [string]: Node } = { [""] = root }

	local paths = {}
	for path in sources do
		table.insert(paths, path)
	end
	table.sort(paths)

	local function dirNode(dir: string): Node
		local existing = dirs[dir]
		if existing then
			return existing
		end
		local parentDir, base = dir:match("^(.*)/([^/]+)$")
		if parentDir == nil then
			parentDir, base = "", dir
		end
		local node = RbxRequire.node(base :: string, "Folder")
		RbxRequire.setParent(node, dirNode(parentDir :: string))
		dirs[dir] = node
		return node
	end

	for _, path in paths do
		local dir, fileName = path:match("^(.*)/([^/]+)$")
		if dir == nil then
			dir, fileName = "", path
		end
		local parent = dirNode(dir :: string)
		local baseName, className = classify(fileName :: string)
		if className == nil then
			continue
		end
		if baseName == "init" then
			parent.className = if className == "JsonModule" then "ModuleScript" else className
			parent.source = sources[path]
			parent.sourcePath = path
		else
			local existing = dirs[if dir == "" then baseName :: string else `{dir}/{baseName}`]
			local node = existing or RbxRequire.node(baseName :: string, "ModuleScript")
			node.className = if className == "JsonModule" then "ModuleScript" else className :: string
			node.json = className == "JsonModule"
			node.source = sources[path]
			node.sourcePath = path
			if not existing then
				RbxRequire.setParent(node, parent)
			end
		end
	end

	return root
end

--[=[
	`Instance.new` for harness code: creates a virtual tree node. Properties
	are stored as plain values; there is no physics, replication or events.
]=]
FakeInstance = {
	new = function(className: string, parent: any?): any
		local node = RbxRequire.node(className, className)
		if parent then
			RbxRequire.setParent(node, nodeOf[parent])
		end
		return node.proxy
	end,
}

export type Loader = {
	require: (target: any) -> any,
	game: any,
	root: Node,
	globals: { [string]: any },
}

--[=[
	Creates a loader over a DataModel node. `globals` are injected into every
	module environment (e.g. test globals or fakes).
]=]
function RbxRequire.loader(root: Node, globals: { [string]: any }?): Loader
	local cache: { [Node]: { value: any } } = {}
	local loading: { [Node]: boolean } = {}
	local loader: Loader

	local function requireModule(target: any): any
		local node = nodeOf[target]
		if node == nil then
			error(`require: expected a ModuleScript, got {typeof(target)} ({tostring(target)})`, 2)
		end
		if node.className ~= "ModuleScript" then
			error(`require: {fullName(node)} is a {node.className}, not a ModuleScript`, 2)
		end

		local cached = cache[node]
		if cached then
			return cached.value
		end
		if loading[node] then
			error(`require: cyclic require of {fullName(node)}`, 2)
		end

		if node.json then
			local value = serde.decode("json", node.source :: string)
			cache[node] = { value = value }
			return value
		end

		loading[node] = true
		local env = {
			script = node.proxy,
			require = requireModule,
			game = loader.game,
			task = task,
			typeof = RbxRequire.typeof,
			Instance = FakeInstance,
		}
		for key, value in loader.globals do
			env[key] = value
		end

		local chunk = luau.load(node.source :: string, {
			debugName = node.sourcePath or fullName(node),
			environment = env,
		})
		local ok, result = pcall(chunk)
		loading[node] = nil
		if not ok then
			error(`error while requiring {fullName(node)}: {result}`, 0)
		end
		cache[node] = { value = result }
		return result
	end

	loader = {
		require = requireModule,
		game = root.proxy,
		root = root,
		globals = globals or {},
	}
	return loader
end

--[=[
	Resolves a dotted path (`ReplicatedStorage.Packages.Blockwork`) from a node.
]=]
function RbxRequire.resolve(root: Node, dotted: string): Node?
	local current: Node? = root
	for part in dotted:gmatch("[^%.]+") do
		if current == nil then
			return nil
		end
		current = RbxRequire.findChild(current, part)
	end
	return current
end

return RbxRequire
