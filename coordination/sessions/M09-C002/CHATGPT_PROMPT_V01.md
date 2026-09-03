---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-prompt
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
baselineCommit: 333bac8a4fefd2aafe6c2279b3093c304f6f47fd
---

# SCRUBBOTS - M09-C002 Batch Import, Batch Validation, and Duplicate-ID Protection

## Objective

Complete the remaining M09 tooling tasks by adding a deterministic, safe batch layer on top of the audited M09-C001 single-image importer.

This cycle targets only:

- `SB-M09-018` Batch import;
- `SB-M09-019` Batch validation;
- `SB-M09-020` Duplicate level ID protection.

M09-C001 is already `AUDITED_PASS`. Preserve its exact-pixel, deterministic, PNG-only, path-safety, overwrite, reconstruction, and validation contracts rather than reimplementing them inconsistently.

## Mandatory GitHub sources

Read these before changing code:

1. Agent governance:
   https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md
2. Canonical task truth:
   https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
3. H!veAI dashboard:
   https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
4. Coordination protocol:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/README.md
5. Session index:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
6. Audit policy:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md
7. Audit learning index:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
8. M09-C001 final independent audit:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V03.md
9. This cycle's audit criteria:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_CRITERIA_V01.md
10. This active prompt:
    https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_PROMPT_V01.md
11. Audited single importer:
    https://github.com/Sekiph82/Scrubbots/blob/main/scripts/tools/level_importer.gd
12. Single-import CLI:
    https://github.com/Sekiph82/Scrubbots/blob/main/tools/import_level.gd
13. Level loader:
    https://github.com/Sekiph82/Scrubbots/blob/main/scripts/data/level_loader.gd
14. Level Data V1 spec:
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/03_LEVEL_DATA_SPEC.md
15. Test strategy:
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/06_TEST_STRATEGY.md
16. Existing TEST level directory:
    https://github.com/Sekiph82/Scrubbots/tree/main/data/levels

## Audit learnings to apply

At minimum apply and explicitly log:

- `AL-005`: task completion requires behavioral evidence, not file existence;
- `AL-006`: do not fabricate owner artwork;
- `AL-008`: do not invent metadata/provenance;
- `AL-009`: individually log every required validation step;
- `AL-010`: all source/output path identities must remain safely canonicalized;
- `AL-011`: negative tests must isolate the failure mode they claim;
- `AL-012`: overwrite safety applies to every generated artifact;
- `AL-013`: filesystem identity comparison must account for dot segments and relative/absolute equivalents.

## Locked scope

Do not start M08, M10, M11, M12, routing, gameplay agents, progression, saves, mobile export, or artwork ingestion.

Do not add a runtime `LevelCatalog`; that belongs to later architecture. M09-C002 may implement a tooling-only catalog scan/index used solely to validate Level Data files and uniqueness.

Do not ingest or generate owner SCRUBBOTS artwork. All batch tests must use deterministic TEST-generated PNGs and/or existing TEST Level Data fixtures.

## Batch interface

Implement a reusable batch service plus a thin headless/developer CLI entrypoint.

Prefer a manifest-driven batch API rather than relying on ambiguous filename inference.

A batch manifest should be deterministic JSON with an ordered array of import requests. Each request should provide the same essential fields as the audited single importer, for example:

- `source`
- `id`
- `name`
- `difficulty`
- `output`
- optional `preview`
- optional `metadata`
- optional `overwrite`

Do not add fields to Level Data V1 itself.

Document the exact manifest schema actually implemented.

Relative request paths must follow one explicit resolution rule consistent with the audited importer. Do not introduce a second conflicting path-identity model.

## Reuse the audited single importer

The batch layer must reuse the single-import conversion/validation semantics rather than copying palette extraction, row-major mapping, PNG loading, difficulty bands, reconstruction, or artifact safety logic into a second implementation.

If the existing single importer needs a small refactor to expose a validation/preparation phase for safe batch preflight, keep it narrow and preserve all M09-C001 behavior/tests.

Do not weaken:

- PNG-only source gate;
- one RGBA8 pixel = one cell;
- deterministic first-seen palette order;
- row-major cells;
- Level Data V1 schema;
- source immutability;
- path alias detection;
- all-artifact overwrite preflight;
- unchanged/no-write behavior;
- TEST vs production validation;
- reconstruction safety.

