# SCRUBBOTS Coordination Session Index

Canonical task truth remains in `tasks.md`. This file indexes ChatGPT/Claude communication cycles and must not duplicate the project backlog.

## Status legend

`PLANNED` · `CLAUDE_IN_PROGRESS` · `AWAITING_AUDIT` · `CHANGES_REQUIRED` · `AUDITED_PASS` · `BLOCKED` · `SUPERSEDED`

## Cycles

| Cycle | Milestone | Started | Last update | Status | ChatGPT prompt | Claude log | ChatGPT audit | Task refs | Repository evidence | Summary |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| M07-C001 | M07 - Visual Reference Library | 2026-08-27 | 2026-08-27 | PLANNED | [`CHATGPT_PROMPT_V01.md`](sessions/M07-C001/CHATGPT_PROMPT_V01.md) | PENDING | PENDING | SB-M07-001..017 | Prompt issued on `main` in `c20380f` | Establish the visual reference library foundation, audit actual repository asset availability, preserve originals, and leave missing owner-art inventory truthfully awaiting owner assets. |
| META-C001 | META / coordination infrastructure | 2026-08-27 | 2026-08-27 | AUDITED_PASS | [`CHATGPT_PROMPT_V01.md`](sessions/META-C001/CHATGPT_PROMPT_V01.md) | N/A (ChatGPT performed process-only repository setup) | [`CHATGPT_AUDIT_V01.md`](sessions/META-C001/CHATGPT_AUDIT_V01.md) | None; no gameplay task status changed | PR #2 merged to `main` as `734ccfe` | Installed the versioned ChatGPT↔Claude communication bus, session index, templates, and single-dashboard synchronization rules. |

## Rules

- Append new cycles; do not delete historical rows.
- Update an existing row when the same cycle advances state.
- Do not create a new cycle solely because a chat/session restarted.
- Prompt and audit links must point to immutable versioned artifacts.
- Claude uses one append-only `CLAUDE_IMPLEMENTATION_LOG.md` per cycle.
- `Repository evidence` should contain commit/PR/path evidence, never secret values.
- Every material ChatGPT or Claude session also updates `.hiveai/PROJECT_DASHBOARD.md` because H!veAI actively watches only that materialized dashboard file.
