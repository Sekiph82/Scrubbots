---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-audit-criteria
cycleId: M09-C002
version: 3
createdAt: 2026-09-04T08:54:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M09
taskRefs:
  - SB-M09-018
  - SB-M09-019
  - SB-M09-020
---

# SCRUBBOTS - M09-C002 ChatGPT Audit Criteria V03

These criteria apply only to the narrow correction triggered by:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V02.md

Claude implements/tests/logs only. ChatGPT performs the independent audit.

## Pass/fail criteria

| ID | Requirement | AUDITED_PASS requires | AUDITED_FAIL if |
| --- | --- | --- | --- |
| AC-M09B3-001 | Final destination type preflight | Every output/preview/metadata resolved destination is rejected if that final path itself is an existing directory. | Directory target reaches commit-time physical write attempt. |
| AC-M09B3-002 | Whole-batch no-write | A later directory-target failure blocks the entire batch before an earlier valid item writes. | Earlier item is committed before the deterministic directory-target failure. |
| AC-M09B3-003 | Validation-only read-only | Directory-target validation creates/removes/modifies no filesystem object. | Validation-only mutates destination state. |
| AC-M09B3-004 | Overwrite cannot bypass type safety | `overwrite=true` still rejects an existing directory as a file destination. | Overwrite authorizes replacing/using a directory as output/preview/metadata. |
| AC-M09B3-005 | Regular-file semantics preserved | Existing regular files continue to use audited unchanged/overwrite behavior. | The correction blanket-rejects valid regular-file re-imports or changes deterministic behavior. |
| AC-M09B3-006 | Same resolver authority | Real destination checks use `LevelImporter._resolve_path()`; canonical comparison semantics remain unchanged. | A second divergent path-resolution model is introduced. |
| AC-M09B3-007 | V02 corrections preserved | Catalog root/health, bidirectional ownership, schema typing, missing-parent checks and catalog reports remain fail-closed. | Any V02 finding regresses. |
| AC-M09B3-008 | Test specificity | Tests use valid parents/catalog/manifest and fail specifically because destination itself is a directory. | Tests pass due to another earlier validation error. |
| AC-M09B3-009 | Regression preservation | Full prior M09-C002/M09-C001 suite remains green. | Previously accepted importer/batch behavior regresses. |
| AC-M09B3-010 | Task truth | SB-M09-018..020 remain complete only after targeted and full validation passes. | Task evidence claims validated completion while F-M09B-006 remains open. |
| AC-M09B3-011 | Validation traceability | Implementation log records targeted tests and mandatory CLI/git sequence individually. | Aggregate total substitutes for named evidence. |
| AC-M09B3-012 | Scope integrity | Changes stay within M09-C002 correction/tests/docs/task/coordination. | M08, M10, M11+, gameplay, routing or owner-art work begins. |

## Mandatory audit learnings

Read and apply:

- `AL-009`
- `AL-010`
- `AL-011`
- `AL-012`
- `AL-013`
- `AL-014`
- `AL-015`
- `AL-016`
- `AL-017`

Audit index:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

## Independent-audit note

Claude-run Godot/CLI results remain implementation evidence. ChatGPT will independently inspect the correction code, diff, targeted test specificity, task truth, and coordination state before assigning the next audit verdict.
