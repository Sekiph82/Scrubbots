---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-prompt
cycleId: M09-C001
version: 2
createdAt: 2026-08-27T23:47:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M09
supersedes: CHATGPT_PROMPT_V01.md
triggerAudit: CHATGPT_AUDIT_V01.md
auditedImplementationHead: 49178d412276137a39da993bfafe47262dc10c97
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

# SCRUBBOTS - M09-C001 Importer Safety Correction Prompt V02

## Objective

Close all findings from ChatGPT independent audit V01 without expanding M09-C001 scope.

The deterministic exact-pixel importer core is already substantially correct. This pass must harden source immutability, artifact path isolation, overwrite behavior, PNG-only format enforcement, malformed reconstruction behavior, and the negative-test matrix.

Do not start M09-C002.

## Mandatory GitHub sources

Read these before modifying code:

1. Project operating manual:
   https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md
2. Canonical task ledger:
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
8. ChatGPT independent audit V01:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V01.md
9. Correction audit criteria V02:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_CRITERIA_V02.md
10. Existing Claude implementation log:
    https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CLAUDE_IMPLEMENTATION_LOG.md
11. This active correction prompt:
    https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V02.md
12. Original M09 scope prompt for inherited requirements:
    https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V01.md
13. Level Data V1 spec:
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/03_LEVEL_DATA_SPEC.md
14. Test strategy:
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/06_TEST_STRATEGY.md

## Audit findings to close

Apply all of these exactly:

- `F-M09-001`: source/artifact path aliasing can destructively overwrite source or derived artifacts.
- `F-M09-002`: preview and metadata do not currently honor a safe overwrite policy.
- `F-M09-003`: PNG-only support is documented but not explicitly enforced by the reusable importer core.
- `F-M09-004`: reconstruction can index malformed short cell arrays unsafely.

Apply audit learnings:

- `AL-009`: every mandatory validation step must be individually traceable.
- `AL-010`: canonicalized path identity and source immutability.
- `AL-011`: negative tests must isolate the claimed failure mode.
- `AL-012`: safe overwrite policy must cover every generated artifact.

Record in `CLAUDE_IMPLEMENTATION_LOG.md` how each finding/learning changed this implementation pass.

## Required implementation corrections

### 1. Canonical path identity preflight

Before any write occurs, derive a canonical identity for every non-empty path participating in the request:

- source path;
- Level JSON output path;
- preview path;
- metadata sidecar path.

The comparison must correctly handle project paths used by this repository (`res://`, `user://`, absolute paths, and practical relative paths). On Windows, path identity must account for case-insensitive filesystem semantics.

Do not rely on raw string inequality alone.

Reject the request before any write if:

- output aliases source;
- preview aliases source;
- metadata aliases source;
- output aliases preview;
- output aliases metadata;
- preview aliases metadata.

The source must remain immutable even when `overwrite=true`.

Add targeted tests that capture source raw bytes before each destructive alias attempt and prove the source bytes are unchanged afterward.

### 2. Preflight all requested derived destinations before writing

Do not write the Level JSON first and only later discover that preview or metadata cannot safely be written.

Preflight requested destination collisions/existing-file policy before the first derived artifact is written.

For `overwrite=false`:

- a missing destination may be written;
- an existing artifact with identical deterministic content may be classified `UNCHANGED` and must not be rewritten;
- an existing artifact with different content must cause a clean actionable failure before any requested derived artifact is written.

Apply this to:

- Level JSON;
- preview PNG;
- metadata sidecar JSON.

For `overwrite=true`:

- existing derived artifacts may be replaced only after all path-alias checks pass;
- source mutation remains forbidden;
- destination-to-destination aliasing remains forbidden.

If useful, add result flags such as `preview_unchanged` and `metadata_unchanged` rather than overloading `output_unchanged`.

### 3. Deterministic preview comparison

The preview is reconstructed from Level Data and must remain so.

