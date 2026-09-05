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
| META-C002 | META - Master UI + Magnific Integration | 2026-09-05 | 2026-09-05 | `AWAITING_AUDIT` | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_PROMPT_V01.md | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CLAUDE_LOG_V01.md | N/A | SB-UI-001..032, SB-M22..M45 additions | Owner visual ref intake (51 files), 95 tasks migrated from UI_TASKS_APPENDIX, global visual production policy, UI foundation validated. 657/657 ALL PASS. No Magnific generation. Next actor CHATGPT. |
| M12-C001 | M12 - Five-Slot Logic | 2026-09-05 | 2026-09-05 | `AWAITING_AUDIT` | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_PROMPT_V02.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CLAUDE_LOG_V02.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_AUDIT_V01.md | SB-M12-001..011 | V02 closes F-M12-001: removed get_slot(), added get_slot_id() scalar getter, M12-18 bypass regression. 657/657 ALL PASS. Next actor CHATGPT. |
| M11-C001 | M11 - Gameplay Session Core | 2026-09-04 | 2026-09-05 | `AUDITED_PASS` | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_PROMPT_V04.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CLAUDE_LOG_V04.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_V04.md | SB-M11-001..012 | M11 final pass. V03 independently closed renderer regression gap; V04 versioned logs/H!ve mapping audited clean. |
| M09-C002 | M09 - Batch Import / Validation / Duplicate IDs | 2026-09-03 | 2026-09-04 | `AUDITED_PASS` | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_PROMPT_V03.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CLAUDE_IMPLEMENTATION_LOG.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V03.md | SB-M09-018..020 | Final audit V03 closed F-M09B-006. Batch import/validation/duplicate-ID tooling is independently accepted; M09 is complete. |
| M09-C001 | M09 - Pixel Art to Level Data Importer Core | 2026-08-27 | 2026-09-03 | `AUDITED_PASS` | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V03.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CLAUDE_IMPLEMENTATION_LOG.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V03.md | SB-M09-001..017 | Exact-pixel importer core and safety hardening independently audited pass. |
| M07-C001 | M07 - Visual Reference Library | 2026-08-27 | 2026-08-27 | `AUDITED_PASS` | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V04.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V02.md | SB-M07-001..017 | Reference-library infrastructure audited; owner asset tasks remain open. |
| META-C001 | META / coordination infrastructure | 2026-08-27 | 2026-08-27 | `AUDITED_PASS` | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_PROMPT_V01.md | N/A | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_AUDIT_V01.md | None | Repository-native ChatGPT/Claude coordination and H!veAI synchronization established. |

## M11-C001 audit history

### ChatGPT independent audit V01

- Audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_V01.md
- Decision: `CHANGES_REQUIRED`.
- Production session architecture/lifecycle accepted by independent inspection.
- Finding `F-M11-001`: tests M11-23/M11-24 do not directly observe the renderer's BoardState source; they can remain green if reset stops rebinding the renderer.
- Reopened task truth only for SB-M11-005 and SB-M11-012.
- Active correction prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_PROMPT_V02.md
- Active criteria: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_CRITERIA_V02.md
- Current state: `CHANGES_REQUIRED`; next actor CLAUDE.

## M09-C002 audit history

### V01 implementation

- Prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_PROMPT_V01.md
- Criteria: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_CRITERIA_V01.md
- Implementation log: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CLAUDE_IMPLEMENTATION_LOG.md
- Implementation head inspected by ChatGPT: `bf5113d44a18252b1351e08337e363d120335135`

### ChatGPT independent audit V01

- Audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V01.md
- Decision: `CHANGES_REQUIRED`
- Findings:
  - `F-M09B-001` predictable missing destination parents are not part of batch preflight;
  - `F-M09B-002` missing/unopenable catalog root fails open as an empty catalog;
  - `F-M09B-003` existing catalog path can be taken over by a different ID with `overwrite=true`;
  - `F-M09B-004` malformed/duplicate catalog health is reported but does not invalidate overall validation;
  - `F-M09B-005` optional manifest field types are not explicitly schema-validated.
- Added learnings: `AL-014`, `AL-015`, `AL-016`.

### V02 correction implementation

- Prompt V02: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_PROMPT_V02.md
- Criteria V02: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_CRITERIA_V02.md
- Closed F-M09B-001 (destination-parent preflight), F-M09B-002 (catalog-root fail-closed), F-M09B-003 (bidirectional catalog ID/path ownership), F-M09B-004 (catalog health invalidates overall validation), F-M09B-005 (optional manifest field type validation).
- `LevelImporter._canonical_path()` split into `_resolve_path()` (real, case-preserved, for actual FileAccess/DirAccess calls) + `_canonical_path()` (adds Windows case-fold, comparison only) — behavior-preserving.
- 32 new tests (426/426 total); all required real-CLI cases independently verified (missing parent, missing/non-directory catalog root, malformed catalog health, existing catalog duplicate, different-ID-same-path takeover with byte-preservation proof, same-ID-same-path re-import, invalid optional type with no crash).
- See `CLAUDE_IMPLEMENTATION_LOG.md` Session 2 for full evidence.
- Cycle state after implementation: `AWAITING_AUDIT` for ChatGPT audit V02.

