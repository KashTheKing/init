---
sidebar_position: 4
title: Install by hand
---

# Install by hand in Studio

1. Download `Init.rbxm` from the [latest release](https://github.com/KashTheKing/init/releases/latest).
2. In Studio, make a Folder named `Packages` in ReplicatedStorage. Drag `Init.rbxm` onto it (or right-click it › **Insert from File**).
3. Make a **Script** named `InitServer` in ServerScriptService and paste in [InitServer](https://github.com/KashTheKing/init/blob/main/example/ServerScriptService/InitServer.server.luau).
4. Make a **LocalScript** named `InitClient` in StarterPlayer › StarterPlayerScripts and paste in [InitClient](https://github.com/KashTheKing/init/blob/main/example/StarterPlayerScripts/InitClient.client.luau).
5. Make the folders the boot scripts name: in ReplicatedStorage `Network`, `Services`, `Controllers`, `Binders` (with `Shared` and `Client` inside); in ServerScriptService `Services` and `Binders`.
6. Press Play and look for `✅ Initialized` in the Output.

The [plugin](no-code.md)'s Setup button does all of this for you.
