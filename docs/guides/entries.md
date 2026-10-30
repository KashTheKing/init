---
sidebar_position: 2
title: Entries and folders
---

# Entries and folders

The boot scripts decide what loads and in what order. Each entry is a group of folders:

```lua
Init.start({
	{ Folders = { ReplicatedStorage.Network } },                     -- 1st: every module in Network
	{
		Folders = { ReplicatedStorage.Services, ServerScriptService.Services },
		Predicate = Init.matchesName("Service$"),                      -- 2nd: only names ending in Service
	},
	{ Folders = { ReplicatedStorage.Binders.Shared, ServerScriptService.Binders } }, -- 3rd
})
```

- **Order:** entries load in list order. Inside an entry, the `Priority` attribute (lower first) then Explorer order.
- **Predicate:** a function `(module) -> boolean`. `Init.matchesName(pattern)` makes one from a [string pattern](https://create.roblox.com/docs/luau/strings#string-patterns): `"Service$"` ends in Service, `"^Admin"` starts with Admin.
- **Shared folders** (in ReplicatedStorage) go in **both** boot scripts.

## Adding your own folder

Say you want `ReplicatedStorage.Systems` with modules named `...System`:

1. Make the folder.
2. Add an entry to `InitServer` and `InitClient` (or just one, if it's one-sided):

   ```lua
   { Folders = { ReplicatedStorage.Systems }, Predicate = Init.matchesName("System$") },
   ```

## Attributes

Set these on a ModuleScript in the Properties window:

| Attribute | Type | Effect |
| --- | --- | --- |
| `Ignore` | boolean | `true`: Init skips it |
| `Priority` | number | lower loads earlier inside its entry (default 0) |

## The old Entries modules

The old Init kept entries in `SharedEntries`/`ServerEntries`/`ClientEntries` modules as named dictionaries with `Order`. That format still works: `Init.start(require(path.to.ServerEntries))` sorts it by `Order`. See [Migrating](../migrating.md).
