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
  scope (lexical normalization only). Internally this is two layered
  helpers: `_resolve_path()` produces a real, case-preserved path usable for
  actual `FileAccess`/`DirAccess` calls (used by M09-C002 batch destination-
  parent and catalog-root checks); `_canonical_path()` adds the Windows
  case-fold on top, strictly for identity *comparison* — its lowercased
  output is never fed back into a real filesystem call.
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

### Batch import, validation, and duplicate-ID protection (M09-C002)

`scripts/tools/level_batch_importer.gd` (`LevelBatchImporter`) adds a
manifest-driven batch layer over the single-item importer above. It reuses
`LevelImporter` unchanged for every per-item concern (PNG gate, exact-pixel
conversion, palette/cell semantics, difficulty legality, reconstruction,
path-alias detection, overwrite/unchanged preflight) — this layer adds only
what a single item cannot know on its own.

**Manifest schema** (deterministic JSON):

```json
{
  "items": [
    {
      "source": "path/to/source.png",
      "id": "level_id",
      "name": "Display Name",
      "difficulty": "TEST | EASY | MEDIUM | HARD | VERY_HARD",
      "output": "path/to/output.json",
      "preview": "path/to/preview.png",
      "metadata": "path/to/metadata.json",
      "overwrite": false
    }
  ]
}
```

`items` must be a non-empty array. `source`, `id`, `name`, `difficulty`, and
`output` are required per item; `preview`, `metadata`, and `overwrite` are
optional (same defaults as the single importer). Optional fields, when
present, must match their declared type — `preview`/`metadata` must be
strings, `overwrite` must be a boolean. A wrong JSON type (e.g.
`"overwrite": "yes"`) is an actionable item schema error, never a runtime
type fault (M09-C002 V02 correction, `F-M09B-005`). Item order is preserved
throughout — batch processing order and report order both follow manifest
order; no other ordering is used.

