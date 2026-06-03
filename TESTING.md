# In-Game Testing Guide

This guide tests Perfect Dismantling `0.2 Alpha`, the script-based version.

## 1. Before Launching

Confirm the installed mod exists at:

```text
C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3\Mods\modPerfectDismantling
```

Confirm it contains the loose script:

```text
content\scripts\game\components\inventoryComponent.ws
content\scripts\game\gui\menus\blacksmithMenu.ws
content\scripts\game\gui\_old\components\guiDisassembleInventoryComponent.ws
```

Confirm the installed game config contains:

```text
bin\config\r4game\user_config_matrix\pc\modPerfectDismantling.xml
```

After running `.\scripts\Install-Mod.ps1`, the installed files should match the built `dist\modPerfectDismantling` output. The install script also adds `modPerfectDismantling.xml` to both `dx11filelist.txt` and `dx12filelist.txt`.

Then:

1. Open Witcher Script Merger.
2. Run a conflict scan.
3. Merge any conflicts in the inventory, blacksmith, or disassemble UI scripts.
4. In the merged files, confirm the Perfect Dismantling hooks are present:

```witcherscript
PerfectDismantling_GetDismantlingParts
PerfectDismantling_TryResolveRecipeParts
PerfectDismantling_ReadCraftingSchematicNode
PerfectDismantling_AddOrStackPart
PerfectDismantling_EnsurePreviousWitcherTier
```

The old helper should not remain in the merged inventory script:

```witcherscript
PerfectDismantling_GetCraftingParts
```

If `blacksmithMenu.ws` or `guiDisassembleInventoryComponent.ws` do not appear under `mod0000_MergedFiles`, that is acceptable when no other installed mod edits those files. In that case, confirm the loose installed versions under `Mods\modPerfectDismantling` contain `PerfectDismantling_GetDismantlingParts`.

## 2. Simple Crafted Item Test

Goal: confirm dismantling uses the live crafting recipe.

1. Go to a blacksmith or armorer.
2. Pick a normal crafted item that outputs exactly one item.
3. Write down the ingredients shown in the crafting screen.
4. Craft the item.
5. Go to the dismantling tab.
6. Select the crafted item.

Expected result: the dismantle preview and result should match the crafting ingredients exactly.

For the Assassin's boots case shown in your screenshots, if crafting shows:

```text
Cured leather x1
Leather scraps x4
Thread x3
String x2
```

then dismantling should return exactly those same quantities.

## 3. Witcher Gear Upgrade Test

Goal: confirm upgraded gear returns the previous tier.

1. Choose a Witcher gear upgrade recipe.
2. Write down the previous-tier item and extra materials shown in the crafting screen.
3. Craft or use that upgraded item.
4. Dismantle it.

Expected result: the previous-tier item is returned, plus the direct materials required for that upgrade step. If loaded recipe data already includes the previous-tier item, it should not be duplicated.

Example:

```text
Mastercrafted Feline Steel Sword
```

should return the lower Feline steel sword tier. The script also has a safety guard for known tiered Witcher gear families that injects the previous-tier item when recipe data omits it.

## 4. Socketed Rune And Glyph Test

Goal: confirm inserted upgrades come back.

1. Take a weapon or armor piece with open slots.
2. Insert known runes or glyphs.
3. Write down the inserted upgrades.
4. Dismantle the item.

Expected result: dismantling returns the recipe ingredients and the inserted upgrades.

## 5. Modded Recipe Test

Goal: confirm compatibility with recipe-changing mods.

1. Enable a mod that changes crafting costs, such as Rational Crafting.
2. Run Script Merger again.
3. Pick an item whose recipe is visibly changed by that mod.
4. Craft and dismantle it.

Expected result: dismantling follows the recipe currently shown in the crafting screen, not the vanilla recipe.

## 6. Fallback Test

Goal: confirm non-crafted items still dismantle normally.

1. Pick a junk item or monster part that has no crafting recipe.
2. Dismantle it.

Expected result: it should use the normal vanilla dismantle output.

## 7. Debug Mode Strict Test

Goal: confirm strict testing prevents accidental item destruction when no recipe match exists for a normal item.

1. Enable Debug Mode in the Perfect Dismantling in-game mod menu.
2. Pick a normal non-Witcher item with no one-output crafting recipe match.
3. Try to dismantle it.

Expected result: the item should not be removed, a denied sound should play in the blacksmith menu, and the notification should report that no dismantling output was found.

The item should still be visible in the dismantle grid if vanilla dismantling would normally allow it. Debug Mode blocks the action path, not the visibility filter.

## 8. Witcher Safety With Missing Recipe Test

Goal: confirm Witcher gear safety is stronger than normal fallback blocking.

1. Enable Debug Mode.
2. Test a recognized upgraded Witcher gear item whose loaded recipe is missing, invalid, or temporarily modified to omit usable output.
3. Dismantle it.

Expected result: the inferred previous-tier Witcher gear item is still returned. If the valid recipe or fallback output already includes that previous-tier item, it should appear only once.

Regression case: in New Game+, Mastercrafted Feline armor pieces whose internal names use the `NGP Lynx ...` prefix should not show an empty dismantle output. If their NG+ recipe output is absent from `crafting_schematics`, the safety path should still return the previous `NGP Lynx ...` tier.

## 9. Build Output Check

Goal: confirm localization and menu config are packaged.

1. Run `.\scripts\Build-Mod.ps1`.
2. Inspect `dist\modPerfectDismantling`.

Expected result: the dist mod should include loose scripts, `bin\config\r4game\user_config_matrix\pc\modPerfectDismantling.xml`, `content\en.csv`, and `content\en.w3strings`.

## 10. Known Limits

- Recipes that output multiple items fall back to vanilla dismantling.
- If two different recipes craft the exact same item, the script uses the first matching loaded recipe.
- If another mod changes crafting through code instead of `crafting_schematics`, this mod may not see that change.
- The game UI preview may require re-entering the dismantle tab after a merge or script change.

## 11. Reporting A Problem

When an item has incorrect dismantle output, record:

```text
Game version:
Active mod list:
Tested item:
Was the item vanilla, DLC, or from another mod?
Recipe shown in the crafting screen:
Dismantle output shown in the dismantling screen:
Did the item have a rune/glyph/upgrade inserted?
Were Perfect Dismantling and Debug Mode enabled in the mod menu?
Was the save NG or NG+?
Script Merger conflict result:
```

Screenshots of the crafting screen and dismantling result are very helpful.
