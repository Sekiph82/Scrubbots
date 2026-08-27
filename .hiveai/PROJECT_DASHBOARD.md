# SCRUBBOTS — H!veAI Project Dashboard

<!--
hiveaiDashboardSchema: hiveai-project-dashboard/v1
dashboardMode: source-map
trackingMode: single-dashboard-watch
refreshPolicy: project-agent-maintained; H!veAI watches only .hiveai/PROJECT_DASHBOARD.md
-->

## Project identity

| Field | Value |
| --- | --- |
| Project | SCRUBBOTS |
| Repository | `https://github.com/Sekiph82/Scrubbots` |
| Branch | `main` |
| Engine | Godot 4.7.1-stable (GDScript) |
| Platform target | Mobile (Android first, iOS later) |
| Attribution | Developed by Akilta |

## H!veAI live status

| Field | Value |
| --- | --- |
| Project status | ACTIVE |
| Health | HEALTHY |
| Current milestone | M07 — Visual Reference Library (next to start; M00–M06 complete) |
| Current task | NONE (between implementation prompts) |
| Current task ID | NONE |
| Current workflow state | WAITING — owner artwork needed to begin M07 |
| Progress | 6/55 milestones complete (M00–M06); 227/227 headless tests passing |
| Required actor | HUMAN |
| Next action | Owner supplies original SCRUBBOTS artwork files for M07 ingestion, and reviews DIRTY/CLEAN presets A/B/C via `scenes/debug/board_renderer_debug.tscn` to close M10 design gate |
| Waiting on | Owner-supplied artwork assets (all categories AWAITING OWNER ASSET) and DIRTY preset approval (M10 design gate) |
| Last meaningful update | 2026-08-18T00:12:34+03:00 |

## Current work

| ID | Item | Status | Owner/actor | Evidence/source |
| --- | --- | --- | --- | --- |
| M07 | Visual Reference Library | NOT_STARTED | HUMAN (owner supplies assets) | `tasks.md` M07 |
| M10 | DIRTY/CLEAN Visual Approval | DESIGN_GATE | HUMAN (owner picks preset) | `tasks.md` M10, `scenes/debug/board_renderer_debug.tscn` |
| M05 | Test Harness Maturity | PARTIAL | CLAUDE | `tasks.md` M05 (SB-M05-006..010 open) |

## Blockers and waiting

- **M07 blocked on owner artwork**: all visual reference categories are `AWAITING OWNER ASSET` — no original SCRUBBOTS artwork exists in the repository yet.
- **M10 design gate**: three DIRTY/CLEAN presets (A/B/C) are built and ready for comparison at native scale, but the owner has not yet chosen one. This must be resolved before real artwork is rendered in production (M09/M21).

## Milestone summary

| Milestone | Name | Status |
| --- | --- | --- |
| M00 | Foundation & Environment | COMPLETE |
| M01 | Variable-Size Level Data Core | COMPLETE |
| M02 | BoardState Core | COMPLETE |
| M03 | Official Difficulty Bands + 59×59 | COMPLETE |
| M04 | Expanded Board Fixtures & Test Matrix | COMPLETE |
| M05 | Test Harness Maturity | PARTIAL (5/10 items) |
| M06 | Board Renderer | COMPLETE |
| M07 | Visual Reference Library | NOT_STARTED |
| M08–M55 | Remaining milestones | NOT_STARTED |

## Quality and verification

- **Test suite**: `tests/run_tests.gd` — **227/227 checks PASS**, exit code 0.
- **Command**: `godot --headless --path . -s res://tests/run_tests.gd`
- **Coverage**: level data parsing, validation (valid + invalid), BoardState operations, coordinate round-trips, difficulty band enforcement (all 4 bands + boundary rejection), BoardRenderer geometry + pixel output at every band boundary + rectangular boards + 59×59 max, palette parsing, DIRTY/CLEAN transform contract, performance sanity benchmarks.
- **Last verified**: Phase M06 completion (commit `abd9ceb`).
- **No build pipeline yet** — Godot export templates not configured (M54).

## Recent meaningful activity

| Date | Event |
| --- | --- |
| 2026-08-18 | M06 complete: BoardRenderer (single Image/ImageTexture, zero per-cell Nodes), DirtyCleanPresets A/B/C, debug comparison tool, 227/227 tests — commit `abd9ceb` |
| 2026-08-17 | M03/M04 complete: DifficultyRules, ProductionLevelValidator, official bands enforced (Easy 20–29 → Very Hard 50–59, max 59×59=3,481), 131/131 tests — commit `89c7d43` |
| 2026-08-17 | Master task plan established — commit `03da4e8` |
| 2026-08-16 | M01/M02 complete: LevelData, LevelLoader, LevelValidator, BoardState, 73/73 tests — commit `5a4a2e6` |
| 2026-08-16 | M00 complete: project bootstrap, Godot 4.7.1, docs, directory structure — commit `58caeab` |

## Provenance

- Task authority: `tasks.md`
- Agent governance: `CLAUDE.md`
- Roadmap context: `docs/04_ROADMAP.md`
- Architecture: `docs/02_TECH_ARCHITECTURE.md`
- Technical decisions: `docs/05_TECH_DECISIONS.md`
- Gameplay spec: `docs/01_GAMEPLAY_SPEC.md`
- Test strategy: `docs/06_TEST_STRATEGY.md`
- Historical evidence: `CHANGELOG.md`

H!veAI actively watches only .hiveai/PROJECT_DASHBOARD.md for project-status changes; the sources above are internal project evidence/provenance and are not independent live-watch targets.
