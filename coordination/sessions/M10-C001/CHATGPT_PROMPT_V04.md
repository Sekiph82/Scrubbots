# M10-C001 — BoardRenderer Debug Variable Canvas Placement Correction (V04)

Status: **ISSUED — supersedes V03 before implementation**

Owner clarification: the Real Artwork source matrix dimensions are **not** the BoardRenderer canvas dimensions, and the canvas is **not always fixed to 59×59**.

The correct model is:

> Keep the source artwork matrix unchanged. Place it inside the currently selected debug board size using VOID padding, as long as the selected board can fully contain the source matrix.

This means the same artwork must be fully visible at every selected board size large enough to contain it.

## Example: Level 007

Source artwork matrix:
- 27×24 = 648 source matrix slots
- 542 real artwork cells
- 106 source VOID

Therefore:
- on a 30×30 debug board, all 542 artwork cells must be visible;
- on a 59×59 debug board, all 542 artwork cells must also be visible;
- the only difference is the amount of outer VOID padding around the unchanged 27×24 source matrix.

Do NOT scale, resample, stretch, crop, repaint, or regenerate the source artwork.

Every source square remains exactly one logical cell.

## Required placement rule

For a selected canvas `canvas_w × canvas_h` and source matrix `source_w × source_h`:

- the canvas is valid only if:
  - `canvas_w >= source_w`
  - `canvas_h >= source_h`

- center the unchanged source matrix inside the selected canvas using:
  - `offset_x = floor((canvas_w - source_w) / 2)`
  - `offset_y = floor((canvas_h - source_h) / 2)`

- source VOID remains VOID;
- all outer padding is also debug-only VOID;
- real artwork cell count and per-color counts never change with canvas size.

## Real Artwork Size dropdown behavior

Unlike V03, the Size dropdown must remain enabled for Real Artwork fixtures.

The owner must be able to compare the same artwork at different board sizes.

For each selected Real Artwork fixture:

1. Keep the existing Size dropdown visible and enabled.
2. A size option is valid only if both selected dimensions can contain the source matrix.
3. Invalid size options must not render a cropped board.
4. Prefer disabling invalid OptionButton items for that fixture. If Godot UI constraints make per-item disabling awkward, reject invalid selections cleanly and automatically select the smallest valid size, but do not crop.
5. When switching fixture, recompute valid/invalid size choices.
6. When switching to a valid size, rebuild the debug canvas with the same source matrix centered inside it.

## Source matrices

The source JSON files remain unchanged and authoritative:

- Level 007 source matrix = 27×24
- Level 010 source matrix = 49×50
- Level 013 source matrix = 28×31

Do not modify these JSON dimensions or arrays.

## Expected valid examples

### Level 007 (27×24)
Must fully render at:
- 29×29
- 30×30
- 39×39
- 34×39
- 40×40
- 49×49
- 48×41
- 50×50
- 59×59
- 53×59
and any other selected canvas where width>=27 and height>=24.

Examples:
- 30×30 offset = (1,3)
- 59×59 offset = (16,17)

### Level 010 (49×50)
Must fully render at:
- 50×50
- 59×59
- 53×59
and any future canvas where width>=49 and height>=50.

Examples:
- 50×50 offset = (0,0)
- 59×59 offset = (5,4)

### Level 013 (28×31)
Must fully render at:
- 39×39
- 34×39
- 40×40
- 49×49
- 48×41
- 50×50
- 59×59
- 53×59
and any future canvas where width>=28 and height>=31.

Examples:
- 39×39 offset = (5,4)
- 59×59 offset = (15,14)

## Debug VOID counts

For any selected valid canvas:

`debug_void_count = canvas_w * canvas_h - artwork_cell_count`

Artwork counts must remain invariant:
- 007 = 542
- 010 = 2450
- 013 = 375

Examples:

### 007
- 30×30: 900 - 542 = 358 debug VOID
- 59×59: 3481 - 542 = 2939 debug VOID

