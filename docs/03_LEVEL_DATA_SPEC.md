# 03 — Level Data Specification (Version 1 — implemented in Prompt 02)

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
  a stored/authoritative field.
- Currently exercised sizes: 40×40 (1,600 cells) and 50×50 (2,500 cells,
  required for Very Hard content), plus small sizes (e.g. 3×2) in tests to
  prove the format is genuinely generic.
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
- `difficulty` — required, non-empty string. No fixed enum is enforced yet;
  known labels in current use are `TEST`, `EASY`, `MEDIUM`, `HARD`,
  `VERY_HARD` (see `docs/01_GAMEPLAY_SPEC.md` — progression thresholds are
  still `[TO BE DESIGNED]`). A `VERY_HARD` level is not required to be
  exactly 50×50, but 50×50 must be supported for it.
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

## Fixtures shipped with Prompt 02

Located at `data/levels/` (dev/test fixtures, not production art — see
`docs/06_TEST_STRATEGY.md`):

- `test_40x40.json` — 40×40 (1,600 cells), simple quadrant pattern.
- `test_50x50.json` — 50×50 (2,500 cells), simple striped pattern. Exists
  specifically to prove the engine is not secretly hard-coded to 40×40.
- `test_3x2.json` — 3×2 (6 cells), tiny generic-size/non-square fixture used
  by automated tests.

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
