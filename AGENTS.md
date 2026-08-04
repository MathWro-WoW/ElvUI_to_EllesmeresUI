# Repository Guide

## Purpose

This repository contains a World of Warcraft: Midnight addon that migrates the active ElvUI profile into a newly created EllesmereUI profile.

## Layout

- `Migration.lua` — source discovery, value conversion, staged execution, profile commit, and selected account-wide tooltip settings.
- `UI.lua` — migration window, component selection, progress, warnings, optional addon disabling, and reload flow.
- `Core.lua` — addon lifecycle, automatic prompt, slash commands, and AddOn Compartment entry point.
- `ElvUI_to_EllesmeresUI.toc` — metadata, dependencies, saved variables, and load order.
- `tests/` — Lua 5.1 fixture and addon-load smoke coverage.
- `graphify-out/` — generated architecture graph and report.

## Load-order contract

The TOC order is intentional:

1. `Migration.lua` defines the namespace API and component registry.
2. `UI.lua` consumes that API and defines `ns.UI`.
3. `Core.lua` registers lifecycle events and public entry points.

Do not reorder these files without updating and running the load smoke test.

## Invariants

- Treat ElvUI and every adjacent addon directory as read only.
- Never mutate the active ElvUI profile.
- Never overwrite an existing EllesmereUI profile name.
- Prepare selected conversions before creating the destination profile.
- Preserve EllesmereUI profile-table identities by syncing values in place.
- Keep EllesmereUI's live font database aligned with the committed profile so its logout hook cannot restore stale fonts.
- Only stage EllesmereUI account-wide settings when their component is selected; tooltip cursor placement and ID-display settings are suite-wide rather than profile-local.
- Keep migration work staged through timers so the UI can render progress between components.
- Lock profile and component controls while a migration is active.
- Keep both addon-disable choices opt-in, and apply them only after migration succeeds when the user explicitly reloads.
- Do not manipulate protected frames during combat.
- Report lossy or unsupported mappings as user-visible warnings rather than silently discarding them.
- Preserve Lua 5.1 compatibility: no later-language syntax or standard-library assumptions.

## Verification

For any behavioral change, run:

```sh
luac -p Migration.lua UI.lua Core.lua tests/migration_spec.lua tests/addon_load_spec.lua
lua tests/migration_spec.lua
lua tests/addon_load_spec.lua
```

Tests must defend observable migration, lifecycle, UI, or packaging contracts. Keep fixtures deterministic and independent of a running WoW client.

## Architecture graph

If `graphify-out/graph.json` exists, query it before broad codebase exploration:

```sh
graphify query "<question>"
graphify path "<node A>" "<node B>"
graphify explain "<node>"
```

After structural code changes, rebuild with `graphify extract . --code-only`. Do not hand-edit generated graph artifacts.

## Releases

- Keep addon archives rooted at `ElvUI_to_EllesmeresUI/`.
- Exclude tests, repository guidance, CI configuration, and graph artifacts from release archives.
- Tag-based releases publish to GitHub through `.github/workflows/release.yml`.
- CurseForge publishing remains disabled until both its project ID and repository secret are deliberately configured.