## Batch validation

Implement a validation-only mode that performs the complete logical batch validation without committing derived artifacts.

Validation must report item-specific actionable failures and a batch summary.

At minimum validate:

- manifest syntax/schema;
- empty batch;
- required request fields;
- source format/readability through the same single-import rules;
- per-item difficulty/dimension legality;
- source/output/preview/metadata path safety;
- duplicate output destinations across the batch, using canonical filesystem identity;
- duplicate level IDs within the batch;
- duplicate level IDs against the configured/existing Level Data catalog;
- existing duplicate IDs already present inside the scanned catalog;
- malformed existing catalog JSON/Level Data in a way that is reported rather than silently ignored.

Batch validation must not mutate source images or write final output artifacts.

## Duplicate level-ID protection

`SB-M09-020` requires uniqueness beyond a single manifest item.

Implement tooling-level uniqueness checks with these rules:

1. Two batch requests with the same `id` are rejected before writes.
2. Catalog scan reads Level Data V1 JSON files through existing loader/validator behavior where practical; do not trust filename as the ID authority.
3. If two existing catalog files declare the same Level Data `id`, validation reports the duplicate with both paths.
4. A new request whose `id` already belongs to a different catalog file is rejected.
5. Re-importing the same logical level to the same canonical output path may be allowed only when it is unambiguously the same catalog entry and normal overwrite/unchanged rules permit it. Do not treat a different file with the same ID as safe merely because `overwrite=true`.
6. TEST fixtures and production levels both participate in ID uniqueness within whatever catalog root is explicitly being validated; do not silently exclude TEST by filename convention.

Do not implement M30 runtime level selection/catalog responsibilities.

## Safe batch write behavior

All predictable logical failures must be discovered before final derived artifacts are written.

At minimum, batch import must complete a preflight over the entire manifest for:

- schema/request validity;
- source readability/format;
- difficulty legality;
- duplicate IDs;
- duplicate/aliased destinations;
- catalog ID collisions;
- overwrite collisions that can be determined before writing.

If any preflight item fails, final derived artifacts for that batch must not be committed.

Do not claim true filesystem transaction/rollback semantics unless actually implemented and tested. If a rare OS write failure can still leave a partial commit after successful logical preflight, document that limitation accurately rather than hiding it.

Prefer a prepare/validate-then-commit architecture if it fits the existing importer cleanly.

## Determinism

For the same manifest, catalog state, and source inputs:

- validation result ordering must be deterministic;
- batch processing order must be deterministic;
- per-item output must retain M09-C001 deterministic semantics;
- rerunning an unchanged batch must not create meaningless content changes;
- summary/report ordering must be stable.

Preserve manifest order unless there is a documented, tested reason to use another stable order.

## Batch result/reporting

Return/report enough structured information to identify:

- overall success/failure;
- total requested items;
- valid/invalid counts;
- written/unchanged counts where applicable;
- per-item ID/source/output;
- per-item errors;
- duplicate-ID collisions and paths;
- whether the run was validation-only or commit mode.

CLI exit code must be non-zero on batch validation/import failure.

Do not print a green summary that hides individual failed items.

## Required automated test matrix

Extend the existing headless suite. Keep all prior 332 checks.

Add behavior tests for at least:

### Happy path

1. Batch of at least 3 deterministic PNGs, including:
   - tiny non-square TEST;
   - rectangular legal production-band fixture;
   - 59x59 maximum fixture.
2. Validation-only succeeds and writes no final derived artifacts.
3. Commit mode imports all items correctly.
4. Re-running unchanged batch reports unchanged/no meaningless writes.
5. Per-item reconstructed raw RGBA8 equality remains valid, directly or through preserved single-import tests.

### Duplicate ID safety

6. Duplicate ID inside one manifest fails before writes.
7. Duplicate ID against a different existing catalog file fails before writes.
8. Existing catalog containing two files with the same declared ID is detected and reported.
9. Same logical ID at the same canonical output path follows explicit allowed re-import semantics without weakening duplicate protection.
10. `overwrite=true` does not permit a different catalog file to steal an existing ID.

### Path/output safety

