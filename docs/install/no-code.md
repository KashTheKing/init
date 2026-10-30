---
sidebar_position: 1
title: Install without code
---

# Install without code

The **Init Framework** plugin sets up everything. You don't need to write a line.

1. Get the plugin from the Creator Store: [Init Framework](https://create.roblox.com/store/asset/77164672536940/Init-Framework). In Studio it appears in the **Plugins** tab.
2. Open your place and press **Setup**. This adds:
   - the loader at `ReplicatedStorage.Packages.Init`
   - `InitServer` in ServerScriptService and `InitClient` in StarterPlayer › StarterPlayerScripts
   - the folders: `Network`, `Services`, `Controllers`, `Binders`, `Classes`, `Constants`, `Input`
3. Press **Add Packages** for Trove, Signal, Packet and Binder (the Network and Binder templates use them).
4. Press **Play**. The Output shows `✅ Initialized 0 Server modules` and `✅ Initialized 0 Client modules`. Init is running.

## Add your first module

1. Click the `Services` folder in **ServerScriptService**.
2. Press **Service** in the plugin. A new module opens.
3. Rename it in the Explorer to `Coin`. The plugin renames it `CoinService` and fills the name into the code.
4. Write your code in the methods (delete the ones you don't need) and press Play.

Every button works the same way: select the folder, press the button, rename.

| Button | Makes | Put it in |
| --- | --- | --- |
| Service | game logic (`...Service`) | ServerScriptService › Services (server) or ReplicatedStorage › Services (both) |
| Controller | client logic (`...Controller`) | ReplicatedStorage › Controllers |
| Gui Controller | a controller for one ScreenGui | ReplicatedStorage › Controllers |
| Network | Packet remote events | ReplicatedStorage › Network |
| Binder | code for every part with a tag | ServerScriptService › Binders, ReplicatedStorage › Binders › Client or Shared |
| Bound Class | a class for a Binder | next to the Binder |
| Class / InheritedClass | an object class | ReplicatedStorage › Classes |
| Input | an InputContext | ReplicatedStorage › Input |
| Add Extras | an `Assets` folder that preloads, plus SFX and Music sound groups | |
| Update Script Name | renames the open script to the text you selected | |

What every template does: [Templates](../guides/templates.md).

:::tip Let an AI write the modules
Once Setup is done, an AI can add modules for you. See [Install with AI](with-ai.md).
:::
