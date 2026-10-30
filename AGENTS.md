# AGENTS.md

Init is a Roblox module loader (`kashtheking/init`). To **use** Init in a game, read `skills/init/SKILL.md`. This file is for changing this repository.

- `src/Init/init.luau` is the loader; `Settings.luau` its defaults; `Promise/` is vendored evaera Promise (don't edit `Promise.luau`).
- `templates/` are the module templates (`_SNIPPET_` is replaced with the name). The plugin bundles them and the docs page `docs/guides/templates.md` is generated from them by `npm run docs:build`; don't edit that page.
- `example/` is the starter place and the source of the boot scripts the plugin installs.
- `plugin/Plugin.server.luau` is the Studio plugin; build with `rojo build plugin.project.json -o build/InitFramework.rbxmx` after `wally install` in `plugin/`.
- Behaviour changes need a test in `tests/run.luau` and an update to `docs/guides/lifecycle.md` and the skill.

Checks before committing:

```sh
lune run tests/run
stylua --check src templates example plugin/*.luau tests/run.luau
selene src templates example plugin/Plugin.server.luau plugin/PreloadAssets.client.luau tests/run.luau
```

Release: bump `wally.toml` and `.claude-plugin/plugin.json`, `wally publish`, attach `build/Init.rbxm` and `build/InitFramework.rbxmx` to a GitHub release, `npm run publish:docs`.