For safe `overwrite=false` handling of an existing preview, compare the existing preview to the newly reconstructed preview in a way that proves equivalent RGBA8 dimensions/data rather than relying only on timestamps.

An unreadable or different existing preview must fail safely rather than being replaced.

### 4. Deterministic metadata comparison

Build the metadata sidecar in memory before write preflight.

For an existing metadata file with `overwrite=false`:

- identical deterministic serialized content => unchanged/no-write;
- different content => actionable collision error.

Do not infer new source metadata while making this change.

### 5. Explicit PNG-only input gate in reusable importer core

Enforce PNG-only input in `scripts/tools/level_importer.gd`, not only in the CLI.

Requirements:

- `.png` accepted case-insensitively;
- a valid non-PNG image must be rejected before normal import processing with an actionable unsupported-format error;
- a corrupt/unreadable file named `.png` must fail separately as unreadable/corrupt input.

Add two distinct negative tests:

1. valid non-PNG image generated at runtime, e.g. JPEG if supported by the installed Godot build, rejected specifically because format is unsupported;
2. corrupt `.png` content rejected because it cannot be decoded.

Do not use a text `.txt` file as the only unsupported-format test.

### 6. Harden `reconstruct_image()` against malformed LevelData

Before indexing cells, reject invalid reconstruction inputs cleanly.

At minimum guard:

- null/invalid level object where practical;
- width <= 0 or height <= 0;
- empty palette;
- invalid palette string;
- `cells.size() != width * height`;
- negative palette ID;
- palette ID >= palette size.

The function may continue returning `null` on invalid input if that fits the current architecture. Do not introduce unnecessary new result frameworks in this correction pass.

Add negative tests for at least:

- short cell array;
- out-of-range palette ID;
- invalid palette string;
- invalid dimensions if constructible safely.

No test may pass merely because a runtime error aborted the tested path.

## Existing behavior that must not regress

Preserve all already-correct M09-C001 behavior:

- exact PNG dimensions;
- one RGBA8 pixel = one logical cell;
- no resize/resample/interpolation/crop/pad;
- deterministic first-seen row-major palette;
- canonical `index = y * width + x` cells;
- alpha preservation;
- TEST vs production distinction;
- DifficultyRules / ProductionLevelValidator authority;
- Level Data V1 schema unchanged;
- source metadata remains a separate sidecar;
- deterministic Level JSON;
- exact reconstruction for valid generated data;
- preview generated from Level Data;
- 3x2 TEST coverage;
- rectangular production-band coverage;
- 59x59 maximum coverage;
- explicit preload discipline;
- no owner artwork fabrication;
- no GPU/FPS claim from headless timing.

## Task truth

The independent audit found that `SB-M09-017` is currently overstated.

During this correction pass:

- reopen `SB-M09-017` before/while correcting the failure behavior if needed for truthful intermediate state;
- mark it complete again only after the new format/path/reconstruction negative tests and full final validation pass;
- keep `SB-M09-018`, `SB-M09-019`, and `SB-M09-020` open;
- keep all M08 tasks open;
- do not alter M10 owner design-gate truth.

Do not reopen unrelated M09 tasks unless the correction actually invalidates their evidence.

## Required test additions

The existing test suite must be extended with focused checks proving at least:

1. output path == source path, overwrite=false => rejected, source unchanged;
2. output path == source path, overwrite=true => rejected, source unchanged;
3. preview path == source path => rejected, source unchanged;
4. metadata path == source path => rejected, source unchanged;
5. output path == preview path => rejected;
6. output path == metadata path => rejected;
7. preview path == metadata path => rejected;
8. equivalent canonical paths using different syntax are detected where feasible in the current test environment;
9. existing different preview with overwrite=false => rejected before Level JSON/metadata writes;
10. existing different metadata with overwrite=false => rejected before Level JSON/preview writes;
11. existing identical preview with overwrite=false => unchanged/no-write behavior if implemented;
12. existing identical metadata with overwrite=false => unchanged/no-write behavior if implemented;
13. overwrite=true can replace distinct derived artifacts safely;
14. valid non-PNG image => unsupported-format rejection;
15. corrupt `.png` => decode/readability rejection;
16. `.PNG` case variant => accepted if otherwise valid;
17. reconstruction short cells => null/clean failure without runtime error;
18. reconstruction invalid palette ID => null/clean failure;
19. reconstruction invalid palette string => null/clean failure;
20. all prior importer regression cases remain green.

