# SCRUBBOTS

SCRUBBOTS is a portrait-first mobile puzzle game built in Godot 4.7.x.
Players activate color/count batches from a FIFO supply, those batches occupy
five production slots, and tiny cleaning robots travel through the canonical
railroad/access system to clear matching ACTIVE pixel-art cells. Cleared cells
become transparent and reveal the gameplay background.

The repository root is the shipping-game project. Offline level/content
production is tracked separately; see **Sidecar / content tooling** below.

## Technology

- Godot Engine **4.7.2** (current development version)
- GDScript
- Git / GitHub
- Data-oriented board rendering with one `Image` / `ImageTexture`, not one
  Node per logical pixel

## Canonical project

- Local project: `C:\Users\sekip\Desktop\ScrubBots`
- Repository: `https://github.com/Sekiph82/Scrubbots`
- Primary branch: `main`
- Live project status: **`TASKS.md`**
- Operating rules for implementation agents: **`CLAUDE.md`**

Do not infer current milestone status from old coordination logs, archived
trackers, stale branches or historical screenshots. `TASKS.md` is the live
tracker.

## Opening and validating the project

1. Install Godot **4.7.2** (standard build).
2. Import `project.godot` in Godot.
3. For a project boot check:
   `godot --headless --path . --quit`
4. For the automated regression suite:
   `godot --headless --path . -s res://tests/run_tests.gd`

Helper scripts include `tools/run_headless.ps1` and
`tools/verify_project.ps1`.

## Repository structure

```text
assets/
  art/          immutable owner/reference/source art
  ui/           generated candidates + approved production UI art
  audio/        music / SFX
  fonts/        licensed production fonts
  brand/        project/company branding
data/           level data, palettes, configuration
scenes/         Godot scenes
scripts/        GDScript modules
docs/           canonical design / architecture / ADR documentation
tests/          headless regression and evidence tests
tools/          import / validation / helper tooling
coordination/   owner decisions, audit evidence and implementation sessions
```

Generated visual candidates and approved production assets are deliberately
separated:

```text
assets/ui/generated/   raw candidates
assets/ui/final/       owner-approved production assets
```

Owner originals and supplied references remain under
`assets/art/references/` and are never overwritten by generated derivatives.

## Documentation entry points

Read these before making architectural or UI changes:

- `CLAUDE.md` — implementation operating rules
- `TASKS.md` — canonical live milestone/task state
- `docs/00_PROJECT_BRIEF.md` — game/product brief
- `docs/01_GAMEPLAY_SPEC.md` — locked gameplay rules
- `docs/02_TECH_ARCHITECTURE.md` — module boundaries
- `docs/03_LEVEL_DATA_SPEC.md` — level-data contract
- `docs/04_ROADMAP.md` — dependency roadmap
- `docs/05_TECH_DECISIONS.md` — architecture decision record
- `docs/06_TEST_STRATEGY.md` — test strategy
- `docs/07_UI_ASSET_PIPELINE_DECISIONS.md` — UI/visual production decisions
- `docs/08_PIXEL_ART_PALETTE_RULES.md` — locked C01..C16 pixel-art palette
- `docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md` — Difficulty V1
- `docs/MASTER_UI_SYSTEM.md` — canonical responsive UI architecture
- `docs/HOME_UI_ASSET_PLAN.md` — Home visual-production plan
- `assets/ui/HOME_ASSET_MANIFEST.json` — machine-readable Home asset inventory
- `ASSET_GENERATION_MANIFEST.json` — provider/provenance generation queue

## Current development status

The exact live status is always the top block of `TASKS.md`.

As of 2026-09-18:

- M21 real-art vertical slice is closed.
- M22 Railroad V1 / production slot foundation is accepted.
- M23 Batch Supply Engine is closed.
- M24 Five-Slot Batch Engine is closed.
- **M25 Batch Target Claim Engine is the active milestone** and is currently in
  V02 hardening after independent audit.
- M26 Auto Dispatch Scheduler and M27 Solvability / Deadlock Engine follow.
- Production gameplay layout/touch begins at M28/M29.
- Home / Navigation remains milestone M42.

The Home visual work now has a complete preproduction inventory, but that
inventory does not close or skip M42. Visual preparation may proceed without
changing the canonical core-gameplay milestone order.

## Core locked gameplay / presentation rules

- Logical board size is level-defined and supports rectangular boards.
- Maximum current production workload remains 59×59 = 3,481 logical cells.
- Production logical artwork uses the locked **C01..C16** palette; a level
  normally uses 3..12 of those colors under Difficulty V1.
- ACTIVE cells render their canonical source color.
- CLEARED cells render alpha 0; BG01 Midnight Slate is the gameplay surface
  visible underneath and is not a logical palette color.
- Exactly five production batch slots are visible.
- A legal supply selection auto-places into the rightmost empty slot.
- Target selection, reservation/claim ownership and routing remain separate.
- Railroad V1 controls exterior travel. After a legal ingress, a Scrubbot may
  traverse OPEN/CLEARED board corridors orthogonally with 90-degree turns.
- No valid target, claim/reservation or route means no robot is dispatched.

## UI / visual asset policy

Production UI is built from responsive Godot Controls/Containers plus approved
illustrative assets. Full-screen AI mockups are art-direction references, not
interactive shipping UI.

For new illustrative UI/character assets:

- **Primary:** ChatGPT image generation
- **Fallback / alternate:** Magnific MCP
- Neither provider is a shipping/runtime dependency.
- Dynamic text, prices, counters, timers, progress and state stay live in Godot.
- Approved art is never silently regenerated or overwritten.

## Sidecar / content tooling

This repository still contains historical/local `level_factory/` and
`content_pipeline/` project folders, but the canonical live Level Factory +
Content Platform requirement tracker has moved to:

`https://github.com/Sekiph82/ScrubBots-Level-Factory`

The shipping mobile game consumes documented declarative content contracts.
Factory/publisher credentials and offline generation systems do not ship in the
app.

---

<p align="center">
  <a href="https://www.akilta.com/" title="Developed by Akilta">
    <img src="assets/brand/akilta-wordmark.svg" alt="Akilta" height="24" style="vertical-align: middle;" />
    <br />
    <sub>Developed by Akilta</sub>
  </a>
</p>
