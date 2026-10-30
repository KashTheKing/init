---
sidebar_position: 1
title: Lifecycle
---

# Lifecycle

`Init.start(entries)` runs in this order, separately on the server and on each client.

## 1. Load

Entries load in list order. Inside an entry, every ModuleScript in its `Folders` (at any depth) is required, lowest `Priority` attribute first, then in Explorer order. Skipped:

- a ModuleScript inside another ModuleScript (it belongs to its parent, which can `require` it)
- a module whose `Ignore` attribute is `true`
- a module the entry's `Predicate` turns down (e.g. not ending in `Service`)

A module that errors while loading is reported and left out; the rest still load.

## 2. Init: one at a time

`module:Init()` runs for each module, in load order, and Init waits for each before the next. Use it for the module's **own** setup: tables, constants, instances it owns. Other modules may not have run their Init yet, so don't call into them here.

If Init errors or takes longer than `InitTimeout` (3 s), it's reported and **that module doesn't Start** or get hooks.

## 3. Start: all at once

After every Init has finished, `module:Start()` runs for every module, in load order, each in its own thread. A Start that waits (for a GUI, for data) doesn't hold up the others. This is where modules use each other.

If Start errors or runs longer than `StartTimeout` (15 s), it's reported. A Start that's still running keeps running; Init just stops waiting for it.

## 4. Hooks

As soon as a module's Start returns, its hooks connect:

| Method | Runs | Args |
| --- | --- | --- |
| `OnPlayerAdded` | for each player already in game, then each player who joins | `player` |
| `OnPlayerRemoving` | when a player leaves | `player` |
| `Step` | exactly 60 times a second, however fast frames run | `dt` (1/60) |
| `OnHeartbeat` | every `RunService.Heartbeat` | `dt` |
| `OnStepped` | every `RunService.Stepped` | `time, dt` |
| `OnRenderStepped` | client: every frame before render | `dt` |
| `OnCharacterAdded` | client: local player's current and each new character | `character` |
| `OnCharacterRemoving` | client: when the character is removed | `character` |
| `OnDied` | client: when the local player's Humanoid dies | |

Errors in a hook are reported and don't break the event. Per-frame hooks get a MicroProfiler label like `CoinService - Step`.

## 5. Done

The promise from `Init.start` resolves once every Start has returned (or timed out):

```lua
Init.start(entries):andThen(function(modules, count, seconds)
	print(modules.CoinService, count, seconds)
end)
```

## Using one module from another

Modules are plain tables, and `require` returns the same table Init loaded:

```lua
local CoinService = require(ServerScriptService.Services.CoinService)

function ShopService.Start(self)
	CoinService:Give(player, 10) -- fine: every Init has run
end
```
