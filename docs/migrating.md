---
sidebar_position: 4
title: Migrating from the old Init
---

# Migrating from the old Init

The old Init was a ModuleScript at `ReplicatedStorage.Init` with `Settings`, `SharedEntries`, `ServerEntries`, `ClientEntries` and two scripts inside it that booted the game. Your modules don't change: same `Init`, `Start` and hook methods.

1. Press **Setup** in the [plugin](install/no-code.md) (or [install by hand](install/model.md)). It adds `ReplicatedStorage.Packages.Init`, `InitServer` and `InitClient`.
2. If you changed the old Entries modules, copy those folders into the new boot scripts as list entries (`Order` becomes the position in the list). If you changed `Settings`, pass those values as the second argument of `Init.start`.
3. Delete `ReplicatedStorage.Init`. While it's there, it boots the game a second time.
4. Press Play and check for `✅ Initialized`.

## What behaves differently

- **Every Init runs before any Start.** The old loader ran Init then Start per module, so a Start could run before other modules' Init. If a Start relied on that, move the code into Init.
- **Starts run at the same time.** A slow Start no longer holds up the modules after it.
- **Modules run in the order you list.** The old loader required in order but called Init/Start in an arbitrary order.
- **Modules inside a ModuleScript aren't loaded.** The old one loaded them too, unless a predicate filtered them out.
- **`Step` runs at 60 per second.** The old one read `Stepped`'s first argument (the game time) as the frame time, so it could run many extra steps per frame.
- **A timed-out Init or Start keeps running.** The old one cancelled it.
- Start errors are always reported (the old one only reported them with `Verbose`).
