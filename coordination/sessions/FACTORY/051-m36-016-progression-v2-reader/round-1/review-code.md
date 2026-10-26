VERDICT: CHANGES

## Checks
git diff --check origin/main...HEAD: pass
Diff read in full (reader, analyzer, playtest, AGENTS.md); suites not run (reviewer-tests owns that).

## Findings
1. scripts/difficulty/level_difficulty_analyzer_v2.gd:522 (and level_difficulty_analyzer_v1.gd:613) The window label is blocking, not cosmetic. Under `--progression v2` the target and signedDelta are v2, but `acceptanceWindow` still comes from `_v1.classify_window`, which reads the v1 file's tolerance (3.5/2.0/5.0). The committed `playtest_v2_progression_v2.json` therefore says `challengeTolerance` = 2.2/1.3/3.2 while every level's window and the `anomalies` list (the "anomalies=11" count) were computed with 3.5/2.0/5.0. The evidence contradicts itself, and levels with |delta| between 2.2 and 3.5 are labelled IN_WINDOW against v2 targets when they are SOFT. The fix is small and keeps default behaviour identical:
   - Give `classify_window` an optional `tol: Dictionary = {}` parameter. When empty it reads the v1 file exactly as before.
   - In the v2 analyzer line 522 pass `_prog.challenge_tolerance()`.
   - Add a suite case: with the v2-built analyzer, a delta of 3.0 is SOFT, while the default analyzer gives IN_WINDOW. Also assert the window from `score(raw, 311)` is consistent with the v2 tolerance.
   - Regenerate `playtest_v2_progression_v2.json` (`--model v2 --progression v2 --committed-measure`) and update the anomalies count in build.md and TASKS.md.
   - Re-check that the default `--model v2` and `--model v1` outputs stay byte-identical, apart from the ms fields.
   - `level_difficulty_analyzer_v2_candidate.gd` is not in scope.

## Notes
- The `--progression v2` + `--model v1` refusal is correct and should stay. The v1 analyzer is frozen on v1 and has no progression argument, so allowing it would silently mix v1 targets with v2 guards. The error text is clear. The message prefix `UNKNOWN_PROGRESSION` is slightly off for a "needs --model v2" case, but that is only a nit.
- `challenge_tolerance()` returns a deep copy and `model_version()` is a plain accessor. Both are fine. The schema check `not x in [..]` is OK.
- The reader reuses the existing class with no parallel copy. Defaults are unchanged, and the distinct output file name protects the v1 evidence.
- `provenance["progressionConfig"]` is only added for v2, as the spec requires.
