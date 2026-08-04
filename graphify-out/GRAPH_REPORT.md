# Graph Report - .  (2026-08-04)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 110 nodes · 228 edges · 8 communities
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 5 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `018ee8a9`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- addon_load_spec.lua
- Migration.lua
- applyUnit
- createFrame
- addWarning
- migration_spec.lua

## God Nodes (most connected - your core abstractions)
1. `addWarning()` - 13 edges
2. `createFrame()` - 13 edges
3. `applyUnit()` - 12 edges
4. `visibilitySettings()` - 11 edges
5. `targetModule()` - 10 edges
6. `moverPosition()` - 9 edges
7. `applyGroupVisuals()` - 9 edges
8. `migrateRaid()` - 8 edges
9. `tooltipStaticPosition()` - 7 edges
10. `migrateBar()` - 7 edges

## Surprising Connections (you probably didn't know these)
- `createFrame()` --calls--> `InCombatLockdown()`  [INFERRED]
  UI.lua → tests/addon_load_spec.lua
- `createFrame()` --calls--> `ReloadUI()`  [INFERRED]
  UI.lua → tests/addon_load_spec.lua
- `makeCheck()` --calls--> `CreateFrame()`  [INFERRED]
  UI.lua → tests/addon_load_spec.lua
- `makeButton()` --calls--> `CreateFrame()`  [INFERRED]
  UI.lua → tests/addon_load_spec.lua
- `createFrame()` --calls--> `CreateFrame()`  [INFERRED]
  UI.lua → tests/addon_load_spec.lua

## Import Cycles
- None detected.

## Communities (8 total, 0 thin omitted)

### Community 0 - "addon_load_spec.lua"
Cohesion: 0.09
Nodes (5): InCombatLockdown(), methods:CreateFontString(), methods:CreateTexture(), object(), ReloadUI()

### Community 1 - "Migration.lua"
Cohesion: 0.19
Nodes (22): barVisibility(), beginMigration(), collectHideOptions(), commitMigration(), complementVisibilityModes(), deepCopy(), groupsContainOnly(), migrateComponent() (+14 more)

### Community 2 - "applyUnit"
Cohesion: 0.17
Nodes (22): anchorName(), applyBarVisibility(), applyGroupVisuals(), applyUnit(), capturedCenter(), copyColor(), ensure(), growthPair() (+14 more)

### Community 3 - "createFrame"
Cohesion: 0.34
Nodes (11): CreateFrame(), color(), createFrame(), fontPath(), makeBackdrop(), makeButton(), makeCheck(), makeText() (+3 more)

### Community 4 - "addWarning"
Cohesion: 0.23
Nodes (13): addWarning(), fontKey(), migrateAppearance(), migrateTooltips(), oppositePoint(), outlineMode(), parseMover(), pointOffset() (+5 more)

### Community 5 - "migration_spec.lua"
Cohesion: 0.29
Nodes (5): aura(), bar(), color(), group(), unit()

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `createFrame()` connect `createFrame` to `addon_load_spec.lua`?**
  _High betweenness centrality (0.036) - this node is a cross-community bridge._
- **Why does `CreateFrame()` connect `createFrame` to `addon_load_spec.lua`?**
  _High betweenness centrality (0.030) - this node is a cross-community bridge._
- **Why does `InCombatLockdown()` connect `addon_load_spec.lua` to `createFrame`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `createFrame()` (e.g. with `CreateFrame()` and `InCombatLockdown()`) actually correct?**
  _`createFrame()` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Should `addon_load_spec.lua` be split into smaller, more focused modules?**
  _Cohesion score 0.08666666666666667 - nodes in this community are weakly interconnected._