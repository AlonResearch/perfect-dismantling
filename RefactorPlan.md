# Refactor Plan

Status: implemented in `0.2 Alpha`.

The recipe-routed dismantling refactor is complete in the active source tree. The current technical source of truth is [TECHNICAL_GROUND_TRUTH.md](TECHNICAL_GROUND_TRUTH.md).

## Implemented Outcomes

- Dismantling now routes through `PerfectDismantling_GetDismantlingParts(...)`.
- Crafted one-output items resolve returned parts from loaded `crafting_schematics` definitions.
- Recipe parsing mirrors the relevant `W3CraftingManager.LoadSchematicsXMLData(...)` fields without requiring the player to know the schematic.
- Multi-output recipes are rejected and use fallback behavior when fallback is allowed.
- Socketed runes, glyphs, and enhancements are appended after base output resolution.
- Recognized upgraded Witcher gear gets a narrow previous-tier safety check.
- Debug Mode blocks normal recipe misses instead of silently falling back.
- Preview, action, and notification paths use the shared returned-parts helper.
- The active build no longer uses the `0.1 Alpha` generated XML override workflow.

## Historical Intent

Perfect Dismantling should behave like the inverse of crafting for any item with a valid one-output recipe. It should prefer effective loaded recipe data, preserve upgraded Witcher gear base items, keep socketed upgrade return behavior, and fall back to vanilla dismantling only where that is safer than inventing output.

Future work should preserve these priorities:

1. Recipe accuracy.
2. Witcher gear previous-tier safety.
3. Native-equivalent socket return behavior.
4. Vanilla fallback for non-crafted or unsupported items.

## Remaining Ideas

- Add scripted or save-based regression cases once a repeatable WitcherScript test harness is available.
- Expand alias handling if non-`NGP` naming compatibility issues appear.
- Add dedicated compatibility notes for specific recipe overhaul mods after player reports confirm their behavior.
- Consider richer Debug Mode notifications if the current log-only detail is not enough for testers.
