---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-audit-criteria
cycleId: M09-C001
version: 2
createdAt: 2026-08-27T23:47:00+03:00
actor: CHATGPT
status: ISSUED
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
---

# SCRUBBOTS - M09-C001 ChatGPT Audit Criteria V02

These criteria apply to the correction pass triggered by:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V01.md

Claude implements/tests/logs only. ChatGPT performs the independent audit.

## Correction gate

M09-C001 cannot become `AUDITED_PASS` until F-M09-001 through F-M09-004 are closed without regressing the already-correct deterministic importer behavior.

## Pass/fail criteria

| ID | Requirement | AUDITED_PASS requires | AUDITED_FAIL if |
| --- | --- | --- | --- |
| AC-M09C-001 | Source immutability | Source path can never be a write destination, even with `overwrite=true`; alias attempts fail before writes and source bytes remain identical. | Any request can overwrite or modify the source. |
| AC-M09C-002 | Cross-artifact path isolation | Canonicalized output/preview/metadata paths must be pairwise distinct and distinct from source. | Equivalent/aliased paths can cause one artifact to replace another. |
| AC-M09C-003 | Safe overwrite preflight | With `overwrite=false`, all requested derived destinations are preflighted before writes; existing different artifacts cause clean failure. | Level output is written before a known preview/metadata collision is discovered, or preview/metadata overwrite existing different files by default. |
| AC-M09C-004 | Deterministic unchanged behavior | Existing identical Level JSON, preview, and metadata can be recognized as unchanged/no-write where implemented; reruns do not create meaningless content changes. | Rerun needlessly rewrites artifacts or reports success after replacing an unrelated file. |
| AC-M09C-005 | Explicit PNG-only gate | Reusable importer core rejects valid non-PNG image input with an actionable unsupported-format error; `.png` matching is case-insensitive. | A valid JPEG/WebP/BMP or other supported Godot image is accepted by M09-C001 importer. |
| AC-M09C-006 | Corrupt PNG distinction | A corrupt/unreadable file named `.png` fails as unreadable/corrupt input, separately from unsupported-format rejection. | One test conflates unsupported extension with corrupt content. |
| AC-M09C-007 | Malformed reconstruction safety | `reconstruct_image()` rejects invalid dimensions/palette/cell-count/palette-ID inputs cleanly without out-of-bounds runtime failure. | Short cells or malformed palette state can trigger unsafe indexing/runtime error. |
| AC-M09C-008 | Regression preservation | First-seen palette ordering, row-major cells, Level Data V1 schema, TEST/production split, alpha round-trip, 20x27 rectangle, 59x59 maximum, CLI import, and deterministic Level JSON behavior remain intact. | Correction changes core semantics or existing tests regress. |
| AC-M09C-009 | Test specificity | New tests isolate each failure mode: source alias, destination alias, preview collision, metadata collision, valid unsupported format, corrupt PNG, malformed reconstruction. | Tests pass for an unrelated reason and do not prove the named safety property. |
| AC-M09C-010 | Task truth | SB-M09-017 is not considered complete until all correction tests and final validation pass; SB-M09-018..020 and M08 remain open. | Checklist overstates completion. |
| AC-M09C-011 | Validation traceability | Implementation log records each correction test and the full final validation sequence with expected/fail/actual/classification. | Aggregate totals substitute for the required safety evidence. |
| AC-M09C-012 | Scope integrity | Only M09-C001 importer safety/tests/docs/task/coordination work changes. | M09-C002, M08 content ingestion, M10, gameplay, slots, routing, or owner-art work begins. |

## Mandatory audit learnings

Claude must read and apply:

- `AL-009` validation traceability;
- `AL-010` path aliasing/source immutability;
- `AL-011` negative-test specificity;
- `AL-012` multi-artifact overwrite safety.

Audit index:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

## Independent-audit note

Claude-run Godot results remain implementation evidence. ChatGPT will independently inspect code, diffs, test design, path-safety semantics, task truth, and repository state; where local Godot execution is unavailable to ChatGPT, runtime totals will be labeled accordingly rather than silently treated as independently executed proof.
