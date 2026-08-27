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

| Cycle | Milestone | Started | Last update | Status | Active ChatGPT prompt | Audit criteria | Claude implementation log | Claude self-audit | ChatGPT audit | Task refs | Summary |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| M07-C001 | M07 - Visual Reference Library | 2026-08-27 | 2026-08-27 | AWAITING_AUDIT | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V03.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_CRITERIA_V01.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_SELF_AUDIT_V01.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V01.md (expected) | SB-M07-001..017 | Visual-reference infrastructure + availability audit complete. 10 infrastructure tasks provisionally validated, 7 asset tasks AWAITING OWNER ASSET. 227/227 regression PASS. Self-audit V01 ready for ChatGPT independent audit. |
| META-C001 | META / coordination infrastructure | 2026-08-27 | 2026-08-27 | AUDITED_PASS | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_PROMPT_V01.md | N/A | N/A | N/A | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_AUDIT_V01.md | None | Established repository-native coordination and H!veAI synchronization. |

## M07-C001 prompt history

- V01: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V01.md
  - Historical evidence only.
  - Superseded before Claude implementation.
- V02: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V02.md
  - Added absolute GitHub URL references.
  - Superseded before Claude implementation.
- V03: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V03.md
  - Active implementation authority.
  - Adds audit-driven verification, prior-audit learning application, and mandatory Claude self-audit.

## Rules

- Append new cycles; do not delete historical rows.
- Update an existing row when the same cycle advances state.
- Do not create a new cycle solely because a chat/session restarted.
- Use absolute GitHub URLs for prompt, audit criteria, implementation log, self-audit, ChatGPT audit, index, dashboard, and repository evidence.
- Published ChatGPT prompt/audit/audit-criteria versions are immutable evidence.
- Claude uses one append-only `CLAUDE_IMPLEMENTATION_LOG.md` per cycle.
- Claude creates a new immutable `CLAUDE_SELF_AUDIT_VNN.md` for each implementation pass handed to ChatGPT.
- Claude self-test results are provisional (`SELF_PASS`/`SELF_FAIL` etc.), never `AUDITED_PASS`.
- Only ChatGPT independent audit may assign `AUDITED_PASS`/`AUDITED_FAIL`.
- Claude must read `AUDIT_INDEX.md` and relevant prior ChatGPT audits before planning verification, then state how those findings changed the test plan.
- Every material ChatGPT or Claude session updates `.hiveai/PROJECT_DASHBOARD.md` because H!veAI actively watches only that materialized dashboard file.
