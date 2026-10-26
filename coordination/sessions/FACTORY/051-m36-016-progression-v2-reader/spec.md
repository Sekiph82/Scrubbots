# Progression v2 reader (SB-M36-016)

> Feature: a versioned reader so data/config/level_progression_v2.json (schema scrubbots-level-progression/v2) is actually consumed by LevelDifficultyAnalyzerV2 lane targets and tools/difficulty_playtest.gd recovery guards in v2 mode; v1 mode and level_progression_v1.json byte-identical behaviour (CLAUDE.md §11.3).

## Context
- `scripts/difficulty/difficulty_progression_v1.gd` (`DifficultyProgressionV1`) loads a progression JSON, but `_load` rejects any schema other than `EXPECTED_SCHEMA = "scrubbots-level-progression/v1"`, so `DifficultyProgressionV1.new("res://data/config/level_progression_v2.json")` gives `is_ok() == false` ("unexpected schema"). Its formulas (`target_challenge_for`, `progression_p`, `class_for`, `recovery_guards`) are already data-driven (`lanes`, `cadence`, `progression.tauCycles`, `recoveryGuards`) and v2 has the same structure, only different numbers (lanes 13.8+9.0 / 30.9+8.3 / 43.8+8.3 / 49.6+7.7, guards 9.6/12.8/9.6/22.4, `challengeTolerance` 2.2/1.3/3.2). See docs/DIFFICULTY_LANE_ANCHOR_CALIBRATION.md §5 "Reader note".
- `scripts/difficulty/level_difficulty_analyzer_v2.gd`: `_init(config_path)` hard-creates `DifficultyProgressionV1.new()` (v1 file); `_prog.target_challenge_for(level_number)` at ~line 518; `provenance()` reads `progressionModelVersion` from the v1 path. `data/config/level_difficulty_analysis_v2.json` names `consumes.progressionModel` = v1 and is hash-pinned (must stay byte-identical).
- `tools/difficulty_playtest.gd`: `run(committed_measure, model)` builds `DifficultyProgressionV1.new()`, passes it to `Tool.recovery_checks(...)` (tools/analyze_m53_first10.gd, uses `prog.recovery_guards()` and `prog.target_challenge_for`), and reads `challengeTolerance` straight from the v1 file path.
- Owner context: shipped L1..L10 are NOT calibration references; re-scoring them under v2 lanes is informational only and must not gate anything.

## Requirements
1. Extend `DifficultyProgressionV1` (no parallel copy) to accept schema `scrubbots-level-progression/v2` in addition to v1: add `V2_CONFIG_PATH := "res://data/config/level_progression_v2.json"` and `V2_SCHEMA` constants; `_load` accepts either schema; any other schema still fails with "unexpected schema". `DEFAULT_CONFIG_PATH`, `EXPECTED_SCHEMA` and all formulas unchanged. Add a `challenge_tolerance() -> Dictionary` accessor (data from the loaded file) and `model_version() -> int` (file `version`), so callers stop re-reading JSON paths.
2. `LevelDifficultyAnalyzerV2._init(config_path := CONFIG_PATH, progression_path := DifficultyProgressionV1.DEFAULT_CONFIG_PATH)`: builds `_prog` from `progression_path`; `provenance()["progressionModelVersion"]` comes from the loaded `_prog.model_version()` (v1 path gives the same value as before). Do not edit `level_difficulty_analysis_v2.json`.
3. `tools/difficulty_playtest.gd`: add `--progression v1|v2` (default `v1`; unknown value prints `UNKNOWN_PROGRESSION` and exits 1). With `v2` it passes `V2_CONFIG_PATH` to both the analyzer and its own `DifficultyProgressionV1` (so recovery guards and target drops are v2) and reads `challengeTolerance` from that same object. With `v1` or omitted, output (incl. `--model v1`) is unchanged from today. v2-progression output must carry the progression path in `provenance` and must not overwrite the default v1-progression output files (use a distinct output name or leave existing OUT paths for the default only).
4. Add tests `tests/m36_progression_v2_reader.gd` (new) covering the criteria below; keep the existing hash pins (v1 progression `fe967a78...`, v2 configs) passing.
5. Docs: update docs/DIFFICULTY_LANE_ANCHOR_CALIBRATION.md §5 reader note (reader now exists, name the constants/flag), add a one-line note in the `## Autonomous Queue` / TASKS.md SB-M36-016 entry with the evidence, and AGENTS.md only if it lists these tools/tests.

