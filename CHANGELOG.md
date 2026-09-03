# Changelog

## Unreleased

### Added — Batch Import, Batch Validation, Duplicate-ID Protection (M09-C002)

- New `LevelBatchImporter` (`scripts/tools/level_batch_importer.gd`):
  manifest-driven batch layer reusing the M09-C001-audited `LevelImporter`
  unchanged for every per-item concern. Adds only manifest parsing,
  whole-batch preflight-before-any-write ordering, cross-item path-alias
  detection, and catalog duplicate-ID scanning (`SB-M09-018..020`).
- `LevelImporter.ImportRequest` gained an additive `dry_run` field
  (default `false`, zero regression risk) so the batch layer's preflight
  pass reuses the exact single-item validation logic without a second
  parallel implementation. `ImportResult` gained matching `*_would_write`
  fields.
- Deterministic JSON manifest schema (`{"items": [...]}`, same fields as a
  single import request); item order is preserved as batch processing and
  report order.
- Prepare/validate-then-commit architecture: every item and every batch-only
  check (duplicate IDs, cross-item destination/source aliasing, catalog
  scan) is preflighted via `dry_run=true` before any commit pass runs;
  validation-only mode never reaches a physical write; commit mode only
  writes if the whole batch preflighted clean, so a failing later item
  cannot leave an earlier item's artifacts committed.
- Duplicate-ID protection: rejects duplicate IDs within one manifest,
  rejects a requested ID that already belongs to a different existing
  catalog file (independent of `overwrite`), allows re-importing the same
  logical level at its own canonical catalog path, and reports (rather than
  silently ignores) existing catalog files that already declare a duplicate
  ID or are malformed/structurally invalid.
- New CLI entrypoint (`tools/import_level_batch.gd`): `--manifest`,
  `--catalog`, optional `--commit`; prints a deterministic JSON batch report
  plus a one-line summary; non-zero exit on any batch failure.
- Documented non-transactional limitation: no filesystem rollback across a
  commit pass; a rare OS-level write failure partway through leaves
  already-written earlier items written.
- Extended `tests/run_tests.gd` from 332 to **394 checks**: 62 new batch
  checks covering the happy path (3-item batch incl. 20×27 and 59×59,
  validation-only writes nothing, commit writes, unchanged rerun,
  reconstruction equality), duplicate-ID safety (within-batch, against
  catalog, existing catalog duplicates, same-entry re-import, overwrite
  cannot steal an ID), cross-item path safety (equivalent-path destination
  alias, preview/output collision, source-aliases-another-item's-destination,
  failing-later-item preflight), and invalid input/catalog (malformed/empty
  manifest, missing field, valid non-PNG, corrupt PNG, malformed catalog
  JSON, structurally invalid catalog entry).

### Fixed — Filesystem Identity Normalization (M09-C001 V03 Correction)

- Closed ChatGPT independent audit V02 finding F-M09-005: `_canonical_path()`
  compared cosmetically-normalized strings only, so a `.`/`..` dot-segment or
  a relative-vs-absolute equivalent of the same physical file could bypass
  the source-immutability/cross-artifact alias preflight (`AL-013`).
- `_canonical_path()` now resolves bare relative paths against `res://` (the
  project root — empirically confirmed as the actual resolution base used by
  `Image.load()`/`FileAccess.open()` for unprefixed CLI paths, not the OS
  process working directory) and applies `String.simplify_path()` to collapse
  `.`/`..` segments before every alias comparison. Symbolic-link identity
  remains explicitly out of scope (lexical normalization only, no `realpath`).
- Extended `tests/run_tests.gd` from 320 to **332 checks**: 12 new targeted
  equivalent-path tests (`./` source alias, `subdir/../` source alias,
  absolute-vs-`user://` source alias, destination-to-destination dot-segment
  alias, `overwrite=true` on an equivalent source alias still rejected, and a
  genuinely distinct dot-segment path still succeeding).

### Fixed — Importer Safety Hardening (M09-C001 V02 Correction)

- Closed all four ChatGPT independent audit V01 findings (F-M09-001..004):
  path aliasing/source immutability, multi-artifact overwrite preflight,
  PNG-only format gate, reconstruction safety against malformed data.
- Applied audit learnings AL-009..012: validation traceability, canonicalized
  path identity, negative-test specificity, multi-artifact overwrite safety.
