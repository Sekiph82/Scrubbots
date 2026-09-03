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
| M09-C001 | M09 - Pixel Art to Level Data Importer Core | 2026-08-27 | 2026-09-03 | `AWAITING_AUDIT` | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V03.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CLAUDE_IMPLEMENTATION_LOG.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V02.md | SB-M09-001..017 | V03 correction pass complete: closed F-M09-005 (filesystem identity normalization / AL-013) via `.`/`..` simplification and an empirically-verified relative-path base. 332/332 tests pass. Ready for ChatGPT audit V03. |
| M07-C001 | M07 - Visual Reference Library | 2026-08-27 | 2026-08-27 | `AUDITED_PASS` | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V04.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V02.md | SB-M07-001..017 | Reference-library infrastructure audited. M07 milestone remains partial only because owner-supplied visual assets are still missing. |
| META-C001 | META / coordination infrastructure | 2026-08-27 | 2026-08-27 | `AUDITED_PASS` | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_PROMPT_V01.md | N/A | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_AUDIT_V01.md | None | Established repository-native coordination and H!veAI synchronization. |

## M09-C001 history

- Prompt V01: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V01.md
  - Initial deterministic exact-pixel importer-core implementation scope, SB-M09-001..017.
- Audit criteria V01: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_CRITERIA_V01.md
- Initial implementation commit: https://github.com/Sekiph82/Scrubbots/commit/7acd0e65ede18f33553eedcec82fabf2125291d1
- Initial implementation-log backfill head: https://github.com/Sekiph82/Scrubbots/commit/49178d412276137a39da993bfafe47262dc10c97
- Audit V01: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V01.md
  - `CHANGES_REQUIRED`.
  - Findings F-M09-001..004: source/artifact aliasing, multi-artifact overwrite policy, PNG gate, malformed reconstruction safety.
  - Added AL-010..012.
- Prompt V02: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V02.md
- Audit criteria V02: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_CRITERIA_V02.md
- V02 correction implementation commit: https://github.com/Sekiph82/Scrubbots/commit/84eebefddbcac35b28410e9db2e4052e3190eb6a
- V02 implementation-log head: https://github.com/Sekiph82/Scrubbots/commit/61172cee24c3996729370cfbba4f54f3c2f9833d
- Audit V02: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V02.md
  - `CHANGES_REQUIRED`.
  - F-M09-002, F-M09-003 and F-M09-004 independently closed.
  - F-M09-001 remains partially open as new finding F-M09-005: dot-segment / relative path identity can still bypass string-based canonical comparison.
  - Added AL-013 filesystem identity normalization.
- Prompt V03: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V03.md
  - Active authority.
  - Narrow correction for F-M09-005 only.
- Audit criteria V03: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_CRITERIA_V03.md
- V03 correction implementation (Session 3): closed F-M09-005 — `_canonical_path()` resolves bare relative paths against `res://` (empirically confirmed, not OS CWD) and applies `String.simplify_path()` before alias comparison. 12 new targeted equivalent-path tests (332/332 total). Full mandatory-validation checklist run individually per prompt V03. See `CLAUDE_IMPLEMENTATION_LOG.md` Session 3.
- Cycle state: `AWAITING_AUDIT` for ChatGPT audit V03.
- Deferred throughout this cycle: SB-M09-018 batch import, SB-M09-019 batch validation, SB-M09-020 duplicate-ID protection.
- M08 remains owner-asset-dependent and open.

## M07-C001 history

- Final prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V04.md
- Final independent audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V02.md
- Decision: `AUDITED_PASS`.
- M07 asset-specific tasks remain owner-dependent as recorded in `tasks.md`.

## Rules

- ChatGPT owns `CHATGPT_PROMPT_VNN.md`, `CHATGPT_AUDIT_CRITERIA_VNN.md`, and `CHATGPT_AUDIT_VNN.md`.
- Claude owns one append-only `CLAUDE_IMPLEMENTATION_LOG.md` per cycle.
- Claude does not create audit or self-audit files.
- Claude reads relevant prior ChatGPT audits and `AUDIT_INDEX.md`, applies those findings to implementation/testing, and records the application in its implementation log.
- Only ChatGPT may assign `AUDITED_PASS` / `AUDITED_FAIL`.
- Use absolute GitHub URLs for GitHub-tracked evidence.
- Do not open a new cycle solely for an audit correction; use a new prompt version in the same cycle.
- Every material ChatGPT or Claude session updates `.hiveai/PROJECT_DASHBOARD.md`, because H!veAI actively watches only that materialized dashboard file.
