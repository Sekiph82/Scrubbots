# SCRUBBOTS - H!veAI Project Dashboard

<!--
hiveaiDashboardSchema: hiveai-project-dashboard/v1
dashboardMode: source-map
trackingMode: single-dashboard-watch
refreshPolicy: project-agent-maintained; H!veAI watches only .hiveai/PROJECT_DASHBOARD.md
coordinationSchema: scrubbots-coordination/v1
-->

This file is the single H!veAI-facing materialized project status and latest-session summary surface. It is **not** a second task ledger. Task checkboxes and milestone truth remain canonical only in `tasks.md`.

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
| Current implementation frontier | M07 - Visual Reference Library / owner asset ingestion |
| Current task | M07-C001 - Visual Reference Library foundation + asset availability audit |
| Current task ID | `M07-C001` |
| Current workflow state | PLANNED - ChatGPT prompt issued; awaiting Claude implementation |
| Automated evidence | 227/227 headless checks PASS at Phase M06 completion (`abd9ceb`) |
| Open design gate | M10 DIRTY/CLEAN final preset selection (A/B/C prototypes exist) |
| Required actor | CLAUDE |
| Next project action | Claude safely syncs `origin/main`, reads `coordination/sessions/M07-C001/CHATGPT_PROMPT_V01.md`, establishes the visual reference library foundation, audits actual repository asset availability, and records implementation evidence. |
| Waiting on | Owner-approved artwork is still required to complete asset-specific M07 inventory tasks, but M07-C001 infrastructure/audit work can proceed now. |
| Canonical task truth | `tasks.md` |

## Latest session summary

| Field | Value |
| --- | --- |
| Timestamp | 2026-08-27T11:42:00+03:00 |
| Actor | CHATGPT |
| Cycle | `M07-C001` |
| Session type | Implementation prompt issuance |
| Cycle status | PLANNED |
| Milestone/task impact | M07 work authorized; no `tasks.md` checkbox changed by prompt issuance |
| Summary | Issued the first normal coordination-cycle implementation prompt for M07. Claude is instructed to build the visual reference library foundation, inspect only verified repository assets, define naming/metadata/approval/source-preservation rules, keep missing owner artwork explicitly awaiting asset, preserve the M10 DIRTY/CLEAN design gate, and maintain both the Desktop phase log and GitHub implementation log. |
| Primary evidence | `coordination/sessions/M07-C001/CHATGPT_PROMPT_V01.md` issued on `main` in `c20380f`; cycle registered in `coordination/SESSION_INDEX.md` |
| Next expected actor | CLAUDE |

## Current work

| ID | Item | Status | Owner/actor | Evidence/source |
| --- | --- | --- | --- | --- |
| M07-C001 | Visual Reference Library foundation + asset availability audit | PLANNED | CLAUDE | `coordination/sessions/M07-C001/CHATGPT_PROMPT_V01.md` |
| M07 | Visual Reference Library | NOT_STARTED / awaiting implementation evidence | CLAUDE + HUMAN for asset-specific tasks | `tasks.md` M07 |
| M10 | DIRTY/CLEAN Visual Approval | DESIGN_GATE | HUMAN (owner picks preset) | `tasks.md` M10, `scenes/debug/board_renderer_debug.tscn` |
| M05 | Test Harness Maturity | PARTIAL | CLAUDE | `tasks.md` M05 |
| META-C001 | GitHub coordination protocol | AUDITED_PASS | CHATGPT | PR #2, `coordination/SESSION_INDEX.md` |

## Blockers and waiting

- **M07 asset-specific tasks still depend on owner artwork**: original SCRUBBOTS visual assets are not yet verified inside the repository. M07-C001 may still complete its infrastructure and availability-audit objective without fabricating assets.
- **M10 design gate**: DIRTY/CLEAN presets A/B/C are implemented but final selection remains owner-controlled.

## Recent coordination cycles

| Cycle | Milestone | Status | Last actor | Summary | Evidence |
| --- | --- | --- | --- | --- | --- |
| `M07-C001` | M07 | PLANNED | CHATGPT | Issued visual reference library foundation and asset-availability audit prompt; awaiting Claude implementation. | `coordination/sessions/M07-C001/CHATGPT_PROMPT_V01.md`, `coordination/SESSION_INDEX.md` |
| `META-C001` | META | AUDITED_PASS | CHATGPT | Established GitHub prompt->implementation->audit communication and single-dashboard session synchronization. | PR #2 merged as `734ccfe`; `coordination/SESSION_INDEX.md` |

## Coordination source map

These files are versioned project evidence that ChatGPT/Claude must read and synchronize into this dashboard. H!veAI itself actively watches **only this dashboard file**.

