# 06 — Test Strategy

No third-party testing framework is used. Godot 4.7 supports headless
execution (`--headless`), which is the backbone for command-line-runnable
checks. Prompt 02 implemented a small custom GDScript test runner
(`tests/run_tests.gd`, extended in Prompt 03 and Prompt 04) invoked via
headless Godot; most later categories below are still planned, not yet
implemented.

**Current total: 426 checks, all passing** (73 from Prompt 02 + 58 added in
Prompt 03 + 96 added in Prompt 04 + 59 added in M09-C001 + 34 safety checks
added in M09-C001 V02 correction + 12 filesystem-identity checks added in
M09-C001 V03 correction + 62 batch-importer checks added in M09-C002 V01 +
32 batch-safety/catalog-integrity checks added in M09-C002 V02 correction).

**Testing renderer output — a lesson from Prompt 04:** `BoardRenderer`
reads pixels back through an `Image` with `Image.FORMAT_RGBA8` (8 bits per
channel). Comparing a rendered pixel against an independently-computed
float `Color` with `Color.is_equal_approx()` (epsilon ~1e-5) will spuriously
fail due to ~1/255 quantization — this is expected engine behavior, not a
bug. Use a quantization-tolerant comparison (`_colors_close()` in
`tests/run_tests.gd`, ±0.01/channel) for renderer-output-vs-source-color
checks, and prefer meaningful-property assertions (hue preserved,
saturation/value reduced) over exact-value matching for DIRTY-vs-CLEAN
comparisons — see "Visual transform test principles" below.

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
- (Prompt 03) A 59×59 fixture loads; `width == 59`, `height == 59`,
  `cell_count == 3481` — the current production maximum, exercised through
  the real JSON-load pipeline, not just an in-memory object.

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
- (Prompt 03) The same benchmark is repeated at 59×59 (3,481 cells, current
  production maximum) — kept as a separate, additional benchmark rather
  than replacing the 50×50 one, so both remain regression baselines.

## Implemented in Prompt 03 (`tests/run_tests.gd`, extended)

### Production difficulty/dimension validation
- Every official band's minimum, maximum, and one rectangular example
  PASS production validation: Easy (20×20, 29×29, 20×27), Medium (30×30,
  39×39, 34×39), Hard (40×40, 49×49, 48×41), Very Hard (50×50, 59×59,
  53×59 — 59×59 is the current maximum).
- Cross-band rejection at both the upper and lower boundary for every
  difficulty (e.g. Easy `20×30` and `19×20` both rejected).
- An unknown/unrecognized difficulty string is rejected, not silently
  accepted as any known band.
- The 3×2 `TEST` fixture is proven to (a) still load and work structurally
  through `BoardState` exactly as before, while (b) being explicitly
  rejected by `ProductionLevelValidator` — the core structural-vs-
  production distinction this phase introduces. A same-dimensions-but-
  `EASY`-labeled level is checked to pass, confirming the *difficulty
  field*, not some hidden dimension rule, is what `TEST` rejection hinges
  on.
- All of the above use `DifficultyRules`/`ProductionLevelValidator`
  directly against in-memory `LevelData` objects (see
  `docs/03_LEVEL_DATA_SPEC.md` "Structural vs. production validation") —
  JSON-parsing correctness itself is already covered by the Prompt 02
  `LevelValidator` tests above, so these tests don't need one fixture file
  per dimension combination.

### Maximum board (59×59 / 3,481 cells)
- `BoardState.from_level_data` on the real `test_59x59.json` fixture
  reports `width == 59`, `height == 59`, `cell_count == 3481`.
- Coordinate/index round-trip verified at all four corners plus center.
- A single-cell mutation at 59×59 is isolated correctly (exactly 1 CLEAN,
  3,480 still DIRTY) — same mutation-isolation guarantee as smaller boards,
  now proven at the real maximum.

## Implemented in Prompt 04 (`tests/run_tests.gd`, extended)

### Palette color parsing
- Well-formed hex palette entries parse to the expected `Color` values.
- A malformed entry is reported as an error but doesn't abort parsing of
  the rest of the palette (a visible fallback color is used for it).
- Parsing the same palette twice is deterministic.

### DIRTY/CLEAN transform contract
- All three presets (A/B/C) produce a color different from CLEAN.
- All three presets differ from each other (preset switching has an
  effect).
- Every preset reduces both saturation *and* value/brightness relative to
  CLEAN (never saturation alone — the core readability requirement) while
  preserving hue (color family stays recognizable).
- Applying a DIRTY transform never mutates the original (CLEAN) `Color`.

### BoardRenderer geometry
- Every official band boundary (20×20, 29×29, 30×30, 39×39, 40×40, 49×49,
  50×50, 59×59) plus representative rectangular boards (20×27, 34×39,
  48×41, 53×59) configure without error.
