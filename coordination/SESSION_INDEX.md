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
| M09-C001 | M09 - Pixel Art to Level Data Importer Core | 2026-08-27 | 2026-08-28 | `AWAITING_AUDIT` | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V02.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CLAUDE_IMPLEMENTATION_LOG.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V01.md | SB-M09-001..017 | V02 correction pass complete. All four audit V01 findings (F-M09-001..004) closed. 320/320 tests pass. Ready for ChatGPT audit V02. |
| M07-C001 | M07 - Visual Reference Library | 2026-08-27 | 2026-08-27 | `AUDITED_PASS` | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V04.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V02.md | SB-M07-001..017 | ChatGPT audit V02 independently verified both V01 corrections. Coordination cycle closed as AUDITED_PASS. M07 milestone remains PARTIAL only because SB-M07-008..014 require owner-supplied visual assets. |
| META-C001 | META / coordination infrastructure | 2026-08-27 | 2026-08-27 | `AUDITED_PASS` | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_PROMPT_V01.md | N/A | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_AUDIT_V01.md | None | Established repository-native coordination and H!veAI synchronization. |

## M09-C001 history

- V01 prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V01.md
  - Initial importer-core implementation scope, SB-M09-001..017.
- Audit criteria V01: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_CRITERIA_V01.md
- Initial implementation commit: https://github.com/Sekiph82/Scrubbots/commit/7acd0e65ede18f33553eedcec82fabf2125291d1
- Initial implementation-log backfill head: https://github.com/Sekiph82/Scrubbots/commit/49178d412276137a39da993bfafe47262dc10c97
- ChatGPT independent audit V01: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V01.md
  - Decision: `CHANGES_REQUIRED`.
  - Findings: F-M09-001 source/artifact aliasing, F-M09-002 multi-artifact overwrite policy, F-M09-003 PNG-only gate, F-M09-004 malformed reconstruction safety.
  - Added AL-010, AL-011, AL-012.
- Audit criteria V02: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_CRITERIA_V02.md
- V02 correction prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V02.md
  - Active authority.
  - Claude must implement/test/log only and return `AWAITING_AUDIT`.
- V02 correction implementation (Session 2): Claude closed F-M09-001..004, added 34 safety checks (320 total), updated docs/CHANGELOG/tasks.
- Correction commit: (pending — this update)
- Cycle state: `AWAITING_AUDIT` for ChatGPT audit V02.
- Deferred until this cycle passes: SB-M09-018 batch import, SB-M09-019 batch validation, SB-M09-020 duplicate-ID protection.
- M08 remains owner-asset-dependent and open.

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
  - Correction prompt for V01 findings.
  - Claude implemented/tested/logged only and returned `AWAITING_AUDIT`.
- Correction commit: https://github.com/Sekiph82/Scrubbots/commit/c66eaf561d5357ea971ab44e3be0cb7a2b6062f2
- Log backfill commit: https://github.com/Sekiph82/Scrubbots/commit/302bcb8edc4e3342dca19e99df689122b93555c7
- ChatGPT independent audit V02: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V02.md
  - Decision: `AUDITED_PASS`.
  - F-M07-001 and F-M07-002 independently verified as closed.
  - No new reusable learning; AL-008 and AL-009 remain active.

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
