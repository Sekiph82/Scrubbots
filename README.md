# SCRUBBOTS

Mobile puzzle game: dispatch tiny cleaning robots ("Scrubbots") from a
limited set of color slots to progressively clear away a visible pixel-art
image. Cells start ACTIVE (their source palette color); a cleaned cell
becomes CLEARED (transparent), exposing the gameplay background through the
hole. No grime layer, no hidden artwork — see `docs/05_TECH_DECISIONS.md`
ADR-019.

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
  loads and that board fixtures load correctly.
- Renderer ACTIVE/CLEARED comparison tool (dev-only, not gameplay): open/run
  `scenes/debug/board_renderer_debug.tscn` directly. Dropdowns switch board
  size (every official difficulty band boundary plus rectangular examples)
  and ACTIVE/CLEARED pattern (All ACTIVE, All CLEARED, Half, Checker) — no
  code changes needed. A visible debug background sits behind the board so
  transparent CLEARED cells are obvious.
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

**M1 + M2 + M3 (partial) — Variable-Size Board Engine, Level Data Core,
official difficulty bands, and BoardRenderer** (see `tasks.md` and
`docs/04_ROADMAP.md`). Board dimensions are level-defined (not a fixed
40×40) — see `docs/05_TECH_DECISIONS.md` ADR-008. Production content is
difficulty-banded: Easy 20–29, Medium 30–39, Hard 40–49, Very Hard 50–59
(max 59×59 = 3,481 cells) — see ADR-010. The board now renders (single
`Image`/`ImageTexture`, no per-cell Nodes — ADR-011) with the owner-locked
ACTIVE/CLEARED model (ADR-019): ACTIVE cells draw their source palette color,
CLEARED cells draw fully transparent. Owner manual QA of the transparent model
is still pending (tasks.md SB-M10-005..011). No slots or Scrubbot logic yet.

## Status

Godot **4.7.1-stable** (official, standard build) installed via winget
(`GodotEngine.GodotEngine`) and verified with `godot --version`. Level
data, BoardState, production difficulty validation
(`DifficultyRules`/`ProductionLevelValidator`), `BoardRenderer` (with
`PaletteColors`, ACTIVE/CLEARED model) and the `ColorCandidateIndex`
(`scripts/gameplay/targeting/`) are all implemented and covered by an
automated headless test suite (`tests/run_tests.gd`, all passing), including
renderer ACTIVE-source-color / CLEARED-transparency tests at every official
band boundary and the 59×59 maximum.

---

<p align="center">
  <a href="https://www.akilta.com/" title="Developed by Akilta">
    <img src="assets/brand/akilta-wordmark.svg" alt="Akilta" height="24" style="vertical-align: middle;" />
    <br />
    <sub>Developed by Akilta</sub>
  </a>
</p>


## Sidecar projects

The repository also contains two intentionally separate development projects:

- \`level_factory/\` — **SCRUBBOTS Level Factory**, an independently openable
  Godot 4.7.1 project for offline deterministic generation, solver/difficulty
  intelligence, human review and batch QA.
- \`content_pipeline/\` — **SCRUBBOTS Content Pipeline**, an offline
  publisher/control plane for \`.scrubpack\`, manifest, staging, production,
  rollback, disable and scheduled remote level delivery.

They are not gameplay modules. The root mobile game consumes only documented
declarative data contracts. See \`tasks.md\`,
\`level_factory/README.md\`, and \`content_pipeline/README.md\`.
