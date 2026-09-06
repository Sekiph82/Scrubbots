# M10-C001 — Canonical Gameplay QA Region from Owner Screen Reference (V08)

Status: **ISSUED — owner visual-QA layout correction after V07 AUDITED_PASS**

This task changes only the **debug/manual-QA presentation area** used to judge BoardRenderer output.

It does NOT change production board-size rules, artwork source matrices, difficulty bands, palette rules, or gameplay mechanics.

## Owner reference

The owner supplied a 887×1774 portrait gameplay composition reference and separately marked the intended gameplay/board region with a red outline.

Use the following owner-approved normalized gameplay region as the canonical M10 debug QA viewport:

Source reference size:
- width = 887
- height = 1774

Gameplay-region bounds:
- x = 13
- y = 175
- width = 844
- height = 942

Normalized ratios:
- left ≈ 13 / 887 = 0.014656
- top ≈ 175 / 1774 = 0.098647
- width ≈ 844 / 887 = 0.951522
- height ≈ 942 / 1774 = 0.530947

Current SCRUBBOTS reference viewport:
- 1080×2160

Equivalent canonical gameplay QA rectangle at 1080×2160:
- x ≈ 16 px
- y ≈ 213 px
- width ≈ 1028 px
- height ≈ 1147 px

Prefer deriving this rectangle from normalized ratios rather than hard-coding only the scaled integer values, so the same relative region remains stable if the debug viewport size changes.

## Core distinction

Do NOT confuse:

1. **screen/gameplay QA region** — presentation rectangle on the phone screen;
2. **selected logical board size** — e.g. 30×30, 39×39, 49×49, 59×59;
3. **source artwork bounding matrix** — e.g. Level 007 = 27×24.

These are three different layers.

Correct nesting:

```text
phone/reference viewport
└── canonical gameplay QA region
    └── selected logical board canvas
        └── immutable source artwork matrix
```

## Required behavior

### A. Canonical QA region

In `scenes/debug/board_renderer_debug.tscn` / `scripts/debug/board_renderer_debug.gd`:

- stop treating the entire remaining portrait screen area as the BoardRenderer comparison surface;
- create/use a dedicated gameplay QA region matching the owner-approved normalized rectangle above;
- visually center the selected logical board inside that gameplay QA region;
- keep the debug controls/info readable and outside/above the gameplay comparison area where practical;
- the BoardRenderer's `available_size` must be the canonical gameplay QA region size, not the full residual VBox portrait area.

### B. Logical board behavior remains unchanged

Production logical board maximum remains:
- 59×59 = 3481 cells

Do NOT introduce 75×75.

Do NOT change:
- DifficultyRules
- production dimension validation
- M03/M04/M06 59×59 contracts
- any production maximum

The Size dropdown still chooses logical board canvases such as 30×30 and 59×59.

### C. Artwork embedding remains unchanged

Keep the accepted V05/V06/V07 logic:

Level 007:
- immutable source = 27×24
- artwork cells = 542

On 30×30:
- source centered inside the 30×30 logical board
- offset = (1,3)
- all 542 artwork cells visible

On 59×59:
- source centered inside the 59×59 logical board
- offset = (16,17)
- all 542 artwork cells visible

Never:
- crop
- resample
- stretch
- regenerate
- repaint logical source cells

### D. BoardRenderer geometry

The renderer should continue to preserve logical board aspect ratio and use integer cell size.

For each selected logical board:
- calculate cell size from the **canonical gameplay QA rectangle**;
- center the resulting board pixel rectangle inside that QA region;
- do not stretch rectangular boards into squares;
- do not let the portrait phone's remaining height distort comparison scale.

### E. Visual rules remain locked

Preserve:
- canonical palette v2 = C01..C16
- C16 Pure Black = #000000
- BG01 Midnight Slate = #202533, outside C01..C16
- ACTIVE = opaque canonical source color
- CLEARED = alpha 0
- source/padding VOID = debug-only absence, never ACTIVE
- flat square cells
- visible cell separation
- no gloss
- no highlight
- no bevel
- no drop shadow
- no 3D/plastic bead appearance
- no interpolation
- no per-cell Nodes

## Debug information

Add enough info to confirm the screen-region geometry during owner QA.

For Real Artwork, the info line should include at least:
- fixture name
- source matrix size
- logical board canvas size
- source offset inside logical board
- gameplay QA region pixel size
- BoardRenderer board pixel size
- cell size
- artwork count
- VOID count
- pattern

Example concept:

```text
Level 007 — source=27x24 — canvas=30x30 — offset=(1,3)
QA=1028x1147 — board_px=1020x1020 — cell=34px
artwork=542 — void=358 — All ACTIVE
```

Exact board_px depends on integer fit.

## Required tests

Add/adjust tests to prove:

1. the canonical normalized QA-region constants match the owner reference;
2. at 1080×2160 the resulting QA region is approximately x=16, y=213, w=1028, h=1147;
3. BoardRenderer receives the QA region size as available_size, not the full portrait residual container;
4. 30×30 is centered inside the QA region with integer cell size;
5. 59×59 is centered inside the same QA region with integer cell size;
6. Level 007 remains fully visible at both 30×30 and 59×59;
7. Level 007 logical offsets remain (1,3) and (16,17);
8. 007 artwork count remains 542;
9. 010 and 013 variable-canvas behavior does not regress;
10. rectangular logical boards preserve aspect ratio;
11. VOID never becomes ACTIVE;
12. C01..C16 / C16 / BG01 rules remain unchanged;
13. no per-cell Node architecture;
14. the debug scene runs through the real deferred fixture-change path without runtime errors;
15. full Godot 4.7.1 headless suite passes;
16. debug scene runtime smoke succeeds.

## Scope

This is still M10 owner manual-QA tooling.

Do NOT:
- change `tasks.md` checkboxes;
- mark SB-M10-005..011 complete;
- start M14+;
- change production board limits;
- change palette values;
- modify source artwork grids;
- update H!veAI tracker files;
- update PROJECT_DASHBOARD;
- update `coordination/SESSION_INDEX.md`;
- self-audit.

## Coordination output

Write only:

`coordination/sessions/M10-C001/CLAUDE_LOG_V08.md`

Run all required Godot 4.7.1 tests and runtime smoke checks.

Commit and push safely.

Hand back:
`AWAITING_AUDIT`

Then stop.
