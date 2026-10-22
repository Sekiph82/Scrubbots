APPROVE

## Why
All three round-1 reviews are PASS with no real problems. The diff is limited to 10 booster .import files, a new budget test, UI-ADR-007 and TASKS.md, with no PNG touched. The merge-tree check is clean. The change cuts booster texture memory from 59.99 MiB to 9.43 MiB.

## Acceptance criteria
1. Diff contains only allowed files and no PNG: met. `git diff --name-only` shows 13 files, and the PNG count is 0.
2. All 10 .import files have `process/size_limit=512`: met. `grep -L` printed nothing, which I checked myself.
3. Source PNG blobs unchanged: met. No PNG appears in the diff.
4. Import runs clean and the budget test prints PASS: met. build.md shows 9.43 MiB of the 12 MiB budget, and the reviewer-tests agent reproduced the PASS.
5. The test fails when the limit is reverted: met. build.md records FAIL (2) with `random.png` at `size_limit=0`, then PASS after the restore.
6. Regression suites pass: met. build.md lists the PASS line for all five suites. The reviewer re-ran m39c and m43 and both passed.
7. Doc has 512 and 12 MiB, TASKS.md has the follow-up: met. UI-ADR-007 and SB-M22-026 are both present, and I grepped them.

Merge note: the main checkout has 10 untracked Godot-generated .png.import files at these same paths. The orchestrator must move them aside before syncing. After the merge, run `--headless --import` in main to rebuild the 512 px ctex files.
