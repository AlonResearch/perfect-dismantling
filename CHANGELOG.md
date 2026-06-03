# Changelog

## 0.2 Alpha

- Refactored Perfect Dismantling into a WitcherScript mod.
- Merchant dismantling now reads the currently loaded `crafting_schematics` definitions at runtime.
- Crafted one-output items dismantle into their direct crafting ingredients.
- Socketed runes, glyphs, and enhancement items are returned from the dismantled item's enhancement list.
- Dismantle menu previews and result notifications now use the same reward list as the actual dismantle action.
- Dismantle menu previews now show returned resource quantities directly in the item labels.
- Items without a one-output crafting recipe fall back to vanilla dismantling.
- Removed the old generated XML override approach from the active build.

## 0.1 Alpha

- Initial public generator for The Witcher 3 Next-Gen 4.04.
- Generates recipe-accurate dismantling tables from a local game installation.
- Covers base game, Hearts of Stone, Blood and Wine, and New Game+ item paths when extracted locally.
- Keeps the mod XML-only to avoid WitcherScript conflicts.
- Skips ambiguous recipes and stack-output recipes such as bolts.
