# Perfect Dismantling

Version: `0.2 Alpha`

Perfect Dismantling is a Witcher 3 Next-Gen 4.04 mod that makes crafted items dismantle back into the materials used to craft them.

Instead of using the game's separate static recycling tables for crafted equipment, the mod reads the currently loaded crafting recipe and returns that recipe's direct ingredients. It also keeps inserted runes, glyphs, and upgrades, and it includes extra protection for upgraded Witcher gear so the previous tier is not lost.

## What It Does

- Crafted one-output items dismantle into their crafting ingredients.
- Recipe changes from other mods can be respected when they are present in the loaded `crafting_schematics` definitions.
- Socketed runes, glyphs, runewords, and similar upgrades are returned.
- Upgraded Witcher gear keeps the previous-tier item when the item is recognized.
- Non-crafted or unsupported items keep vanilla dismantling behavior when Debug Mode is off.
- Multi-output recipes, such as bolts, stay on vanilla dismantling to avoid material duplication.
- The dismantle preview, result notification, and actual returned items use the same reward list.

## Requirements

- The Witcher 3 Next-Gen 4.04.
- Witcher Script Merger.
- A mod manager or manual access to the game's `Mods` folder.

Perfect Dismantling is a script mod. If you use other script mods, run Witcher Script Merger after installing.

## Install

Recommended install path:

1. Download the release archive.
2. Install it with [Vortex Mod Manager from Nexus Mods](https://www.nexusmods.com/about/vortex/) or [The Witcher 3 Mod Manager](https://github.com/Systemcluster/The-Witcher-3-Mod-manager).
3. Run Witcher Script Merger and merge any script conflicts.

Vortex or The Witcher 3 Mod Manager are the more practical options for normal play because they manage the mod folder and load order for you. Witcher Script Merger is still needed because Perfect Dismantling includes WitcherScript files.

Manual install:

1. Download or build `modPerfectDismantling`.
2. Copy the mod folder into:

```text
The Witcher 3\Mods\modPerfectDismantling
```

3. Install the mod menu config into:

```text
The Witcher 3\bin\config\r4game\user_config_matrix\pc\modPerfectDismantling.xml
```

4. Make sure `modPerfectDismantling.xml;` is listed in both:

```text
dx11filelist.txt
dx12filelist.txt
```

5. Run Witcher Script Merger and merge any script conflicts.

If you are building from this repository, the helper scripts handle the mod folder and menu config:

```powershell
.\scripts\Build-Mod.ps1
.\scripts\Install-Mod.ps1
```

After installing, still run Witcher Script Merger.

## In-Game Options

Perfect Dismantling adds a mod menu entry:

```text
Options -> Mods -> Perfect Dismantling
```

Options:

- `Enable Perfect Dismantling`: turns the recipe-routed dismantling behavior on or off.
- `Debug Mode`: strict testing mode. Missing recipe matches block normal dismantling instead of falling back, while recognized upgraded Witcher gear can still return its inferred previous-tier safety item.

Leave Debug Mode off for normal play.

## What To Test

A quick confidence test:

1. Visit a blacksmith or armorer.
2. Choose a crafted item that produces exactly one item.
3. Note the ingredients shown on the crafting screen.
4. Craft the item.
5. Open the dismantle tab and select the crafted item.

Expected result: the dismantle preview and actual result should match the crafting ingredients.

For upgraded Witcher gear, the previous-tier gear item should also be returned. For socketed gear, inserted upgrades should come back too.

For a full checklist, see [TESTING.md](TESTING.md).

## Compatibility

Perfect Dismantling is most compatible with mods that change recipes through loaded `crafting_schematics` definitions. It may not see recipe changes made only through separate script logic.

Because this mod edits common script files, conflicts are expected in larger mod lists. Merge with Witcher Script Merger and keep the Perfect Dismantling calls in the inventory and dismantle UI paths.

## Known Limits

- Recipes that output more than one item use vanilla dismantling.
- If multiple loaded recipes craft the same item, the first matching loaded recipe is used.
- Debug Mode is meant for testing and can block normal fallback dismantling.
- The mod is built and documented for The Witcher 3 Next-Gen 4.04.

## Known Bugs

- Dismantle preview UI can leave the socketed item display on the right visible after an item is dismantled.
- Opening the dismantle screen can stutter because recipe data is gathered at runtime. Investigate compiling or caching the recipe list when the game loads instead of rebuilding it when the dismantle screen opens.

## For Modders

The current implementation details are recorded in [TECHNICAL_GROUND_TRUTH.md](TECHNICAL_GROUND_TRUTH.md). That file is the source of truth for the `0.2 Alpha` script implementation.