11. Two batch items targeting canonically equivalent output paths (`./`, `../`, relative/absolute equivalent) fail before writes.
12. Cross-item preview/metadata/output collisions are detected, not only within one request.
13. A source path from one item cannot alias a write destination from another item.
14. With a failing later item, earlier final artifacts are not written during logical preflight.

### Invalid input/catalog

15. Malformed manifest.
16. Empty manifest.
17. Missing required item field.
18. Valid non-PNG source.
19. Corrupt PNG.
20. Malformed catalog Level Data JSON.
21. Structurally invalid catalog Level Data.

Negative tests must prove the named failure mode, not merely any failure.

## CLI validation

Provide a real headless CLI command for both:

- validation-only;
- import/commit.

The CLI should accept at least a manifest path and a catalog root/path configuration appropriate to the implemented design.

Document exact commands.

## Performance sanity

Batch-test at least a small multi-item set including 59x59. Record CPU timings only if useful.

Do not create a hard millisecond gate in this cycle.

Avoid obvious repeated full-catalog rescans per batch item. Build the tooling ID index once per batch validation/import where practical.

## Documentation

Update durable docs to match actual behavior:

- `docs/03_LEVEL_DATA_SPEC.md` or an appropriate tooling section/document;
- `docs/06_TEST_STRATEGY.md`;
- `CHANGELOG.md`;
- `docs/05_TECH_DECISIONS.md` only if a durable architecture decision genuinely warrants an ADR.

Document:

- batch manifest schema;
- validation-only mode;
- duplicate-ID rules;
- catalog-scan semantics;
- preflight/no-final-write-on-logical-validation-failure guarantee;
- any accurately bounded non-transactional filesystem limitation;
- M09-C001 single-import invariants remain authoritative.

## tasks.md truth

Only mark these complete after implementation and validation evidence exists:

- `SB-M09-018`;
- `SB-M09-019`;
- `SB-M09-020`.

Do not modify M08 task completion. Do not mark M10 or later milestones complete.

If a required M09-C002 behavior cannot be completed safely, leave the corresponding task open and record the blocker instead of forcing completion.

## Logging

Use local phase log:

`C:\Users\sekip\Desktop\SCRUBBOTS_PHASE_M09_LOG.md`

Local phase log stays local-only and must not be committed.

Create/update the GitHub implementation log:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CLAUDE_IMPLEMENTATION_LOG.md

Claude implements/tests/logs only. Claude must not create audit or self-audit files.

Before ending, update:

- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md

Set M09-C002 to `AWAITING_AUDIT` only when implementation, tests, docs, task truth and implementation logging are ready for independent ChatGPT review.

## Mandatory final validation

Record each item separately in `CLAUDE_IMPLEMENTATION_LOG.md` with expected outcome, fail condition, actual result, and `CLAUDE_TEST_PASS` / `CLAUDE_TEST_FAIL` / `NOT_RUN` / `BLOCKED`.

1. `godot --version`
2. `powershell -File tools\verify_project.ps1`
3. `godot --headless --path . --quit-after 5`
4. `godot --headless --path . -s res://tests/run_tests.gd`
5. Real CLI validation-only happy-path batch with at least 3 items including rectangle and 59x59.
6. Prove validation-only creates no final derived artifacts.
7. Real CLI commit of the same valid batch.
8. Re-run unchanged batch and record unchanged/no-meaningless-write behavior.
9. Real CLI duplicate-ID-within-manifest rejection, proving no final writes.
10. Real CLI duplicate-ID-against-catalog rejection, proving no final writes.
11. Real CLI canonical cross-item destination-alias rejection using syntactically different equivalent paths.
12. Real CLI failing-later-item preflight case, proving earlier final artifacts are not written.
13. Catalog duplicate scan case with two existing files declaring the same ID.
14. Malformed catalog entry case with actionable failure.
15. Confirm no owner SCRUBBOTS artwork was fabricated/ingested.
16. `git diff --check`
17. Inspect final diff for scope integrity and accidental binaries/temp/cache files.
18. `git status --short` before commit.
19. Commit with a precise M09-C002 message.
20. Push to `origin/main` without force.
21. Final `git status --short` and record commit/push evidence.

Do not replace named checks with only an aggregate test total.

## Stop condition

After M09-C002 is implemented, validated, logged, pushed, and marked `AWAITING_AUDIT`, stop.

Do not start M08, M10, M11, or any new milestone.
