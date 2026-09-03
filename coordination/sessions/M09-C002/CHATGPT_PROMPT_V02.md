---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-prompt
cycleId: M09-C002
version: 2
createdAt: 2026-09-03T11:38:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M09
supersedes: CHATGPT_PROMPT_V01.md
triggerAudit: CHATGPT_AUDIT_V01.md
auditedImplementationHead: bf5113d44a18252b1351e08337e363d120335135
taskRefs:
  - SB-M09-018
  - SB-M09-019
  - SB-M09-020
---

# SCRUBBOTS - M09-C002 Batch Safety and Catalog Integrity Correction V02

## Objective

Close every finding from ChatGPT independent audit V01 without expanding M09-C002 scope.

The existing batch architecture is substantially useful and should be corrected, not replaced. Preserve the accepted behavior from V01 while fixing deterministic preflight fidelity, fail-closed catalog validation, bidirectional catalog ownership, and manifest schema type safety.

Do not start another milestone.

## Mandatory GitHub sources

Read these before changing code:

1. Independent audit V01:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V01.md
2. Correction audit criteria V02:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_CRITERIA_V02.md
3. This active prompt V02:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_PROMPT_V02.md
4. Audit learning index:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
5. Canonical task truth:
   https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
6. Current batch implementation:
   https://github.com/Sekiph82/Scrubbots/blob/main/scripts/tools/level_batch_importer.gd
7. Audited single importer:
   https://github.com/Sekiph82/Scrubbots/blob/main/scripts/tools/level_importer.gd
8. Batch CLI:
   https://github.com/Sekiph82/Scrubbots/blob/main/tools/import_level_batch.gd
9. Current implementation log:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CLAUDE_IMPLEMENTATION_LOG.md
10. Level Data spec:
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/03_LEVEL_DATA_SPEC.md
11. Test strategy:
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/06_TEST_STRATEGY.md
12. Session index:
    https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
13. H!veAI dashboard:
    https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md

## Audit learnings to apply

Explicitly apply and log:

- `AL-009`
- `AL-010`
- `AL-011`
- `AL-012`
- `AL-013`
- `AL-014`
- `AL-015`
- `AL-016`

## Locked scope

This is a correction pass inside `M09-C002` only.

Do not start:

- M08 artwork audit/intake;
- M10 owner visual approval;
- M11 gameplay session core;
- slots, routing, agents, progression, saves, mobile export;
- runtime LevelCatalog/M30 work;
- owner-art ingestion.

Do not rewrite the audited M09-C001 pixel conversion semantics.

## Correction 1 - Preflight destination parent directories

The batch logical preflight must detect missing/non-directory destination parents before any final artifact write.

For every requested final destination:

- Level JSON output;
- preview PNG when requested;
- metadata sidecar when requested;

resolve the path using the same filesystem identity model already used by M09-C001 and validate the destination parent.

Requirements:

1. The parent must exist before commit.
2. The parent must actually be a directory.
3. Validation-only mode must not create the parent directory.
4. Batch commit must not auto-create a missing parent as a hidden side effect unless a future explicit design changes this contract.
5. A missing/non-directory parent is a predictable logical validation failure and must block the entire batch before any item writes.
6. Continue documenting genuinely race-like OS failures after successful preflight as non-transactional limitations. Do not use that limitation to classify a missing parent as an unpredictable OS failure.

Do not merely modify tests to pre-create every directory. The production preflight itself must enforce this rule.

## Correction 2 - Catalog root must fail closed

The configured `catalog_root` is part of the uniqueness authority for this tooling run.

Requirements:

1. Missing catalog root must fail.
2. Unopenable catalog root must fail.
3. A path that is not a directory must fail.
4. Failure must be represented in structured batch reporting with an actionable message.
5. `BatchResult.is_ok()` must be false.
6. CLI exit code must be non-zero in both validation-only and commit mode.
7. No final artifact writes may occur.

Do not silently reinterpret an invalid root as an empty catalog.

## Correction 3 - Catalog health is part of validation truth

A catalog containing malformed/structurally invalid Level Data or duplicate declared IDs is not a clean validation state.

Requirements:

1. Preserve deterministic `catalog_malformed` reporting with paths/errors.
2. Preserve deterministic duplicate-ID reporting with all paths.
3. Any malformed/structurally invalid catalog entry makes overall batch validation fail.
4. Any existing duplicate declared ID in the scanned catalog makes overall batch validation fail.
5. CLI must exit non-zero.
6. Do not delete, rewrite, or repair those catalog files automatically.
7. Report enough information for a human/developer to resolve them.

If a separate `catalog_errors` / `catalog_valid` field improves clarity, add it to the batch report without polluting Level Data V1.

## Correction 4 - Protect catalog path ownership as well as ID ownership

The catalog scan must establish both directions:

- declared Level Data ID -> canonical catalog path(s);
- canonical catalog path -> declared Level Data ID / entry status.

For each batch request:

1. If requested ID belongs to another catalog path, preserve the existing rejection.
2. If requested output path aliases an existing valid catalog file, the requested ID must equal that existing file's declared ID.
3. A different ID targeting that same catalog path must fail even when `overwrite=true`.
4. Same ID + same canonical output path remains the explicit same-entry re-import case and continues to obey the audited single-import unchanged/overwrite behavior.
5. If requested output aliases an existing malformed/structurally invalid catalog file, fail closed because ownership cannot be safely established.
6. Rejection must occur during preflight, before any writes.

Do not use filename as the ID authority. Read the Level Data through existing loader/validator behavior.

