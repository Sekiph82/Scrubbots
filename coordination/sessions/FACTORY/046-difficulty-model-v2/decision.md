APPROVE

## Why
Score model v2 is added as a new versioned model. v1, the frozen candidate and level_progression_v1.json are untouched (reviewers confirmed the diffs are empty). Reviewers also confirmed the locked weights and that no level data or assets changed. All three round-1 reviews (rules, code, tests; job.json lists these three) are PASS with no problem in their Notes. The shortfalls are reported honestly: Spearman +0.64 equals the candidate, cadence is partial, all three recovery guards fail, and SB-M36-013 is filed behind an owner decision. `git merge-tree --write-tree origin/main HEAD` reports no conflicts.

## Acceptance criteria
1. Suite `m36_difficulty_v2` prints PASS: met. The tests reviewer reproduced 38/38, exit 0.
2. v1 and candidate files untouched, with hash constants embedded: met. The reviewer matched the constants to `git show origin/main:<file>`, and `git diff origin/main` shows nothing in the v1 files or data/levels (my name-only check agrees).
3. Weights, version and schema: met. The rules review confirms the weights are unchanged, and the v2 suite asserts them.
4. D finite and within 0..100: met. Suite s03 and s06 cover it (build.md).
5. The v1 suite still passes, and the 11 vs 311 EASY target assertion is repeated in the v2 suite: met. The tests reviewer reproduced the v1 suite PASS.
6. Playtest `--model v2` and `--model v1`: met, per build.md. The v1 JSON differs from the committed file only in wall-clock fields, and the committed file was restored, so `playtest_v1.json` is not in the diff.
7. Spearman computed and printed: met. The tests reviewer recomputed +0.6448 independently, which is above the +0.64 threshold.
8. Cadence ordering printed, and the shortfall documented: met. `CADENCE_ORDER_PARTIAL` is reported under "Honest shortfall".
9. Recovery guards in the doc and the JSON: met.
10. Calibration doc and the `changes` array: met. The `changes` array has 9 entries with component, before, after and reason (suite s02).
11. Anti-overfit (`firstTenRead` false, corpus manifest sha256 matches the candidate's): met (suite s05).
12. `git diff --check` clean, no forbidden paths touched: met. I checked both. The new suite is not in the CI runner, which is out of scope per the spec and the v1 precedent.
13. TASKS.md reflects requirement 10: met, per the rules review.

## For the human
Not applicable.
