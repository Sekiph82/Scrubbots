# SB-M53-C002-R01-001 — PLATFORM-INDEPENDENT SERIALIZATION RE-FREEZE — R02

Status: AUTHORIZED / EXECUTE NOW
Date: 2026-10-07
Repository: `Sekiph82/Scrubbots`
Owner-local checkout: `C:/Users/sekip/Desktop/ScrubBots`
Decision authority: `coordination/sessions/M53-C002/CHATGPT_SERIALIZATION_AUTHORITY_DECISION_V01.md`
Prior diagnostic log: `coordination/sessions/M53-C002/SB-M53-C002-R01-001_CLAUDE_LOG_V01.md`

## Purpose

Close the Linux/cloud determinism failure in `tests/m53_c002_difficulty_calibration.gd` by removing platform C-runtime float-to-text dependence from the M53-C002 QA evidence pipeline.

This is a **serialization-only re-freeze**. It is NOT a difficulty retune.

## 0. Safe sync / governance

Before implementation:
- inspect current branch, status, HEAD, origin/main, ahead/behind and untracked files;
- work from `C:/Users/sekip/Desktop/ScrubBots` when accessible;
- if cloud-only, state that limitation truthfully;
- sync non-destructively with latest `origin/main`;
- preserve `project.godot`, `scenes/app/main.tscn`, `addons/`, `.mcp.json`, unrelated owner-local edits and untracked files;
- no reset --hard, git clean, force checkout/push or destructive overwrite;
- root `TASKS.md` is READ ONLY for Claude.

Confirm the already merged Remote Content Runtime and CP05-R01 remain intact.

## 1. Canonical JSON authority

Add one explicit QA-only canonical serialization helper used by the M53-C002 calibration tool and its exact-determinism comparison.

Requirements:
- platform-independent float formatting;
- full precision / round-trip-safe output;
- deterministic key ordering;
- deterministic newline/indent policy;
- no dependence on platform C-runtime `printf` rounding;
- integer/string/bool/null semantics preserved;
- no tolerance/epsilon normalization.

Prefer Godot's platform-independent full-precision JSON path if verified from the exact Godot 4.7.2 implementation. If that path is not demonstrably platform-independent, implement a narrow deterministic serializer for this QA evidence instead. Do not change generic game JSON behavior.

Add permanent golden tests for:
- `1.286916935992815`;
- `124.9313038031345`;
- ordinary floats, negative values, zero, integers;
- nested arrays/dictionaries and deterministic key order;
- repeated runs.

The exact determinism check must remain an exact string/byte equality after canonical serialization. No skips, platform branches or tolerance.

## 2. Rebuild QA evidence through the existing canonical tool

Use the existing calibration workflow, not manual editing.

Regenerate in canonical sequence:
1. calibration corpus raw measurements;
2. corpus calibration / derived anchors;
3. frozen V2 candidate config if its canonical serialized bytes/anchor values change;
4. corpus evidence;
5. First Ten holdout raw measurements under the newly frozen config;
6. holdout merge/evidence/matrix.

Preserve chronological semantics: corpus calibration/freeze precedes First Ten holdout.

Do not hand-edit generated numeric fields or SHA values.

## 3. Provenance

Publish a machine-readable before/after report containing at minimum:
- old/new artifact SHA-256 for every regenerated file;
- old/new frozenConfigSha256;
- old/new corpusManifestSha256;
- per-fixture levelSha256 and supplySha256 identity;
- every numeric leaf that changed and its old/new value;
- max absolute and relative delta for raw and derived numeric outputs;
- all old/new decision booleans / categorical outcomes;
- old/new displayed/rounded challenge scores and session-load values;
- old/new ordinal-pair results;
- old/new family-check results;
- old/new robustness results;
- old/new First Ten window/class-like verdicts;
- old/new recovery guard results and L10 boss relationship.

Label the event:
`SERIALIZATION_ONLY_PLATFORM_INDEPENDENT_REFREEZE`.

## 4. Hard stop conditions

STOP and return `GPT_REQUIRED_SEMANTIC_DRIFT` if ANY of these changes:
- production LevelData or owner supply plan bytes;
- production catalog/palette;
- Difficulty V1 weights or progression targets;
- V2 formula/coefficient/policy/tolerance/fixture definition;
- any corpus ordinal PASS/FAIL;
- any family-check PASS/FAIL;
- any robustness PASS/FAIL;
- any First Ten acceptance/window/class-like decision;
- any recovery guard PASS/FAIL;
- L10 boss/cycle conclusion;
- any owner-reviewed qualitative conclusion;
- any rounded/product-facing score at the precision previously presented to the owner;
- any content hashes for level/supply fixtures.

Do not continue by declaring such changes insignificant.

Tiny full-precision numeric deltas are allowed only when all semantic gates above are identical and the report demonstrates the source is recovery from the old lossy serialization boundary.

## 5. Test requirements

After re-freeze:
- `tests/m53_c002_difficulty_calibration.gd` must PASS with its exact fresh==committed assertion intact;
- run the new canonical serialization golden suite;
- run M53-C001 / `m53_first10_difficulty`;
- M52 owner supply / R01 / R02;
- relevant M54 difficulty/progression/content regressions;
- CP04, CP05, CP05-R01 and remote family fixture;
- M35, M37, M40, M43 order-context;
- root `tests/run_tests.gd`;
- `git diff --check`.

No existing test may be removed or weakened. No new unexplained SCRIPT ERROR / ERROR.

## 6. Audit evidence and log

Write:
`coordination/sessions/M53-C002/SB-M53-C002-R01-001_REFREEZE_CLAUDE_LOG_V02.md`

Also commit the machine-readable before/after semantic delta report under:
`coordination/sessions/M53-C002/evidence/r01_refreeze/`

The log must include:
- sync truth;
- exact canonical serialization implementation;
- generated-artifact sequence;
- old/new SHA table;
- semantic invariant table;
- max numeric deltas;
- all test results;
- exact final SHA / branch / ahead-behind;
- confirmation root TASKS.md untouched.

Push to the authorized branch.

Finish exactly:
`AWAITING_GPT_M53_C002_R01_REFREEZE_AUDIT`
