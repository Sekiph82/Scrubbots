# 03 — Level Data Specification (Version 1 — implemented in Prompt 02, production/test validation split added in Prompt 03)

> **Correction note (Prompt 02):** The Prompt 01 draft of this document
> proposed a fixed-40×40-flavored schema (`grid_width`/`grid_height` always
> 40, palette-as-objects, reserved `cell_overrides`). That draft was never
> implemented in code. Prompt 02 implements the schema below instead, which
> is deliberately simpler and, critically, **does not assume any fixed board
> size**. This document now describes the format actually implemented by
> `scripts/data/level_data.gd` and `scripts/data/level_loader.gd`, not an
> aspirational one. See `docs/05_TECH_DECISIONS.md` ADR-008.

## Requirements it supports

- **Variable-size** logical grid: `width` and `height` are level-defined
  integers, each `> 0`. Cell count is always `width * height` — derived, not
  a stored/authoritative field. Structural validity (this document) is
  separate from *production* legality — see "Structural vs. production
  validation" below and ADR-010 in `docs/05_TECH_DECISIONS.md`.
- Currently exercised sizes span the full official production range —
  40×40 (1,600 cells) and 50×50 (2,500 cells) are two example sizes, not the
  only ones; the engine is exercised up to the current production maximum
  of 59×59 (3,481 cells) — plus small non-production sizes (e.g. 3×2) in
  tests to prove the format is genuinely generic.
- A palette of colors referenced by compact numeric id (array index) — not
  repeated color strings per cell.
- Per-cell color assignment via palette id.
- Level metadata: `id`, `name`, `difficulty`.
- Explicit format `version` for forward compatibility.

Per-cell *runtime* state (dirty/clean) is intentionally **not** part of level
data — it belongs to `BoardState`, which is runtime-only and derived fresh
from `LevelData` each time a board is constructed. See "LevelData vs.
BoardState" in `docs/02_TECH_ARCHITECTURE.md`.

## Format (Version 1, as implemented)

```jsonc
{
  "version": 1,
  "id": "test_40",
  "name": "40x40 Test",
  "difficulty": "TEST",
  "width": 40,
  "height": 40,

  // Palette: array of hex color strings. Palette id == array index.
  "palette": ["#00000000", "#E5484D", "#3B82F6", "#22C55E"],

  // Flat array, length MUST equal width * height, row-major:
  // index = y * width + x. Each value is a palette id (0-based index
  // into "palette").
  "cells": [0, 0, 1, 1, 2, 3, 0, 0 /* ... exactly width*height entries ... */]
}
```

### Field rules

- `version` — required, integer. Only `1` is currently supported. An
  unsupported/missing version is a hard validation failure.
- `id` — required, non-empty string, unique per level file.
- `name` — required, non-empty string (display label).
- `difficulty` — required, non-empty string. **Structural validation**
  (`LevelValidator`) does not constrain its value at all — any non-empty
  string passes. **Production validation** (`ProductionLevelValidator`,
  Prompt 03) does: it must be one of `EASY`, `MEDIUM`, `HARD`, `VERY_HARD`
  (each with an official width/height band — see
  `docs/01_GAMEPLAY_SPEC.md` and ADR-010) or the special value `TEST`, which
  means "development/engine fixture" and is explicitly *rejected* by
  production validation, never treated as any production difficulty. A
  `VERY_HARD` level is not required to be exactly 50×50 — any width/height
  in 50..59 is valid, up to the current maximum 59×59.
- `width`, `height` — required, integers `> 0`. No relationship between them
  is assumed or required (a level is not required to be square).
- `palette` — required, non-empty array of color strings. Palette ids are
  implicit (array index), not separately declared. `palette[0]` is not
  reserved/special by convention here; any cell may reference any valid id.
- `cells` — required array of integers. **Must** have exactly
  `width * height` entries. Every entry must be a valid index into
  `palette` (`0 <= id < palette.size()`).

### Validation error format

Validation failures are reported as specific, actionable messages, e.g.:

```text
Level test_50: expected 2500 cell entries (width=50 * height=50), found 2499
Level test: palette id 4 at cell 17 exceeds palette size 4
Level test: unsupported version 2 (expected 1)
Level test: width must be > 0, got 0
```

Malformed/invalid level data never crashes the loader — it returns a result
that clearly distinguishes success from a list of specific validation
errors. See `scripts/data/level_validator.gd`.

## Structural vs. production validation (Prompt 03)

Two separate, deliberately non-overlapping questions:

- **`LevelValidator`** — "is this Level Data V1 internally valid?" Generic,
  dimension-agnostic, never difficulty-aware. The 3×2 fixture passes this
  just as validly as a 59×59 level. This is what the error examples above
  come from.
- **`ProductionLevelValidator`** (new in Prompt 03,
  `scripts/data/production_level_validator.gd`) — "is this
  *structurally-valid* level legal as a real production SCRUBBOTS level?"
  Only this validator knows about difficulty bands
  (`scripts/data/difficulty_rules.gd`, the single source of truth for the
  official ranges). It rejects `TEST` outright, rejects unknown difficulty
  strings, and rejects width/height combinations outside the declared
  difficulty's band, e.g.:

  ```text
  Level easy_bad_01: difficulty EASY requires width and height in range
  20..29; received width=20 height=30.
  ```

