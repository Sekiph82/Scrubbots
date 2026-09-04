---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-audit
cycleId: M09-C002
version: 2
createdAt: 2026-09-04T08:54:00+03:00
actor: CHATGPT
status: CHANGES_REQUIRED
milestone: M09
taskRefs:
  - SB-M09-018
  - SB-M09-019
  - SB-M09-020
auditedPromptVersions: [1, 2]
auditedImplementationHead: a95ca5bff646e9e8f2a1382303be2df14d847ace
---

# SCRUBBOTS - M09-C002 ChatGPT Independent Audit V02

## Decision

`CHANGES_REQUIRED`

The V02 correction closes all five findings from ChatGPT audit V01 at the code level:

- destination parent directories are preflighted read-only;
- missing/non-directory/unopenable catalog roots fail closed;
- malformed and duplicate catalog state invalidates overall validation;
- catalog ownership is protected in both ID -> path and path -> ID directions;
- optional manifest fields are type-checked before typed use.

The implementation also preserves the previously audited M09-C001 path-identity model by separating the case-preserved `_resolve_path()` used for real filesystem access from `_canonical_path()` used for identity comparison.

Claude reported 426/426 checks passing. That remains implementer-run runtime evidence. ChatGPT independently inspected the repository diff, current implementation, test design, task truth, and coordination state, but did not execute the local Godot binary.

A new deterministic preflight gap remains.

## Accepted V01 findings now closed

| Finding | Audit V02 result | Repository evidence |
| --- | --- | --- |
| F-M09B-001 missing destination parent | CLOSED for missing/non-directory parent cases | Batch preflight resolves every destination and checks its parent with `DirAccess.dir_exists_absolute()`. |
| F-M09B-002 invalid catalog root fails open | CLOSED | `catalog_root_valid` becomes false for empty/missing/non-directory/unopenable roots and `BatchResult.is_ok()` rejects the batch. |
| F-M09B-003 catalog path takeover | CLOSED | Catalog scan builds canonical path -> entry ownership and rejects different-ID takeover even with overwrite=true. |
| F-M09B-004 unhealthy catalog only informational | CLOSED | Malformed entries and duplicate declared IDs now make `BatchResult.is_ok()` false. |
| F-M09B-005 optional field type safety | CLOSED | `preview`/`metadata` string and `overwrite` boolean types are checked before request construction. |

## New finding

### F-M09B-006 - HIGH - Existing directory used as a final destination is not preflighted

The batch contract requires predictable logical filesystem failures to be discovered before any final artifact is written.

Current destination preflight checks only the destination's parent:

1. resolve output/preview/metadata path;
2. obtain `get_base_dir()`;
3. verify that parent exists and is a directory.

It does **not** reject the case where the final destination path itself already exists as a directory.

Example:

- item 0 output: `valid_parent/level_a.json`;
- item 1 output: an existing directory named `existing_dir.json`.

For item 1:

- its parent exists, so batch destination-parent preflight passes;
- `LevelImporter.run_import(dry_run=true)` does not perform the physical file write, so it can reach an otherwise successful dry-run;
- commit then writes item 0 successfully;
- item 1 attempts to open a directory path as a file and deterministically fails;
- because the design intentionally has no filesystem rollback, item 0 remains committed.

The same class applies to preview and metadata destinations.

This is not a race-like disk-full/permission-change failure. The target being a directory is knowable before commit and must be part of logical preflight.

### Required correction

Before commit, for every requested final destination:

- resolve it with the same case-preserved `LevelImporter._resolve_path()` used for real filesystem calls;
- if the final resolved destination itself is an existing directory, reject the item with an actionable error;
- perform this check read-only in validation-only mode;
- ensure the whole batch fails before any final write;
- cover output, preview, and metadata destination roles;
- prove a failing later item leaves an earlier valid item's artifact absent;
- preserve normal behavior for existing regular files, including audited overwrite/unchanged semantics.

Do not claim general writability/permission guarantees that are not actually preflighted. This correction is specifically about deterministic destination type identity.

## Test review

Claude's V02 tests specifically cover the five V01 findings and are materially stronger than V01. However, no test constructs an existing **directory as the destination path itself**, so the current 426-check suite cannot detect F-M09B-006.

The correction tests must isolate this exact failure mode rather than fail because the parent directory is missing or because of an unrelated catalog/manifest error.

## Scope review

The correction diff remains within M09-C002 tooling/tests/docs/task/coordination scope. No M08, M10, M11+, gameplay, routing, or owner-art work was introduced.

## Task truth impact

`SB-M09-018` and `SB-M09-019` are not independently accepted yet because batch commit/validation still has a deterministic preflight hole. `SB-M09-020` duplicate-ID protection is materially corrected, but the M09-C002 coordination cycle remains open until F-M09B-006 passes independent audit.

Do not begin another milestone.

## Reusable audit learning

Add:

- `AL-017`: filesystem preflight must validate both destination parent type and the destination object's own incompatible type. Checking only the parent can still allow deterministic mid-commit failure and partial batch writes.

## Next action

Claude must implement the narrow correction in `CHATGPT_PROMPT_V03.md`, run the targeted and full regression validation, append evidence to `CLAUDE_IMPLEMENTATION_LOG.md`, return M09-C002 to `AWAITING_AUDIT`, and stop.
