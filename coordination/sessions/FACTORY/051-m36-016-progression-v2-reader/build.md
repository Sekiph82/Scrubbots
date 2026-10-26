STATUS: READY

# Build: Progression v2 reader (SB-M36-016)

## Summary
`DifficultyProgressionV1` now accepts schema `scrubbots-level-progression/v2` as well as v1. It adds the constants `V2_CONFIG_PATH`/`V2_SCHEMA` and the accessors `model_version()`/`challenge_tolerance()`. Any other schema still fails with "unexpected schema". `LevelDifficultyAnalyzerV2._init(config_path, progression_path)` builds its progression from the path it is given, and its provenance `progressionModelVersion` comes from that loaded reader. `tools/difficulty_playtest.gd --progression v1|v2`:
- The default is v1.
- An unknown value prints `UNKNOWN_PROGRESSION` and exits 1.
- v2 also requires `--model v2`, because the v1 analyzer is frozen on v1. Otherwise it prints `UNKNOWN_PROGRESSION v2 needs --model v2` and exits 1.
- With v2, lane targets, recovery guards, challengeTolerance and the per-level acceptance window all come from level_progression_v2.json. `LevelDifficultyAnalyzerV1.classify_window(delta, tol := {})` applies the passed tolerance; an empty tolerance keeps the old v1 file read. The v2 analyzer passes `_prog.challenge_tolerance()`. Output goes to `playtest_v2_progression_v2.json` with `provenance.progressionConfig`.

v1 stays the default everywhere, and no config file was edited.

Commits: c1f4eb55 (code, suite, docs), 95b947d8 (v2-progression evidence, TASKS), b8f197b9 (round 2: window uses the v2 tolerance, evidence regenerated).
Files:
- scripts/difficulty/difficulty_progression_v1.gd
- scripts/difficulty/level_difficulty_analyzer_v1.gd (round 2: optional `tol` on classify_window)
- scripts/difficulty/level_difficulty_analyzer_v2.gd
- tools/difficulty_playtest.gd
- tests/m36_progression_v2_reader.gd (new)
- docs/DIFFICULTY_LANE_ANCHOR_CALIBRATION.md (section 5 reader note)
- AGENTS.md (one clause on the lane-targets line)
- TASKS.md (SB-M36-016 ticked, queue row DONE)
- coordination/sessions/FACTORY/046-difficulty-model-v2/playtest_v2_progression_v2.json (new evidence, informational)

## Acceptance criteria
1. [x] v2 loads; v3 and missing schema are rejected: suite s01 (`v2 reader ok, version 2`, `schema v3 rejected`, `missing schema rejected`). Suite prints `M36 progression v2 reader: PASS (55 cases, 0 fail)`, exit 0.
2. [x] Level 311 vs 11 through the readers. v2 target(311) = 20.8898, equal to 13.8+9.0*(1-exp(-31/20)), and greater than target(11) = 14.24. v1: 31.03 > 20.68, equal to 20+14P (suite s02).
3. [x] Cadence for n = 1/10/11/111/300/310/311/1000/1001/1010 gives the expected classes and slots under both readers, and the readers agree on class/slot/role/novelty (suite s03, 30 cases).
4. [x] Recovery guards: v2 is 9.6/12.8/9.6/22.4 and v1 is 15/20/15/35. Tolerance: v2 is 2.2/1.3/3.2 and v1 is 3.5/2.0/5.0 (suite s04).
5. [x] The default analyzer gives progressionModelVersion 1, and the v2-progression analyzer gives 2. `score(raw, 311)` on the committed M53-C002 raw for level_002_apple exercises the target line. targetChallenge is 31.0285 under v1 and 20.8898 under v2. Each equals its reader, and they differ. Window cases: delta 3.0 is IN_DEFAULT_WINDOW under v1 and SOFT under v2, delta 3.3 is OUT under v2, the v2 analyzer's window matches the v2 tolerance, and the default analyzer's window is unchanged (suite s05).
6. [x] Config and default-output byte identity:
   - `git diff ff68fed1 HEAD -- data/config` is empty, and the sha pins pass in the new suite s06, m36_anchor_calibration and m36_difficulty_v2.
   - Default playtest outputs were compared before and after the change with `--committed-measure`, for `--model v2` and `--model v1 --progression v1`. Ignoring the solver wall-clock `"ms":` fields, there are 0 differing lines. Those fields hold timing that changes from run to run; they differed in the same way before the change.
   - The committed evidence files were restored and are not changed in the branch.