Relative item paths resolve exactly like the single importer's `res://`
project-root base (see the source-immutability entry above) — there is no
second, conflicting path-identity model. `LevelBatchImporter`, like
`FileAccess.open()`/`LevelImporter`, does **not** auto-create missing output
directories; callers (and this project's tests/CLI usage) must ensure
destination directories already exist. Unlike the single importer's own
preflight, the batch layer additionally *validates* every destination
parent directory before commit (see below) — it still never creates one.

**Prepare/validate-then-commit architecture:**

1. Every well-formed item is preflighted via
   `LevelImporter.run_import(dry_run=true)` — this alone runs every
   M09-C001 validation/safety check, including that item's own path
   aliasing. On top of that, batch-only checks run once per batch: manifest
   schema (required fields and optional field types), destination-parent-
   directory existence for every requested output/preview/metadata path,
   duplicate IDs within the manifest, duplicate/aliased destinations across
   items (a source in one item aliasing a destination in another included),
   catalog-root validity, and a single scan of `catalog_root` for
   malformed/duplicate entries and bidirectional ID/path ownership.
2. **Validation-only mode** stops after step 1. Every check still runs;
   nothing is ever written or created — no directories, no files — because
   `dry_run=true` never reaches a physical write call inside
   `LevelImporter.run_import()`, and every batch-only check (destination
   parent, catalog root) is a read-only existence check.
3. **Commit mode** performs step 1, and only if the *entire* batch
   preflights clean does it re-invoke `LevelImporter.run_import()` per item
   (in manifest order) with `dry_run=false` to write final artifacts. If any
   item or any batch-only check fails preflight, no item's final artifacts
   are committed — a failing later item prevents an earlier, individually
   valid item from being written. `BatchResult.committed` is `true` only
   once every requested commit write actually completed successfully; a
   rare post-preflight OS write failure on any item leaves it `false`
   instead of presenting a misleading blanket success flag.

**Destination-parent-directory preflight** (M09-C002 V02 correction,
`F-M09B-001`): a missing or non-directory parent for any requested
output/preview/metadata path is a *predictable* logical validation failure,
not a rare OS race — it is detected for every item before any item in the
batch is committed, exactly like every other preflight check. This check
never creates the missing directory in either mode.

**Destination-type preflight** (M09-C002 V03 correction, `F-M09B-006` /
`AL-017`): if any requested output/preview/metadata final destination path
resolves to an *existing directory*, the item is rejected with an actionable
error before any item in the batch writes. This is equally predictable as a
missing parent and is detected via the same `LevelImporter._resolve_path()`
resolver. `overwrite=true` cannot bypass this safety — overwrite semantics
apply only to regular files, never to replacing a directory with a file.
Validation-only mode performs this check read-only (no creation/removal).

**Catalog root validity** (M09-C002 V02 correction, `F-M09B-002`): a
missing, unopenable, or non-directory `catalog_root` fails the whole batch
with an actionable `catalog_root_error` (`BatchResult.catalog_root_valid ==
false`) — it is never silently treated as an empty, trustworthy catalog.

**Duplicate level-ID protection and catalog ownership** (`SB-M09-020`):

- Two manifest items declaring the same `id` are rejected before any write.
- The catalog directory is scanned once per batch run (flat, non-recursive,
  `*.json` files) through the existing `LevelLoader`/`LevelValidator`
  pipeline — filenames are never trusted as ID authority. The scan builds
  **both** ownership directions: declared ID → canonical catalog path(s),
  and canonical catalog path → declared ID/entry status (M09-C002 V02
  correction, `F-M09B-003`).
- Two existing catalog files declaring the same `id` are reported (both
  paths) as `catalog_duplicate_ids`. A malformed or structurally invalid
  existing catalog file is reported as `catalog_malformed` (path + specific
  errors) — a JSON-parse failure and a structurally-invalid-but-parseable
  Level Data file are reported distinctly. **Either kind of existing catalog
  corruption fails the whole batch's validation result** — not merely an
  informational report — whether or not the current batch touches the
  affected ID (M09-C002 V02 correction, `F-M09B-004`; corrupt catalog files
  are never deleted, rewritten, or auto-repaired).
- A requested `id` that already belongs to a *different* existing catalog
  file (by canonical path identity, not string equality) is rejected —
  `overwrite=true` does not authorize reassigning an existing level ID to a
  different file.
- A requested `output` that aliases an *existing* catalog file declaring a
  **different** `id` is rejected, even with `overwrite=true` — this is the
  reverse direction of the check above (a different ID cannot steal an
  existing catalog path). If the aliased existing file is itself malformed,
  the request is rejected too: ownership cannot be safely established, so
  the batch fails closed rather than allowing an overwrite of unknown state.
- A requested `id` at the *same* canonical catalog output path as its
  existing (valid) entry is treated as re-importing that same logical
  level, not a conflict — ordinary `LevelImporter` overwrite/unchanged rules
  then decide whether anything actually changes.
- TEST fixtures and production levels participate in the same ID-uniqueness
  space within whatever catalog root is explicitly being validated; TEST is
  never silently excluded by filename convention.

**Cross-item path safety:** every item's `source`/`output`/`preview`/
`metadata` path is canonicalized (same identity rules as the single
importer) and compared pairwise across the *entire* batch — not just within
one item — so two items can never write the same physical destination, and
one item's source can never be aliased as another item's write destination.

**Non-transactional limitation:** preflight validates against catalog state
observed at batch start, then the commit pass re-invokes the audited single
importer per item in manifest order. There is no filesystem
transaction/rollback. If preflight passes but a rare OS-level write failure
occurs partway through the commit pass (disk full, permissions changed
mid-run, etc.), items already written before that point remain written —
this is a real, documented limitation, not a claimed guarantee.

CLI entrypoint: `tools/import_level_batch.gd` — validation-only by default,
add `--commit` to write:

```
godot --headless --path . -s res://tools/import_level_batch.gd -- \
  --manifest <manifest.json> --catalog <catalog_dir> [--commit]
```

Prints a deterministic JSON report (`LevelBatchImporter.BatchResult.to_report()`)
plus a one-line summary; exit code is non-zero whenever the batch is not
fully OK.

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
