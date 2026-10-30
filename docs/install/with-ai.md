---
sidebar_position: 2
title: Install with AI
---

# Install with AI

Init ships an **AI skill**: one file that teaches an AI how to install Init (in a Rojo project or in Studio), where every kind of module goes, the rules to follow, and every template. Point your AI at it.

- Skill, with every template inside: [`https://kashtheking.com/init/SKILL.md`](https://kashtheking.com/init/SKILL.md)
- Templates (raw): `https://kashtheking.com/init/templates/Service.luau`, `Controller.luau`, `Binder.luau`, ...
- Everything in one page for AI: [`https://kashtheking.com/init/llms.txt`](https://kashtheking.com/init/llms.txt)

## Copy this prompt

Paste it into Claude, Cursor, ChatGPT or any AI that can read web pages:

```text
Read https://kashtheking.com/init/SKILL.md and follow it.
Set up the Init framework (kashtheking/init) in my Roblox game, then add a CoinService
that gives every player 100 coins when they join and shows them on the leaderboard.
```

Change the second part to whatever you want built. After setup, you can keep asking: *"add a ShopGuiController for my Shop ScreenGui"*, *"add a LavaBinder that kills players who touch parts tagged Lava"*.

## Claude Code

Install the plugin once and Claude uses the skill whenever you mention Init. It carries the templates, so it works offline:

```text
/plugin marketplace add KashTheKing/init
/plugin install init@kashtheking-init
```

In a Rojo project, Claude edits files and runs `wally install`. With the **Roblox Studio MCP** connected, it can create the modules in Studio and playtest.

## Roblox Studio's Assistant

Studio's built-in Assistant can't read web pages, so give it the skill once:

1. Open [`kashtheking.com/init/SKILL.md`](https://kashtheking.com/init/SKILL.md), select everything (Ctrl+A) and copy it.
2. In Studio's Assistant, type `Save this as a skill named init-framework:` and paste.

It shows up under the Assistant's **Skills** tab and is used whenever you ask for Init things. The Assistant can't install plugins, so press **Setup** in the [plugin](no-code.md) yourself first.

## Cursor, Codex and other coding AIs

In a Rojo project with Init installed by Wally, the skill and templates are on disk at `Packages/_Index/kashtheking_init@<version>/init/skills/init/SKILL.md` and `.../init/templates/`. Add one line to your `AGENTS.md` (or `.cursor/rules`):

```text
This game uses the Init framework. Before changing modules, read Packages/_Index/kashtheking_init@*/init/skills/init/SKILL.md.
```

## If your AI can't touch Studio or files

Chat AIs (ChatGPT, Claude.ai) can't click in Studio. Do the setup with the [plugin](no-code.md) (two clicks), then ask the AI for module code and paste it into a module the plugin made.

## Check the AI's work

Press Play. The Output should say `✅ Initialized N Server modules` and `✅ Initialized N Client modules`. Anything that starts with `[Init]` is an error: paste it back to the AI. See [Troubleshooting](../guides/troubleshooting.md).