- Computed `cell_size` matches the fit-to-available-rect formula exactly.
- Computed board pixel size equals `width/height * cell_size`.
- The first cell's center is within bounds (`>= 0`); the final row/column's
  cell center does not overflow the computed board pixel size.
- `BoardRenderer.get_child_count() == 0` at every tested size, including
  59×59 — the constant-node-count guarantee, automated.

### BoardRenderer pixel output
- A CLEAN cell's rendered pixel matches its source palette color (within
  8-bit quantization tolerance — see the note above this section).
- A DIRTY cell's rendered pixel visibly differs from an identically-colored
  CLEAN cell, with lower saturation, lower value, and preserved hue —
  verified by reading back actual rendered pixels, not by comparing to an
  independently precomputed float value.
- `update_cells()` correctly reflects a single changed cell without a full
  `refresh_all()`.
- `BoardState` cell states are unchanged after `configure()`/`refresh_all()`
  — the renderer never mutates gameplay truth.

### BoardRenderer performance sanity (not a pass/fail gate)
- `configure()`, `refresh_all()`, and `update_cells()` are timed at 40×40,
  50×50, 59×59, and 53×59 (rectangular Very Hard). No hard millisecond
  threshold — see `SCRUBBOTS_PHASE_M06_LOG.md` for actual measured numbers
  and the explicit statement that true GPU/on-screen frame-rate could not
  be measured under `--headless` (no display surface to composite to).

## Implemented in M09-C001 (`tests/run_tests.gd`, extended)

### LevelImporter core (59 checks)
- **3×2 non-square TEST import**: correct dimensions, cell count, difficulty,
  palette count (4), first-seen palette ordering (differs from sorted RGB),
  cell-to-palette mapping for all 6 cells including repeated colors in
  separated positions, output/preview/metadata files written.
- **Pixel-perfect reconstruction (3×2)**: raw RGBA8 byte comparison between
  source PNG and reconstruction from Level Data (palette+cells only, no
  source-image shortcut). Verifies width, height, format, exact byte match.
- **Deterministic rerun (3×2)**: identical import request on existing output
  detects UNCHANGED, no file rewrite.
- **Rectangular production-band (20×27 EASY)**: dimensions exact, difficulty
  preserved, passes ProductionLevelValidator and LevelValidator, raw RGBA8
  reconstruction byte match, deterministic rerun UNCHANGED.
- **Maximum size (59×59 VERY_HARD)**: 3,481 cells, passes production validator,
  raw RGBA8 reconstruction byte match (13,924 bytes).
- **Semi-transparent alpha round-trip (2×2)**: includes alpha=0, alpha=255,
  and alpha≈128; raw RGBA8 bytes match source exactly.
- **Performance sanity (59×59)**: import+validate+write and reconstruction
  timed (CPU only — no GPU/FPS claims per AL-003). Printed, no hard threshold.
- **Negative tests**: missing file, non-image file, empty level_id, empty
  display_name, unknown difficulty, TEST rejected by production validator,
  3×2 with EASY rejected (outside band), auto_difficulty correct for
  EASY/MEDIUM/VERY_HARD and empty for out-of-band/cross-band, overwrite
  safety (collision rejected, overwrite=true succeeds).
- All tests use runtime-generated deterministic fixtures — no committed
  artwork.

### LevelImporter safety hardening (34 checks, M09-C001 V02 correction)

- **Path alias safety (7 checks)**: output==source rejected (overwrite=false
  and overwrite=true — source immutable even with overwrite), preview==source
  rejected, metadata==source rejected, output==preview rejected,
  output==metadata rejected, preview==metadata rejected. Source byte
  preservation verified after each destructive alias attempt.
- **Preview/metadata overwrite safety (4 checks)**: existing different preview
  with overwrite=false rejected *before* Level JSON is written; existing
  different metadata rejected similarly; identical existing preview detected
  as UNCHANGED (no rewrite); identical existing metadata UNCHANGED.
- **Overwrite=true multi-artifact (1 check)**: all three artifacts (Level
  JSON, preview, metadata) replaced when overwrite=true.
- **PNG-only format gate (3 checks)**: valid JPEG image (generated at runtime
  via `save_jpg`) with `.jpg` extension rejected with "Unsupported source
  format" (AL-011: isolates format rejection from corrupt-file rejection);
  corrupt `.png` (random bytes) rejected with "Could not load"; uppercase
  `.PNG` variant accepted.
- **Reconstruction safety (5 checks)**: short cell array → null, out-of-range
  palette ID → null, invalid palette hex string → null, zero-dimension level
  → null, null level → null. All return cleanly without runtime errors.
- **Prior regression (14 checks)**: all 14 existing overwrite/negative tests
  from initial M09-C001 remain green.

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

## Explicitly out of scope for Prompt 02, Prompt 03, and Prompt 04

Slot system, target selector, routing system, save system do not exist
yet — their tests remain planned only. Rendering now exists
(`BoardRenderer`) but Scrubbot movement/visual effects on top of it do not.