A level must pass `LevelValidator` before `ProductionLevelValidator` is even
meaningful to run against it — the production check assumes structurally
valid input (a valid `LevelData`), not raw JSON.

## Minimal example (format proof, not a real level)

```jsonc
{
  "version": 1,
  "id": "example_2x2",
  "name": "Format Example",
  "difficulty": "TEST",
  "width": 2,
  "height": 2,
  "palette": ["#00000000", "#E5484D"],
  "cells": [1, 0, 0, 1]
}
```

## Fixtures (dev/test only — not production art)

Located at `data/levels/` (see `docs/06_TEST_STRATEGY.md`). **All current
fixtures use `"difficulty": "TEST"`**, which is the authoritative signal
that they are development fixtures, not production content — the `test_`
filename prefix is a human naming convention only, not what the engine
checks. `ProductionLevelValidator` rejects every one of them as production
content by design (see above).

- `test_3x2.json` — 3×2 (6 cells), tiny generic-size/non-square fixture used
  by automated tests. Proves the engine is genuinely dimension-generic, not
  secretly hard-coded to any "standard" size.
- `test_40x40.json` — 40×40 (1,600 cells), simple quadrant pattern.
- `test_50x50.json` — 50×50 (2,500 cells), simple striped pattern.
  (Corrected in Prompt 03: previously mislabeled `"difficulty":
  "VERY_HARD"`, which would have made it silently pass production
  validation despite being a synthetic engine-proof pattern, not real art.)
- `test_59x59.json` — 59×59 (3,481 cells, current production maximum),
  checkerboard pattern. New in Prompt 03, to prove the full
  JSON-load → `LevelData` → `BoardState` → performance pipeline at the real
  maximum, not just via in-memory test objects.

## Importer (M09-C001)

`scripts/tools/level_importer.gd` converts a source PNG into Level Data V1
JSON deterministically:

- **Exact-pixel contract**: one source RGBA pixel = one logical cell. No
  resize, resample, interpolation, crop, pad, or forced dimensions.
- **Deterministic palette**: first-seen color during canonical row-major scan
  (`y=0..h-1, x=0..w-1`). Color representation: `#RRGGBBAA` uppercase hex
  (preserves alpha exactly, accepted by existing palette parsing).
- **Canonical cell order**: `index = y * width + x` (matches
  BoardState/LevelData).
- **Difficulty**: uses `DifficultyRules` as authority. TEST imports allow
  arbitrary positive dimensions. Production imports validate dimensions
  against the declared difficulty band. `auto_difficulty()` returns the
  unique matching production band or empty string if ambiguous.
- **Metadata sidecar**: separate JSON file recording importer version, source
  path, dimensions, palette count, difficulty, output level ID — never
  mutates Level Data V1.
- **Reconstruction**: `reconstruct_image()` rebuilds RGBA8 `Image` from
  Level Data palette+cells alone (never touches the source image). Pixel-
  perfect raw-byte match verified at 3×2, 20×27, and 59×59.
- **No meaningless diffs**: identical output content → UNCHANGED (no file
  write). Overwrite safety: collision rejected unless `overwrite=true`.
- **PNG-only gate**: only `.png` source files accepted (case-insensitive).
  Valid non-PNG images (JPEG, BMP, etc.) are rejected with an actionable
  "unsupported source format" error before any import processing. Corrupt
  `.png` files fail separately as unreadable input.
- **Source immutability**: the source PNG is never a valid write destination.
  Path aliasing (output/preview/metadata pointing at the source) is rejected
  even when `overwrite=true`. All destination paths must be pairwise distinct.
  Path comparison uses one canonical filesystem identity per path: `res://`/
  `user://` resolution, bare relative paths resolved against `res://` (the
  actual base `Image.load()`/`FileAccess.open()` use for unprefixed CLI
  paths — not the OS process working directory), `.`/`..` segment
  simplification (`String.simplify_path()`), backslash normalization, and
  case-insensitive comparison on Windows. Symbolic-link identity is out of
  scope (lexical normalization only).
- **Multi-artifact preflight**: all requested destinations (Level JSON,
  preview PNG, metadata sidecar) are checked for overwrite collisions
  *before* any file is written. A collision on preview or metadata does not
  leave a partial Level JSON behind.
- **Reconstruction safety**: `reconstruct_image()` validates all
  preconditions (null level, zero/negative dimensions, empty palette, invalid
  palette hex strings, cell count mismatch, out-of-range palette IDs) and
  returns `null` cleanly — no runtime array-indexing errors on malformed data.

CLI entrypoint: `tools/import_level.gd` (headless Godot script).
Test fixture generator: `tools/generate_test_fixtures.gd`.

Batch import (`SB-M09-018..020`) deferred to M09-C002.

## Explicitly deferred

- Per-cell runtime-state overrides / special cells (locked cells, bonus
  cells, obstacles) — no reserved field exists for this in Version 1; adding
  one is a Version 2 decision if/when the feature is designed.
- Final on-disk format alternatives (Godot `.tres` Resource, binary) — JSON
  is sufficient for now and is what M2 implements.
- Level pack / chapter grouping metadata.
- Compression for shipped level data, if ever needed.
- An explicit initial per-cell state array (all cells currently start
  `DIRTY` unconditionally when a `BoardState` is built from `LevelData`).

Do not build large production levels from this spec yet — Prompt 02's
fixtures exist to validate the engine, not to ship content.
