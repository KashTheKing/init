--!strict
--[[

Init Framework Plugin by KashTheKing
Apache License
Version 2.0, January 2004

]]

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")
local ServerScriptService = game:GetService("ServerScriptService")
local ScriptEditorService = game:GetService("ScriptEditorService")
local SoundService = game:GetService("SoundService")
local StarterPlayer = game:GetService("StarterPlayer")
local StudioService = game:GetService("StudioService")

--Template clones carry this tag while they still rename themselves; remove it to stop that
local TEMPLATE_TAG = "InitFrameworkTemplate"
local SNIPPET = "_SNIPPET_"

--Templates whose object name is forced to <typed> .. <suffix>; all others keep the typed name as-is
local FORCED_SUFFIXES = {
	Service = "Service",
	Controller = "Controller",
	GuiController = "GuiController",
	Binder = "Binder",
	Network = "Network",
}

--Plugin Instances
local Root = script.Parent
local Templates = Root.Templates
local Setup = Root.Setup

--Plugin Connections
local connections = {}

--Plugin Components
local toolbar = plugin:CreateToolbar("Init Framework")

--Buttons
local function button(id: string, tooltip: string, classIcon: string): PluginToolbarButton
	local result = StudioService:GetClassIcon(classIcon)

	local image = result.Image

	local toolbarButton = toolbar:CreateButton(id, tooltip, image)
	toolbarButton.ClickableWhenViewportHidden = true
	return toolbarButton
end

local addFrameworkBtn = button("Setup", "Adds the Init Framework to the game", "Configuration")
local addExtrasBtn = button("Add Extras", "Adds extra setup features to the game", "WeldConstraint")
local addPackagesBtn = button("Add Packages", "Adds Init Framework packages", "PackageLink")
local addServiceBtn = button("Service", "Adds a template service", "Script")
local addControllerBtn = button("Controller", "Adds a template controller", "LocalScript")
local addGuiControllerBtn = button("Gui Controller", "Adds a template gui controller", "BillboardGui")
local addInputBtn = button("Input", "Adds a template input context", "ClickDetector")
local addBinderBtn = button("Binder", "Adds a template binder", "Weld")
local addBoundClassBtn = button("Bound Class", "Adds a template class that uses Binder", "ModuleScript")
local addClassBtn = button("Class", "Adds a template class", "ModuleScript")
local addInheritedClassBtn = button("InheritedClass", "Adds a template inherited class", "ModuleScript")
local addNetworkBtn = button("Network", "Adds a template network", "RemoteEvent")
local updateScriptNameBtn = button("Update Script Name", "Renames the active script to the selected text", "Dialog")

--Utility
local function addClone<T>(instanceToClone: T, parent: Instance, properties: { [string]: any }?): T
	assert(typeof(instanceToClone) == "Instance", "Not an instance")

	local clone = (instanceToClone :: Instance):Clone()

	if clone:IsA("Script") or clone:IsA("LocalScript") then
		clone.Enabled = true
	end

	if properties then
		for property, value in properties do
			(clone :: any)[property] = value
		end
	end

	clone.Parent = parent

	return clone
end

local function hakariIdleDeathGambleJackpotRegeneration()
	ChangeHistoryService:SetWaypoint("HakariIdleDeathGambleJackpotRegeneration")
end

local function createOrUseFolder(parent: Instance, folderName: string): Folder
	local folder = parent:FindFirstChild(folderName)

	if folder and folder:IsA("Folder") then
		return folder
	end

	local newFolder = Instance.new("Folder")
	newFolder.Name = folderName
	newFolder.Parent = parent

	return newFolder
end

local function cloneOverwrite(parent: Instance, instanceToClone: Instance): (Instance, boolean)
	local clone = parent:FindFirstChild(instanceToClone.Name)

	local wasOverwritten = false

	if clone and clone:IsA(instanceToClone.ClassName) then
		clone:Destroy()
		wasOverwritten = true
	end

	local newClone: any = instanceToClone:Clone()

	if newClone:IsA("Script") or newClone:IsA("LocalScript") then
		newClone.Enabled = true
	end

	newClone.Parent = parent

	return newClone, wasOverwritten
end

local function cloneIfMissing(parent: Instance, instanceToClone: Instance): (Instance, boolean)
	local existing = parent:FindFirstChild(instanceToClone.Name)

	if existing and existing:IsA(instanceToClone.ClassName) then
		return existing, false
	end

	local newClone: any = instanceToClone:Clone()

	if newClone:IsA("Script") or newClone:IsA("LocalScript") then
		newClone.Enabled = true
	end

	newClone.Parent = parent

	return newClone, true
end

--Snippet Naming
local function hasSnippet(source: string): boolean
	return string.find(source, SNIPPET, 1, true) ~= nil
end

