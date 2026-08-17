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

1. Install Godot **4.7** (standard build).
2. Open Godot, choose "Import", select `project.godot` in this directory.

## Running it

- From the editor: press Play (F5). It boots the scene at
  `scenes/app/main.tscn`, a minimal bootstrap screen confirming the project
  loads correctly.
- From the command line (once a Godot 4.7 executable is available), see
  `tools/run_headless.ps1` and `tools/verify_project.ps1`.

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

Read `CLAUDE.md` first — it is the operating manual for anyone (human or AI)
modifying this project. Then:

- `docs/00_PROJECT_BRIEF.md` — what the game is
- `docs/01_GAMEPLAY_SPEC.md` — locked gameplay rules vs. open design areas
- `docs/02_TECH_ARCHITECTURE.md` — module boundaries
- `docs/03_LEVEL_DATA_SPEC.md` — level data format (v1 proposal)
- `docs/04_ROADMAP.md` — milestone sequence
- `docs/05_TECH_DECISIONS.md` — architecture decision record
- `docs/06_TEST_STRATEGY.md` — test plan

## Current milestone

**M0 — Project foundation** (see `docs/04_ROADMAP.md`). No gameplay is
implemented yet — this is the project shell, docs, and a bootstrap scene
only.

## Status

Foundation bootstrapped and connected to GitHub. Godot 4.7 executable was
not found on this machine at bootstrap time — see the report for the
in-session validation this implies and the next action needed to unblock
command-line validation.
