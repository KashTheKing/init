---
sidebar_position: 1
title: What is Init?
---

# What is Init?

Init is a **module loader**: the thing that starts your game's code.

Without one, every Script runs on its own, in an order you don't control, and each one connects `Players.PlayerAdded`, `RunService.Heartbeat` and friends by hand. With Init, your game has exactly two scripts (one for the server, one for the client) and everything else is a ModuleScript in a folder:

```
ReplicatedStorage
├─ Packages/Init            the loader
├─ Network                  remote events (loaded first)
├─ Services                 code for server AND client   (names end in Service)
├─ Controllers              code for the client only     (names end in Controller)
└─ Binders/Shared, Client   code that runs per tagged instance
ServerScriptService
├─ InitServer               boots the server
├─ Services                 server-only code              (names end in Service)
└─ Binders
StarterPlayer/StarterPlayerScripts
└─ InitClient               boots the client
```

When the game starts, Init:

1. **Loads** every module, folder by folder, in the order the boot script lists them.
2. Calls **`Init`** on each one, one at a time. Modules set up their own data here.
3. Calls **`Start`** on all of them. Now every module is ready, so they can use each other.
4. Connects their **hooks**: `OnPlayerAdded`, `OnPlayerRemoving`, `Step` (60 times a second), `OnHeartbeat`, and on the client `OnCharacterAdded`, `OnDied`, `OnRenderStepped`...

A module only writes the methods it needs:

```lua
local CoinService = {}

function CoinService.Init(self)
	self.Coins = {}
end

function CoinService.OnPlayerAdded(self, player: Player)
	self.Coins[player] = 0
end

function CoinService.OnPlayerRemoving(self, player: Player)
	self.Coins[player] = nil
end

return CoinService
```

## Pick how to install

- **[Without code](install/no-code.md):** the Init Framework plugin. Two clicks.
- **[With AI](install/with-ai.md):** paste one prompt into Claude, Cursor or ChatGPT.
- **[Rojo + Wally](install/wally.md):** `kashtheking/init`.
- **[Studio, by hand](install/model.md):** drag in `Init.rbxm`.

Next: [the lifecycle](guides/lifecycle.md) explains exactly when each method runs.
