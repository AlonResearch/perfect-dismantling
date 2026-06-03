# Perfect Dismantling Technical Ground Truth

Version: `0.2 Alpha`

Last updated: `2026-06-03`

This document describes the current technical implementation in this repository. For player-facing setup and behavior, see [README.md](README.md).

## Product Contract

Perfect Dismantling makes dismantling behave like the inverse of crafting for crafted items with a valid one-output recipe.

The expected behavior is:

- Use the currently loaded crafting recipe for the item being dismantled.
- Return that recipe's direct ingredients as the base dismantle output.
- Append socketed runes, glyphs, runewords, and similar enhancement items after the base output is resolved.
- Use vanilla recycling when no valid one-output recipe is found and Debug Mode is off.
- Reject multi-output recipes and use fallback behavior to avoid duplication exploits.
- Preserve the previous-tier item for recognized upgraded Witcher gear.
- In Debug Mode, block normal missing recipe matches instead of silently falling back. Recognized upgraded Witcher gear can still return the inferred previous-tier safety item.

## Repository Layout

- `source/modPerfectDismantling/content/scripts/game/components/inventoryComponent.ws`: main runtime hook, recipe resolver, fallback logic, socket return, aggregation, and Witcher gear safety.
- `source/modPerfectDismantling/content/scripts/game/gui/menus/blacksmithMenu.ws`: merchant dismantle action and notification integration.
- `source/modPerfectDismantling/content/scripts/game/gui/_old/components/guiDisassembleInventoryComponent.ws`: dismantle grid visibility and preview integration.
- `source/modPerfectDismantling/bin/config/r4game/user_config_matrix/pc/modPerfectDismantling.xml`: in-game config group and toggles.
- `source/modPerfectDismantling/bin/config/r4game/user_config_matrix/pc/dx11filelist.txt`: config file-list entry for DX11.
- `source/modPerfectDismantling/bin/config/r4game/user_config_matrix/pc/dx12filelist.txt`: config file-list entry for DX12.
- `source/modPerfectDismantling/content/en.csv`: English localization strings for the mod menu.
- `scripts/Build-Mod.ps1`: builds `dist/modPerfectDismantling`.
- `scripts/Install-Mod.ps1`: installs the built mod and game-level mod menu config.
- `scripts/tools/w3strings-encode/`: Rust helper for compiling CSV localization to `.w3strings`.
- `VERSION`: release identifier, currently `0.2-alpha`.

## Runtime Entry Points

### `RecycleItem(...)`

File: `inventoryComponent.ws`

The vanilla dismantle path has been routed through:

```witcherscript
parts = PerfectDismantling_GetDismantlingParts(id);
```

If the returned part list is empty, the item is not removed. This is important for Debug Mode strict failures and failed safety cases.

When parts exist:

1. Each part stack is added with `AddAnItem(parts[i].itemName, parts[i].quantity)`.
2. The original item is removed with `RemoveItem(id)`.
3. Debug logs describe success or add-item failures when Debug Mode is enabled.

The `level : ECraftsmanLevel` argument remains in the function signature for compatibility with the original call sites, but the current Perfect Dismantling logic does not branch on craftsman level.

### `PerfectDismantling_GetDismantlingParts(...)`

File: `inventoryComponent.ws`

This is the shared source of returned parts for preview, notification, and actual dismantling.

Current flow:

1. Validate the unique item ID and internal item name.
2. If `PD_Enabled` is true, try recipe-routed dismantling through `PerfectDismantling_TryResolveRecipeParts(...)`.
3. If a valid recipe is resolved, use recipe ingredients as base output.
4. If the recipe is missing or invalid and Debug Mode is on, return only the inferred Witcher previous-tier safety item when available. Otherwise return an empty list.
5. If the recipe is missing or invalid and Debug Mode is off, copy vanilla `GetItemRecyclingParts(id)` output.
6. If the mod is disabled, copy vanilla `GetItemRecyclingParts(id)` output.
7. After any base output path, call `PerfectDismantling_EnsurePreviousWitcherTier(...)` where applicable.
8. Append enhancement items from `GetItemEnhancementItems(id, upgrades)`.
9. Aggregate duplicate returned part names.
10. Return the final part list.

