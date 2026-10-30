---
sidebar_position: 5
title: Troubleshooting
---

# Troubleshooting

Init's errors start with `[Init]` and name the module and method.

| You see | Why | Fix |
| --- | --- | --- |
| `Network is not a valid member of ReplicatedStorage` | a boot script names a folder that doesn't exist | make the folder, or remove the entry |
| `... must return exactly one value` | the module doesn't end with `return` | add `return MyModule` at the bottom |
| `X:Init() didn't finish within 3s` | Init is waiting (WaitForChild, a DataStore, another module) | move the waiting into `Start` |
| `X:Start() didn't finish within 15s` | Start waits a long time | fine if intended (it keeps running); otherwise `task.spawn` the loop or raise `StartTimeout` |
| `X:Init() errored: ...` | a bug in Init | fix it; that module won't Start until then |
| `Two loaded modules are named "X"` | two modules share a name | rename one; both still run |
| `Init.start was already called` | two boot scripts on one side | keep one InitServer and one InitClient (the old `ReplicatedStorage.Init` boots too, see [Migrating](../migrating.md)) |
| `"X" isn't a setting` | a typo in the settings table | check [Settings](settings.md) |

## A module never runs

- Its name doesn't match the entry's predicate: `Coins` isn't loaded by `matchesName("Service$")`; name it `CoinService`.
- It's inside another ModuleScript. Only top-level modules (folders are fine) load.
- It has the `Ignore` attribute.
- It's in a folder no entry lists, or on the wrong side (a Controller in ServerScriptService).
- Turn on `Verbose = true` to see every module Init loads.

## Nothing prints at all

The boot scripts aren't running: `InitServer` must be a **Script** in ServerScriptService and `InitClient` a **LocalScript** in StarterPlayerScripts, both enabled.
