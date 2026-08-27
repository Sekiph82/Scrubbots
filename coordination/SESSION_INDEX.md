# SCRUBBOTS Coordination Session Index

Canonical task truth remains in `tasks.md`. This file indexes ChatGPT/Claude coordination cycles and does not duplicate the backlog.

Canonical URL:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md

Audit policy:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md

Audit learning index:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

## Status legend

`PLANNED` · `CLAUDE_IN_PROGRESS` · `AWAITING_AUDIT` · `CHANGES_REQUIRED` · `AUDITED_PASS` · `BLOCKED` · `SUPERSEDED`

## Cycles

| Cycle | Milestone | Started | Last update | Status | Active ChatGPT prompt | Claude implementation log | Latest ChatGPT audit | Task refs | Summary |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| M07-C001 | M07 - Visual Reference Library | 2026-08-27 | 2026-08-27 | `AWAITING_AUDIT` | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V04.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V01.md | SB-M07-001..017 | V04 corrections applied: F-M07-001 (Akilta originalFilename→null) and F-M07-002 (full validation sequence logged individually). 227/227 regression PASS. All 13 inventory checks PASS. Ready for ChatGPT audit V02. |
| META-C001 | META / coordination infrastructure | 2026-08-27 | 2026-08-27 | `AUDITED_PASS` | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_PROMPT_V01.md | N/A | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_AUDIT_V01.md | None | Established repository-native coordination and H!veAI synchronization. |

## M07-C001 history

- V01: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V01.md
  - Historical only; superseded before implementation.
- V02: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V02.md
  - Historical inherited M07 scope and validation requirements.
- V03: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V03.md
  - Drove the initial implementation pass.
  - Its Claude self-audit requirement is superseded by the owner's corrected protocol.
- Historical audit criteria: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_CRITERIA_V01.md
  - Still useful for M07 requirement comparisons.
  - Its Claude self-audit criterion is superseded by the corrected owner protocol.
- Initial Claude implementation commit: https://github.com/Sekiph82/Scrubbots/commit/1c23eba106eb9c347f0ef63fd5f691d5180cdd0c
- Initial implementation log: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md
- Historical Claude self-audit V01: retained as old evidence only; not part of current workflow and not independent proof.
- ChatGPT independent audit V01: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V01.md
  - Decision: `CHANGES_REQUIRED`.
  - Findings: `F-M07-001`, `F-M07-002`.
  - Added audit learnings: `AL-008`, `AL-009`.
- V04: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V04.md
  - Active correction prompt.
  - Claude must implement/test/log only, then return `AWAITING_AUDIT`.

## Rules

- ChatGPT owns `CHATGPT_PROMPT_VNN.md`, `CHATGPT_AUDIT_CRITERIA_VNN.md`, and `CHATGPT_AUDIT_VNN.md`.
- Claude owns one append-only `CLAUDE_IMPLEMENTATION_LOG.md` per cycle.
- Claude does not create audit or self-audit files.
- Historical Claude self-audit artifacts remain historical only and are not audit proof.
- Claude reads relevant prior ChatGPT audits and `AUDIT_INDEX.md`, applies those findings to implementation/testing, and records the application in its implementation log.
- Only ChatGPT may assign `AUDITED_PASS` / `AUDITED_FAIL`.
- Use absolute GitHub URLs for GitHub-tracked evidence.
- Do not open a new cycle solely for an audit correction; use a new prompt version in the same cycle.
- Every material ChatGPT or Claude session updates `.hiveai/PROJECT_DASHBOARD.md`, because H!veAI actively watches only that materialized dashboard file.
