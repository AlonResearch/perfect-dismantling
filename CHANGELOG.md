# Changelog

## 0.2 Alpha

- Refactored Perfect Dismantling into a WitcherScript mod.
- Merchant dismantling now reads the currently loaded `crafting_schematics` definitions at runtime.
- Crafted one-output items dismantle into their direct crafting ingredients.
- Upgraded Witcher gear preserves the previous-tier item, including a fallback for known tiered gear when recipe data omits it.
- Socketed runes, glyphs, and enhancement items are returned from the dismantled item's enhancement list.
- Dismantle menu previews and result notifications now use the same reward list as the actual dismantle action.
- Dismantle menu previews show returned resource quantities on the item icons.
- Items without a one-output crafting recipe fall back to vanilla dismantling.
- Added an in-game mod menu with enable and debug toggles.
- Debug Mode treats missing recipe matches as strict test failures and prevents item removal.
- Build output now packages menu config files and compiles CSV localization into `.w3strings`.
- Removed the old generated XML override approach from the active build.

## 0.1 Alpha

- Initial public generator for The Witcher 3 Next-Gen 4.04.
- Generates recipe-accurate dismantling tables from a local game installation.
- Covers base game, Hearts of Stone, Blood and Wine, and New Game+ item paths when extracted locally.
- Keeps the mod XML-only to avoid WitcherScript conflicts.
- Skips ambiguous recipes and stack-output recipes such as bolts.
