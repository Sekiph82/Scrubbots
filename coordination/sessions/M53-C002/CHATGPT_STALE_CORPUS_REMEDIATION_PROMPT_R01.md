# SB-M53-C002-R01-001 | Stale Calibration Corpus Determinism Remediation

Status: PREPARED / QUEUED AFTER CP05-R01
Date: 2026-10-07
Repository: Sekiph82/Scrubbots
Authority: ChatGPT owns root TASKS.md, Claude implements and logs only.
Issue: tests/m53_c002_difficulty_calibration.gd has one failing assertion on untouched e36e023 baseline:
fresh run == committed corpus raw (timing excluded)
Run: godot --headless --path . -s res://tests/m53_c002_difficulty_calibration.gd

## Scope and historical authority
M53-C002 candidate calibration was frozen in 4bea41ed270b0b7562b913abfae0571f580391c7 (before First 10 holdout), with holdout in e7865b493d66a726f5f86ebeeae2e3a6d67827eb. The V2 model is CANDIDATE_NOT_PRODUCTION_AUTHORITY. Owner deferred M53-C003 recalibration. The current failure predates CP04/M15 + CP05/M16; do not blame the remote content changes.

## Safe sync
First inspect local git status, branches and origin/main, then sync non-destructively while preserving C:/Users/sekip/Desktop/ScrubBots owner-local project.godot, main.tscn, addons, .mcp.json, changed/untracked files. If cloud-only, document the limitation. No reset, clean, force or owner-file overwrite. Root TASKS.md read-only.

## Investigation MUST precede repair
1. Reproduce the exact one-assertion failure on untouched baseline e36e023 and current main. Verify two fresh measures equal when timing is excluded.
2. Obtain per-fixture old committed raw and fresh V2 measurement; produce a deterministic machine-readable diagnostic difference for all changed fields, first on flow_stripes3_20, then the complete corpus as needed. Include policy runs, scalar/vector changes, schema and hashes. Normalize ONLY volatile timing already excluded by the existing test, never exclude any other differing field.
3. Trace dependencies of V2.measure and the canonical tool and compare git history from freeze commit 4bea41e through current main for scripts/difficulty/, tools/calibrate_difficulty_v2.gd, supply/solver/routing/target selection, palette and fixture/corpus files. Bisect to the first relevant behavior-changing commit rather than guessing.
4. Identify which exact upstream authority changed, the first changed raw field and the source commit(s). Verify whether this was an independently audited intended product change or a real regression.
5. If a BUG: fix the root cause in the narrowest safe code path while retaining new intended and audited behavior, then prove committed raw equality and all affected regressions.
6. If an INTENTIONAL AUDITED CHANGE: only then regenerate impacted QA corpus/evidence through the existing deterministic calibration tool, preserving provenance, fixture level/supply hashes, frozen-config chronology/sha binding, anchors, and holdout coherence. If re-freezing or score/anchor changes would alter the deferred owner's candidate calibration authority, do NOT quietly accept them: stop with a concrete OWNER_REQUIRED/GPT_REQUIRED decision package. Never silently rewrite the frozen V2 candidate to fit First 10 scores.
7. Do not alter the assertion, skip the test, relax equality/tolerance, strip a newly divergent field, delete evidence or fabricate old values.

## Safety/Scope
Do not mutate production LevelData, accepted artworks, approved owner supply plans, the production catalog, Difficulty V1 scoring weights, progression targets or released V2 calibration decisions without a separate explicitly audited authority. No gameplay tuning or broad refactor. Calibration data stays QA-only.

## Regression
Required: m53_c002_difficulty_calibration PASS without weakened assertions, M53-C001 and First 10 suites PASS, M52 supply/solver tests PASS, relevant M54 regression PASS, CP04+CP05 and family fixture PASS after their R01 is merged, root tests ALL PASS, git diff --check clean. Explicitly show before/after failure and exact changed files/digests.

## Log
Write coordination/sessions/M53-C002/SB-M53-C002-R01-001_CLAUDE_LOG_V01.md with the per-record diff, bisect, source-of-drift proof, remediation type, provenance and tests, then push to authorized branch. Do not edit TASKS.md. Finish:
AWAITING_GPT_M53_C002_R01_STALE_CORPUS_AUDIT
