# In-Game Testing Guide

This guide validates Perfect Dismantling `0.2 Alpha`.

## 1. Install Check

Confirm the mod is installed at:

```text
The Witcher 3\Mods\modPerfectDismantling
```

The installed mod should contain:

```text
content\scripts\game\components\inventoryComponent.ws
content\scripts\game\gui\menus\blacksmithMenu.ws
content\scripts\game\gui\_old\components\guiDisassembleInventoryComponent.ws
content\en.csv
content\en.w3strings
bin\config\r4game\user_config_matrix\pc\modPerfectDismantling.xml
```

The game config folder should contain:

```text
bin\config\r4game\user_config_matrix\pc\modPerfectDismantling.xml
```

Both file lists should include:

```text
modPerfectDismantling.xml;
```

Run Witcher Script Merger after installing. If the inventory, blacksmith, or dismantle UI scripts conflict, merge them.

## 2. Merge Check

The final active script stack should contain these functions or calls:

```witcherscript
PerfectDismantling_GetDismantlingParts
PerfectDismantling_TryResolveRecipeParts
PerfectDismantling_ReadCraftingSchematicNode
PerfectDismantling_AddOrStackPart
PerfectDismantling_EnsurePreviousWitcherTier
```

The old raw helper should not be present:

```witcherscript
PerfectDismantling_GetCraftingParts
```

If only `inventoryComponent.ws` appears in merged files, that can be fine when no other installed mod edits the UI files. In that case, confirm the loose installed UI files still call `_inv.PerfectDismantling_GetDismantlingParts(...)`.

## 3. Simple Crafted Item

Goal: confirm dismantling uses the loaded crafting recipe.

1. Go to a blacksmith or armorer.
2. Pick a normal crafted item that creates exactly one item.
3. Write down the ingredients shown in the crafting screen.
4. Craft the item.
5. Go to the dismantling tab.
6. Select the crafted item.
7. Dismantle it.

Expected result: the preview, notification, and actual returned items match the crafting ingredients.

Example:

```text
Assassin's boots recipe:
Cured leather x1
Leather scraps x4
Thread x3
String x2
```

Expected dismantle result:

```text
Cured leather x1
Leather scraps x4
Thread x3
String x2
```

## 4. Witcher Gear Upgrade

Goal: confirm upgraded Witcher gear returns the previous tier.

1. Choose a Witcher gear upgrade recipe.
2. Write down the previous-tier item and extra materials shown in the crafting screen.
3. Craft or obtain that upgraded item.
4. Dismantle it.

Expected result: the previous-tier item is returned once, plus the direct materials from the upgrade recipe. If the recipe data already contains the previous-tier item, the safety path should not duplicate it.

Test families to prioritize:

- Feline or `Lynx`
- Bear
- Griffin or `Gryphon`
- Wolf
- Forgotten Wolf or `Netflix`
- New Game+ `NGP ...` variants

## 5. Socketed Upgrade Return

Goal: confirm inserted upgrades are preserved.

1. Use a weapon or armor piece with sockets.
2. Insert known runes or glyphs.
3. Dismantle the item.

Expected result: returned parts include the recipe or fallback output plus each inserted upgrade once.

## 6. Modded Recipe

Goal: confirm compatibility with recipe-changing mods.

1. Enable a mod that changes crafting recipes through loaded recipe definitions.
2. Run Witcher Script Merger again.
3. Pick an item whose crafting screen visibly changed.
4. Craft and dismantle the item.

Expected result: dismantling follows the recipe currently shown by the crafting screen.

## 7. Vanilla Fallback

Goal: confirm unsupported items still dismantle normally during regular play.

1. Make sure Debug Mode is off.
2. Pick a junk item, monster part, or other item with no one-output crafting recipe.
3. Dismantle it.

Expected result: the item uses vanilla dismantling output.

## 8. Multi-Output Recipe Fallback

Goal: confirm stack-output recipes do not duplicate materials.

1. Pick a recipe that creates multiple items, such as bolts.
2. Craft or obtain that item.
3. Dismantle it with Debug Mode off.

Expected result: the recipe is rejected by Perfect Dismantling and vanilla dismantling is used.

## 9. Debug Mode Strict Miss

Goal: confirm Debug Mode blocks silent recipe misses.

1. Enable Debug Mode in the Perfect Dismantling mod menu.
2. Pick a normal non-Witcher item with no valid one-output recipe match.
3. Try to dismantle it.

Expected result: the item is not removed, a denied sound plays in the blacksmith menu, and the notification reports that no dismantling output was found.

The item should still appear in the dismantle grid if vanilla dismantling would normally allow it. Debug Mode blocks the action path, not the visibility filter.

## 10. Debug Mode Witcher Safety

Goal: confirm recognized upgraded Witcher gear remains protected even when strict fallback is active.

1. Enable Debug Mode.
2. Test a recognized upgraded Witcher item whose recipe is missing, invalid, or temporarily altered.
3. Dismantle it.

Expected result: the inferred previous-tier item is returned. If the valid recipe or fallback output already includes that previous-tier item, it appears only once.

Regression case:

```text
NGP Lynx armor, boots, gloves, trousers, steel sword, or silver sword
```

If the live item uses an `NGP ...` name and the loaded recipe still crafts the unprefixed item, the resolver should bridge to that recipe and rewrite returned Witcher gear ingredients to the live `NGP ...` item IDs when those IDs exist.

## 11. Build Output

Run:

```powershell
.\scripts\Build-Mod.ps1
```

Expected output under `dist\modPerfectDismantling`:

```text
content\scripts\...
content\en.csv
content\en.w3strings
bin\config\r4game\user_config_matrix\pc\modPerfectDismantling.xml
bin\config\r4game\user_config_matrix\pc\dx11filelist.txt
bin\config\r4game\user_config_matrix\pc\dx12filelist.txt
```

## 12. Problem Report Template

```text
Game version:
Perfect Dismantling version:
Active mod list:
Tested item:
Vanilla, DLC, or modded item:
Recipe shown in the crafting screen:
Dismantle preview:
Actual dismantle result:
Inserted rune, glyph, or upgrade:
Perfect Dismantling enabled:
Debug Mode enabled:
New Game or New Game+:
Script Merger result:
```

Screenshots of the crafting screen and dismantle result are very helpful.
