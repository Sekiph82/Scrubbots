---
hiveaiDashboardSchema: hiveai-project-dashboard/v1
projectKey: scrubbots
repository: Sekiph82/Scrubbots
branchPolicy: main
dashboardMode: source-map
refreshPolicy: watcher-driven source invalidation plus agent-maintained session summaries
coordinationSchema: scrubbots-coordination/v1
---

# SCRUBBOTS — H!veAI Project Dashboard

This file is the H!veAI-facing project status and latest-session summary surface. It is **not** a second task ledger. Task checkboxes and milestone truth remain canonical only in `tasks.md`.

## Project identity

| Field | Value |
| --- | --- |
| Project | SCRUBBOTS |
| Repository | `Sekiph82/Scrubbots` |
| Default branch | `main` |
| Engine | Godot 4.7.1-stable / GDScript |
| Product | Mobile-first portrait puzzle game |

## Current project state

| Field | Value |
| --- | --- |
| Project status | ACTIVE |
| Current implementation frontier | M07 — Visual Reference Library / owner asset ingestion |
| Completed technical baseline | Variable board/data core, production difficulty bands, 59×59 max validation, BoardRenderer |
| Automated evidence | 227/227 headless checks PASS at Phase M06 completion (`abd9ceb`) |
| Open owner design gate | M10 DIRTY/CLEAN final preset selection (A/B/C prototypes exist) |
| Waiting on | Owner-approved SCRUBBOTS artwork files for M07; owner DIRTY/CLEAN preset review |
| Canonical task truth | `tasks.md` |

## Latest session summary

| Field | Value |
| --- | --- |
| Timestamp | 2026-08-27T11:09:00+03:00 |
| Actor | CHATGPT |
| Cycle | `META-C001` |
| Session type | Repository audit + coordination-system setup |
| Cycle status | AUDITED_PASS |
| Milestone/task impact | META only; no `tasks.md` gameplay checkbox changed |
| Summary | Installed the repository-native ChatGPT↔Claude communication protocol: versioned ChatGPT prompts/audits, append-only Claude implementation logs, session index, templates, and dashboard synchronization rules while preserving the local phase-log workflow. |
| Primary evidence | `coordination/sessions/META-C001/CHATGPT_AUDIT_V01.md` |
| Next expected actor | OWNER / CHATGPT for the next scoped project cycle; CLAUDE when a versioned implementation prompt is issued |
| Next project action | Supply/identify owner-approved SCRUBBOTS artwork for M07 and review DIRTY/CLEAN presets when ready |

## Recent coordination cycles

| Cycle | Milestone | Status | Last actor | Summary | Evidence |
| --- | --- | --- | --- | --- | --- |
| `META-C001` | META | AUDITED_PASS | CHATGPT | Established GitHub coordination bus and H!veAI session tracking. | `coordination/SESSION_INDEX.md`, `coordination/sessions/META-C001/` |

## Coordination source map

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

## H!veAI watcher targets

H!veAI should invalidate/refresh project state when any of these change:

- `.hiveai/PROJECT_DASHBOARD.md`
- `tasks.md`
- `coordination/SESSION_INDEX.md`
- `coordination/sessions/**/CHATGPT_PROMPT_V*.md`
- `coordination/sessions/**/CHATGPT_AUDIT_V*.md`
- `coordination/sessions/**/CLAUDE_IMPLEMENTATION_LOG.md`
- `coordination/sessions/**/OWNER_NOTES.md`
- `CHANGELOG.md`

The watcher should treat `tasks.md` as task authority and the coordination artifacts as execution/communication evidence. A coordination status must never silently mark a `tasks.md` checkbox complete.

## Per-session refresh contract

After every **material** ChatGPT or Claude project session, the acting agent must update this file before ending the session.

Refresh at minimum:

1. `Latest session summary` timestamp, actor, cycle, status, summary, evidence, next actor/action.
2. The matching row in `Recent coordination cycles`.
3. `Current project state` only when task/project truth actually changed.
4. `coordination/SESSION_INDEX.md` in the same session.

A material session includes issuing/revising a Claude prompt, completing Claude implementation work, publishing a ChatGPT audit, changing a blocker/design decision, or materially changing repository/project status. Pure conversational discussion with no project-state effect does not require a Git commit.

## Cycle model

A normal implementation loop is:

`ChatGPT prompt -> Claude implementation/log -> ChatGPT audit -> PASS or revised prompt in the same cycle`

Example:

`M07-C001/CHATGPT_PROMPT_V01.md`

then

`M07-C001/CLAUDE_IMPLEMENTATION_LOG.md`

then

`M07-C001/CHATGPT_AUDIT_V01.md`

If the audit requires corrections, do not create a duplicate task/cycle solely for the retry. Keep `M07-C001`, add `CHATGPT_PROMPT_V02.md`, and let Claude append another session entry to the same implementation log.

## Dashboard integrity rules

- Never copy the full `tasks.md` checklist into this dashboard.
- Never edit historical prompt/audit versions to make later work appear compliant.
- Never publish secrets or sensitive environment values.
- Keep detailed implementation chronology in the cycle files and local Desktop phase log, not in this summary.
- Use repository commits/tests/files as evidence whenever available.
