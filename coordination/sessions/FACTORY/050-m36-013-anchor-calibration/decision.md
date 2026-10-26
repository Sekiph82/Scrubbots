APPROVE

## Why
All three round-1 reviews are VERDICT: PASS and their Notes describe no real problem. The branch merges cleanly into origin/main (merge-tree reported no conflicts). It adds a 24-fixture anchor corpus and applies the pre-committed decision rule. The rule outcome is RESCALE, which produces the additive `data/config/level_progression_v2.json`. v1 configs, scripts and levels are untouched. The one gap, that no reader loads the v2 file, is accepted and filed as SB-M36-016.

## Acceptance criteria
1. Deterministic build: met. build.md records three identical runs and a clean `git status`. The reviewers re-ran the checks.
2. Measure and merge: met. 24 of 24 fixtures were measured and solved; `anchors_v2.json` is in the diff.
3. `m36_anchor_calibration` PASS (126 cases, 0 fail): met. build.md reports it and the tests reviewer re-ran it.
4. Doc contains the rule, and the rule was committed before measurement: met. Commit 27a66955 holds the rule and 05129032 holds the data. I confirmed the commit order in `git log`.
5. Outcome consistency: met. The v2 file exists with the outcome RESCALE. I spot-checked the lane bases: 13.8, 30.9, 43.8, 49.6, matching the medians in build.md. The suite recomputes the numbers independently.
6. Regression suites: met. All four PASS per build.md and the tests review.
7. No forbidden changes: met. The diff of `data/config`, `scripts` and `data/levels` against origin/main shows only the added `level_progression_v2.json` (188 insertions).
8. Anchors absent from data/scenes/scripts: met. My grep returned nothing.
9. TASKS.md: met. SB-M36-013 is `[x]` with the evidence line, and SB-M36-016 is filed.