--Collects every script under root (inclusive) that still contains a _SNIPPET_ placeholder
local function collectSnippetScripts(root: Instance): { LuaSourceContainer }
	local scripts = {}

	local function check(instance: Instance)
		if instance:IsA("LuaSourceContainer") and hasSnippet(instance.Source) then
			table.insert(scripts, instance)
		end
	end

	check(root)
	for _, descendant in root:GetDescendants() do
		check(descendant)
	end

	return scripts
end

--Strips the trailing template suffix from a name, e.g. "KillBrickBinder" + "Binder" -> "KillBrick"
local function deriveSnippet(name: string, suffix: string): string
	if #name > #suffix and string.sub(name, -#suffix) == suffix then
		return string.sub(name, 1, #name - #suffix)
	end

	return name
end

--Clones a tagged template, then refills every _SNIPPET_ to match whenever the clone is renamed
local function addTemplateWithNaming(template: Instance)
	local parent = Selection:Get()[1]

	if not parent then
		warn("Select a parent first")
		return
	end

	hakariIdleDeathGambleJackpotRegeneration()

	local clone = addClone(template, parent)
	Selection:Set({ clone })

	--Only templates with _SNIPPET_ placeholders rename themselves
	local scripts = collectSnippetScripts(clone)

	if #scripts == 0 then
		hakariIdleDeathGambleJackpotRegeneration()
		return
	end

	CollectionService:AddTag(clone, TEMPLATE_TAG)

	local originals: { [LuaSourceContainer]: string } = {}
	for _, scr in scripts do
		originals[scr] = scr.Source
	end

	local suffix = FORCED_SUFFIXES[template.Name]

	--Open the primary script so the user sees the fill happen
	local opened, openErr = ScriptEditorService:OpenScriptDocumentAsync(scripts[1])
	if not opened then
		warn(`[InitFramework] Couldn't open {scripts[1]:GetFullName()}: {openErr}`)
	end

	local busy = false
	local conn: RBXScriptConnection
	conn = clone:GetPropertyChangedSignal("Name"):Connect(function()
		if busy then
			return
		end

		--Stop handling once it's no longer a tagged template
		if not CollectionService:HasTag(clone, TEMPLATE_TAG) then
			conn:Disconnect()
			return
		end

		busy = true

		local snippet = clone.Name
		if suffix then
			snippet = deriveSnippet(clone.Name, suffix)
		end

		hakariIdleDeathGambleJackpotRegeneration()

		for _, scr in scripts do
			local original = originals[scr]
			ScriptEditorService:UpdateSourceAsync(scr, function()
				return (original:gsub("_SNIPPET_", function()
					return snippet
				end))
			end)
		end

		if suffix then
			local normalized = snippet .. suffix
			if clone.Name ~= normalized then
				clone.Name = normalized
			end
		end

		hakariIdleDeathGambleJackpotRegeneration()

		busy = false
	end)

	table.insert(connections, conn)

	hakariIdleDeathGambleJackpotRegeneration()
end

--Renames the currently edited script to the user's selected text
local function updateScriptName()
	local active: LuaSourceContainer? = StudioService.ActiveScript :: LuaSourceContainer

	if not active then
		warn("No script is open")
		return
	end

	local document = ScriptEditorService:FindScriptDocument(active)

	if not document or not document:HasSelectedText() then
		warn("Select text in the script first")
		return
	end

	local selected = document:GetSelectedText():match("^%s*(.-)%s*$")

	if not selected or selected == "" then
		warn("Selection is empty")
		return
	end

	hakariIdleDeathGambleJackpotRegeneration()
	active.Name = selected
	hakariIdleDeathGambleJackpotRegeneration()

	print("Renamed script to " .. selected)
end

--Add Functions
local function addFramework()
	hakariIdleDeathGambleJackpotRegeneration()

	--The loader lives where Wally puts it, so code is the same for Studio and Rojo games
	local packages = createOrUseFolder(ReplicatedStorage, "Packages")
	local initModule, wasOverwritten = cloneOverwrite(packages, Setup.Init)

	--Boot scripts: kept if they exist, since you may have edited their entries
	local initServer = cloneIfMissing(ServerScriptService, Setup.InitServer)
	local initClient = cloneIfMissing(StarterPlayer:WaitForChild("StarterPlayerScripts"), Setup.InitClient)

	--Server Stuff
	local services = createOrUseFolder(ServerScriptService, "Services")
	local serverClasses = createOrUseFolder(ServerScriptService, "Classes")
	local serverBinders = createOrUseFolder(ServerScriptService, "Binders")
	local serverConstants = createOrUseFolder(ServerScriptService, "Constants")

	--Shared/Client Stuff
	local network = createOrUseFolder(ReplicatedStorage, "Network")

	local binders = createOrUseFolder(ReplicatedStorage, "Binders")
	createOrUseFolder(binders, "Client")
	createOrUseFolder(binders, "Shared")

	local controllers = createOrUseFolder(ReplicatedStorage, "Controllers")
	local sharedServices = createOrUseFolder(ReplicatedStorage, "Services")

	local sharedClasses = createOrUseFolder(ReplicatedStorage, "Classes")
	local sharedConstants = createOrUseFolder(ReplicatedStorage, "Constants")

	local input = createOrUseFolder(ReplicatedStorage, "Input")

	--The old loader (before the Wally package) booted itself from ReplicatedStorage.Init
	local oldInit = ReplicatedStorage:FindFirstChild("Init")
	if oldInit and oldInit:IsA("ModuleScript") then
		warn(
			"[InitFramework] ReplicatedStorage.Init is the old version of Init and it still boots the game. "
				.. "Move any entries you added to its Entries modules into InitServer/InitClient, then delete it. "
				.. "Guide: https://kashtheking.com/init/docs/migrating"
		)
	end

	if wasOverwritten then
		print("Updated Init in ReplicatedStorage.Packages")
	else
		print("Added the Init Framework")
	end

	Selection:Set({
		initModule,
		initServer,
		initClient,

		services,
		serverClasses,
		serverBinders,
		serverConstants,

		network,
		input,
		binders,
		controllers,
		sharedServices,
		sharedClasses,
		sharedConstants,
	})

	hakariIdleDeathGambleJackpotRegeneration()
end

local function addExtras()
	hakariIdleDeathGambleJackpotRegeneration()

	local preloadScript = cloneOverwrite(ReplicatedFirst, Setup.PreloadAssets)
	local assetsFolder = cloneIfMissing(ReplicatedStorage, Setup.Assets)

	local sfxGroup = cloneIfMissing(SoundService, Setup.SFX)
	local musicGroup = cloneIfMissing(SoundService, Setup.Music)

	print("Added extras")

	Selection:Set({
		preloadScript,
		assetsFolder,
		sfxGroup,
		musicGroup,
	})

	hakariIdleDeathGambleJackpotRegeneration()
end

local function addPackages()
	hakariIdleDeathGambleJackpotRegeneration()

	local functionSelection = {}
	local addedPackages = {}
	local addedReferences = {}

	local packages = cloneIfMissing(ReplicatedStorage, Setup.Packages)
	table.insert(functionSelection, packages)

	local index = cloneIfMissing(packages, Setup.Packages._Index)
	table.insert(functionSelection, index)

	for _, package in Setup.Packages._Index:GetChildren() do
		local addedPackage = cloneIfMissing(index, package)
		table.insert(addedPackages, addedPackage)
	end

	for _, reference in Setup.Packages:GetChildren() do
		if not reference:IsA("ModuleScript") then
			continue
		end

		local addedReference = cloneIfMissing(packages, reference)
		table.insert(addedReferences, addedReference)
	end

	print("Added packages and references")

	Selection:Set(functionSelection)
	Selection:Add(addedPackages)
	Selection:Add(addedReferences)

	hakariIdleDeathGambleJackpotRegeneration()
end

local function addService()
	addTemplateWithNaming(Templates.Service)
end

local function addController()
	addTemplateWithNaming(Templates.Controller)
end

local function addGuiController()
	addTemplateWithNaming(Templates.GuiController)
end

local function addInput()
	addTemplateWithNaming(Templates.Input)
end

local function addBinder()
	addTemplateWithNaming(Templates.Binder)
end

local function addBoundClass()
	addTemplateWithNaming(Templates.BoundClass)
end

local function addClass()
	addTemplateWithNaming(Templates.Class)
end

local function addInheritedClass()
	addTemplateWithNaming(Templates.InheritedClass)
end

local function addNetwork()
	addTemplateWithNaming(Templates.Network)
end

--Connections
connections = {
	addFrameworkBtn.Click:Connect(addFramework),
	addExtrasBtn.Click:Connect(addExtras),
	addPackagesBtn.Click:Connect(addPackages),
	addServiceBtn.Click:Connect(addService),
	addControllerBtn.Click:Connect(addController),
	addGuiControllerBtn.Click:Connect(addGuiController),
	addInputBtn.Click:Connect(addInput),
	--addMechanicBtn.Click:Connect(addMechanic),
	addBinderBtn.Click:Connect(addBinder),
	addBoundClassBtn.Click:Connect(addBoundClass),
	addClassBtn.Click:Connect(addClass),
	addInheritedClassBtn.Click:Connect(addInheritedClass),
	addNetworkBtn.Click:Connect(addNetwork),
	updateScriptNameBtn.Click:Connect(updateScriptName),
}

plugin.AncestryChanged:Wait()

for _, connection in connections do
	connection:Disconnect()
end
