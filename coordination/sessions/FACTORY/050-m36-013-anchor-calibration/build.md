STATUS: READY

# Build: Anchor-corpus lane calibration (SB-M36-013, redone)

## Summary
The branch builds a deterministic anchor corpus of 24 TEST fixtures: 5 per lane plus 4 EXTREME ceiling probes. Each fixture was designed from the component rules. The branch measures the corpus with the unchanged `LevelDifficultyAnalyzerV2` and applies the Requirement 5 decision rule. That rule was committed before any measurement.

**Outcome: RESCALE.**
- Lane medians: EASY 13.81, MEDIUM 30.90, HARD 43.83, VERY_HARD 49.64. They are monotonic, but no lane holds.
- Scale s = 0.6398.
- The new file `data/config/level_progression_v2.json` has these lanes (base + growth):
  - EASY 13.8 + 9.0
  - MEDIUM 30.9 + 8.3
  - HARD 43.8 + 8.3
  - VERY_HARD 49.6 + 7.7
- Recovery guards are 9.6 / 12.8 / 9.6 / 22.4. Tolerance is 2.2 / 1.3 / 3.2.
- Ceiling: the best EXTREME probe scores D 59.70, which is at least the VERY_HARD cap of 57.3, so the cap check passes.
- `level_progression_v1.json` and every model/analysis config, analyzer script and level file are unchanged.

Commits (job branch, not pushed):
- `27a66955`: builder, measure tool, fixtures, manifest and the doc's decision rule. Committed before any D measurement.
- `05129032`: per-fixture raw records, `anchors_v2.json` and `level_progression_v2.json`.
- `ce18592e`: test suite, doc results and informational section, AGENTS/docs11 pointers, supersede line, TASKS.md.

Files added:
- `tools/build_difficulty_anchors.gd`
- `tools/measure_difficulty_anchors.gd`
- `tests/m36_anchor_calibration.gd`
- `tests/fixtures/difficulty_anchors/` (24 level files, 24 supply files and `anchor_manifest_v1.json`)
- `coordination/sessions/FACTORY/050-m36-013-anchor-calibration/anchors_v2.json` and `anchors_raw/*_raw.json` (24 files)
- `data/config/level_progression_v2.json`
- `docs/DIFFICULTY_LANE_ANCHOR_CALIBRATION.md`

Files changed:
- `AGENTS.md`: pointer section.
- `docs/11_LEVEL_DIFFICULTY_CALIBRATION_QA.md`: pointer.
- `docs/DIFFICULTY_LANE_CALIBRATION_PROPOSAL_V1.md`: one supersede line at option C2.
- `TASKS.md`: SB-M36-013 ticked and its queue row set to DONE; new SB-M36-016 added.

## Acceptance criteria
1. [x] **Deterministic build.**
   - `"$GODOT" --headless --path <wt> -s res://tools/build_difficulty_anchors.gd` was run three times: twice before the first commit and once after all commits. Each run printed `ANCHORS_BUILT lanes=4 perLaneMin>=5 extreme>=4` and exited 0.
   - After the last run, `git status --porcelain tests/fixtures/difficulty_anchors` printed nothing.
   - The builder also loads every fixture through LevelLoader and the supply loader and requires `SolvabilitySolver` status SOLVED. All 24 are SOLVED.
2. [x] **Measure and merge.**
   - `--measure=<id>` was run for each of the 24 ids (6 in parallel via xargs, one Godot invocation per fixture). All exited 0 and printed `MEASURED_ANCHOR <id> solver=SOLVED ok=true` (31-81 s each).
   - `-- --merge` printed `ANCHORS_MEASURED fixtures=24 solved=24` and `DECISION outcome=RESCALE`, and wrote `anchors_v2.json`.
3. [x] `-s res://tests/m36_anchor_calibration.gd` printed `M36 anchor calibration: PASS (126 cases, 0 fail)` and exited 0, with no SCRIPT ERROR or Parse Error.
4. [x] **Doc.**
   - Section 2 of the doc holds the Requirement 5 rule verbatim; the suite greps four key phrases.
   - The doc also has the per-fixture table (rationale, D, W..S, Session Load, policy range, solver), the four medians, the ceiling, `Outcome: **RESCALE**`, the labelled informational L1..L10 section and the reproduction commands.
   - The rule text is in `27a66955`, which is an ancestor of `05129032`, the commit that adds `anchors_v2.json`.
5. [x] **Outcome consistency.**
   - `level_progression_v2.json` exists and the outcome is RESCALE.
   - The suite recomputes the medians and steps 1-3 from `anchors_v2.json` on its own. It asserts the exact base, growth, guards and tolerance (s < 1, so tolerance is scaled), that the cadence, progression and envelope sections equal v1, and that the calibration block is bound to the manifest and config sha256.
