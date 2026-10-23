APPROVE

## Why
All three round-1 reviews are PASS with no problem notes. The merge-tree is clean. The diff holds only the measure tool, the budget test, `.import` files, docs, TASKS.md and coordination files, with no PNG. The two cap raises from 512 to 1024 are raises only, so they break no rule. They went beyond the spec's out-of-scope line on changing existing caps. The orchestrator ordered them mid-build and they are recorded in build.md.

## Acceptance criteria
1. Measure tool ends with DONE (52 scenarios, 219 textures): met per build.md. N is above 18 and M above 144. Skipped scenarios are listed with reasons, which review-code confirms.
2. `measure_merged.json` exists and keeps every step 2 key at a value >= the step 2 value: met. The builder checked 144 keys and review-code confirmed the per-path max merge.
3. Dry run reports `would cap 0 texture(s)`: met. I re-ran it myself in the worktree.
4. Diff scope: met. No PNG. The only removed `.import` lines are the two `size_limit=512` lines, raised to 1024 (a raise, not a lowering). The new `.import` files carry the caps.
5. Budget test PASS: met per build.md, including a negative check that failed as expected. The reviewer-tests review is PASS.
6. Booster budget and the suites of the touched screens: met. build.md lists 20 suites at LOCAL_PASS, run after the re-import, and the cap-raise commit was re-tested.
7. UI-ADR-008 step 4: met. It has the counts (75 observed, 45 capped, 2102.9 MiB total, 341 unobserved with a reason per group) and they match the tool outputs.
8. `git diff --check` is clean: met, confirmed by review-code.
