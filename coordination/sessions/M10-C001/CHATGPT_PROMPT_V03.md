# M10-C001 — BoardRenderer Debug 59x59 Master-Grid Placement Correction (V03)

Status: **ISSUED — owner manual-QA correction after V02 AUDITED_PASS**

Owner manual QA found a presentation/modeling mismatch in the debug tool.

## Problem

The three real-artwork JSON fixtures currently use their extracted bounding-matrix dimensions as the BoardRenderer board dimensions:

- Level 007: 27×24
- Level 010: 49×50
- Level 013: 28×31

That causes each artwork to scale to fill the available debug area independently. This is not the intended comparison.

The extracted JSON dimensions are the **artwork bounding matrix**, not the final comparison canvas.

The owner expects each artwork to be placed inside the canonical maximum **59×59 = 3,481-slot master grid** so its true relative footprint can be judged against the same board scale.

## Required correction

Keep the existing JSON fixture files unchanged as source-art bounding matrices.

For the BoardRenderer manual-QA view, embed each real artwork into a fixed **59×59 debug master grid** with VOID padding around it.

Use deterministic centered placement:

- Level 007, 27×24:
  - x offset = 16
  - y offset = 17
  - resulting padding: left 16, right 16, top 17, bottom 18

- Level 010, 49×50:
  - x offset = 5
  - y offset = 4
  - resulting padding: left 5, right 5, top 4, bottom 5

- Level 013, 28×31:
  - x offset = 15
  - y offset = 14
  - resulting padding: left 15, right 16, top 14, bottom 14

The placement rule is:
`offset = floor((59 - source_dimension) / 2)`

## Semantics

- The 59×59 canvas has 3,481 debug slots.
- Source artwork cells retain their exact row-major logical layout and canonical colors.
- Source VOID stays VOID.
- All added outer padding is also debug-only VOID.
- VOID is still not a production BoardState state and must never become ACTIVE artwork.
- ACTIVE/CLEARED patterns apply only to real artwork cells.
- BG01 #202533 shows through VOID and CLEARED positions.
- Do not alter the production LevelData / BoardState semantics.

## Debug UI behavior

For all three Real Artwork fixtures:
- render on a fixed 59×59 master grid;
- use the same BoardRenderer cell size for direct visual comparison;
- keep the Size dropdown disabled;
- info text must show both:
  - source artwork matrix dimensions (e.g. 27×24)
  - debug canvas dimensions 59×59
  - artwork cell count
  - total VOID count after padding
  - placement offset

Example info concept:
`Real Artwork - Level 007 — source=27x24 — canvas=59x59 — offset=(16,17) — artwork=542 — void=2939`

Computed total debug VOID counts:
- 007: 3481 - 542 = 2939
- 010: 3481 - 2450 = 1031
- 013: 3481 - 375 = 3106

## Important

Do not scale/resample/repaint the source matrices into 59×59.
This is **padding/placement**, not image scaling.

Every source square remains exactly one gameplay-cell unit inside the master grid.

Do not create per-cell Nodes.

Keep the existing flat-fill + batched grid overlay visual contract.

## Tests required

Add/adjust focused tests proving:

1. all Real Artwork debug boards are exactly 59×59;
2. source matrices remain unchanged in their JSON files;
3. source cells are copied to the exact centered offsets above;
4. source VOID remains VOID;
5. outer padding is VOID;
6. total artwork counts remain exactly 542 / 2450 / 375;
7. total debug VOID counts become exactly 2939 / 1031 / 3106;
8. color counts remain unchanged;
9. ALL_ACTIVE activates only artwork cells;
10. ALL_CLEARED activates none;
11. CHECKER never activates source/padded VOID;
12. BG01 remains #202533;
13. no per-cell Node architecture;
14. Synthetic Stripes behavior remains unchanged;
15. full headless suite passes;
16. debug scene headless boot succeeds.

## Scope

This is still M10 debug/manual-QA tooling only.

Do not:
- change the fixture JSON source matrices;
- promote fixtures to production catalog;
- weaken production difficulty/dimension rules;
- change tasks.md checkboxes;
- mark SB-M10-005..011 complete;
- touch M14+ gameplay implementation.

## Coordination

Write:
`coordination/sessions/M10-C001/CLAUDE_LOG_V03.md`

Do NOT update any H!veAI tracker files or PROJECT_DASHBOARD.
ChatGPT will update all tracker/dashboard files after the independent audit.

Your responsibility ends after:
- implementation,
- tests,
- CLAUDE_LOG_V03.md,
- commit/push,
- and handing the cycle back as AWAITING_AUDIT.

Do not self-audit.
