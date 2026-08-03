# ElvUI to EllesmereUI

A one-time migration assistant for World of Warcraft: Midnight. It creates a new EllesmereUI profile from the active ElvUI profile while leaving the source profile unchanged.

> **AI assistance disclosure:** AI-assisted coding was used to design and implement this addon. Its migration behavior is covered by automated Lua fixtures, but users should still review the generated EllesmereUI profile before relying on it.

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
- Action bars, stance bar, pet bar, micro menu, and bag bar visibility
- Minimap

Where the addons expose equivalent settings, the migrator copies dimensions, positions, growth directions, visibility, sorting, textures, fonts, colors, text, cast bars, portraits, auras, and related layout options.

Direct action-bar visibility translations include Always, Mouseover, Never, In Combat, Out of Combat, Raid, Party, Solo, Dragonriding, and Not Dragonriding. Compatible combined conditions and the Hide While Mounted, Hide Without Target, and Hide Without Enemy options are also preserved. Each destination bar keeps its built-in pet-battle, vehicle, and override-bar guards; a source-only guard that the destination cannot express produces a migration warning.

“Supported” means that the migrator copies the settings for which the two addons have a practical equivalent; it does not clone every setting in those ElvUI modules.

## Not migrated or only partially mapped

- ElvUI modules outside the list above are not migrated. This includes nameplates, bags, chat, data texts and data bars, skins, tooltips, standalone cooldown configuration, and other general ElvUI styling.
- Custom unit-frame texts, tags, and complex text formats are not reproduced exactly. Only the supported text sizes, positions, and broad health-display modes are mapped.
- Custom aura filters, priorities, blacklists, whitelists, and detailed indicator rules are not recreated. Basic buff/debuff visibility, count, size, position, and personal-debuff behavior are mapped where possible.
- Heal-prediction, absorb, threat/glow, custom indicator, and other advanced unit-frame behaviors without a direct EllesmereUI equivalent are not copied.
- ElvUI bars 7–9, which use action pages 7–9, are not migrated because EllesmereUI exposes no independent destination bars for those pages. Visibility expressions without a direct EllesmereUI equivalent, custom paging rules, action assignments, and keybindings are not copied; the migrator reports a warning when it must fall back from an unsupported visibility expression.
- Minimap migration covers its basic size, shape, rotation, text scale, selected button visibility, and position. Other ElvUI minimap integrations and icon-placement rules are not copied.
- A saved mover anchored relative to another ElvUI frame may not be convertible when its live position cannot be read. In that case, EllesmereUI keeps its existing position and the migrator reports a warning.

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

Push an annotated `v*` tag to package the addon and publish a GitHub release:

```sh
git tag -a v1.0.0 -m "v1.0.0"
git push origin v1.0.0
```

The workflow can also be started manually for an existing tag from the GitHub Actions page. It uses the BigWigsMods packager to create an archive rooted at `ElvUI_to_EllesmeresUI/`.

CurseForge publishing is intentionally disabled. The commented configuration in `.pkgmeta` and `.github/workflows/release.yml` documents the project ID and secret changes required to enable it later.