- Extended `tests/run_tests.gd` from 286 to **320 checks**: 34 new safety
  checks covering 7 path-alias cases (with source byte preservation), 4
  preview/metadata overwrite safety, 3 PNG-only format gate (valid JPEG
  rejected, corrupt .png rejected, .PNG accepted), 5 reconstruction safety
  (short cells, bad palette ID, invalid hex, zero dimensions, null level).
- Updated `docs/03_LEVEL_DATA_SPEC.md` and `docs/06_TEST_STRATEGY.md` with
  safety contract clarifications and actual test coverage.

### Added — Pixel Art to Level Data Importer Core (M09-C001)

- New `LevelImporter` (`scripts/tools/level_importer.gd`): deterministic
  exact-pixel PNG → Level Data V1 converter. One source pixel = one cell,
  no resize/resample/interpolation. Palette ordered by first-seen during
  row-major scan. `#RRGGBBAA` hex preserves alpha exactly. Output passes
  structural and production validation. Reconstruction from Level Data
  alone is pixel-perfect (raw RGBA8 byte match verified at 3×2, 20×27,
  59×59). Deterministic rerun detects UNCHANGED, no meaningless file writes.
- New CLI entrypoint (`tools/import_level.gd`): headless Godot script for
  command-line imports with `--source`, `--id`, `--name`, `--difficulty`,
  `--output`, `--preview`, `--metadata`, `--overwrite` arguments.
- New test fixture generator (`tools/generate_test_fixtures.gd`) and
  reconstruction verifier (`tools/verify_reconstruction.gd`) for CLI-level
  validation.
- Optional JSON metadata sidecar records importer version, source path,
  dimensions, palette count, difficulty, output ID — never mutates Level
  Data V1.
- `auto_difficulty()` convenience: returns production difficulty when
  dimensions fall in exactly one band, empty string otherwise.
- Extended `tests/run_tests.gd` from 227 to **286 checks**: 59 new importer
  checks covering 3×2 non-square/transparency, 20×27 rectangular EASY,
  59×59 VERY_HARD maximum, semi-transparent alpha round-trip, deterministic
  rerun, overwrite safety, and 11 negative/error tests.
- Updated `docs/03_LEVEL_DATA_SPEC.md`, `docs/06_TEST_STRATEGY.md`,
  `CHANGELOG.md`, `tasks.md`. M09 tasks SB-M09-001..017 marked complete.
  SB-M09-018..020 (batch import) deferred to M09-C002.

### Added — Visual Reference Library infrastructure (M07-C001)

- Established visual reference directory structure per `tasks.md` §9.6:
  `assets/art/references/{gameplay,ui,scrubbots,pixel_method,
  external_inspiration}/`, `assets/art/characters/scrubbots/`,
  `assets/art/levels/source/{easy,medium,hard,very_hard}/`,
  `assets/art/levels/previews/`.
- Created human-readable visual reference guide
  (`assets/art/references/README.md`): visual authority hierarchy, source
  classes, approval/availability semantics, canonical naming, immutable
  source-original preservation policy, intake process, external-inspiration
  limits, M08 technical-audit boundary, M10 DIRTY/CLEAN design-gate
  continuity.
- Created machine-readable inventory (`assets/art/references/inventory.json`,
  `scrubbots-visual-inventory/v1`): every expected visual category recorded
  with stable ID, source class, approval/availability status, and null paths
  for missing assets. Akilta branding classified as `PROJECT_BRANDING`,
  explicitly not SCRUBBOTS gameplay art.
- All 7 expected owner-asset categories (Scrubbot characters, gameplay
  screens, five-slot references, level artwork, underwater theme, other
  themes, pixel-construction references) recorded as
  `AWAITING_OWNER_ASSET` — no fabricated or guessed assets.
- Colony Flow external inspiration recorded as text-only provenance entry
  with explicit non-copying policy.
- M07 infrastructure tasks SB-M07-001..007, 015..017 validated and marked
  complete. Asset-specific tasks SB-M07-008..014 remain open pending
  owner-supplied files.

### Added — GitHub coordination bus + H!veAI session tracking (META-C001)

