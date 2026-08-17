# 06 — Test Strategy

No third-party testing framework is used. Godot 4.7 supports headless
execution (`--headless`), which is the backbone for command-line-runnable
checks. Prompt 02 implements a small custom GDScript test runner
(`tests/run_tests.gd`) invoked via headless Godot; most later categories
below are still planned, not yet implemented.

## Implemented in Prompt 02 (`tests/run_tests.gd`)

Run via `tools/run_headless.ps1` or directly:
`godot --headless --path . -s res://tests/run_tests.gd`

### Dimensions
- 40×40 fixture loads; `width == 40`, `height == 40`,
  `cell_count == 1600` (derived, not read from a stored field).
- 50×50 fixture loads; `width == 50`, `height == 50`,
  `cell_count == 2500`.
- A small 3×2 (non-square) fixture loads with `cell_count == 6`, proving the
  engine is generic and not special-cased for 40 or 50.

### Index conversion
- `coordinate -> index -> coordinate` round-trips correctly for corner cells
  `(0,0)`, `(width-1,0)`, `(0,height-1)`, `(width-1,height-1)`, and several
  interior cells, on both the 40×40 and 50×50 fixtures.
- Indexing formula is centralized (`BoardState.get_cell_index` /
  `get_cell_position`) and used everywhere — never duplicated.

### Invalid coordinates / indices
- Negative x/y rejected.
- `x >= width` / `y >= height` rejected.
- Negative index rejected.
- `index >= cell_count` rejected.

### Level validation
- Rejects: missing/unsupported `version`, `width <= 0`, `height <= 0`, wrong
  `cells` array length, empty `palette`, out-of-range palette ids in
  `cells`, malformed JSON.
- Validator uses the generic `width * height` formula — never hard-codes
  1600 or 2500 as special cases.
- Error messages are specific (level id, expected vs. actual) — see
  `docs/03_LEVEL_DATA_SPEC.md`.

### BoardState mutation
- New `BoardState` initializes all cells to `DIRTY`.
- `DIRTY -> CLEAN` mutation works and is observable via `get_cell_state`.
- Mutating an invalid index fails safely (no crash, reported failure).
- Cleaning one cell does not affect neighboring cells.
- `count_cells_by_state` returns correct counts.

### Independence
- Two `BoardState` instances built from the same `LevelData` do not share
  mutable runtime arrays — cleaning a cell in one does not affect the other.

### Performance sanity (not a pass/fail gate)
- 50×50 (2,500 cell) construction, full read, state counting, coordinate
  conversion, and bulk state mutation are timed and printed for diagnostics.
  No hard millisecond threshold is enforced (machine-dependent); the check
  is for catastrophic structural problems (crashes, pathological allocation
  patterns), not micro-optimization.

## Planned, not yet implemented

### Project boot
- Project opens/parses without error in headless mode. *(Manually verified
  in Prompt 02 via `godot --headless --path . --quit`; not yet an automated
  assertion in `run_tests.gd`.)*

### Slot state correctness
- Exactly the configured number of slots exist (currently 5).
- A slot's assigned color id is always a valid palette id for the current
  level.

### Target eligibility / dispatch
- A Scrubbot is never dispatched from a slot when `TargetSelector` reports
  no valid target for that slot's color.
- `TargetSelector` never returns a target cell that is already cleaned or
  otherwise unavailable.

### Routing result validity
- A `RoutingSystem` result always terminates at the target cell assigned by
  `TargetSelector`.
- A routing result never references a cell outside the board's actual
  `width`/`height` for that level (not a hard-coded 40×40 assumption).

### Cleanup / win / reward
- Reaching a target cell transitions it to cleaned exactly once.
- Win detection matches whatever win condition is finalized in M9.
- Win-streak reward mapping matches the locked table exactly:
  `1->1, 2->5, 3->10, 4->25, 5+->100` (regression test against the known-
  wrong mapping documented in `docs/01_GAMEPLAY_SPEC.md`).

### Save data
- Saved/loaded round-trip preserves streak count and currency exactly.

## Explicitly out of scope for Prompt 02

Slot system, target selector, routing system, save system, and rendering do
not exist yet — their tests remain planned only.
