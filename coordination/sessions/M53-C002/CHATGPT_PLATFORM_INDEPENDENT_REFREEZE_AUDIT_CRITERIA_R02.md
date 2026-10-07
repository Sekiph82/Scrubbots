# SB-M53-C002-R01-001 — PLATFORM-INDEPENDENT RE-FREEZE — AUDIT CRITERIA R02

Date: 2026-10-07

## Governance
- [ ] Non-destructive sync; owner-local edits preserved.
- [ ] Root TASKS.md untouched by builder.
- [ ] M53 scope only; Remote Content Runtime remains unchanged.

## Canonical serialization
- [ ] One explicit QA-only canonical serialization authority.
- [ ] Platform-independent full-precision float formatting proven for Godot 4.7.2 path or implemented independently.
- [ ] Deterministic key order/newline/indent.
- [ ] No epsilon/tolerance/field deletion/platform exception.
- [ ] Golden tests include the three known boundary values and nested/repeated cases.
- [ ] Existing fresh==committed check remains exact.

## Re-freeze integrity
- [ ] Regeneration used existing calibration workflow, not manual value edits.
- [ ] Corpus freeze happens before First Ten holdout.
- [ ] Every regenerated artifact has old/new SHA evidence.
- [ ] frozenConfigSha256 and provenance bindings are coherent.
- [ ] Fixture level/supply SHA identities unchanged.
- [ ] No production LevelData/supply/catalog/palette/Difficulty-V1/progression changes.
- [ ] No V2 formula/coefficient/policy/tolerance/fixture-definition changes.

## Semantic invariants
- [ ] Machine-readable old/new numeric delta report exists.
- [ ] All ordinal-pair PASS/FAIL identical.
- [ ] All family-check PASS/FAIL identical.
- [ ] All robustness PASS/FAIL identical.
- [ ] First Ten window/class-like verdicts identical.
- [ ] Recovery guards identical.
- [ ] L10 boss/cycle conclusion identical.
- [ ] Owner-reviewed qualitative conclusions unchanged.
- [ ] Previously owner-presented rounded scores/metrics unchanged.
- [ ] Max absolute/relative numeric deltas reported and attributable only to recovered serialization precision.
- [ ] Any semantic drift would have stopped as GPT_REQUIRED rather than being normalized away.

## Regression
- [ ] m53_c002_difficulty_calibration PASS with exact assertion.
- [ ] canonical serializer golden suite PASS.
- [ ] m53_first10/M53-C001 PASS.
- [ ] M52 + relevant M54 PASS.
- [ ] CP04/CP05/CP05-R01/family fixture PASS.
- [ ] M35/M37/M40/M43 PASS.
- [ ] root tests ALL PASS.
- [ ] diff --check clean.
- [ ] no new unexplained script errors.

## Handoff
- [ ] V02 Claude log exists with SHA tables, semantic invariant table and test results.
- [ ] Root TASKS.md untouched.
- [ ] End marker is AWAITING_GPT_M53_C002_R01_REFREEZE_AUDIT.

PASS closes the stale-corpus platform dependence without adopting V2 as production difficulty authority.