The exact number of new checks is not prescribed. Report the actual total.

## CLI verification

The correction is in the reusable core, but verify the real CLI still behaves correctly.

At minimum rerun successful imports for:

- 3x2 TEST;
- 20x27 EASY or another legal rectangular production fixture;
- 59x59 VERY_HARD.

Also run at least one CLI negative case for a valid non-PNG input and one source/path-alias case, proving actionable failure and non-zero exit.

## Documentation

Update only docs that need to reflect actual behavior, especially:

- `docs/03_LEVEL_DATA_SPEC.md` if importer safety/format contract needs clarification;
- `docs/06_TEST_STRATEGY.md` with actual new checks and safety coverage;
- `CHANGELOG.md` for the correction pass if project convention warrants it.

Do not create an ADR unless a durable architecture decision genuinely requires one.

## Logging

Continue the existing local phase log:

`C:\Users\sekip\Desktop\SCRUBBOTS_PHASE_M09_LOG.md`

Append a new session entry to the existing GitHub implementation log:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CLAUDE_IMPLEMENTATION_LOG.md

Do not rewrite prior entries.

The new entry must include:

- actual starting commit;
- audit V01 URL;
- criteria V02 URL;
- F-M09-001..004;
- AL-009..012;
- code/test/docs/task changes;
- every new safety test and result;
- failures/debugging history;
- full final validation sequence;
- final commit URL and push result;
- remaining M08/M09-C002/M10 gates.

Claude must not create or modify any `CHATGPT_AUDIT_*` file or any self-audit file.

## Mandatory final validation sequence

Run and individually record:

1. `godot --version`
2. `powershell -File tools\verify_project.ps1`
3. `godot --headless --path . --quit-after 5`
4. `godot --headless --path . -s res://tests/run_tests.gd`
5. Real CLI successful import: 3x2 TEST
6. Real CLI successful import: legal rectangular production-band fixture
7. Real CLI successful import: 59x59 VERY_HARD
8. Real CLI valid non-PNG rejection
9. Real CLI source/path-alias rejection with source-byte preservation check
10. Deterministic rerun/no-change behavior for Level JSON plus preview/metadata where those outputs are requested
11. Reconstruction raw RGBA8 byte equality for 3x2, rectangle, 59x59
12. Malformed reconstruction safety checks
13. `git diff --check`
14. inspect `git diff`
15. `git status --short` before commit
16. focused commit
17. push to `origin/main` without force
18. `git status --short` after push

For each, log expected result, explicit fail condition, actual result, and `CLAUDE_TEST_PASS` / `CLAUDE_TEST_FAIL` / `NOT_RUN` / `BLOCKED`.

## Coordination handoff

Before ending:

1. update https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
2. update https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
3. set `M09-C001` to `AWAITING_AUDIT` only when corrections/tests/logging are complete;
4. set `BLOCKED` only for a real blocker;
5. push safely;
6. stop.

Do not mark `AUDITED_PASS`.

Do not start M09-C002, M08, M10, or M11.

## Expected Claude final response

Keep the chat response short. Include only:

- `Cycle: M09-C001`
- cycle state;
- correction commit + push status;
- implementation log URL;
- actual test total and concise safety-test summary;
- blockers, if any;
- `READY FOR CHATGPT AUDIT` when appropriate.
