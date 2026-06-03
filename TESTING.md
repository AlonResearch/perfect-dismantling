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
content\scripts\game\player\playerWitcher.ws
content\scripts\game\gui\menus\blacksmithMenu.ws
content\scripts\game\gui\_old\components\guiDisassembleInventoryComponent.ws
```

Then:

1. Open Witcher Script Merger.
2. Run a conflict scan.
3. Merge the `playerWitcher.ws` conflict.
4. In the merged files, confirm the Perfect Dismantling hooks are present:

```witcherscript
PerfectDismantling_GetDismantlingParts
PerfectDismantling_GetCraftingParts
PerfectDismantling_AddOrStackPart
```

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

Expected result: the previous-tier item is returned, plus the direct materials required for that upgrade step.

Example:

```text
Mastercrafted Feline Steel Sword
```

should return the lower Feline steel sword tier if that lower tier is listed as a recipe ingredient.

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

## 7. Known Limits

- Recipes that output multiple items fall back to vanilla dismantling.
- If two different recipes craft the exact same item, the script uses the first matching loaded recipe.
- If another mod changes crafting through code instead of `crafting_schematics`, this mod may not see that change.
- The game UI preview may require re-entering the dismantle tab after a merge or script change.

## 8. Reporting A Problem

When an item has incorrect dismantle output, record:

```text
Game version:
Active mod list:
Tested item:
Was the item vanilla, DLC, or from another mod?
Recipe shown in the crafting screen:
Dismantle output shown in the dismantling screen:
Did the item have a rune/glyph/upgrade inserted?
Was the save NG or NG+?
Script Merger conflict result:
```

Screenshots of the crafting screen and dismantling result are very helpful.
