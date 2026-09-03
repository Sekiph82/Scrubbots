---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-audit-criteria
cycleId: M09-C002
version: 2
createdAt: 2026-09-03T11:38:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M09
taskRefs:
  - SB-M09-018
  - SB-M09-019
  - SB-M09-020
---

# SCRUBBOTS - M09-C002 ChatGPT Audit Criteria V02

These criteria apply to the correction pass triggered by:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V01.md

Claude implements/tests/logs only. ChatGPT performs the independent audit.

## Pass/fail criteria

| ID | Requirement | AUDITED_PASS requires | AUDITED_FAIL if |
| --- | --- | --- | --- |
| AC-M09B2-001 | Predictable destination preflight | Every output/preview/metadata parent directory is validated before commit. Missing/non-directory parents fail the whole batch before any final write. | A later deterministic missing-parent failure can occur after an earlier item writes. |
| AC-M09B2-002 | Validation-only no mutation | Parent-path validation in validation-only mode does not create directories or final artifacts. | Validation-only creates destination directories/files. |
| AC-M09B2-003 | Catalog root fail-closed | Missing/unopenable/non-directory catalog root yields actionable batch failure and non-zero CLI exit. | Invalid catalog root is silently treated as an empty catalog. |
| AC-M09B2-004 | Catalog health fail-closed | Malformed/structurally invalid catalog entries and existing duplicate IDs make overall catalog validation fail while preserving deterministic detailed reports. | CLI can report `ok:true` while catalog integrity/uniqueness is known invalid. |
| AC-M09B2-005 | Catalog path ownership | Canonical catalog path -> declared ID ownership is indexed and protected. An output aliasing an existing catalog file must use that same declared ID. | `overwrite=true` can replace an existing catalog file with a different logical ID. |
| AC-M09B2-006 | Same-entry re-import preserved | Same ID + same canonical catalog path still follows normal audited overwrite/unchanged behavior. | The correction rejects every legitimate same-entry re-import. |
| AC-M09B2-007 | Malformed catalog path protection | A requested output cannot overwrite a catalog file whose valid identity cannot be established because that entry is malformed. | `overwrite=true` can erase malformed/unknown catalog state before it is resolved. |
| AC-M09B2-008 | Manifest optional schema types | `preview` and `metadata` are strings when present; `overwrite` is boolean when present; wrong types return actionable item/schema errors without crash. | Invalid optional JSON types reach typed assignments/import execution or cause runtime errors. |
| AC-M09B2-009 | Whole-batch no-write proof | Missing-parent, catalog-root, catalog-health, path-ownership and schema failures are detected before commit and tests prove earlier valid items remain unwritten. | Tests only assert error flags without proving no earlier final write. |
| AC-M09B2-010 | Regression preservation | All accepted V01 batch behavior and all M09-C001 invariants remain intact. | Duplicate-ID/path/PNG/determinism/reconstruction/unchanged behavior regresses. |
| AC-M09B2-011 | Task truth | SB-M09-018..020 are `[x]` only after the corrected behavior and full validation pass. | Task ledger claims completed/validated while any audit V01 finding remains open. |
| AC-M09B2-012 | Validation traceability | Claude log records targeted correction tests plus full final validation, expected/fail/actual/classification, commit/push. | Aggregate test total substitutes for named correction evidence. |
| AC-M09B2-013 | Scope integrity | Only M09-C002 batch tooling/tests/docs/task/coordination corrections change. | M08, M10, M11+, gameplay, routing or owner-art work begins. |

## Mandatory audit learnings

Claude must read and apply:

- `AL-009` validation traceability;
- `AL-010` path/source immutability;
- `AL-011` negative-test specificity;
- `AL-012` multi-artifact overwrite safety;
- `AL-013` filesystem identity normalization;
- `AL-014` preflight fidelity for deterministic filesystem preconditions;
- `AL-015` fail-closed catalog root/health and bidirectional ownership;
- `AL-016` optional manifest schema type validation.

Audit index:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

## Independent-audit note

Claude-run Godot/CLI results remain implementation evidence. ChatGPT will independently inspect code, diffs, test specificity, catalog ownership semantics, preflight behavior, task truth and coordination state before assigning the next audit verdict.