6. [x] **Regression suites** (each exit 0, no SCRIPT ERROR):
   - `m36_difficulty_v2`: `M36 difficulty V2 evidence: PASS (38/38 cases, 0 fail)`
   - `m36_difficulty_v1`: `M36 difficulty V1 evidence: PASS`
   - `m37_level_progression`: `M37 level progression evidence: PASS`
   - `m53_first10_difficulty`: `M53 FIRST10 DIFFICULTY: PASS`
7. [x] **No forbidden changes.**
   - `git diff --stat main` over `level_progression_v1.json`, `difficulty_score_model_v1/v2.json`, `level_difficulty_analysis_v1/v2/v2_candidate.json`, `scripts/` and `data/levels` is empty. The only change under `data/` is the new `level_progression_v2.json`.
   - The suite also asserts the sha256 values from main for v1 progression and the v2 model and analysis configs.
   - `git diff --check main..HEAD` is clean.
8. [x] `grep -rn difficulty_anchors <wt>/data <wt>/scenes <wt>/scripts` returns nothing. The v2 calibration block records only the manifest sha256, not its path. The suite scans `res://data` for every anchor id.
9. [x] `TASKS.md`:
   - The SB-M36-013 entry is `[x]` with the evidence block: outcome, medians, lanes, guards, ceiling, the suite PASS line, regressions and doc path.
   - The queue row is DONE.
   - SB-M36-014 is unchanged: its component checks are not affected by the outcome.

## Validation
- `tools/build_difficulty_anchors.gd`, run three times: PASS, byte-identical output.
- `tools/measure_difficulty_anchors.gd -- --measure=<id>` on all 24 fixtures, then `-- --merge`: PASS (24/24 SOLVED).
- `tests/m36_anchor_calibration.gd`: LOCAL_PASS (126 cases, 0 fail).
- `tests/m36_difficulty_v2.gd`, `tests/m36_difficulty_v1.gd`, `tests/m37_level_progression.gd`, `tests/m53_first10_difficulty.gd`: LOCAL_PASS.
- `git diff --check main..HEAD`: clean.
- `git status`: the only remaining entries are untracked `*.uid` and modified/untracked `*.import` files. Godot generated them when it imported the worktree; this job did not create them and they are not committed.

## Log
### Round 0
- **Anti-tuning order.** I designed the fixtures from the component definitions only. I did not open any L1..L10 score file while designing. Then I committed builder, fixtures, manifest, measure tool and the doc's rule (`27a66955`) before running any D measurement.
- **Solvability replacement before measurement.** The draft probe `x_rings12q_r1_straddle_24` (1-wide quadrant rings, straddle30 supply) was DEADLOCK in the builder's solver check. Before the first commit and before any measurement, I replaced it with `x_rings12q_straddle_24` (2-wide quadrant rings, straddle30), which is SOLVED. The doc (section 3) records this.
- **Post-commit tool edit, not a score change.** After the first commit I removed the fixture manifest *path* from the progression-v2 `calibration` block (the sha256 stays). The path would have matched acceptance criterion 8's `grep difficulty_anchors data/`. No fixture was edited after measuring.
- **Unfavourable observations, reported and not acted on.**
  - 1-wide rings score lower than designed. `vh_rings10h_r1_split_24` scores 37.4, and the 1-wide EXTREME probes score about 40: A stays low because a thin ring is fully targetable as soon as the ring outside it clears.
  - `med_shafts6_24` (22.2) is below `easy_frame5_24` (24.2).
  - B stays at or below 0.28 on every fixture.
- **Finding: the v2 file is not loadable by the existing reader.**
  - The spec requires both schema `scrubbots-level-progression/v2` and "v2 loadable through DifficultyProgressionV1's config_path" with the reader unmodified. These conflict: `DifficultyProgressionV1` checks `EXPECTED_SCHEMA == .../v1`, and a probe confirmed `DifficultyProgressionV1.new(v2 path).is_ok() == false` ("unexpected schema").
  - I kept the mandated schema and the unmodified reader. The suite computes v2 targets with the same formula (level 311 EASY 20.89 > level 11 EASY 14.24).
  - I documented the gap (doc section 5) and filed SB-M36-016 (progression v2 reader) in TASKS.md, both in the queue and as a checklist entry.
- **Number format.** JSON numbers copied from v1 into the v2 file serialize as floats (for example `"fromSlot": 3.0`), because Godot JSON parses every number as float. The values are the same JSON numbers.
- **Informational L1..L10 section.** Doc section 6 was written after the decision was recorded. It copies `playtest_v2.json` and was not re-measured. Under the v2 lanes, L10 is soft (-2.88) and the other nine are outside ±3.2; guards: 3->4 PASS, 5->6 FAIL, 8->9 FAIL. It was not used for anything.