## Correction 5 - Manifest optional field type validation

Validate the manifest schema before typed use.

For each item:

- `preview`, when present, must be a string;
- `metadata`, when present, must be a string;
- `overwrite`, when present, must be a boolean.

Wrong types must:

- produce an actionable item/schema validation error;
- never cause a GDScript typed-assignment/runtime failure;
- never reach import execution;
- never write final artifacts.

Preserve the existing required-field validation.

## Batch result semantics

Review report state for clarity after the corrections.

At minimum:

- `ok` must be false for catalog-root/catalog-health/schema/preflight failures;
- validation-only mode must never report a final artifact as physically written;
- if commit is requested but a rare post-preflight OS write failure occurs, do not present a misleading full-success `committed` flag;
- if useful, define `committed` explicitly as "all requested commit writes completed successfully" and use written/error counts to represent partial OS failure accurately.

Do not claim transaction/rollback support.

## Required targeted automated tests

Keep all existing tests. Add isolated tests for at least:

1. Later item has a missing Level JSON parent directory; earlier valid item has a valid parent. Batch preflight fails and earlier item is not written.
2. Missing preview parent blocks whole batch before writes.
3. Missing metadata parent blocks whole batch before writes.
4. Validation-only missing-parent case creates neither directory nor final file.
5. Missing catalog root returns overall failure and CLI non-zero.
6. Catalog-root path that is a file/non-directory is rejected.
7. Malformed catalog entry unrelated to requested IDs still makes overall validation fail and remains reported.
8. Structurally invalid catalog entry unrelated to requested IDs still makes overall validation fail and remains reported.
9. Existing catalog duplicate ID unrelated to requested IDs still makes overall validation fail and reports both paths.
10. Existing valid catalog file declares `old_id`; batch requests `new_id` at that exact canonical output with `overwrite=true` -> reject before writes; existing file bytes unchanged.
11. Same existing file + same declared ID + same canonical output still follows allowed unchanged/overwrite semantics.
12. Requested output aliases a malformed catalog file -> fail closed; file unchanged.
13. `preview: 42` -> clean schema error, no crash/write.
14. `metadata: {}` -> clean schema error, no crash/write.
15. `overwrite: "yes"` -> clean schema error, no crash/write.
16. Existing V01 duplicate-ID-within-batch behavior still passes.
17. Existing canonical cross-item path safety still passes.
18. Existing validation-only happy path still writes nothing.
19. Existing commit + unchanged-rerun behavior still passes.
20. All previous M09-C001 regression checks remain green.

Negative tests must prove the named failure mode directly and prove no earlier final artifact was written where whole-batch preflight is the property under test.

## Real CLI validation

Run real CLI cases for at least:

- happy validation-only;
- happy commit;
- missing destination parent;
- missing/invalid catalog root;
- malformed catalog health failure;
- catalog path takeover attempt with `overwrite=true`;
- invalid optional manifest type.

Record exit code and no-write evidence for each negative case.

## Documentation

Update durable docs to match the corrected behavior, especially:

- `docs/03_LEVEL_DATA_SPEC.md`
- `docs/06_TEST_STRATEGY.md`
- `CHANGELOG.md`

Document:

- destination parent directories are a preflight requirement and are not auto-created;
- invalid catalog root fails closed;
- malformed/duplicate catalog state makes validation fail;
- catalog ownership protects both IDs and canonical paths;
- optional manifest field types;
- bounded non-transactional limitation after successful logical preflight.

## tasks.md truth

ChatGPT audit V01 reopens `SB-M09-018`, `SB-M09-019`, and `SB-M09-020` because the current implementation is not yet fully validated against the batch contract.

Only restore them to `[x]` after all V02 corrections and required tests pass.

Do not change M08, M10, or later task status.

## Logging

Append this correction session to:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CLAUDE_IMPLEMENTATION_LOG.md

Claude implements/tests/logs only. Do not create or edit ChatGPT audit files.

Before ending, update:

- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md

Set M09-C002 to `AWAITING_AUDIT` only after the correction, tests, docs, task truth and log are complete.

## Mandatory final validation

Record each item individually with expected outcome, fail condition, actual result and classification:

1. `godot --version`
2. `powershell -File tools\\verify_project.ps1`
3. `godot --headless --path . --quit-after 5`
4. `godot --headless --path . -s res://tests/run_tests.gd`
5. Real CLI happy validation-only batch.
6. Prove happy validation-only creates no final artifacts.
7. Real CLI happy commit and unchanged rerun.
8. Real CLI missing-later-parent rejection; prove earlier item is not written.
9. Real CLI missing catalog root rejection.
10. Real CLI malformed catalog health rejection.
11. Real CLI existing catalog duplicate health rejection.
12. Real CLI different-ID same-catalog-path takeover rejection with `overwrite=true`; prove existing bytes unchanged.
13. Real CLI same-ID same-catalog-path re-import still works under normal unchanged/overwrite semantics.
14. Real CLI invalid optional manifest type rejection without runtime crash.
15. Confirm no owner SCRUBBOTS artwork was fabricated/ingested.
16. `git diff --check`
17. Inspect final diff for scope integrity and accidental binaries/temp/cache.
18. `git status --short` before commit.
19. Commit with a precise M09-C002 V02 correction message.
20. Push to `origin/main` without force.
21. Final `git status --short` and record commit/push evidence.

## Stop condition

After V02 is implemented, tested, documented, logged, pushed, and M09-C002 is `AWAITING_AUDIT`, stop.

Do not start another cycle or milestone.
