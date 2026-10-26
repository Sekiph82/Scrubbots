VERDICT: PASS

## Findings
None.

## Notes
Suites re-run by me in the worktree. Each exited 0 with no SCRIPT ERROR or Parse Error. Last PASS lines:
- m36_anchor_calibration: `M36 anchor calibration: PASS (126 cases, 0 fail)`
- m36_difficulty_v2: `M36 difficulty V2 evidence: PASS (38/38 cases, 0 fail)`
- m36_difficulty_v1: `M36 difficulty V1 evidence: PASS`
- m37_level_progression: `M37 level progression evidence: PASS`
- m53_first10_difficulty: `M53 FIRST10 DIFFICULTY: PASS`

Determinism and re-measurement:
- I re-ran `build_difficulty_anchors.gd`. It printed `ANCHORS_BUILT lanes=4 perLaneMin>=5 extreme>=4`, and git showed no fixture byte changes.
- I re-measured `easy_frame5_24` and `vh_maze10_24` with `--measure`. Both came back SOLVED.
- The re-measured raw records differ from the committed ones only in the `totalMs` timing field, so the D inputs reproduce. I did not run `--merge`, so `anchors_v2.json` was not regenerated; its inputs were checked via the raw records only. I restored those two tracked files with `git checkout` and nothing tracked is left modified.

Test honesty:
- The suite asserts the claimed properties directly:
  - manifest counts;
  - rationale regex for L1..L10, "first 10", "rating", "shipped" and "owner";
  - no anchor id or path anywhere under `res://data`;
  - fixture sha256 against the manifest;
  - byte-equal in-memory regeneration;
  - LevelLoader legality and 3..12 canonical colours;
  - `anchors_v2.json` bound to the current config and fixture sha256 values;
  - an independent recompute of the medians and the step 1/2/3 outcome from the recorded D values;
  - exact v2 base, growth, guards and tolerance values, with v2 existing only on RESCALE;
  - the frozen v1 and v2 config hashes;
  - cadence over levels 1..1010, and the level 311 target above the level 11 target.
- I found no skipped, weakened or deleted tests.

Minor points, non-blocking:
- The ceiling check (`cap <= best_x or doc contains "CEILING FINDING"`) is lenient by design. It does hold here: cap 57.3 against best probe 59.70.
- The suite trusts the recorded D values in `anchors_v2.json` rather than re-measuring them, which would take roughly 25 minutes. My spot re-measure covers that gap.
- Build.md's reported finding is real and filed as SB-M36-016: `DifficultyProgressionV1` rejects the v2 schema, so the v2 file is not loadable through `config_path` as the spec assumed.
