# 03 — Level Data Specification (Version 1 proposal)

This is a first proposal, expected to evolve. It is intentionally simple:
enough structure to support the locked rules without overbuilding.

## Requirements it must support

- 40 × 40 logical grid, exactly 1,600 cells.
- A palette of colors referenced by compact numeric id (not repeated color
  strings per cell).
- Per-cell color assignment.
- Per-cell initial state (currently: cleaned or not — all cells start
  uncleaned).
- Level metadata (id, name/label, grid size — kept explicit even though
  currently always 40×40, in case of future variation).
- Difficulty metadata (a simple numeric/string field for now).
- Room for future optional special-cell data without breaking the base
  format (forward-compatible, not fully designed now).

## Proposed format (Version 1)

Plain JSON (or a Godot `Resource` wrapping equivalent fields — implementation
detail for the Level Loader milestone, M2). Field shape:

```jsonc
{
  "format_version": 1,
  "level_id": "sample_001",
  "display_name": "Sample Level",
  "grid_width": 40,
  "grid_height": 40,
  "difficulty": 1,

  "palette": [
    { "id": 0, "color": "#00000000" },   // 0 reserved: empty/no-color
    { "id": 1, "color": "#E5484D" },
    { "id": 2, "color": "#3B82F6" },
    { "id": 3, "color": "#22C55E" }
  ],

  // Flat array, length == grid_width * grid_height, row-major
  // (index = y * grid_width + x). Each value is a palette id.
  "cells": [0, 0, 1, 1, 2, 3, 0, 0 /* ... 1592 more ... */],

  // Reserved for future per-cell overrides (special cells, locks, etc.).
  // Empty in Version 1. Keyed by cell index as a string.
  "cell_overrides": {}
}
```

### Notes

- `cells` is a flat, row-major array of palette ids — this is the
  "compact numeric id instead of repeating color strings 1,600 times"
  requirement. 1,600 small integers, not 1,600 color strings.
- `palette` maps a small id space to actual colors once per level (or could
  later be shared across levels via `data/palettes/`; not decided yet).
- `cell_overrides` exists so a future "special cell" feature (locked cell,
  bonus cell, obstacle, etc.) does not require a format break — it is
  reserved and unused in Version 1.
- `grid_width` / `grid_height` are explicit fields rather than assuming
  40×40 everywhere, in case a future level intentionally deviates. Current
  levels must set both to 40.
- This document does not finalize slot-to-color mapping at the level level;
  that is gameplay-runtime concern (Slot System), not level data, unless a
  future need proves otherwise.

## Minimal example (not a real level)

A tiny 2×2 illustrative sample (not a real 40×40 level, just format proof):

```jsonc
{
  "format_version": 1,
  "level_id": "example_2x2",
  "display_name": "Format Example",
  "grid_width": 2,
  "grid_height": 2,
  "difficulty": 0,
  "palette": [
    { "id": 0, "color": "#00000000" },
    { "id": 1, "color": "#E5484D" }
  ],
  "cells": [1, 0, 0, 1],
  "cell_overrides": {}
}
```

## Explicitly deferred

- Final on-disk format (raw JSON vs. Godot `.tres` Resource vs. custom binary)
  — a decision for M2 (Level Data Loading).
- Special-cell schema details.
- Level pack / chapter grouping metadata.
- Compression for shipped level data, if ever needed.

Do not build a full 1,600-cell production level from this spec yet — this
document exists to unblock the Level Loader milestone with a stable shape to
target, not to ship content.