- Added `coordination/README.md` as the durable ChatGPT↔Claude communication protocol while keeping `tasks.md` as the sole canonical task ledger.
- Added `coordination/SESSION_INDEX.md` to index stable coordination cycles such as `M07-C001` without duplicating task checkboxes.
- Added versioned templates for ChatGPT implementation prompts and audits plus an append-only Claude implementation log template under `coordination/templates/`.
- Added the first process-only coordination record under `coordination/sessions/META-C001/`, capturing the repository audit and setup instruction that established this system.
- Preserved H!veAI `single-dashboard-watch`: H!veAI continues to watch only `.hiveai/PROJECT_DASHBOARD.md`, while ChatGPT/Claude must read the versioned coordination sources and materialize a Latest Session Summary into the dashboard after every material session.
- Extended `CLAUDE.md` so every material Claude session reads the active coordination cycle, appends GitHub implementation evidence, keeps the existing local Desktop phase log, updates the session index/dashboard, and hands implementation back as `AWAITING_AUDIT` for ChatGPT review.
- ChatGPT prompt/audit versions are immutable evidence after publication; Claude implementation logs are append-only within a cycle. Audit corrections stay in the same cycle through a new prompt version rather than creating duplicate task truth.

### Added — BoardRenderer + DIRTY/CLEAN visual prototype (Prompt 04)

- New `BoardRenderer` (`scripts/gameplay/board/board_renderer.gd`, extends
  `TextureRect`): draws any `BoardState` as one `Image`/`ImageTexture` (one
  texel per logical cell, nearest-neighbor filtered) — exactly one Node
  regardless of board size, verified at every official difficulty band
  boundary and at the 59×59/3,481-cell maximum. See ADR-011.
- New `PaletteColors`/`PaletteParseResult` (`scripts/data/`) — the single,
  validated hex-string → `Color` conversion path.
- New `DirtyCleanPresets` (`scripts/gameplay/board/`) — centralized DIRTY
  visual transform (HSV saturation *and* value reduction, never saturation
  alone) with three named prototype presets (A/B/C). CLEAN always displays
  the unmodified source palette color. **None of the three presets is
  approved as final** — this is an explicit open design gate (`tasks.md`
  M10), not resolved by this phase.
- New dev-only comparison tool
  (`scenes/debug/board_renderer_debug.tscn` +
  `scripts/debug/board_renderer_debug.gd`): dropdowns to switch board size
  (every band boundary + rectangular examples), DIRTY/CLEAN pattern, and
  preset A/B/C at native gameplay scale, without code changes. Not
  production UI.
- New `BoardDebugFixtures` (`scripts/debug/`) — deterministic multi-hue
  in-memory level/board/state-pattern generator shared by the debug tool
  and tests.
- Extended `tests/run_tests.gd` from 131 to **227 checks**: palette
  parsing, DIRTY/CLEAN transform contract, renderer geometry across every
  band boundary + rectangular boards, renderer pixel output (including a
  constant-node-count assertion at every size), and renderer performance
  sanity at 40×40/50×50/59×59/53×59. Along the way, fixed a genuinely
  brittle test (exact-float pixel comparison broke on expected 8-bit
  `Image` quantization) — see `docs/06_TEST_STRATEGY.md` and the Prompt 04
  phase log for the full failure/fix record.
- Updated `CLAUDE.md`, `tasks.md`, and `docs/01`, `02`, `04`, `05`, `06` to
  describe the renderer architecture and the new locked DIRTY/CLEAN
  readability requirement.

### Added — Official difficulty bands + production/test validation (Prompt 03)