7. [x] `--model v2 --progression v2 --committed-measure` prints `DIFFICULTY_PLAYTEST OK levels=10 anomalies=12` (round 2; 11 before the window fix). The 12 are 9 LANE_MISS OUT_OF_HARD_LIMIT, 1 LANE_MISS SOFT (L10, delta -2.9) and 2 RECOVERY, all computed with the v2 tolerance. Its recovery guards show designMinimumDrop 9.6/12.8/9.6. The 22.4 guard (10 to next-cycle 1) has no `toSlot`, so `recovery_checks` skips it, exactly as it already did for v1's 35. challengeTolerance is the v2 object, progressionModelVersion is 2, and progressionConfig is the v2 path. L1..L10 targets now follow the v2 lanes (13.8 ... 49.6). These are informational only and no gate was added. Error paths: `--progression v3` gives `UNKNOWN_PROGRESSION v3`, exit 1; `--model v1 --progression v2` exits 1.
8. [x] Regression suites (exit 0, no SCRIPT ERROR/Parse Error):
   - m36_progression_v2_reader PASS (55 cases, 0 fail)
   - m36_anchor_calibration PASS (126 cases, 0 fail)
   - m36_difficulty_v2 PASS (38/38 cases, 0 fail)
   - m36_difficulty_v1 PASS
   - m37_level_progression PASS
   - m53_first10_difficulty PASS
9. [x] `git diff --check ff68fed1 HEAD` is clean. The changed files are only the ones listed above.

## Validation
GODOT = Godot_v4.7.2-stable_win64_console.exe --headless --path <worktree>. LOCAL_PASS:
- `-s res://tests/m36_progression_v2_reader.gd`: PASS (55 cases, 0 fail)
- `-s res://tests/m36_anchor_calibration.gd`, `m36_difficulty_v2`, `m36_difficulty_v1`, `m37_level_progression`, `m53_first10_difficulty`: all PASS
- `-s res://tools/difficulty_playtest.gd` default, `--model v1 --progression v1`, and `--model v2 --progression v2` (all `--committed-measure`): all OK
- `git diff --check ff68fed1 HEAD`: clean

Worktree note: `git status --porcelain` is not empty. It lists 1509 Godot import byproducts (modified `*.import`, untracked `*.uid`, including owner-inbox `.import` files). These were already present when the job started (same count of 1509) and are not part of this job, so I did not stage them.

## Log
### Round 0
Implemented the reader as schema-version support inside the existing class, with no parallel copy. Added the analyzer's progression_path argument, the playtest `--progression` flag, the new suite and the docs/TASKS updates. Captured the before outputs of the default playtest runs, then compared them with the after outputs as described in criterion 6.

Decisions beyond the spec:
- `--progression v2` is refused with `--model v1`. The v1 analyzer has no progression argument, so its targets would silently stay v1.
- (Superseded in round 2.) The v2 analyzer's `acceptanceWindow` was left on the v1 tolerance in this round.

### Round 2
Finding (review-code.md 1, blocking): under `--progression v2` the acceptanceWindow labels and LANE_MISS anomalies used the v1 tolerance, while the evidence reported the v2 tolerance. Fixed:
- `LevelDifficultyAnalyzerV1.classify_window(delta, tol: Dictionary = {})`: an empty tolerance reads the v1 file exactly as before. The method lives on the v1 analyzer, not on DifficultyProgressionV1.
- `LevelDifficultyAnalyzerV2` passes `_prog.challenge_tolerance()`. Under the default progression these are the same v1 numbers, so default output is unchanged.
- Added 5 suite cases (55 total).
- Regenerated `playtest_v2_progression_v2.json`: anomalies went from 11 to 12 (L10 delta -2.9 is now SOFT). Updated TASKS.md (anomalies=12, 55 cases).

Re-verified:
- Default `--model v2` and `--model v1` `--committed-measure` outputs have 0 non-`ms` diff lines against the pre-change baseline. Evidence files restored.
- All six suites pass with exit 0 and no SCRIPT ERROR/Parse Error.
- `git diff --check ff68fed1 HEAD` is clean.

Kept the `--model v1` refusal, as the reviewer asked.
