# M10-C001 — BoardRenderer Debug Real Artwork Fixtures (V02)

Status: **ISSUED — supersedes V01 before implementation**

This V02 keeps the exact same owner intent and scope as V01, but simplifies the implementation contract: **do not reconstruct fixture data from Markdown. Load the three repository JSON fixtures directly.**

## First action

Safely sync `C:\Users\sekip\Desktop\ScrubBots` main with `origin/main` while preserving owner work. No reset-hard, clean-fd, destructive restore, or force push.

Then read:
- https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md
- https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/README.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
- https://github.com/Sekiph82/Scrubbots/blob/main/docs/08_PIXEL_ART_PALETTE_RULES.md
- https://github.com/Sekiph82/Scrubbots/blob/main/data/palettes/scrubbots_palette_v1.json
- https://github.com/Sekiph82/Scrubbots/blob/main/scenes/debug/board_renderer_debug.tscn
- https://github.com/Sekiph82/Scrubbots/blob/main/scripts/debug/board_renderer_debug.gd
- https://github.com/Sekiph82/Scrubbots/blob/main/scripts/debug/board_debug_fixtures.gd
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M10-C001/CHATGPT_AUDIT_CRITERIA_V02.md

## Canonical fixture files — load these directly

- https://github.com/Sekiph82/Scrubbots/blob/main/data/debug/board_renderer_fixtures/level_007.json
- https://github.com/Sekiph82/Scrubbots/blob/main/data/debug/board_renderer_fixtures/level_010.json
- https://github.com/Sekiph82/Scrubbots/blob/main/data/debug/board_renderer_fixtures/level_013.json

These JSONs are the implementation source of truth for the three real-artwork debug fixtures. Do not OCR, regenerate, infer or manually retype the grids.

Each file already contains:
- exact width/height;
- exact row-major `color_id_array`;
- palette subset IDs;
- exact per-color counts;
- VOID count;
- BG01;
- ACTIVE/CLEARED/VOID semantics;
- flat-cell rendering contract.

The prior `OWNER_FIXTURE_DATA_V01.md` remains provenance/evidence only. V02 implementation should consume the JSON files instead.

## Required debug UI

Extend the existing procedural BoardRenderer debug UI with:

```text
Fixture
├─ Synthetic Stripes
├─ Real Artwork - Level 007
├─ Real Artwork - Level 010
└─ Real Artwork - Level 013
```

- Synthetic Stripes keeps existing size dropdown + ACTIVE/CLEARED pattern behavior.
- Real Artwork fixtures use fixed dimensions from JSON; do not resize/resample logical grids.
- Existing pattern selector applies only to actual artwork cells.
- VOID remains background and never becomes ACTIVE/CLEARED artwork.
- Real Artwork background = BG01 Midnight Slate `#202533`.
- Synthetic Stripes may retain the conspicuous magenta transparency-test background.

## Critical rendering rule

Keep square gameplay cells visibly separated, but flatten their material:
- visible square cell boundaries/separation;
- one flat canonical color inside each cell;
- no gloss/highlight/bevel/drop shadow/3D bulge;
- no interpolation;
- no per-cell Nodes.

Implement the boundary treatment as batched/presentation-only debug rendering. Do not replace BoardRenderer with thousands of Controls/Sprites.

## Palette / state contract

- Logical colors only C01..C15 from `scrubbots_palette_v1.json`.
- BG01 is not C16 and never a LevelData cell color.
- ACTIVE = canonical source color, opaque.
- CLEARED = alpha 0, BG01 visible.
- VOID = debug-only mask concept; do not add a production BoardState VOID state.

Level 010 JSON already contains the owner-requested blue recolor:
- source bright green -> C06 Cyan
- source mid green -> C07 Ocean Blue
- source dark green -> C08 Deep Blue

Do not alter that mapping.

## Scope boundary

This is M10 debug/manual-QA tooling only.
- Do not add these fixtures to production LevelCatalog.
- Do not weaken difficulty-size rules.
- Do not mark M47/M48 content tasks complete.
- Do not mark SB-M10-005..011 complete; owner must visually approve those.
- Do not start or modify M14/M15/M16/M17.

Also fix the stale comment in `scripts/debug/board_debug_fixtures.gd` that says no real palette exists.

## Validation

At minimum:
1. `godot --version` confirms Godot 4.7.1 stable/current approved version.
2. Full headless suite passes.
3. `board_renderer_debug.tscn` boots/parses headlessly without fatal errors.
4. Fixture dropdown labels/order are exact.
5. JSON dimensions, array lengths, palette subsets, per-color counts and VOID counts validate exactly.
6. All nonzero logical IDs are legal C01..C15 and local palettes are ascending C-ID.
7. VOID never becomes colored when changing state patterns.
8. ALL CLEARED makes every artwork cell transparent while VOID remains background.
9. ALL ACTIVE reconstructs each mapped layout.
10. Real Artwork uses exact BG01 `#202533`.
11. Synthetic Stripes behavior remains intact.
12. No per-cell Node explosion; record child-count/architecture evidence.
13. Flat cell fill + visible cell separation has no gloss/bevel/shadow/interpolation.
14. Inspect `git diff` before commit.

## Coordination

Use the matching log:
`coordination/sessions/M10-C001/CLAUDE_LOG_V02.md`

Before ending, update SESSION_INDEX + H!ve tracking/dashboard, push safely, set `AWAITING_AUDIT`, and stop. Do not self-audit.

## Success condition

Opening `scenes/debug/board_renderer_debug.tscn` in Godot 4.7.1 lets the owner select Synthetic Stripes or exact JSON-backed Real Artwork 007/010/013. The real artworks show flat canonical colors with visible square-cell structure, BG01 behind absent/CLEARED cells, 010 in the requested blue family, and no plastic-bead material look.
