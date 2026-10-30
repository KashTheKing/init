---
sidebar_position: 3
title: Install with Wally
---

# Install with Rojo + Wally

1. Add Init to `wally.toml`:

   ```toml
   [dependencies]
   Init = "kashtheking/init@1.0.1"
   ```

2. `wally install`, and map `Packages` to `ReplicatedStorage.Packages` in your project file.

3. Add the boot scripts and folders. The [example project](https://github.com/KashTheKing/init/tree/main/example) has all of them; copy it, or start from it:

   ```bash
   git clone https://github.com/KashTheKing/init && cd init && rojo serve example.project.json
   ```

   - [`ServerScriptService/InitServer.server.luau`](https://github.com/KashTheKing/init/blob/main/example/ServerScriptService/InitServer.server.luau)
   - [`StarterPlayer/StarterPlayerScripts/InitClient.client.luau`](https://github.com/KashTheKing/init/blob/main/example/StarterPlayerScripts/InitClient.client.luau)

   Every folder a boot script names must exist. Git doesn't keep empty folders, so add a `.gitkeep` to each (Rojo ignores it) or declare them in the project file with `"$className": "Folder"`.

4. `rojo serve`, connect from Studio and press Play.

Your folders, names and order are yours: change the entries in the boot scripts. See [Entries](../guides/entries.md).

The [templates](../guides/templates.md) are plain `.luau` files you can copy (Wally also puts them in `Packages/_Index/kashtheking_init@<version>/init/templates/`), and the [plugin](no-code.md)'s template buttons work in Rojo games too.
