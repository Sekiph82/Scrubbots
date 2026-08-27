---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-audit-criteria
cycleId: M09-C001
version: 3
createdAt: 2026-08-28T00:02:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M09
taskRefs:
  - SB-M09-017
---

# SCRUBBOTS - M09-C001 ChatGPT Audit Criteria V03

These criteria apply only to the narrow correction triggered by:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V02.md

Claude implements/tests/logs only. ChatGPT performs the independent audit.

## Pass/fail criteria

| ID | Requirement | AUDITED_PASS requires | AUDITED_FAIL if |
| --- | --- | --- | --- |
| AC-M09D-001 | Dot-segment normalization | Filesystem identity comparison simplifies `.` and `..` segments before alias decisions. | `source.png` vs `./source.png` or equivalent `dir/../...` forms can bypass alias checks. |
| AC-M09D-002 | Relative/absolute identity | Relative paths are resolved against one explicit base consistent with importer file-access semantics before comparison with absolute/globalized paths. | Equivalent relative and absolute paths compare as different identities. |
| AC-M09D-003 | Source immutability | Equivalent-path aliases to source are rejected before writes, including with `overwrite=true`, and source bytes remain unchanged. | Any equivalent path can authorize source destruction. |
| AC-M09D-004 | Destination isolation | Output/preview/metadata equivalent paths are rejected even when represented with different dot segments or relative forms. | Two derived artifacts can resolve to the same physical target. |
| AC-M09D-005 | Existing safety behavior preserved | V02 PNG gate, all-artifact preflight, unchanged detection, reconstruction guards, exact-pixel/deterministic semantics remain unchanged. | Narrow correction regresses any already-closed finding. |
| AC-M09D-006 | Targeted test specificity | Tests construct syntactically different paths that resolve to the same TEST file/destination and prove the named alias property directly. | Tests only repeat exact-string equality cases. |
| AC-M09D-007 | Fail-closed limitation handling | Any path class that cannot be safely canonicalized is rejected or explicitly constrained/documented rather than silently assumed safe. | Code claims canonical identity without actually resolving it. |
| AC-M09D-008 | Validation traceability | Claude log records baseline, targeted path tests, full regression total, CLI alias check, diff/status, commit/push. | Aggregate total replaces named evidence. |
| AC-M09D-009 | Scope integrity | Only path identity safety, targeted tests/docs/task/coordination change. | M09-C002, M08, M10, gameplay, art ingestion, or unrelated refactors begin. |
| AC-M09D-010 | Task truth | SB-M09-017 is considered closed only after targeted correction checks pass; SB-M09-018..020 and M08 remain open. | Task ledger overstates completion. |

## Mandatory audit learnings

Claude must read and apply:

- `AL-009` validation traceability;
- `AL-010` path alias/source immutability;
- `AL-012` multi-artifact overwrite safety;
- `AL-013` filesystem identity normalization.

Audit index:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

## Independent-audit note

Claude-run Godot results are implementation evidence. ChatGPT will independently inspect the path-normalization implementation, diff, test specificity, task truth, and coordination evidence before assigning the next audit verdict.