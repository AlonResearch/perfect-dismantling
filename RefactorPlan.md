# Clean Recipe-Routed Dismantling With Witcher Gear Safety

## Status
Implemented in `0.2 Alpha`. The active source now uses `PerfectDismantling_TryResolveRecipeParts(...)` plus `PerfectDismantling_ReadCraftingSchematicNode(...)` for loaded recipe resolution, and `PerfectDismantling_EnsurePreviousWitcherTier(...)` for the Witcher gear safety invariant.

## Summary
Rework Perfect Dismantling around one clear flow: crafted items dismantle into loaded crafting recipe ingredients when possible, fallback behavior is explicit and narrow, and legacy helper paths that no longer match this model are removed. For recognized upgraded Witcher gear, the previous-tier gear item is a hard safety invariant: dismantling must return it whenever the item is recognized as upgraded Witcher gear.

## Intention
Perfect Dismantling should behave like the inverse of crafting for any item with a valid one-output recipe. The mod should prefer the effective loaded recipe data over vanilla recycling, should not require the player to know or own the schematic, and should remain compatible with recipe mods that alter loaded `crafting_schematics`.

Fallbacks exist to protect players, not to silently approximate recipe dismantling. Normal non-crafted items may use vanilla recycling when Debug Mode is off. Recognized upgraded Witcher gear is stricter: users must never lose the previous-tier base gear item through dismantling. If the mod recognizes an item as upgraded Witcher gear, it must add the inferred previous-tier item to the output whenever that previous-tier item is not already present.

Future fixes should preserve these priorities in order: recipe accuracy, Witcher gear safety, native-equivalent socket return behavior, then vanilla fallback for non-crafted or unsupported items.

## Key Changes
- Replace direct inline ingredient scanning with a dedicated Perfect Dismantling recipe resolver that scans the effective loaded `crafting_schematics` definitions by `craftedItem_name`.
- Do not rely on normal `W3CraftingManager.Init(...)`, because it only loads schematics known by the character/save.
- Parse matched schematic nodes with crafting-manager-equivalent logic, so modded loaded recipe definitions are respected without requiring the player to know the schematic.
- Treat only one-output recipes as recipe-routed dismantle targets; multi-output recipes fall back to vanilla unless Witcher gear safety requires previous-tier preservation.
- Remove or collapse legacy recipe/fallback helpers that duplicate old raw-node behavior, keeping only the new resolver, vanilla fallback, socket return handling, and Witcher safety guard.

## Dismantle Flow
- Resolve the dismantled item name and look for a valid loaded one-output crafting recipe.
- If found, return the resolved recipe ingredients as the base dismantle output.
- If no valid recipe is found, Debug Mode on blocks normal dismantling and logs useful discovery info; Debug Mode off uses vanilla recycling for normal items. Recognized upgraded Witcher gear is the safety exception: it can still return the inferred previous-tier item when normal fallback would be blocked.
- Always append socketed glyphs/runes/enchantments after base output selection, using the current enhancement-list behavior as the vanilla game does.
- For the preview menu, returned parts should aggregate duplicate item names from recipe ingredients, Witcher safety injection, vanilla fallback, or socket returns as one stacked entry with the correct total quantity.

## Witcher Gear Safety
- Detect upgraded Witcher gear only through stable internal item names and loaded item/schematic definitions, not localized display names.
- Infer the previous tier from the known internal tier chain, such as `Lynx Pants 5 -> Lynx Pants 4`.
- For recognized upgraded Witcher gear, ensure the previous-tier item is present in the final output.
- If a valid recipe already contains the previous-tier item, do not duplicate it.
- If a valid recipe omits the previous-tier item, inject the inferred previous-tier item.
- If no valid recipe exists, still inject the inferred previous-tier item alongside the normal fallback output.
- Only apply this safety injection to recognized tiered Witcher gear with tier greater than the base tier, keeping the fallback narrow and avoiding unrelated crafted equipment.

## Test Plan
- Unknown schematic on save: dismantling a crafted item still returns loaded recipe ingredients.
- Modded recipe: dismantling follows the effective loaded `crafting_schematics` recipe.
- Grandmaster Feline trousers and Mastercrafted Feline armor: previous-tier gear is always returned, with no duplicates.
- Witcher gear with missing/invalid recipe: previous-tier gear is still returned.
- Socketed Witcher gear: returns recipe/fallback parts plus socketed upgrades exactly once.
- Normal crafted item: returns resolved recipe ingredients.
- Multi-output recipe such as bolts: falls back to vanilla behavior while still preserving previous-tier items if ever recognized as upgraded Witcher gear.
- Non-crafted/junk item: Debug Mode off falls back to vanilla recycling; Debug Mode on blocks dismantling.

## Assumptions
- "Resolved like crafting" means matching vanilla `W3CraftingManager.LoadSchematicsXMLData(...)` parsing semantics, not using the normal initialized manager instance.
- Witcher gear safety takes priority over vanilla fallback behavior.
- Compatibility covers mods that alter loaded `crafting_schematics`; mods that change crafting only through separate script logic may still require dedicated compatibility work.
