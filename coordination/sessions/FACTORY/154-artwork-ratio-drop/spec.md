# ScrubBots game — drop the 25%-of-board artwork ratio (ADR-030 D2), keep the 200-cell floor

Owner decision, 2026-11-12. Written by the Factory Claude for the Claude working in
`C:\Users\sekip\Desktop\Scrubbots` (`Sekiph82/Scrubbots`). The owner explicitly authorizes
this game change. Follow the game repo's own CLAUDE.md, TASKS.md and test rules for
everything not stated here.

## Decision

A production level must have **>= 200 non-VOID (artwork) cells**. The second condition,
**>= 25% of W*H non-VOID**, is removed. Nothing else in D2 / ADR-030 changes: the 20..59
per-dimension envelope, the full W x H board, and the VOID semantics all stay as they are.

## Why

- The Factory produces 56x56 PixelLab artworks. 22 of them have 462..778 artwork cells and
  were rejected only because 778 < 25% of 3136. A full, void-free 20x20 level has only 400
  cells and is accepted. The ratio therefore rejected artwork that is larger than levels the
  game already accepts, and it penalised thin or tall figures on a mostly transparent canvas.
- The 200-cell floor still stops near-empty or broken outputs.
- Real evidence: the Factory solver bridge, running the game's own validator, failed with
  `ProductionLevelValidator rejected bridge LevelData: ... production artwork needs >= 200
  non-VOID cells and >= 1/4 of the board; got 719 of 3136`.

## Change exactly these places (verify each with your own search first)

Code:
1. `scripts/data/production_level_validator.gd`
   - Lines 22 and 32 (doc comments): the rule becomes ">= 200 non-VOID cells".
   - Lines 34-35: remove `MIN_ARTWORK_FRACTION_NUM` and `MIN_ARTWORK_FRACTION_DEN`, unless
     something else still references them.
   - Line 64: the check becomes `if artwork < MIN_ARTWORK_CELLS:`.
   - Lines 66-67: update the error message to match, e.g.
     "production artwork needs >= %d non-VOID cells; got %d of %d".
2. `tools/audit_level_art.py`
   - Line 25: drop `MIN_ARTWORK_FRACTION`.
   - Line 131: keep only `nonvoid_cells < MIN_ARTWORK_CELLS`.
3. Search the whole repo for any other enforcement of the ratio and change it the same way:
   `rg -n "FRACTION|0\.25|25%|1/4" scripts tools tests`. Look in particular at
   `scripts/content_runtime/scrubpack_v1.gd`, `scripts/tools/level_importer.gd`,
   `scripts/tools/production_art_level_builder.gd` and `scripts/data/level_validator.gd`.

Docs (record the change; do not rewrite history):
4. `docs/05_TECH_DECISIONS.md:1071` (ADR-030 D2): change the rule. Add a dated amendment
   line: "2026-11-12 owner amendment: the >= 25% of W*H condition is removed; >= 200
   non-VOID cells remains."
5. `docs/03_LEVEL_DATA_SPEC.md:72` and `:103`: update the rule.
6. `CLAUDE.md:134`: update the rule.

Tests:
7. `tests/void_cells_c001.gd`
   - Line 4: update the header comment.
   - Any case that expects a rejection only because of the ratio must now expect acceptance.
   - Keep, or add, a case that is still rejected below 200 artwork cells.
8. Add one regression case to the validator tests: a 56x56 level with VOID cells and about
   700 artwork cells (below 25% of the board, above 200) is ACCEPTED, and a 56x56 level with
   199 artwork cells is REJECTED. Watch it fail on the old code first.

## Must not change

- The 30 existing campaign levels, their data and art.
- The VOID semantics, the 20..59 envelope, the Difficulty V1 analyzer and the solver.
- Any other ADR-030 decision (D1, D3 and so on).

## Done when

- The game's full headless test suite passes. Report the exact counts, including any failures.
- `rg` finds no remaining enforcement of the 25% ratio. Historical logs or archives may still
  mention it; leave them.
- One commit with a clear message is pushed to the game's main branch the way that repo
  normally does it. Report the commit hash to the owner.
