---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-audit-criteria
cycleId: M09-C002
version: 1
createdAt: 2026-09-03T11:38:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M09
taskRefs:
  - SB-M09-018
  - SB-M09-019
  - SB-M09-020
---

# SCRUBBOTS - M09-C002 ChatGPT Audit Criteria V01

Claude implements/tests/logs only. ChatGPT performs the independent audit.

## Pass/fail criteria

| ID | Requirement | AUDITED_PASS requires | AUDITED_FAIL if |
| --- | --- | --- | --- |
| AC-M09B-001 | Scope integrity | Changes stay within M09 batch tooling/tests/docs/task/coordination. | M08, M10, gameplay, routing, owner art, or unrelated runtime systems begin. |
| AC-M09B-002 | Single-import authority preserved | Batch layer reuses audited M09-C001 conversion/path/validation semantics instead of duplicating divergent logic. | Batch implements a second inconsistent pixel/palette/difficulty/path pipeline. |
| AC-M09B-003 | Deterministic batch manifest | Manifest schema and processing order are explicit and stable. | Item ordering/output/report changes nondeterministically. |
| AC-M09B-004 | Validation-only mode | Complete logical validation can run without writing final derived artifacts. | Validation-only mutates final outputs or sources. |
| AC-M09B-005 | Whole-batch logical preflight | Predictable request/catalog/path/overwrite failures are detected across the entire batch before final artifact writes. | Earlier items are committed before a later known logical validation failure is discovered. |
| AC-M09B-006 | Duplicate IDs within batch | Two requests declaring the same Level Data ID are rejected before writes. | Duplicate batch IDs can be imported. |
| AC-M09B-007 | Duplicate IDs against catalog | Requested ID already owned by a different catalog file is rejected, independent of overwrite flag. | `overwrite=true` or filename tricks allow one file to steal another level ID. |
| AC-M09B-008 | Existing catalog duplicates | Catalog scan detects two existing Level Data files declaring the same ID and reports both paths deterministically. | Existing duplicate IDs are silently ignored. |
| AC-M09B-009 | Same-entry re-import semantics | Same ID at same canonical catalog output is explicitly distinguished from a conflicting different file and still obeys overwrite/unchanged rules. | All same-ID cases are either dangerously allowed or incorrectly rejected without identity semantics. |
| AC-M09B-010 | Catalog validity | Malformed/structurally invalid catalog entries produce actionable validation failures rather than being skipped silently. | Invalid catalog data is ignored while uniqueness is claimed. |
| AC-M09B-011 | Cross-item path safety | Canonical source/output/preview/metadata identities are checked across batch items, including `.`/`..` and relative/absolute equivalents. | Two items can write the same physical destination or one item can overwrite another item's source. |
| AC-M09B-012 | Overwrite safety | Existing different derived artifacts across all batch items are preflighted consistently with M09-C001. | Batch weakens preview/metadata/output overwrite protection. |
| AC-M09B-013 | Unchanged rerun | Re-running the same successful batch does not create meaningless content changes and reports stable unchanged state. | Unchanged batch needlessly rewrites or changes serialized outputs. |
| AC-M09B-014 | CLI behavior | Real headless validation-only and commit commands exist, return non-zero on failure, and expose useful per-item/batch summaries. | CLI hides failures behind success or lacks one of the required modes. |
| AC-M09B-015 | Negative-test specificity | Duplicate ID, catalog corruption, PNG format, path alias, and later-item failure tests prove their named failure modes directly. | Tests pass because of unrelated earlier errors. |
| AC-M09B-016 | Regression preservation | Existing M09-C001 semantics and previous 332 checks remain green; new tests extend the same suite. | Exact-pixel, reconstruction, PNG, path, difficulty, or deterministic behavior regresses. |
| AC-M09B-017 | Task truth | Only SB-M09-018..020 are newly closed if evidence exists; M08 and M10+ remain unchanged. | Checklist overstates completion. |
| AC-M09B-018 | Validation traceability | Claude log records all mandatory final-validation steps individually with expected/fail/actual/classification. | Aggregate green total substitutes for named evidence. |
| AC-M09B-019 | No fake owner art | Batch fixtures remain clearly synthetic TEST inputs; no owner/canonical artwork is invented. | Generated test art is mislabeled as owner/original/production art. |
| AC-M09B-020 | Transaction claims bounded | Any unimplemented OS-level rollback limitation is documented accurately. | Tool claims atomic/transactional guarantees it does not actually provide. |

## Required audit learnings

Claude must read and apply relevant entries from:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

Especially:

- `AL-005`
- `AL-006`
- `AL-008`
- `AL-009`
- `AL-010`
- `AL-011`
- `AL-012`
- `AL-013`

## Independent-audit note

Claude-run Godot/CLI results are implementation evidence. ChatGPT will independently inspect repository code, diffs, test specificity, duplicate-ID semantics, catalog-scan behavior, task truth, and coordination evidence. Runtime commands unavailable to ChatGPT will not be silently relabeled as independently executed proof.