### 010
- 50×50: 2500 - 2450 = 50 debug VOID
- 59×59: 3481 - 2450 = 1031 debug VOID

### 013
- 39×39: 1521 - 375 = 1146 debug VOID
- 59×59: 3481 - 375 = 3106 debug VOID

## Semantics

- Source JSON bounding matrix is immutable.
- Selected board size is the debug comparison canvas.
- Source matrix is centered within the selected canvas.
- Source artwork cells keep exact canonical color IDs.
- Source VOID and added padding VOID are debug-only absence.
- VOID must never become ACTIVE artwork.
- ACTIVE/CLEARED patterns apply only to real artwork cells.
- BG01 #202533 shows through VOID and CLEARED.
- No production BoardState VOID state may be introduced.

## Rendering

Keep the existing visual contract:
- one square = one logical cell;
- visible square-cell separation;
- flat solid canonical fill;
- no gloss;
- no highlight;
- no bevel;
- no drop shadow;
- no 3D bead/bulge;
- no interpolation;
- no per-cell Nodes.

The cell size should be derived from the selected canvas dimensions, so changing 30×30 -> 59×59 changes display scale but never changes the logical artwork.

## Debug info text

For Real Artwork show at least:
- fixture name
- source matrix size
- selected canvas size
- centered offset
- artwork cell count
- total debug VOID count
- palette subset
- BG01
- cell size
- ACTIVE/CLEARED pattern

Example:
`Real Artwork - Level 007 — source=27x24 — canvas=30x30 — offset=(1,3) — artwork=542 — void=358`

## Implementation direction

Refactor the Real Artwork debug adapter so loading the JSON returns the immutable source fixture data, and a separate helper embeds that source into a requested valid canvas.

Prefer a clear debug-only helper, for example:
- `embed_real_fixture_in_canvas(source_fixture, canvas_w, canvas_h)`
or equivalent.

Do not overload the source JSON itself with canvas padding.

## Tests required

Add/adjust tests proving:

1. source JSON matrices remain exactly 27×24 / 49×50 / 28×31;
2. source JSON files are unchanged;
3. Real Artwork Size dropdown remains usable;
4. invalid too-small canvas sizes cannot crop the artwork;
5. 007 renders completely at 30×30 and 59×59;
6. 007 offsets are exactly (1,3) at 30×30 and (16,17) at 59×59;
7. 007 artwork count stays 542 at both sizes;
8. 007 debug VOID is 358 at 30×30 and 2939 at 59×59;
9. 010 renders completely at 50×50 and 59×59;
10. 010 offsets are (0,0) and (5,4);
11. 010 artwork count stays 2450;
12. 013 renders completely at 39×39 and 59×59;
13. 013 offsets are (5,4) and (15,14);
14. 013 artwork count stays 375;
15. source VOID remains VOID;
16. outer padding is VOID;
17. ALL_ACTIVE activates only artwork cells;
18. ALL_CLEARED activates none;
19. CHECKER never activates source/padded VOID;
20. per-color counts remain invariant across canvas sizes;
21. BG01 remains #202533;
22. no per-cell Node architecture;
23. Synthetic Stripes behavior remains unchanged;
24. full headless suite passes;
25. debug scene headless boot succeeds.

## Scope

Still M10 debug/manual-QA tooling only.

Do not:
- modify source JSON fixture matrices;
- promote fixtures to production;
- weaken production difficulty/dimension rules;
- change tasks.md checkboxes;
- mark SB-M10-005..011 complete;
- touch M14+ gameplay implementation.

## Coordination

Write:
`coordination/sessions/M10-C001/CLAUDE_LOG_V04.md`

Do NOT update any H!veAI tracker files or PROJECT_DASHBOARD.
ChatGPT will update all tracker/dashboard files after the independent audit.

Your responsibility ends after:
- implementation,
- tests,
- CLAUDE_LOG_V04.md,
- commit/push,
- handing the cycle back as AWAITING_AUDIT.

Do not self-audit.
