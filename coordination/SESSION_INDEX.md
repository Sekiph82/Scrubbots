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
| M09-C002 | M09 - Batch Import / Validation / Duplicate IDs | 2026-09-03 | 2026-09-03 | `AWAITING_AUDIT` | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_PROMPT_V01.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CLAUDE_IMPLEMENTATION_LOG.md | PENDING | SB-M09-018..020 | Implementation complete: `LevelBatchImporter` + CLI reuse the audited M09-C001 importer per item; whole-batch preflight-then-commit; duplicate-ID (within-batch/against-catalog/existing-catalog) and cross-item path safety enforced. 394/394 tests pass (62 new); 21-step mandatory CLI/regression validation complete. Ready for ChatGPT audit V01. |
| M09-C001 | M09 - Pixel Art to Level Data Importer Core | 2026-08-27 | 2026-09-03 | `AUDITED_PASS` | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V03.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CLAUDE_IMPLEMENTATION_LOG.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V03.md | SB-M09-001..017 | Final audit V03 independently closed F-M09-005. Exact-pixel single importer, safety hardening and filesystem-identity normalization are audited pass. |
| M07-C001 | M07 - Visual Reference Library | 2026-08-27 | 2026-08-27 | `AUDITED_PASS` | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V04.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V02.md | SB-M07-001..017 | Reference-library infrastructure audited. M07 milestone remains partial only because owner-supplied visual assets are still missing. |
| META-C001 | META / coordination infrastructure | 2026-08-27 | 2026-08-27 | `AUDITED_PASS` | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_PROMPT_V01.md | N/A | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_AUDIT_V01.md | None | Established repository-native ChatGPT/Claude coordination and H!veAI synchronization. |

## M09-C002 issuance

- Active prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_PROMPT_V01.md
- Pre-published audit criteria: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_CRITERIA_V01.md
- Required prior audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V03.md
- Scope: `SB-M09-018`, `SB-M09-019`, `SB-M09-020` only.
- M08 remains owner-asset-dependent and open.
- M10 remains owner-controlled.

## M09-C002 implementation (Session 1)

- `scripts/tools/level_batch_importer.gd` (new) + `tools/import_level_batch.gd` (new CLI); `scripts/tools/level_importer.gd` gained an additive `dry_run` param reused for batch preflight (zero regression to existing call sites).
- Whole-batch prepare(dry_run)/validate-then-commit architecture; duplicate-ID (within-batch, against-catalog, existing-catalog-duplicates) and cross-item source/destination path safety via the same `LevelImporter._canonical_path()` identity used by the audited single importer.
- 394/394 tests pass (62 new, all 332 prior checks unchanged). All 21 prompt-mandated validation steps run individually and recorded, including real CLI runs proving validation-only writes nothing, commit writes, unchanged rerun, duplicate-ID/path-alias rejection with no writes, failing-later-item preflight, and catalog duplicate/malformed detection.
- See `CLAUDE_IMPLEMENTATION_LOG.md` Session 1 for full evidence.
- Cycle state: `AWAITING_AUDIT` for ChatGPT audit V01.

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
  - F-M09-001 remained partially open as F-M09-005: dot-segment / relative path identity bypass.
  - Added AL-013 filesystem identity normalization.
- Prompt V03: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V03.md
- Audit criteria V03: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_CRITERIA_V03.md
- V03 correction implementation commit: https://github.com/Sekiph82/Scrubbots/commit/d9400e7512c5f221794a026c876b79095c990422
- V03 implementation-log backfill head: https://github.com/Sekiph82/Scrubbots/commit/333bac8a4fefd2aafe6c2279b3093c304f6f47fd
- Audit V03: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V03.md
  - `AUDITED_PASS`.
  - F-M09-005 independently closed via explicit relative-base resolution + `String.simplify_path()` and targeted equivalent-path tests.
  - M09-C001 closed; no new reusable learning beyond AL-013.
- Deferred to M09-C002: SB-M09-018 batch import, SB-M09-019 batch validation, SB-M09-020 duplicate-ID protection.

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
