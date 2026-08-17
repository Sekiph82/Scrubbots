# SCRUBBOTS

Mobile puzzle game: dispatch tiny cleaning robots ("Scrubbots") from a
limited set of color slots to reveal pixel-art images hidden under grime.

## Technology

- Godot Engine **4.7**
- GDScript
- Git / GitHub

## Project location

Canonical local path: `C:\Users\sekip\Desktop\ScrubBots` (this directory).
Canonical repository: https://github.com/Sekiph82/Scrubbots

## Opening the project

1. Install Godot **4.7.1** (standard build) — e.g.
   `winget install --id GodotEngine.GodotEngine --exact`.
2. Open Godot, choose "Import", select `project.godot` in this directory.

## Running it

- From the editor: press Play (F5). It boots the scene at
  `scenes/app/main.tscn` — a bootstrap/debug screen confirming the project
  loads and (as of Prompt 02) that the two board-size fixtures load
  correctly.
- From the command line: `godot --headless --path . --quit` (project boot
  check) or `godot --headless --path . -s res://tests/run_tests.gd`
  (automated test suite). See `tools/run_headless.ps1` and
  `tools/verify_project.ps1`.

## Repository structure

```text
assets/     art, audio, fonts (source assets)
data/       level data, palettes, config (game data, not code)
scenes/     Godot scenes (.tscn)
scripts/    GDScript source, mirrors scenes/ + gameplay module split
docs/       source-of-truth design & architecture documentation
tests/      test scripts (headless-runnable, see docs/06_TEST_STRATEGY.md)
tools/      PowerShell helper scripts for validation
```

## Documentation entry points

Read `CLAUDE.md` and `tasks.md` first — the operating manual and the master
task checklist for anyone (human or AI) modifying this project. Then:

- `docs/00_PROJECT_BRIEF.md` — what the game is
- `docs/01_GAMEPLAY_SPEC.md` — locked gameplay rules vs. open design areas
- `docs/02_TECH_ARCHITECTURE.md` — module boundaries
- `docs/03_LEVEL_DATA_SPEC.md` — level data format (v1 proposal)
- `docs/04_ROADMAP.md` — milestone sequence
- `docs/05_TECH_DECISIONS.md` — architecture decision record
- `docs/06_TEST_STRATEGY.md` — test plan

## Current milestone

**M1 + M2 — Variable-Size Logical Board Engine + Level Data Core, with
official difficulty bands** (see `tasks.md` and `docs/04_ROADMAP.md`).
Board dimensions are level-defined (not a fixed 40×40) — see
`docs/05_TECH_DECISIONS.md` ADR-008. Production content is now
difficulty-banded: Easy 20–29, Medium 30–39, Hard 40–49, Very Hard 50–59
(max 59×59 = 3,481 cells) — see ADR-010. No rendering, slots, or Scrubbot
logic yet.

## Status

Godot **4.7.1-stable** (official, standard build) installed via winget
(`GodotEngine.GodotEngine`) and verified with `godot --version`. Level
data (`scripts/data/`) and BoardState (`scripts/gameplay/board/`) implemented,
plus a separate production difficulty/dimension validator
(`DifficultyRules` + `ProductionLevelValidator`), covered by an automated
headless test suite (`tests/run_tests.gd`, **131 checks, all passing**)
against 3×2, 40×40, 50×50, and 59×59 (current production maximum)
fixtures, plus the full 20..59 production band matrix.
