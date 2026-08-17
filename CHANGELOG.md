# Changelog

## Unreleased

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