### ChatGPT independent audit V02

- Audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V02.md
- Decision: `CHANGES_REQUIRED`.
- V01 findings F-M09B-001..005 were independently accepted as closed.
- New finding: `F-M09B-006` existing directory as a final destination can bypass parent-only preflight and fail deterministically during commit, allowing an earlier item to remain written.
- Added learning: `AL-017` destination object-type preflight.
- Active correction prompt V03: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_PROMPT_V03.md
- Active criteria V03: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_CRITERIA_V03.md

### V03 correction implementation

- Prompt V03: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_PROMPT_V03.md
- Criteria V03: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_CRITERIA_V03.md
- Closed F-M09B-006 (destination-type preflight): `elif DirAccess.dir_exists_absolute(resolved)` added to batch destination preflight step 3, rejecting existing directories at output/preview/metadata final paths before any commit write. Uses same `LevelImporter._resolve_path()` resolver. Read-only in both modes.
- 21 new tests (447/447 total); 7 targeted scenarios covering all three destination roles, validation-only, overwrite=true, regular-file preservation.
- See `CLAUDE_IMPLEMENTATION_LOG.md` Session 3 for full evidence.
- Cycle state after implementation: `AWAITING_AUDIT` for ChatGPT audit V03.

### ChatGPT independent audit V03

- Audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V03.md
- Decision: `AUDITED_PASS`.
- F-M09B-006 independently closed: output/preview/metadata final destinations that are existing directories are rejected in preflight through the same `LevelImporter._resolve_path()` resolver.
- Targeted tests isolate directory-target failure and preserve regular-file unchanged/overwrite behavior.
- Claude reported 447/447 ALL PASS; ChatGPT independently inspected code/diff/test design but did not execute the local Godot binary.
- M09 milestone: COMPLETE.

## M11-C001 issuance

- Active prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_PROMPT_V01.md
- Audit criteria: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_CRITERIA_V01.md
- Required prior audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V03.md
- Scope: SB-M11-001..012 only.
- Completion remains an explicit lifecycle transition only; win/lose rules are not invented.
- M08 remains blocked on owner artwork and M10 remains owner-controlled.
- Implementation log: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CLAUDE_IMPLEMENTATION_LOG.md
- Cycle state: `AWAITING_AUDIT`; next actor CHATGPT.

## Previous completed audit baselines

- M09-C001 final audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V03.md
- M07-C001 final audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V02.md
- META-C001 audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_AUDIT_V01.md

## Rules

- ChatGPT owns `CHATGPT_PROMPT_VNN.md`, `CHATGPT_AUDIT_CRITERIA_VNN.md`, and `CHATGPT_AUDIT_VNN.md`.
- Claude owns one append-only `CLAUDE_IMPLEMENTATION_LOG.md` per cycle.
- Claude does not create audit or self-audit files.
- Claude reads relevant prior ChatGPT audits and `AUDIT_INDEX.md`, applies those findings to implementation/testing, and records the application in its implementation log.
- Only ChatGPT may assign `AUDITED_PASS` / `AUDITED_FAIL`.
- Use absolute GitHub URLs for GitHub-tracked evidence.
- Audit corrections stay in the same cycle using a new prompt version.
- Every material ChatGPT or Claude session updates `.hiveai/PROJECT_DASHBOARD.md`, because H!veAI actively watches only that materialized dashboard file.


## Coordination v4 active migration

- Policy: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/VERSIONED_LOG_POLICY.md
- Active prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_PROMPT_V04.md
- Expected Claude log: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CLAUDE_LOG_V04.md
- V04 backfills M11 CLAUDE_LOG_V01/V02/V03 and creates native CLAUDE_LOG_V04.


### ChatGPT independent audit V03

- Audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_V03.md
- Decision: `AUDITED_PASS`.
- F-M11-001 closed by direct BoardRenderer pixel observability after bind/reset.

### ChatGPT independent audit V04

- Audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_V04.md
- Decision: `AUDITED_PASS`.
- Versioned Claude log migration and H!ve mapping accepted.
- M11-C001 final state: `AUDITED_PASS`.


## M12-C001 issuance

- Prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_PROMPT_V01.md
- Criteria: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_AUDIT_CRITERIA_V01.md
- Expected Claude log: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CLAUDE_LOG_V01.md
- Scope: SB-M12-001..011 only.
- First action: safe local repository synchronization with origin/main.
- Durable evidence: GitHub only; no Desktop phase/handoff log.


### M12-C001 ChatGPT independent audit V01

- Audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_AUDIT_V01.md
- Decision: `CHANGES_REQUIRED`.
- Finding F-M12-001: `get_slot()` leaks internally owned mutable SlotState,
  allowing `set_palette_id()` to bypass SlotSystem validation.
- Reopened SB-M12-003/005/009/010/011.
- Active correction prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_PROMPT_V02.md
- Claude log: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CLAUDE_LOG_V02.md
- V02 correction: Removed `get_slot()` (the leak point). Added `get_slot_id()` scalar getter. M12-18 bypass regression test proves `get_slot()` absent and all queries return scalars. 657/657 ALL PASS.
- Cycle state: `AWAITING_AUDIT`; next actor CHATGPT.
