# Perfect Dismantling

Version: `0.2 Alpha`

Perfect Dismantling is a Witcher 3 Next-Gen 4.04 script mod that changes dismantling for crafted items.

## Product Contract

Perfect Dismantling's product promise is that crafted items dismantle into the materials used to craft them, not into the game's separate static `<recycling_parts>` table.

At a high level, dismantling should behave like the inverse of crafting for any item with a valid one-output crafting recipe:

- Given the item being dismantled, find the same resolved recipe data that the crafting UI/game logic would use to craft that exact item.
- Return that recipe's direct ingredients as the base dismantle output.
- Preserve the game's native behavior for socketed glyphs, runes, runewords, and similar upgrades by appending the dismantled item's enhancement list once after the base material list is resolved.
- Use vanilla recycling only when no valid one-output crafting recipe can be resolved.
- Keep multi-output recipes, such as bolts, on vanilla recycling to avoid material duplication exploits.
- For upgraded Witcher gear, the previous-tier item is part of the user-facing contract. It should normally be returned because it appears in the resolved recipe ingredients; if loaded recipe data omits it but the item is reliably identifiable as upgraded Witcher gear, the mod should add the previous-tier item as a narrow compatibility fallback.
- Debug Mode is a safety rail: when enabled, normal missing recipe matches prevent item removal instead of silently falling back. Recognized upgraded Witcher gear still preserves the inferred previous-tier item.

This contract is intentionally implementation-agnostic. If a specific technical route fails, prefer another route that preserves these outcomes over treating the current implementation as the source of truth.

## Current Build Ground Truth

The current build is a script mod that routes inventory dismantling through helper functions in `inventoryComponent.ws`.

- `RecycleItem()` calls `PerfectDismantling_GetDismantlingParts()` before removing the item.
- Recipe lookup reads the loaded `crafting_schematics` custom definitions at runtime, scans for recipes whose `craftedItem_name` matches `GetItemName(id)`, and parses matched nodes into `SCraftingSchematic` data using the same fields as `W3CraftingManager.LoadSchematicsXMLData(...)`.
- Exact recipe matches are preferred. If an installed mod changes a live item ID to an `NGP ...` name while the loaded recipe still crafts the unprefixed item, the resolver can bridge to that loaded recipe and rewrites returned ingredients to live `NGP ...` item IDs when those definitions exist.
- Recipes with `craftedItemQuantity != 1` are rejected and fall back to vanilla recycling when Debug Mode is off.
- If no recipe match is found, Debug Mode off falls back to `GetItemRecyclingParts()` for normal items; Debug Mode on treats normal missing recipes as strict failures and does not remove the item.
- Socketed upgrades are appended by reading the dismantled item's enhancement list after recipe/fallback/Witcher safety output is selected.
- A narrow Witcher-tier safety helper adds the inferred previous-tier Witcher item when loaded recipe data or fallback output omits it. For recognized upgraded Witcher gear with no valid recipe, this safety item still appears even when normal Debug Mode fallback would be blocked.
- Returned parts are stacked by internal item name before the preview/result list is shown.
- Debug Mode does not hide normal vanilla-dismantlable items from the dismantle grid. It only blocks the actual dismantle action when the selected item has no valid recipe or Witcher safety output.
- After building and installing, Witcher Script Merger must be run so these source changes are present in the final `mod0000_MergedFiles` script stack.

## Compatibility Model

This is now a script mod, so it must be merged with other script mods.

The current compatibility point is that recipe lookup happens at runtime through:

```witcherscript
main = dm.GetCustomDefinition('crafting_schematics');
```

So the mod reads the effective crafting definitions loaded by the game, including recipe XML changes from other mods when those definitions win load order. It intentionally does not initialize `W3CraftingManager`, because the normal manager only loads schematics known by the current character/save. Instead, the resolver mirrors the relevant `LoadSchematicsXMLData(...)` parsing fields against the full loaded definition tree.

The mod edits a few script files that are common conflict targets. Use Witcher Script Merger after installing.

## Folder Layout

- `source/modPerfectDismantling/content/scripts/game/components/inventoryComponent.ws` contains the runtime recipe lookup and exact dismantle reward logic.
- `source/modPerfectDismantling/content/scripts/game/gui/menus/blacksmithMenu.ws` keeps merchant dismantling notifications and refreshes aligned with the new rewards.
- `source/modPerfectDismantling/content/scripts/game/gui/_old/components/guiDisassembleInventoryComponent.ws` keeps the dismantle list preview aligned with the new rewards.
- `source/modPerfectDismantling/bin/config/r4game/user_config_matrix/pc/modPerfectDismantling.xml` defines the in-game toggle and debug options.
- `source/modPerfectDismantling/content/en.csv` contains the localized strings for the in-game mod menu.
- `scripts/tools/w3strings-encode/` contains the Rust helper used to compile `.csv` localization files into `.w3strings`.
- `dist/modPerfectDismantling/` is generated by the build script.
- `scripts/` contains helper commands.

## Build And Install

Build the loose-script mod:

```powershell
.\scripts\Build-Mod.ps1
```

The build script copies loose scripts and `bin` config files, copies localization CSV files, and generates `.w3strings` files with `scripts/tools/w3strings-encode`. Cargo's generated `target/` output for that helper is intentionally ignored by Git.

Install it into your game:

```powershell
.\scripts\Install-Mod.ps1
```

You can also install the built mod with [The Witcher 3 Mod Manager](https://github.com/Systemcluster/The-Witcher-3-Mod-manager) if that is how you manage your load order.

The install script also installs the mod menu config into the game's `bin\config\r4game\user_config_matrix\pc` folder and adds it to the DX11/DX12 file lists.

Then open Witcher Script Merger, scan conflicts, and merge script conflicts. Keep the `RecycleItem()` changes plus these helpers in `inventoryComponent.ws`:

```witcherscript
PerfectDismantling_GetDismantlingParts
PerfectDismantling_TryResolveRecipeParts
PerfectDismantling_ReadCraftingSchematicNode
PerfectDismantling_EnsurePreviousWitcherTier
```

If `blacksmithMenu.ws` or `guiDisassembleInventoryComponent.ws` conflict, keep the `_inv.PerfectDismantling_GetDismantlingParts(...)` preview/action calls. If those UI files do not appear in `mod0000_MergedFiles`, that is okay when no other installed mod edits them; the loose files from `modPerfectDismantling` remain active.

Quick merge sanity check:

```powershell
rg -n "PerfectDismantling_TryResolveRecipeParts|PerfectDismantling_EnsurePreviousWitcherTier|PerfectDismantling_GetCraftingParts" "C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3\Mods\mod0000_MergedFiles"
```

Expected result: the merged inventory script contains the new resolver/safety helpers and does not contain the old `PerfectDismantling_GetCraftingParts` helper.

For in-game validation steps, see [TESTING.md](TESTING.md).

## Notes

- Designed for The Witcher 3 Next-Gen 4.04.
- Built and merge-checked against the current local merged script stack in `mod0000_MergedFiles`.
- The old generated XML override approach has been removed from the active repository workflow.
- New crafted items from other mods should work if they are present in the loaded `crafting_schematics` definitions and craft exactly one item per recipe.
