# Changelog

## Unreleased

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
