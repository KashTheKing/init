---
sidebar_position: 2
title: Install with AI
---

# Install with AI

Init ships an **AI skill**: one file that teaches an AI how to install Init, where every kind of module goes and the rules to follow. Point your AI at it.

- Skill: [`https://kashtheking.com/init/SKILL.md`](https://kashtheking.com/init/SKILL.md)
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

Install the skill once and Claude uses it whenever you mention Init:

```bash
mkdir -p ~/.claude/skills/init-framework && curl -L https://kashtheking.com/init/SKILL.md -o ~/.claude/skills/init-framework/SKILL.md
```

With the **Roblox Studio MCP** connected, Claude can create the modules in Studio and playtest. With a Rojo project, it edits files and runs `wally install`.

## If your AI can't touch Studio

Chat AIs (ChatGPT, Claude.ai) can't click in Studio. Do the setup with the [plugin](no-code.md) (two clicks), then ask the AI for module code and paste it into a module the plugin made.

## Check the AI's work

Press Play. The Output should say `✅ Initialized N Server modules` and `✅ Initialized N Client modules`. Anything that starts with `[Init]` is an error: paste it back to the AI. See [Troubleshooting](../guides/troubleshooting.md).