## Acceptance criteria
GODOT = `C:/Users/sekip/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe`; run as `"$GODOT" --headless --path <worktree> -s res://tests/<suite>.gd`.
1. `DifficultyProgressionV1.new(V2_CONFIG_PATH).is_ok()` is true; a file with schema `.../v3` or none still `is_ok() == false`. Suite `m36_progression_v2_reader` prints `M36 progression v2 reader: PASS (N cases, 0 fail)`.
2. Real v2 reader: `target_challenge_for(311)` (EASY slot 1) equals `13.8 + 9.0*(1-exp(-31/20)) + 0` (~20.89) and is strictly greater than `target_challenge_for(11)` (~14.24); asserted in the suite via the reader, not a re-implemented formula. Same strict check for v1 reader (`20+14P`).
3. Cadence §11.1 via the v2 reader and v1 reader: `class_for` for n = 1, 10, 11, 111, 300, 310, 311, 1000, 1001, 1010 gives, in order, EASY, VERY_HARD, EASY, EASY, VERY_HARD, VERY_HARD, EASY, VERY_HARD, EASY, VERY_HARD; `slot_for` gives 1, 10, 1, 1, 10, 10, 1, 10, 1, 10; both readers agree on class/slot/role/novelty for those n.
4. v2 `recovery_guards()` minimum drops equal 9.6 / 12.8 / 9.6 / 22.4 and v1 equal 15 / 20 / 15 / 35; `challenge_tolerance()` default/preferred/neverForce equals 2.2/1.3/3.2 (v2) and 3.5/2.0/5.0 (v1).
5. `LevelDifficultyAnalyzerV2.new()` (defaults) reads v1: `provenance()["progressionModelVersion"] == 1`; `LevelDifficultyAnalyzerV2.new(CONFIG_PATH, V2_CONFIG_PATH)` is ok, reads `progressionModelVersion == 2`, and its internal target for a level number equals the v2 reader's `target_challenge_for` (the analyzer target line ~518 is exercised, e.g. through the score/analysis path on one fixture, and differs from the v1-built analyzer's target for the same level).
6. Byte identity: `data/config/level_progression_v1.json`, `level_progression_v2.json`, `level_difficulty_analysis_v2.json`, `difficulty_score_model_v2.json` unchanged (git diff empty; existing sha pins in m36_anchor_calibration / m36_difficulty_v2 still pass). With default args, `difficulty_playtest.gd --model v2` and `--model v1` output files are byte-identical to before the change (run before/after and compare, or `git diff --stat` on the committed evidence files shows no change).
7. `difficulty_playtest.gd --progression v2` runs (`DIFFICULTY_PLAYTEST OK ...`); its `recovery` section `designMinimumDrop` values are 9.6/12.8/9.6/22.4 and `challengeTolerance` is the v2 object. Shipped L1..L10 results are informational: no failure/anomaly gate is added for them.
8. Regression suites all print PASS with 0 fail: `m36_anchor_calibration`, `m36_difficulty_v2`, `m36_difficulty_v1`, `m37_level_progression`, `m53_first10_difficulty`.
9. `git -C <worktree> diff --check` is clean; changed files limited to the ones named above plus docs/TASKS.md.

## Out of scope
- Changing any lane number, guard or tolerance, or re-running the anchor calibration.
- Making v2 the default progression for the analyzer, tools or game runtime, or editing `level_progression_v1.json` / `level_difficulty_analysis_v2.json`.
- Re-tuning, re-ordering or re-scoring shipped levels; adding gates on L1..L10; regenerating committed evidence files.
- A new progression class/file duplicating `DifficultyProgressionV1`; any runtime (non-tool) wiring.

## Assumptions
- Default stays v1 everywhere (conservative; existing evidence and hash pins depend on it); v2 is opt-in via constructor arg / `--progression v2`, since the pinned analysis config cannot be edited to point at v2.
- "Versioned reader" is satisfied by schema-version support in the existing class (task allows it and the rules prefer reuse).
- `model_version()` and `challenge_tolerance()` accessors are the minimum needed to stop path-based re-reads in the analyzer provenance and playtest tool.