## Config

Config group:

```text
PerfectDismantling
```

Variables:

- `PD_Enabled`: defaults to `true`. Values other than `"false"` and `"0"` are treated as enabled.
- `PD_Debug`: defaults to `false`. Values `"true"` and `"1"` are treated as enabled.

Debug logging uses:

```witcherscript
LogChannel('PerfectDismantling', message);
```

## Recipe Resolution

### Data Source

The resolver reads the effective loaded definitions:

```witcherscript
dm = theGame.GetDefinitionsManager();
main = dm.GetCustomDefinition('crafting_schematics');
```

It does not initialize or rely on `W3CraftingManager.Init(...)`, because that manager only loads schematics known by the current character or save. The mod instead scans the loaded `crafting_schematics` definition tree directly.

### Matching

`PerfectDismantling_TryResolveRecipeParts(itemName, parts)` scans `main.subNodes` and reads each node's `craftedItem_name`.

Matching priority:

1. Exact `craftedItem_name == itemName`.
2. First alias match where the live item starts with `NGP ` and the loaded recipe crafts the same unprefixed item name.

If an alias match is used, `PerfectDismantling_RewriteRecipePartsForItemAlias(...)` attempts to rewrite returned unprefixed Witcher gear ingredients to live `NGP ...` item IDs when those definitions exist.

### Recipe Parsing

`PerfectDismantling_ReadCraftingSchematicNode(...)` resets and fills an `SCraftingSchematic` using the same relevant fields as the vanilla crafting schematic loader:

- `name_name`
- `craftedItem_name`
- `craftsmanType_name`
- `craftedItemQuantity`
- `craftsmanLevel_name`
- `price`
- `ingredients` subnodes with `item_name` and `quantity`

### Recipe Acceptance

A recipe is accepted only when:

- `craftedItemQuantity == 1`
- at least one valid ingredient is found
- every returned ingredient has a valid item name and positive quantity

If `craftedItemQuantity != 1`, the resolver rejects the recipe and the caller follows fallback behavior.

Returned recipe parts are stacked through `PerfectDismantling_AddOrStackPart(...)`.

## Fallback Behavior

Fallback depends on settings:

- Mod enabled, Debug Mode off: use vanilla `GetItemRecyclingParts(id)` when no valid one-output recipe resolves.
- Mod enabled, Debug Mode on: block normal fallback by returning an empty list, which prevents item removal in `RecycleItem(...)`.
- Mod disabled: use vanilla `GetItemRecyclingParts(id)`.

Recognized upgraded Witcher gear is the safety exception. If the mod can infer a previous-tier item, that item may still be returned even when Debug Mode blocks normal fallback.

## Witcher Gear Safety

`PerfectDismantling_EnsurePreviousWitcherTier(...)` guarantees that recognized upgraded Witcher gear includes its previous-tier item in the returned parts.

The safety path:

1. Checks whether the internal item name belongs to a known Witcher gear family and gear piece.
2. Infers the previous tier from suffix patterns such as ` 5 ->  4`, `5 -> 4`, or ` upgrade 1 -> 1`.
3. Resolves the previous-tier item name by checking loaded `craftedItem_name` values first.
4. Falls back to item definitions with the relevant Witcher set tag.
5. Falls back to `GetItemsNames()`.
6. Adds the previous-tier item only when it is not already present.

Known family prefixes:

- `Lynx` and `NGP Lynx`
- `Bear` and `NGP Bear`
- `Gryphon` and `NGP Gryphon`
- `Wolf` and `NGP Wolf`
- `Red Wolf` and `NGP Red Wolf`
- `Viper` and `NGP Viper`
- `Netflix` and `NGP Netflix`

