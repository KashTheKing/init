---
sidebar_position: 3
title: Settings
---

# Settings

Pass overrides as the second argument of `Init.start`. A name that isn't a setting is an error, so typos are caught.

```lua
Init.start(entries, { Verbose = true, StartTimeout = 30 })
```

| Setting | Default | What |
| --- | --- | --- |
| `Verbose` | `false` | log every module as it loads, inits and starts |
| `DefaultLogEnabled` | `true` | log `🔲 Initializing` and `✅ Initialized N modules` |
| `DebugLabelFormat` | `"%s - %s"` | MicroProfiler label for per-frame hooks (module, method) |
| `InitTimeout` | `3` | seconds to wait for each `Init` |
| `StartTimeout` | `15` | seconds to wait for each `Start` |
| `DefaultPriority` | `0` | priority of modules without a `Priority` attribute |
| `IgnoreAttribute` | `"Ignore"` | attribute that skips a module |
| `PriorityAttribute` | `"Priority"` | attribute that orders modules |

The method names are settings too, if you'd rather call them something else:

| Setting | Default |
| --- | --- |
| `InitMethod` | `"Init"` |
| `StartMethod` | `"Start"` |
| `PlayerAdded` | `"OnPlayerAdded"` |
| `PlayerRemoving` | `"OnPlayerRemoving"` |
| `Accumulator` | `"Step"` |
| `Heartbeat` | `"OnHeartbeat"` |
| `Stepped` | `"OnStepped"` |
| `RenderStepped` | `"OnRenderStepped"` |
| `Died` | `"OnDied"` |
| `CharacterAdded` | `"OnCharacterAdded"` |
| `CharacterRemoving` | `"OnCharacterRemoving"` |

Source: [`Settings.luau`](https://github.com/KashTheKing/init/blob/main/src/Init/Settings.luau).
