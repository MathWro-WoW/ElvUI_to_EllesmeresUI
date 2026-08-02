# Graph Report - .  (2026-08-02)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 91 nodes · 182 edges · 11 communities (10 shown, 1 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 6 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- addon_load_spec.lua
- createFrame
- Migration.lua
- beginMigration
- migration_spec.lua
- addWarning
- targetModule
- migrateAppearance
- object

## God Nodes (most connected - your core abstractions)
1. `createFrame()` - 14 edges
2. `applyUnit()` - 12 edges
3. `targetModule()` - 10 edges
4. `addWarning()` - 9 edges
5. `moverPosition()` - 9 edges
6. `applyGroupVisuals()` - 9 edges
7. `migrateRaid()` - 8 edges
8. `migrateBar()` - 7 edges
9. `makeCheck()` - 7 edges
10. `migrateParty()` - 6 edges

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

## Communities (11 total, 1 thin omitted)

### Community 1 - "createFrame"
Cohesion: 0.34
Nodes (11): CreateFrame(), color(), createFrame(), fontPath(), makeBackdrop(), makeButton(), makeCheck(), makeText() (+3 more)

### Community 2 - "Migration.lua"
Cohesion: 0.40
Nodes (10): anchorName(), applyGroupVisuals(), applyUnit(), copyColor(), healthTextMode(), migrateOtherUnits(), migratePlayer(), migrateTarget() (+2 more)

### Community 3 - "beginMigration"
Cohesion: 0.31
Nodes (9): beginMigration(), commitMigration(), deepCopy(), migrateComponent(), ns.RunMigration(), ns.StartMigration(), set(), sourceInfo() (+1 more)

### Community 4 - "migration_spec.lua"
Cohesion: 0.33
Nodes (5): aura(), bar(), color(), group(), unit()

### Community 5 - "addWarning"
Cohesion: 0.36
Nodes (8): addWarning(), capturedCenter(), growthPair(), migrateParty(), migrateRaid(), moverPosition(), parseMover(), visibleGroups()

### Community 6 - "targetModule"
Cohesion: 0.53
Nodes (6): barVisibility(), ensure(), migrateActionBars(), migrateBar(), migrateMinimap(), targetModule()

### Community 7 - "migrateAppearance"
Cohesion: 0.40
Nodes (6): fontKey(), migrateAppearance(), outlineMode(), textureKey(), trim(), validateProfileName()

### Community 8 - "object"
Cohesion: 0.67
Nodes (3): methods:CreateFontString(), methods:CreateTexture(), object()

## Knowledge Gaps
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `createFrame()` connect `createFrame` to `addon_load_spec.lua`, `beginMigration`?**
  _High betweenness centrality (0.433) - this node is a cross-community bridge._
- **Why does `ns.StartMigration()` connect `beginMigration` to `createFrame`, `Migration.lua`?**
  _High betweenness centrality (0.380) - this node is a cross-community bridge._
- **Why does `CreateFrame()` connect `createFrame` to `addon_load_spec.lua`, `object`?**
  _High betweenness centrality (0.131) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `createFrame()` (e.g. with `ns.StartMigration()` and `CreateFrame()`) actually correct?**
  _`createFrame()` has 4 INFERRED edges - model-reasoned connections that need verification._
- **Should `addon_load_spec.lua` be split into smaller, more focused modules?**
  _Cohesion score 0.09090909090909091 - nodes in this community are weakly interconnected._