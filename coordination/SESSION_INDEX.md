# SCRUBBOTS Coordination Session Index

Canonical task truth remains in `tasks.md`. This file indexes ChatGPT/Claude communication cycles and must not duplicate the project backlog.

Canonical URL:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md

Audit policy:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md

Audit learning index:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

## Status legend

`PLANNED` · `CLAUDE_IN_PROGRESS` · `AWAITING_AUDIT` · `CHANGES_REQUIRED` · `AUDITED_PASS` · `BLOCKED` · `SUPERSEDED`

## Cycles

| Cycle | Milestone | Started | Last update | Status | Active ChatGPT prompt | Claude implementation log | Claude self-audit | ChatGPT audit | Task refs | Repository evidence | Summary |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| M07-C001 | M07 - Visual Reference Library | 2026-08-27 | 2026-08-27 | PLANNED | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V02.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md (to be created by Claude) | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_SELF_AUDIT_V01.md (expected) | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V01.md (expected after implementation) | SB-M07-001..017 | V02 supersedes V01 before Claude implementation | Establish visual-reference infrastructure and asset-availability audit under the new dual-audit policy. Claude must self-audit provisionally; ChatGPT independently audits afterward. |
| META-C001 | META / coordination infrastructure | 2026-08-27 | 2026-08-27 | AUDITED_PASS | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_PROMPT_V01.md | N/A | N/A | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_AUDIT_V01.md | None | PR #2 merged to `main` as `734ccfe` | Installed the versioned ChatGPT<->Claude communication bus and H!veAI synchronization rules. |

## M07-C001 prompt history

- V01: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V01.md
  - Historical evidence only.
  - Superseded before Claude implementation.
- V02: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V02.md
  - Active implementation authority.
  - Adds canonical GitHub URL references and the dual-audit/self-audit model.

## Rules

- Append new cycles; do not delete historical rows.
- Update an existing row when the same cycle advances state.
- Do not create a new cycle solely because a chat/session restarted.
- Prompt, self-audit, and ChatGPT audit links must use absolute GitHub URLs.
- Published ChatGPT prompt/audit versions are immutable evidence.
- Claude uses one append-only `CLAUDE_IMPLEMENTATION_LOG.md` per cycle.
- Claude creates a new immutable `CLAUDE_SELF_AUDIT_VNN.md` for each implementation pass handed to ChatGPT.
- Claude self-test results are provisional (`SELF_PASS`/`SELF_FAIL` etc.), never `AUDITED_PASS`.
- `AUDITED_PASS` is assigned only by ChatGPT independent audit.
- `Repository evidence` must contain commit/PR/path evidence, never secret values.
- Every material ChatGPT or Claude session updates `.hiveai/PROJECT_DASHBOARD.md` because H!veAI actively watches only that materialized dashboard file.
