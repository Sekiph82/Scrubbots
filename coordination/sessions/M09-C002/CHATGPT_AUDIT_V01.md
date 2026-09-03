---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-audit
cycleId: M09-C002
version: 1
createdAt: 2026-09-03T11:38:00+03:00
actor: CHATGPT
status: CHANGES_REQUIRED
milestone: M09
taskRefs:
  - SB-M09-018
  - SB-M09-019
  - SB-M09-020
auditedPromptVersions: [1]
auditedImplementationHead: bf5113d44a18252b1351e08337e363d120335135
---

# SCRUBBOTS - M09-C002 ChatGPT Independent Audit V01

## Decision

`CHANGES_REQUIRED`

The batch architecture has several strong properties: it reuses the audited single importer, preserves manifest order, performs cross-item canonical path checks, detects duplicate IDs within the manifest and against catalog IDs, supports validation-only mode, and documents that commit is not an OS-level transaction.

However, independent repository inspection found predictable preflight and catalog-integrity gaps that can allow a supposedly preflighted batch to partially commit or can bypass catalog ownership protection. Claude's reported `394/394` result remains implementer-run evidence; ChatGPT inspected the repository code, diff, test design, task truth and coordination state independently but did not execute the local Godot binary.

## Findings

### F-M09B-001 - HIGH - Predictable missing destination parent directories are not preflighted

The active prompt requires all predictable logical failures to be discovered before any final batch artifact is written.

`LevelImporter.run_import(dry_run=true)` skips the actual write calls and does not verify that the parent directory for output/preview/metadata exists. `LevelBatchImporter` adds no destination-parent preflight.

Claude's own implementation log records that the first batch commit test failed because output directories did not exist. The correction was to pre-create those directories in the tests, not to make batch preflight detect the deterministic failure.

Therefore a real commit can still behave like this:

1. item 1 has an existing destination directory and writes successfully;
2. item 2 targets a missing parent directory;
3. dry-run preflight reports both items valid;
4. commit writes item 1, then deterministically fails on item 2.

That is not merely a rare OS race. It is a predictable filesystem precondition and violates `AC-M09B-005` whole-batch logical preflight.

Required correction:

- validate every requested output/preview/metadata parent directory during batch preflight;
- validation-only must not create those directories;
- a missing/non-directory parent must fail the batch before writes;
- add a failing-later-item test where the later failure is specifically a missing destination parent and prove the earlier item is not written.

### F-M09B-002 - HIGH - Missing/unopenable catalog root fails open as an empty catalog

`LevelBatchImporter.run_batch()` calls `DirAccess.open(catalog_root)` and scans only when the result is non-null. There is no error path when the configured catalog root cannot be opened.

This means a typo, missing directory, invalid path, or inaccessible catalog root silently disables catalog uniqueness checks while the batch can still report success.

That violates the configured-catalog uniqueness contract and `AC-M09B-010` fail-safe catalog validation.

Required correction:

- catalog root must be explicitly validated;
- a missing/unopenable/non-directory catalog root must make the batch result fail with an actionable catalog error;
- CLI must exit non-zero;
- validation-only and commit modes must behave consistently.

### F-M09B-003 - HIGH - Existing catalog path ownership can be stolen by a different ID with overwrite=true

The implementation builds `id -> catalog paths` and protects an incoming ID from being claimed at a different path. It does not build the inverse ownership relation, `canonical catalog path -> declared ID`.

Consequently, if the catalog contains:

`catalog/existing.json` declaring `id = old_id`

then a manifest item can request:

- `id = new_id`
- `output = catalog/existing.json`
- `overwrite = true`

Because `new_id` is not already in the ID index, the batch-level duplicate-ID check does not object. The single importer permits overwrite of a different existing derived file when `overwrite=true`, so the catalog entry can be replaced with a different logical ID.

That breaks catalog ownership semantics and the prompt's same-entry re-import rule. Same canonical path is safe only when it is unambiguously the same catalog entry, not merely because overwrite was requested.

Required correction:

- build canonical path -> catalog entry/declared ID ownership during the single catalog scan;
- if requested output aliases an existing valid catalog file, require the requested ID to equal that file's declared ID;
- a different ID at the same catalog path must fail regardless of overwrite;
- source bytes/catalog file bytes must remain unchanged after rejection;
- same ID + same canonical path must continue to follow normal unchanged/overwrite rules.

### F-M09B-004 - MEDIUM - Catalog corruption/duplicate state is reported but does not make validation fail

`BatchResult.is_ok()` checks manifest errors and item errors only. `catalog_malformed` and `catalog_duplicate_ids` do not affect the overall verdict unless a current manifest item happens to collide with one of those IDs.

The CLI can therefore emit `ok: true` and exit zero even while the configured catalog contains malformed Level Data or already contains duplicate declared IDs.

That is inconsistent with `AC-M09B-008` / `AC-M09B-010` and with the purpose of batch validation. A catalog whose identity/uniqueness state is not trustworthy must not be presented as a successful validation result.

Required correction:

- existing malformed/structurally invalid catalog entries make the batch validation fail;
- existing duplicate IDs in the scanned catalog make the batch validation fail;
- retain deterministic detailed reports with paths/errors;
- do not silently delete or repair catalog files.

### F-M09B-005 - MEDIUM - Optional manifest field types are not schema-validated

Required string fields are validated, but optional `preview`, `metadata`, and `overwrite` values are read directly into typed variables:

- `preview` should be string when present;
- `metadata` should be string when present;
- `overwrite` should be boolean when present.

Malformed JSON such as `"preview": 42` or `"overwrite": "yes"` must produce an actionable manifest/item validation error, not a typed-assignment/runtime failure or implicit coercion.

Required correction:

- explicitly validate optional field types before constructing `ImportRequest`;
- add isolated negative tests for each invalid optional type;
- malformed manifest data must fail cleanly with no writes.

## Accepted behavior that must not regress

The following parts of M09-C002 V01 are accepted and should be preserved during correction:

- reuse of `LevelImporter` rather than a second conversion pipeline;
- deterministic manifest-order processing/reporting;
- validation-only physical no-write behavior for valid paths;
- duplicate ID detection within a manifest;
- requested ID collision against a different catalog file;
- existing duplicate-ID path reporting;
- cross-item source/destination canonical alias checks;
- same-ID same-canonical-path re-import concept;
- PNG/readability/difficulty/exact-pixel behavior inherited from M09-C001;
- deterministic unchanged rerun behavior;
- bounded non-transactional OS-failure documentation;
- no owner artwork ingestion/fabrication;
- M08/M10/gameplay scope remained untouched.

## Task truth

`SB-M09-018`, `SB-M09-019`, and `SB-M09-020` must be treated as reopened for correction because `[x]` in `tasks.md` means completed and validated. The current independent audit shows the batch import/validation/uniqueness guarantees are not yet fully validated.

## Reusable audit learnings

- `AL-014`: Dry-run/preflight must validate deterministic filesystem preconditions it claims to cover. Test setup must not hide a predictable commit failure by pre-creating the missing condition.
- `AL-015`: Catalog validation must fail closed. Validate both ID -> path and path -> ID ownership, and never treat an unreadable/invalid catalog as an empty trustworthy catalog.
- `AL-016`: Manifest schema validation includes optional field types. Invalid user JSON must become structured validation evidence, never a runtime type fault.

## Next action

Claude should follow `CHATGPT_PROMPT_V02.md` in this same cycle, implement only the corrections above, extend the existing test suite, append evidence to `CLAUDE_IMPLEMENTATION_LOG.md`, and return M09-C002 to `AWAITING_AUDIT` for ChatGPT audit V02.
