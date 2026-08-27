---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-audit
cycleId: M09-C001
version: 2
createdAt: 2026-08-28T00:02:00+03:00
actor: CHATGPT
status: CHANGES_REQUIRED
milestone: M09
taskRefs:
  - SB-M09-001
  - SB-M09-002
  - SB-M09-003
  - SB-M09-004
  - SB-M09-005
  - SB-M09-006
  - SB-M09-007
  - SB-M09-008
  - SB-M09-009
  - SB-M09-010
  - SB-M09-011
  - SB-M09-012
  - SB-M09-013
  - SB-M09-014
  - SB-M09-015
  - SB-M09-016
  - SB-M09-017
auditedPromptVersions: [2]
auditedCommit: 61172cee24c3996729370cfbba4f54f3c2f9833d
---

# SCRUBBOTS - M09-C001 ChatGPT Independent Audit V02

## Decision

`CHANGES_REQUIRED`

The V02 correction pass successfully closes the PNG-format gate, multi-artifact preflight/overwrite behavior, malformed reconstruction safety, and the obvious exact-string path collision cases. However, source immutability is not yet fully proven because `_canonical_path()` does not normalize `.` / `..` path segments or general relative paths into one stable filesystem identity before alias comparison.

This leaves a real bypass in the very safety property the correction was intended to establish: two syntactically different paths may still identify the same file.

Claude's reported `320/320` result is implementer-run evidence. ChatGPT independently inspected the V02 repository diff, current importer code, V02 test design, implementation log, task truth, and coordination state, but did not execute the local Godot binary in this audit environment.

## Evidence reviewed

- V02 prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V02.md
- V02 audit criteria: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_CRITERIA_V02.md
- Prior audit V01: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V01.md
- Claude implementation log: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CLAUDE_IMPLEMENTATION_LOG.md
- V02 correction implementation commit: https://github.com/Sekiph82/Scrubbots/commit/84eebefddbcac35b28410e9db2e4052e3190eb6a
- V02 log-backfill head: https://github.com/Sekiph82/Scrubbots/commit/61172cee24c3996729370cfbba4f54f3c2f9833d
- Current importer: https://github.com/Sekiph82/Scrubbots/blob/main/scripts/tools/level_importer.gd
- Current tests: https://github.com/Sekiph82/Scrubbots/blob/main/tests/run_tests.gd
- Task ledger: https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
- Audit index: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

Independent correction diff reviewed:

https://github.com/Sekiph82/Scrubbots/compare/7634ec92459b8a235d77f053ddc72c66d256d111...61172cee24c3996729370cfbba4f54f3c2f9833d

The correction diff remains inside M09-C001 importer safety/tests/docs/task/coordination scope. No M09-C002, M08 content ingestion, M10, gameplay, slot, routing, or owner-art work was introduced.

## V01 finding closure review

| Finding | V02 audit result | Evidence |
| --- | --- | --- |
| F-M09-001 source/artifact aliasing | `PARTIAL / AUDITED_FAIL` | Direct same-string aliases, `res://`/`user://`, separator normalization, and Windows case folding were added. But `.` / `..` and general relative-path identity remain unnormalized. |
| F-M09-002 multi-artifact overwrite safety | `AUDITED_PASS` | All artifacts are built/preflighted before writes; preview and metadata collision/unchanged paths now have explicit handling and targeted tests. |
| F-M09-003 PNG-only gate | `AUDITED_PASS` | Core rejects valid JPEG by extension with an unsupported-format error, corrupt `.png` separately fails decode, uppercase `.PNG` is accepted. |
| F-M09-004 malformed reconstruction safety | `AUDITED_PASS` | Null, dimensions, empty/invalid palette, exact cell count, and palette-ID range are checked before indexed reconstruction. |

## New finding

### F-M09-005 - HIGH - Path identity is not fully canonicalized

Current `_canonical_path()`:

1. globalizes `res://` and `user://`;
2. normalizes backslashes;
3. lowercases on Windows.

It does **not** simplify dot segments or normalize arbitrary relative filesystem paths to a single absolute identity before comparison.

Examples of syntactically different paths that may still refer to the same file include:

- `source.png` and `./source.png`
- `dir/../source.png` and `source.png`
- an absolute path and an equivalent relative path from the process/project working directory
- destination-to-destination variants using the same `.` / `..` trick

Because `_check_path_aliases()` compares the returned strings directly, one of these equivalent paths can evade the alias preflight. With `overwrite=true`, that can still violate the locked source-immutability contract.

The V02 alias tests cover exact same-path combinations but do not isolate dot-segment/equivalent-relative aliases, so the green runtime total does not prove this edge case.

### Required correction

Continue the same cycle with V03.

Normalize path identity using a Godot-supported path simplification/canonicalization approach before alias comparison. At minimum:

- resolve `res://` and `user://`;
- normalize relative paths against one explicit base that matches actual FileAccess/Image path semantics for this tool;
- simplify `.` and `..` segments;
- normalize separators;
- preserve Windows case-insensitive comparison behavior;
- keep source identity separate from all derived destination identities;
- keep destination identities pairwise distinct.

Do not rely on filename string equality alone.

Add targeted tests where the exact same physical TEST file is referenced through syntactically different equivalent paths, including at least a `./` or `../` source alias and a destination-to-destination equivalent-path alias. Verify rejection occurs before any writes and source bytes remain unchanged, including with `overwrite=true`.

If Godot cannot reliably resolve a particular filesystem identity category, fail closed for that category and document the limitation rather than claiming a stronger guarantee.

## Requirement-by-requirement V02 audit

| Criterion | Result | Notes |
| --- | --- | --- |
| AC-M09C-001 Source immutability | `AUDITED_FAIL` | Exact-string aliases are blocked, but equivalent dot-segment/relative aliases can bypass string comparison. |
| AC-M09C-002 Cross-artifact path isolation | `AUDITED_FAIL` | Same root cause for equivalent destination paths. |
| AC-M09C-003 Safe overwrite preflight | `AUDITED_PASS` | Collision preflight now occurs before writes for known distinct identities. |
| AC-M09C-004 Deterministic unchanged behavior | `AUDITED_PASS` | Level JSON, preview, and metadata unchanged handling is present and specifically tested. |
| AC-M09C-005 Explicit PNG-only gate | `AUDITED_PASS` | Valid JPEG rejected as unsupported; `.PNG` accepted. |
| AC-M09C-006 Corrupt PNG distinction | `AUDITED_PASS` | Corrupt `.png` is tested as decode failure, separate from format rejection. |
| AC-M09C-007 Malformed reconstruction safety | `AUDITED_PASS` | Safety checks precede cell indexing. |
| AC-M09C-008 Regression preservation | `NOT_INDEPENDENTLY_EXECUTED` | Claude reports 320/320; code/diff review shows prior semantics retained. |
| AC-M09C-009 Test specificity | `AUDITED_FAIL` | Existing alias tests do not test equivalent syntactic paths for the same filesystem target. |
| AC-M09C-010 Task truth | `CHANGES_REQUIRED` | SB-M09-017 must not be treated as finally audited until F-M09-005 closes. |
| AC-M09C-011 Validation traceability | `AUDITED_PASS` | V02 implementation log records the correction sequence and named checks. |
| AC-M09C-012 Scope integrity | `AUDITED_PASS` | Correction scope remains narrow. |

## Reusable audit learning

Add:

- `AL-013`: **Filesystem identity normalization.** Path-safety checks must compare normalized filesystem identities, not merely cosmetically normalized strings. Dot segments and relative-vs-absolute equivalents must be challenged explicitly when overwrite/source immutability matters.

## Task-truth impact

- SB-M09-001..016 remain substantively implemented.
- SB-M09-017 is not independently closed while source immutability/path safety remains bypassable through equivalent-path syntax. V03 must correct and revalidate it.
- SB-M09-018..020 remain open.
- M08 remains open / owner-asset-dependent.
- M10 remains owner-controlled.

## Next action

ChatGPT publishes `CHATGPT_PROMPT_V03.md` and `CHATGPT_AUDIT_CRITERIA_V03.md` in the same cycle.

Claude must implement/test/log only, append to the existing implementation log, update Session Index and H!veAI dashboard, set the cycle back to `AWAITING_AUDIT`, push safely, and stop.

Only ChatGPT may publish the next audit verdict.