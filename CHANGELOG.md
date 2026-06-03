# Changelog

## 0.3 Alpha - 2026-06-03

- Changed `Debug Mode` so it only controls Perfect Dismantling debug logs.
- Recipe misses now behave the same whether Debug Mode is on or off: recognized upgraded Witcher gear can still return its inferred previous-tier safety item, and other unresolved items use vanilla recycling parts when available.
- Enabled the vanilla recycling fallback for recipe-less items while keeping preview, toast, and action behavior consistent across the debug toggle.
- Rebuilt the loose-script mod and installed the latest build for local testing.

## 0.21 Alpha - 2026-06-03

- Changed `Debug Mode` so it only controls Perfect Dismantling debug logs.
- Recipe misses behaved the same whether Debug Mode was on or off: recognized upgraded Witcher gear could still return its inferred previous-tier safety item, and other unresolved items were not dismantled.
- Removed the enabled-mod debug-off vanilla fallback path from recipe-miss handling so preview, toast, and action behavior stayed consistent across the debug toggle.
- Rebuilt the loose-script mod and installed the latest build for local testing.

## 0.2 Alpha - 2026-06-03

- Refactored Perfect Dismantling into a WitcherScript mod.
- Prepared the project for the `0.2 Alpha` release with player-focused README, updated testing docs, and a technical ground-truth document.
- Merchant dismantling now reads the currently loaded `crafting_schematics` definitions at runtime.
- Recipe lookup now uses a dedicated loaded-recipe resolver that parses matched schematic nodes with `W3CraftingManager.LoadSchematicsXMLData(...)`-equivalent fields instead of the legacy raw ingredient helper.
- Crafted one-output items dismantle into their direct crafting ingredients.
- Multi-output recipes explicitly stay on the vanilla fallback path to avoid duplicating recipe outputs.
- Upgraded Witcher gear preserves the previous-tier item, including a safety injection for known tiered gear when recipe data or fallback output omits it.
- Socketed runes, glyphs, and enhancement items are returned from the dismantled item's enhancement list.
- Returned parts are aggregated by internal item name for preview and result notifications.
- Dismantle menu previews and result notifications now use the same reward list as the actual dismantle action.
- Dismantle menu previews show returned resource quantities on the item icons.
- Items without a one-output crafting recipe fall back to vanilla dismantling.
- Added an in-game mod menu with enable and debug toggles.
- Debug Mode treats normal missing recipe matches as strict test failures and prevents item removal, while still allowing recognized upgraded Witcher gear to return its inferred previous-tier safety item.
- Debug Mode keeps normal vanilla-dismantlable items visible in the dismantle grid so recipe misses can be inspected instead of disappearing from the menu.
- Build output now packages menu config files and compiles CSV localization into `.w3strings`.
- Removed the old generated XML override approach from the active build.

## 0.1 Alpha

- Initial public generator for The Witcher 3 Next-Gen 4.04.
- Generates recipe-accurate dismantling tables from a local game installation.
- Covers base game, Hearts of Stone, Blood and Wine, and New Game+ item paths when extracted locally.
- Keeps the mod XML-only to avoid WitcherScript conflicts.
- Skips ambiguous recipes and stack-output recipes such as bolts.
