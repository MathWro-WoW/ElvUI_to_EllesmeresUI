# Graph Report - .  (2026-08-04)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 104 nodes · 212 edges · 9 communities
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 6 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `8524beda`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- addon_load_spec.lua
- Migration.lua
- createFrame
- addWarning
- applyUnit
- migration_spec.lua
- migrateAppearance

## God Nodes (most connected - your core abstractions)
1. `createFrame()` - 14 edges
2. `applyUnit()` - 12 edges
3. `visibilitySettings()` - 11 edges
4. `addWarning()` - 10 edges
5. `targetModule()` - 10 edges
6. `moverPosition()` - 9 edges
7. `applyGroupVisuals()` - 9 edges
8. `migrateRaid()` - 8 edges
9. `makeCheck()` - 7 edges
10. `migrateBar()` - 7 edges

## Surprising Connections (you probably didn't know these)
- `createFrame()` --calls--> `InCombatLockdown()`  [INFERRED]
  UI.lua → tests/addon_load_spec.lua
- `createFrame()` --calls--> `ReloadUI()`  [INFERRED]
  UI.lua → tests/addon_load_spec.lua
- `createFrame()` --calls--> `ns.StartMigration()`  [INFERRED]
  UI.lua → Migration.lua
- `makeCheck()` --calls--> `CreateFrame()`  [INFERRED]
  UI.lua → tests/addon_load_spec.lua
- `makeButton()` --calls--> `CreateFrame()`  [INFERRED]
  UI.lua → tests/addon_load_spec.lua

## Import Cycles
- None detected.

## Communities (9 total, 0 thin omitted)

### Community 0 - "addon_load_spec.lua"
Cohesion: 0.09
Nodes (5): InCombatLockdown(), methods:CreateFontString(), methods:CreateTexture(), object(), ReloadUI()

### Community 1 - "Migration.lua"
Cohesion: 0.19
Nodes (22): barVisibility(), beginMigration(), collectHideOptions(), commitMigration(), complementVisibilityModes(), deepCopy(), groupsContainOnly(), migrateComponent() (+14 more)

### Community 2 - "createFrame"
Cohesion: 0.34
Nodes (11): CreateFrame(), color(), createFrame(), fontPath(), makeBackdrop(), makeButton(), makeCheck(), makeText() (+3 more)

### Community 3 - "addWarning"
Cohesion: 0.33
Nodes (13): addWarning(), applyBarVisibility(), capturedCenter(), ensure(), growthPair(), migrateActionBars(), migrateBar(), migrateMinimap() (+5 more)

### Community 4 - "applyUnit"
Cohesion: 0.27
Nodes (10): anchorName(), applyGroupVisuals(), applyUnit(), copyColor(), healthTextMode(), migrateOtherUnits(), migratePlayer(), migrateTarget() (+2 more)

### Community 5 - "migration_spec.lua"
Cohesion: 0.29
Nodes (5): aura(), bar(), color(), group(), unit()

### Community 6 - "migrateAppearance"
Cohesion: 0.40
Nodes (6): fontKey(), migrateAppearance(), outlineMode(), parseMover(), textureKey(), trim()

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `createFrame()` connect `createFrame` to `addon_load_spec.lua`, `Migration.lua`?**
  _High betweenness centrality (0.417) - this node is a cross-community bridge._
- **Why does `ns.StartMigration()` connect `Migration.lua` to `createFrame`?**
  _High betweenness centrality (0.379) - this node is a cross-community bridge._
- **Why does `CreateFrame()` connect `createFrame` to `addon_load_spec.lua`?**
  _High betweenness centrality (0.120) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `createFrame()` (e.g. with `ns.StartMigration()` and `CreateFrame()`) actually correct?**
  _`createFrame()` has 4 INFERRED edges - model-reasoned connections that need verification._
- **Should `addon_load_spec.lua` be split into smaller, more focused modules?**
  _Cohesion score 0.08666666666666667 - nodes in this community are weakly interconnected._