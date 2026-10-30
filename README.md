# Init

**A module loader for Roblox games.** Put your modules in folders. Init requires them in the order you choose, calls every module's `Init`, then every module's `Start`, and connects `OnPlayerAdded`, `Step`, `OnCharacterAdded` and the rest for you.

📖 **Docs:** https://kashtheking.com/init/ · 🧩 **Plugin:** [Init Framework](https://create.roblox.com/store/asset/77164672536940/Init-Framework) · 📦 **Wally:** `kashtheking/init` · 💬 [Discord](https://discord.gg/6HYgCk22eD)

<!--moonwave-hide-before-this-line-->

## Install

| You are... | Do this |
| --- | --- |
| New to scripting | Install the [Init Framework plugin](https://create.roblox.com/store/asset/77164672536940/Init-Framework), press **Setup**. [Guide](https://kashtheking.com/init/docs/install/no-code/) |
| Using an AI (Claude, Cursor, ChatGPT) | Paste the prompt from [Install with AI](https://kashtheking.com/init/docs/install/with-ai/). |
| Using Rojo + Wally | `Init = "kashtheking/init@1.0.1"` in `wally.toml`. [Guide](https://kashtheking.com/init/docs/install/wally/) |
| Using Studio, no plugin | Drag `Init.rbxm` from [Releases](https://github.com/KashTheKing/init/releases/latest) into `ReplicatedStorage.Packages`. |

## What it looks like

```lua
-- ServerScriptService/InitServer (Script)
local Init = require(ReplicatedStorage.Packages.Init)

Init.start({
	{ Folders = { ReplicatedStorage.Network } },
	{ Folders = { ReplicatedStorage.Services, ServerScriptService.Services }, Predicate = Init.matchesName("Service$") },
})
```

```lua
-- ServerScriptService/Services/CoinService
local CoinService = {}

function CoinService.Init(self) self.Coins = {} end           -- own state only
function CoinService.Start(self) end                           -- other modules are ready
function CoinService.OnPlayerAdded(self, player) self.Coins[player] = 0 end
function CoinService.OnPlayerRemoving(self, player) self.Coins[player] = nil end

return CoinService
```

## This repository

| Path | What |
| --- | --- |
| [`src/Init`](src/Init) | The package (`kashtheking/init`) |
| [`templates`](templates) | Module templates (Service, Controller, Binder, ...), used by the plugin and by AI |
| [`example`](example) | A starter place: boot scripts, folders, one service and one controller |
| [`plugin`](plugin) | The Init Framework Studio plugin (FSL-1.1-ALv2) |
| [`skills/init/SKILL.md`](skills/init/SKILL.md) | The AI skill (also a Claude Code plugin: `/plugin marketplace add KashTheKing/init`) |
| [`docs`](docs) | The docs site (Moonwave) |
| [`tests`](tests) | Lune tests: `lune run tests/run` |

```sh
rokit install                                   # rojo, wally, lune, selene, stylua, luau-lsp
lune run tests/run                              # tests, no Studio needed
selene src templates example plugin tests/run.luau
rojo serve example.project.json                 # try the example in Studio
rojo build plugin.project.json -o InitFramework.rbxmx   # after `wally install` in plugin/
```

MIT licensed, except `plugin/` ([FSL-1.1-ALv2](plugin/LICENSE.md): free to use and change, not for a competing product; each version becomes Apache-2.0 after two years). Promise is [evaera/roblox-lua-promise](https://github.com/evaera/roblox-lua-promise) (MIT), bundled so Init has no dependencies.