Known gear-piece substrings:

- `armor`
- `pants`
- `boots`
- `gloves`
- `steel sword`
- `silver sword`
- `crossbow`

The safety path is intentionally narrow and uses internal names rather than localized display names.

## Socketed Upgrade Return

After recipe or fallback output is selected, the mod calls:

```witcherscript
GetItemEnhancementItems(id, upgrades);
```

Each returned enhancement name is added with quantity `1`. This keeps inserted runes, glyphs, and similar upgrades in the final dismantle output.

## Aggregation

Returned parts are stacked by exact internal item name:

```witcherscript
PerfectDismantling_IsSameReturnedPart(firstItemName, secondItemName)
```

Currently this comparison is exact name equality. The helper exists so comparison semantics can change later without changing every call site.

## UI Integration

### Blacksmith Menu

File: `blacksmithMenu.ws`

The merchant dismantle path calls:

```witcherscript
partList = _inv.PerfectDismantling_GetDismantlingParts(item);
```

If the part list is empty, the item is not dismantled, the denied sound plays, and a notification is shown.

Before dismantling, the menu converts each part quantity to the player's current inventory quantity for notification comparison. The actual returned items still come from `_inv.RecycleItem(...)`.

### Dismantle Inventory Component

File: `guiDisassembleInventoryComponent.ws`

`ShouldShowItem(...)` keeps vanilla visibility behavior first by checking `GetItemRecyclingParts(item)`. If vanilla parts are empty, it checks `PerfectDismantling_GetDismantlingParts(item)`.

This means Debug Mode does not hide normal vanilla-dismantlable items from the grid. It can still block the action path when the selected item has no valid recipe or Witcher safety output.

`addRecyclingPartsList(...)` uses `PerfectDismantling_GetDismantlingParts(item)` for preview data and sets both `quantity` and `reqQuantity` to the returned quantity.

## Build And Install

### Build

Run:

```powershell
.\scripts\Build-Mod.ps1
```

The build script:

1. Removes the previous `dist/modPerfectDismantling` folder.
2. Copies `source/modPerfectDismantling/bin` into the built mod when present.
3. Copies loose scripts into `dist/modPerfectDismantling/content/scripts`.
4. Copies localization CSV files into `dist/modPerfectDismantling/content`.
5. Runs the Rust `w3strings-encode` helper to generate `.w3strings`.
6. Packs non-script, non-CSV, non-`.w3strings` content through `wcc_lite` only if such files exist.

The current repo is primarily a loose-script mod with config and localization.

### Install

Run:

```powershell
.\scripts\Install-Mod.ps1
```

The install script:

1. Requires built content under `dist/modPerfectDismantling/content`.
2. Replaces the installed mod folder under `The Witcher 3\Mods\modPerfectDismantling`.
3. Copies `modPerfectDismantling.xml` to the game's user config matrix folder.
4. Adds `modPerfectDismantling.xml;` to `dx11filelist.txt` and `dx12filelist.txt`.
5. Reminds the user to run Witcher Script Merger.

## Release State

`0.2 Alpha` is the first script-based release. The active build no longer uses the old generated XML override workflow from `0.1 Alpha`.

Publishing checklist:

- `VERSION` is `0.2-alpha`.
- README is player focused.
- Changelog has a `0.2 Alpha` section.
- Technical implementation is documented here.
- Testing checklist is updated for the script implementation.
- Build output should include loose scripts, mod menu config, CSV localization, and generated `.w3strings`.

## Known Limits

- Multi-output recipes are rejected and fall back when fallback is allowed.
- If two loaded recipes craft the exact same item, the first matching loaded recipe wins.
- Mods that change crafting only through script logic may not be visible to this resolver.
- Alias bridging is currently focused on live `NGP ...` item names whose loaded recipe still uses the unprefixed item name.
- Witcher gear safety is based on known internal naming patterns and known set tags.
- The implementation targets The Witcher 3 Next-Gen 4.04.
