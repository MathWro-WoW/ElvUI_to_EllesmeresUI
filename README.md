# ElvUI to EllesmereUI

A one-time migration assistant for World of Warcraft: Midnight. It creates a new EllesmereUI profile from the active ElvUI profile while leaving the source profile unchanged.

## Requirements

- World of Warcraft Retail / Midnight
- EllesmereUI 8.7.3 or newer
- ElvUI enabled for the login in which the migration runs
- The corresponding EllesmereUI modules enabled for settings you want to use

## Installation

1. Place the addon in `Interface/AddOns/ElvUI_to_EllesmeresUI`.
2. Enable **ElvUI to EllesmereUI**, **ElvUI**, **EllesmereUI**, and the EllesmereUI modules you plan to migrate.
3. Log in and use the migration window that opens automatically.

The window can also be opened from the AddOn Compartment or with any of these slash commands:

```text
/e2e
/e2eui
/elvtoeui
```

## Using the migrator

1. Confirm the detected ElvUI source profile.
2. Enter a unique name for the new EllesmereUI profile.
3. Select the components to migrate.
4. Choose whether ElvUI should be disabled when the UI reloads.
5. Select **Create profile** and follow the visible progress indicator.
6. Review any warnings printed in chat, then reload the UI.

The migration runs in stages and reports the active component, completed steps, and percentage. Controls are locked while profile data is being prepared so the selected migration cannot change mid-run.

## Supported components

- Global fonts, outlines, and status-bar textures
- Player and target frames
- Focus, pet, target-of-target, focus-target, and boss frames
- Party frames
- Raid frames and supported raid-size overrides
- Action bars, stance bar, and pet bar
- Minimap

Where the addons expose equivalent settings, the migrator copies dimensions, positions, growth directions, visibility, sorting, textures, fonts, colors, text, cast bars, portraits, auras, and related layout options.

## Safety and limitations

- The active ElvUI profile is read only.
- Migration always creates a new EllesmereUI profile; it will not overwrite an existing profile name.
- Unselected components retain the values inherited from the current EllesmereUI profile.
- Custom fonts and textures remain SharedMedia references. Keep their media provider enabled if EllesmereUI cannot resolve them independently.
- ElvUI action pages 7–9 do not have equivalent exposed EllesmereUI bars and are reported as warnings when enabled.
- Some concepts differ between the two addons, so the closest supported EllesmereUI representation is used.

## Development

The addon targets Lua 5.1 as embedded by World of Warcraft. Run the local verification suite from the addon directory:

```sh
luac -p Migration.lua UI.lua Core.lua tests/migration_spec.lua tests/addon_load_spec.lua
lua tests/migration_spec.lua
lua tests/addon_load_spec.lua
```

Generated architecture artifacts are stored in `graphify-out/`. Rebuild them after structural changes with:

```sh
graphify extract . --code-only
```

## Releases

Version tags trigger the GitHub Actions release workflow. The workflow uses the BigWigsMods packager to create a correctly nested addon archive and publish it as a GitHub release.
