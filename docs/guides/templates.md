---
sidebar_position: 4
title: Templates
---

# Templates

Every module type, ready to copy. Replace `_SNIPPET_` with your name (the plugin's buttons do it for you).
Raw files for AI: `https://kashtheking.com/init/templates/<File>`.

## Binder

[Raw](pathname:///init/templates/Binder.luau)

```lua
--!strict
-- A Binder (kashtheking/binder): runs code for every instance with a tag, and cleans up when it goes away.
-- Install Trove and Binder from Wally or the plugin's "Add Packages".
-- Put it in ServerScriptService/Binders (server), ReplicatedStorage/Binders/Client (client) or
-- ReplicatedStorage/Binders/Shared (both). Init calls the binder's Start for you.
-- This example pushes every part tagged "_SNIPPET_" forward at its "Speed" attribute.
-- Binder docs: https://kashtheking.com/library/docs/packages/binder
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Binder = require(ReplicatedStorage.Packages.Binder)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- Called for each matching instance. The trove is cleaned when the instance is unbound;
-- anything you return with a :Destroy() method is cleaned too.
local function _SNIPPET_(part: BasePart, trove: Trove.Trove, speed: number)
	trove:Connect(RunService.Heartbeat, function()
		part.AssemblyLinearVelocity = part.CFrame.LookVector * speed
	end)

	return trove
end

return Binder.new(_SNIPPET_, {
	Tags = { "_SNIPPET_" }, -- instances need one of these CollectionService tags
	ClassNames = { "BasePart" }, -- and must be one of these classes (optional)
	Ancestors = { workspace }, -- and must be inside one of these (optional)

	-- Last check (optional). Return true to bind; anything returned after true goes to the constructor.
	Predicate = function(instance: Instance)
		local speed = tonumber(instance:GetAttribute("Speed"))
		if not speed then
			warn(`[_SNIPPET_Binder] {instance:GetFullName()} needs a number "Speed" attribute`)
			return false
		end
		return true, speed
	end,
})
```

## BoundClass

[Raw](pathname:///init/templates/BoundClass.luau)

```lua
--!strict
-- A class for a Binder to construct, one per bound instance: Binder.new(_SNIPPET_, { Tags = { "_SNIPPET_" } }).
-- Put it next to the Binder that uses it. The Binder cleans the trove when the instance is unbound.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)

local _SNIPPET_ = {}
_SNIPPET_.__index = _SNIPPET_

export type _SNIPPET_Properties = {
	Instance: Instance,
	Trove: Trove.Trove,
}

export type _SNIPPET_ = typeof(setmetatable({} :: _SNIPPET_Properties, _SNIPPET_))

export type ClassType = _SNIPPET_

-- Called by the Binder for each bound instance. Values your Binder's Predicate returns after `true`
-- arrive as extra parameters after the trove.
function _SNIPPET_.new(instance: Instance, trove: Trove.Trove): _SNIPPET_
	local self = setmetatable(
		{
			Instance = instance,
			Trove = trove,
		} :: _SNIPPET_Properties,
		_SNIPPET_
	)

	return self
end

-- Called by the Binder when the instance is unbound
function _SNIPPET_.Destroy(self: _SNIPPET_): () end

return _SNIPPET_
```

## Class

[Raw](pathname:///init/templates/Class.luau)

```lua
--!strict
-- A plain class (an object you make many of with .new). Init does NOT load classes; require them yourself.
-- Put it in ReplicatedStorage/Classes (shared) or ServerScriptService/Classes (server-only).
local _SNIPPET_ = {}
_SNIPPET_.__index = _SNIPPET_

export type _SNIPPET_Properties = {}

export type _SNIPPET_ = typeof(setmetatable({} :: _SNIPPET_Properties, _SNIPPET_))

export type ClassType = _SNIPPET_

-- Creates a new _SNIPPET_
function _SNIPPET_.new(): _SNIPPET_
	local properties: _SNIPPET_Properties = {}

	local self = setmetatable(properties, _SNIPPET_)

	return self
end

-- Cleans up the _SNIPPET_
function _SNIPPET_.Destroy(self: _SNIPPET_): () end

return _SNIPPET_
```

## Controller

[Raw](pathname:///init/templates/Controller.luau)

```lua
--!strict
-- A Controller: client-only game logic that Init loads and starts for you. Name it <Something>Controller.
-- Put it in ReplicatedStorage/Controllers. Every method below is optional; delete the ones you don't use.
local _SNIPPET_Controller = {}

export type _SNIPPET_Controller = typeof(_SNIPPET_Controller)

-- Runs first, one module at a time. Set up this module's own state here.
-- Don't wait for other modules here (they may not have run Init yet); use Start for that.
function _SNIPPET_Controller.Init(self: _SNIPPET_Controller) end

-- Runs after every module's Init has finished. Safe to use other modules here.
-- Waiting here is fine for a few seconds (StartTimeout is 15s); it doesn't hold up other modules.
function _SNIPPET_Controller.Start(self: _SNIPPET_Controller) end

---- Runs for the local player's current character, then every time it respawns
--function _SNIPPET_Controller.OnCharacterAdded(self: _SNIPPET_Controller, character: Model)
--
--end

---- Runs when the local player's character is being removed
--function _SNIPPET_Controller.OnCharacterRemoving(self: _SNIPPET_Controller, character: Model)
--
--end

---- Runs when the local player's Humanoid dies
--function _SNIPPET_Controller.OnDied(self: _SNIPPET_Controller)
--
--end

---- Runs every frame before it renders (camera, UI that follows things)
--function _SNIPPET_Controller.OnRenderStepped(self: _SNIPPET_Controller, dt: number)
--
--end

---- Runs for every player already in the game (the local player too), then for every player who joins
--function _SNIPPET_Controller.OnPlayerAdded(self: _SNIPPET_Controller, player: Player)
--
--end

---- Runs when a player is leaving the game
--function _SNIPPET_Controller.OnPlayerRemoving(self: _SNIPPET_Controller, player: Player)
--
--end

---- Runs exactly 60 times a second, however fast the frames are
--function _SNIPPET_Controller.Step(self: _SNIPPET_Controller, dt: number)
--
--end

---- Runs every RunService.Heartbeat
--function _SNIPPET_Controller.OnHeartbeat(self: _SNIPPET_Controller, dt: number)
--
--end

return _SNIPPET_Controller
```

## GuiController

[Raw](pathname:///init/templates/GuiController.luau)

```lua
--!strict
-- A Controller for one ScreenGui. Name the ScreenGui in StarterGui "_SNIPPET_" (or change the name below).
-- Put it in ReplicatedStorage/Controllers. It's a normal Controller with the GUI lookup done for you.
local Players = game:GetService("Players")

local player = assert(Players.LocalPlayer, "_SNIPPET_GuiController must be required on the client")
local PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

-- Gives you autocomplete for the ScreenGui's children (works when the ScreenGui exists in StarterGui)
export type Gui = typeof(game:GetService("StarterGui")["_SNIPPET_"])

local _SNIPPET_GuiController = {
	Gui = (nil :: any) :: Gui,
}

export type _SNIPPET_GuiController = typeof(_SNIPPET_GuiController)

-- The ScreenGui is copied into PlayerGui when the player spawns, which can take a moment, so wait for it in Start
function _SNIPPET_GuiController.Start(self: _SNIPPET_GuiController)
	self.Gui = assert(
		PlayerGui:WaitForChild("_SNIPPET_", 5) :: any,
		`[_SNIPPET_GuiController] the ScreenGui "_SNIPPET_" didn't appear in PlayerGui`
	)
end

return _SNIPPET_GuiController
```

## InheritedClass

[Raw](pathname:///init/templates/InheritedClass.luau)

```lua
--!strict
-- A class that inherits from another class. Insert it as a child of the parent class's ModuleScript.
-- Init does NOT load classes; require them yourself.
local SuperClass = require(script.Parent)

local _SNIPPET_ = setmetatable({}, SuperClass)
_SNIPPET_.__index = _SNIPPET_

export type _SNIPPET_ = typeof(_SNIPPET_) & SuperClass.ClassType & {
	__super: SuperClass.ClassType,
}

export type ClassType = _SNIPPET_

-- Creates a new _SNIPPET_; arguments go to the parent class's .new
function _SNIPPET_.new(...: any): _SNIPPET_
	local super = SuperClass.new(...)

	local self: _SNIPPET_ = setmetatable(super :: any, _SNIPPET_) :: any
	self.__super = super

	return self
end

return _SNIPPET_
```

## Input

[Raw](pathname:///init/templates/Input.model.json)

```json
{
	"className": "InputContext",
	"properties": {
		"Priority": 1000,
		"Sink": false
	},
	"children": [
		{
			"name": "InputAction",
			"className": "InputAction",
			"properties": {
				"Type": "Bool"
			},
			"children": [
				{ "name": "Mouse", "className": "InputBinding", "properties": { "KeyCode": "MouseLeftButton" } },
				{ "name": "Keyboard", "className": "InputBinding" },
				{ "name": "Gamepad", "className": "InputBinding", "properties": { "KeyCode": "ButtonR2" } },
				{ "name": "Touch", "className": "InputBinding" }
			]
		}
	]
}
```

## Network

[Raw](pathname:///init/templates/Network.luau)

```lua
--!strict
-- Network packets, made with kashtheking/packet (install it from Wally or the plugin's "Add Packages").
-- Put it in ReplicatedStorage/Network. Init loads Network first on both sides, so every packet exists
-- before anything sends one. Docs: https://kashtheking.com/library/docs/packages/packet
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Packages.Packet)

return {
	-- Packet.new(name, ...types). Use exact types (Packet.NumberU8, Packet.String, ...) for smaller packets.
	_SNIPPET_ = Packet.new("_SNIPPET_", Packet.Any),
}
```

## Service

[Raw](pathname:///init/templates/Service.luau)

```lua
--!strict
-- A Service: game logic that Init loads and starts for you. Name it <Something>Service.
-- Server-only: ServerScriptService/Services. Shared (runs on server AND client): ReplicatedStorage/Services.
-- Every method below is optional; delete the ones you don't use.
local _SNIPPET_Service = {}

export type _SNIPPET_Service = typeof(_SNIPPET_Service)

-- Runs first, one module at a time. Set up this module's own state here.
-- Don't wait for other modules here (they may not have run Init yet); use Start for that.
function _SNIPPET_Service.Init(self: _SNIPPET_Service) end

-- Runs after every module's Init has finished. Safe to use other modules here.
-- Waiting here is fine for a few seconds (StartTimeout is 15s); it doesn't hold up other modules.
function _SNIPPET_Service.Start(self: _SNIPPET_Service) end

---- Runs for every player already in the game, then for every player who joins
--function _SNIPPET_Service.OnPlayerAdded(self: _SNIPPET_Service, player: Player)
--
--end

---- Runs when a player is leaving the game
--function _SNIPPET_Service.OnPlayerRemoving(self: _SNIPPET_Service, player: Player)
--
--end

---- Runs exactly 60 times a second, however fast the frames are (good for game ticks)
--function _SNIPPET_Service.Step(self: _SNIPPET_Service, dt: number)
--
--end

---- Runs every RunService.Heartbeat
--function _SNIPPET_Service.OnHeartbeat(self: _SNIPPET_Service, dt: number)
--
--end

---- Runs every RunService.Stepped (before physics)
--function _SNIPPET_Service.OnStepped(self: _SNIPPET_Service, time: number, dt: number)
--
--end

return _SNIPPET_Service
```