| Purpose | Canonical source |
| --- | --- |
| Task ledger | `tasks.md` |
| Agent governance | `CLAUDE.md` |
| Coordination protocol | `coordination/README.md` |
| Coordination cycle index | `coordination/SESSION_INDEX.md` |
| ChatGPT implementation prompts | `coordination/sessions/**/CHATGPT_PROMPT_V*.md` |
| Claude implementation evidence | `coordination/sessions/**/CLAUDE_IMPLEMENTATION_LOG.md` |
| ChatGPT audits | `coordination/sessions/**/CHATGPT_AUDIT_V*.md` |
| Optional owner clarifications | `coordination/sessions/**/OWNER_NOTES.md` |
| Project execution history | `CHANGELOG.md` |
| Roadmap context | `docs/04_ROADMAP.md` and `tasks.md` |
| Architecture | `docs/02_TECH_ARCHITECTURE.md` |
| Technical decisions | `docs/05_TECH_DECISIONS.md` |
| Gameplay rules | `docs/01_GAMEPLAY_SPEC.md` |
| Test strategy | `docs/06_TEST_STRATEGY.md` |
| Build/test metadata | `project.godot`, `tests/`, `tools/` |

## Single-dashboard synchronization contract

H!veAI watches only `.hiveai/PROJECT_DASHBOARD.md`. Therefore the acting project agent is responsible for materializing relevant changes from the coordination sources above into this file after every **material** ChatGPT or Claude session.

Refresh at minimum:

1. `Latest session summary`: timestamp, actor, cycle, status, task impact, concise summary, primary evidence, next actor.
2. The matching row in `Recent coordination cycles`.
3. `H!veAI live status` / `Current work` only when project/task truth actually changed.
4. `coordination/SESSION_INDEX.md` in the same session.

A material session includes issuing/revising a Claude prompt, completing Claude implementation work, publishing a ChatGPT audit, changing a blocker/design decision, or materially changing repository/project status. Pure conversation with no project-state effect does not require a Git commit.

## Cycle model

Normal implementation loop:

`ChatGPT prompt -> Claude implementation/log -> ChatGPT audit -> PASS or revised prompt in the same cycle`

Current cycle artifacts:

- `coordination/sessions/M07-C001/CHATGPT_PROMPT_V01.md`
- `coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md` - to be created/appended by Claude
- `coordination/sessions/M07-C001/CHATGPT_AUDIT_V01.md` - to be created after Claude implementation review

If the audit requires corrections, keep the same cycle, add `CHATGPT_PROMPT_V02.md`, and let Claude append another session entry to the same implementation log.

## Milestone summary

| Milestone | Name | Status |
| --- | --- | --- |
| M00 | Foundation & Environment | COMPLETE |
| M01 | Variable-Size Level Data Core | COMPLETE |
| M02 | BoardState Core | COMPLETE |
| M03 | Official Difficulty Bands + 59x59 | COMPLETE |
| M04 | Expanded Board Fixtures & Test Matrix | COMPLETE |
| M05 | Test Harness Maturity | PARTIAL |
| M06 | Board Renderer | COMPLETE |
| M07 | Visual Reference Library | NOT_STARTED / M07-C001 prompt issued |
| M08-M55 | Remaining milestones | NOT_STARTED |

## Quality and verification

- **Test suite**: `tests/run_tests.gd` - **227/227 checks PASS**, exit code 0 at Phase M06 completion.
- **Command**: `godot --headless --path . -s res://tests/run_tests.gd`
- **Last verified code milestone**: Phase M06 (`abd9ceb`).
- Prompt issuance does not claim a fresh gameplay test rerun. Claude must run and record the actual regression result during M07-C001.

## Recent meaningful activity

| Date | Event |
| --- | --- |
| 2026-08-27 | M07-C001 issued: Visual Reference Library foundation + asset availability audit prompt - `coordination/sessions/M07-C001/CHATGPT_PROMPT_V01.md`. |
| 2026-08-27 | META-C001 merged: repository-native ChatGPT<->Claude coordination ledger and dashboard synchronization protocol - PR #2 / `734ccfe`. |
| 2026-08-27 | H!veAI single-dashboard tracking + Akilta attribution added on `main` (`d7a7019`). |
| 2026-08-18 | M06 complete: BoardRenderer, DirtyCleanPresets A/B/C, 227/227 tests - `abd9ceb`. |
| 2026-08-17 | M03/M04 complete: official difficulty ranges through 59x59 and 131/131 tests - `89c7d43`. |
| 2026-08-17 | Master task plan established - `03da4e8`. |

## Dashboard integrity rules

- H!veAI actively watches only this file. ChatGPT/Claude perform source synchronization.
- Never copy the full `tasks.md` checklist into this dashboard.
- Never let coordination-cycle status silently change a `tasks.md` checkbox.
- Never rewrite historical ChatGPT prompt/audit versions to make later work appear compliant.
- Never publish secrets or sensitive environment values.
- Keep detailed chronology in cycle files and the local Desktop phase log, not in this summary.
- Use repository commits/tests/files as evidence whenever available.
