VERDICT: PASS

## Findings
None.

## Notes
Reproduced at worktree HEAD 90d012dd, Godot 4.7.2 headless. All four suites exit 0 with 0 SCRIPT ERROR/Parse Error, and `git status` is clean afterwards.
- m36_difficulty_v2: `M36 difficulty V2 evidence: PASS (38/38 cases, 0 fail)`
- m36_difficulty_v1: `M36 difficulty V1 evidence: PASS`
- m53_first10_difficulty: `M53 FIRST10 DIFFICULTY: PASS`
- m53_c002_difficulty_calibration: `M53-C002 DIFFICULTY CALIBRATION: PASS`

Hash assertions are real. The constants in tests/m36_difficulty_v2.gd lines 33-36 equal the LF-normalised sha256 of `git show origin/main:<file>` for all four files: score_model_v1 b8310c9d, analysis_v1 a0b0236e, v2_candidate 7dc96a0d, level_progression_v1 fe967a78. `git diff origin/main` on score_model_v1, level_progression_v1 and data/levels is empty.

Spearman recomputed independently from `playtest_v2.json` challengeScore against ratings (6,3,6,3,5,3,3,5,3,5), with average ranks for ties: +0.6448. This matches the suite and build.md.

I did not run the 25-minute fresh playtest. The shortfalls (HARD below the MEDIUM mean, all three recovery guards failing) are reported honestly in build.md and in the doc, and SB-M36-013 is filed for them. They are not hidden by the tests.