- Refined the Prompt 02 board-size framing ("40×40 standard / 50×50
  required for Very Hard") into the actual official production rules:
  Easy 20–29×20–29, Medium 30–39×30–39, Hard 40–49×40–49,
  Very Hard 50–59×50–59, current maximum 59×59 = 3,481 cells. Rectangular
  boards are explicitly valid (width/height checked independently). See
  `docs/05_TECH_DECISIONS.md` ADR-010.
- New `DifficultyRules` (`scripts/data/difficulty_rules.gd`) — single
  source of truth for the band table and the `TEST` non-production
  identifier.
- New `ProductionLevelValidator` + `ProductionValidationResult`
  (`scripts/data/`) — a validator deliberately separate from the existing
  generic `LevelValidator`: answers "is this legal *production* content?"
  without making the underlying board engine difficulty-aware. The 3×2
  engine-proof fixture keeps working exactly as before and is explicitly
  rejected as production content (it's `TEST`), demonstrating the
  structural-vs-production split end to end.
- Corrected a pre-existing mislabeling: `data/levels/test_50x50.json` had
  claimed `"difficulty": "VERY_HARD"` despite being a synthetic
  engine-proof fixture; changed to `"TEST"` so it can't silently pass
  production validation.
- New fixture `data/levels/test_59x59.json` (3,481 cells, checkerboard,
  `TEST`) — proves the full JSON-load → LevelData → BoardState →
  performance pipeline at the real current maximum.
- Extended `tests/run_tests.gd` from 73 to **131 checks**: full band matrix
  (min/max/rectangular per difficulty), upper- and lower-boundary rejection
  per difficulty, unknown-difficulty rejection, TEST-vs-production
  distinction, 59×59 BoardState/coordinate/mutation tests, and a second
  performance-sanity benchmark at 59×59 (kept alongside, not replacing, the
  existing 50×50 one).
- Updated `CLAUDE.md`, `tasks.md`, and all of `docs/00`–`06` to describe the
  official bands instead of the earlier "standard/required size" framing
  (40×40 and 50×50 remain valid *examples*, not the only sizes).

### Fixed — Architecture correction (Prompt 02)

- Corrected a Prompt 01 documentation error that locked the board to a fixed
  40×40 (1,600-cell) size. The engine is variable-size: board dimensions
  come from level data (`width`/`height`), cell count is always derived as
  `width * height`, and 50×50 (2,500 cells) is required and supported for
  Very Hard content. See `docs/05_TECH_DECISIONS.md` ADR-008. Updated
  `CLAUDE.md`, `README.md`, and every `docs/0X_*.md` file that had
  referenced the fixed size.

### Added — Variable-size board engine + level data core (M1 + M2)

- Installed Godot **4.7.1-stable** (official, standard build) via
  `winget install --id GodotEngine.GodotEngine --exact` — no usable Godot
  was present on this machine at the end of Prompt 01.
- `LevelData`, `LevelLoader`, `LevelValidator`, `LevelValidationResult`
  (`scripts/data/`) — Level Data Spec Version 1 JSON loading with specific,
  actionable validation errors (see `docs/03_LEVEL_DATA_SPEC.md`).
- `BoardState` (`scripts/gameplay/board/board_state.gd`) — data-oriented
  runtime cell state (flat `PackedInt32Array`/`PackedByteArray`), generic
  over board size, with centralized `index = y * width + x` coordinate
  conversion.
- Three deterministic fixture levels in `data/levels/`: `test_40x40.json`
  (1,600 cells, quadrant pattern), `test_50x50.json` (2,500 cells, striped
  pattern — proves the engine is not secretly 40×40), `test_3x2.json`
  (6 cells, non-square, proves generic sizing).
- `tests/run_tests.gd` — headless GDScript test suite (73 checks): fixture
  loading, index round-trips (incl. 40×40/50×50/3×2 boundary cases), invalid
  coordinate/index rejection, level validation failure cases, BoardState
  mutation, cross-instance independence, and a 50×50 performance sanity
  benchmark (timings printed, no hard threshold).
- Extended the bootstrap scene (`scenes/app/main.tscn` /
  `scripts/app/main.gd`) to load both size fixtures and display their cell
  counts as a live smoke test — still no board rendering.
- New permanent workflow rule (`CLAUDE.md` rule 26): every future numbered
  SCRUBBOTS prompt ends with a Desktop handoff log
  (`C:\Users\sekip\Desktop\SCRUBBOTS_PROMPT_XX_LOG.md`), never committed to
  this repository.
- ADR-009 (`docs/05_TECH_DECISIONS.md`): cross-script references in
  `scripts/data/` and `scripts/gameplay/board/` use explicit `preload()`
  rather than bare `class_name`, so headless runs work without a
  pre-existing editor-built global script class cache.

### Added — Project foundation (M0)

- Connected local project directory to `origin/main` at
  `https://github.com/Sekiph82/Scrubbots.git` (cloned existing remote
  history rather than re-initializing).
- Godot 4.7 project shell (`project.godot`), portrait mobile baseline
  (1080×1920, `canvas_items` stretch, `keep` aspect).
- Full directory structure for assets, data, scenes, scripts, docs, tests,
  tools per the agreed module layout.
- `CLAUDE.md` — persistent operating manual for future AI agent sessions.
- Source-of-truth documentation set under `docs/`: project brief, gameplay
  spec (including the locked win-streak reward mapping), tech architecture,
  level data spec (v1 proposal), roadmap, tech decisions (ADR), test
  strategy.
- Minimal bootstrap scene (`scenes/app/main.tscn` + `scripts/app/main.gd`)
  displaying project/version confirmation only — no gameplay.
- `.gitignore` for Godot-generated/cache content.
- `tools/verify_project.ps1` and `tools/run_headless.ps1` PowerShell helpers.

No gameplay systems (board, level loading, slots, Scrubbot dispatch,
targeting, routing) are implemented yet — out of scope for this milestone.
