APPROVE

## Why
All three round-1 reviews (code, rules, tests) are VERDICT: PASS with no real problems in their Notes. The change is small and contained: a file-mode CLI, a shared-path generalisation in the driver, one new suite, docs and the Codex prompt. `git merge-tree` is clean against origin/main. The reviewer-tests re-ran the new suite and got 6/6 in 134 s, which matches the builder's 133 s. The builder also ran `real_play_levels` and got 5/5, so the catalog path is unchanged. No CI run was made on the branch. The suite is added to the CI list with the 6/6 guard, which is an accepted risk given the local passes.

## Acceptance criteria
1. Suite PASS 6/6: met. The builder and reviewer-tests both ran it, and the exact-count guard is in place.
2. Valid run: met. Build.md shows exit 0, WON_ROBUST, all three dts won, `--out` equal to the stdout JSON, and sha and schema fields correct.
3. Lost run: met. OLD_L22 clicks gave exit 1, LOST, stuck at click 27, and `searchedClicks` null.
4. Search run: met. It gave exit 0, WON_ROBUST, `searched:true`, and the re-run without `--search` also won.
5. Invalid inputs: met. Nine cases each gave exit 2 with a clean subprocess.
6. No repo writes: met. `git status` was identical before and after.
7. Catalog regression: met. L22 was WON at 1/60, and the catalog count stayed 30.
8. `real_play_levels` 5/5: met per build.md, and the code review confirms the catalog branch is intact.
9. Docs and `git diff --check`: met. The code reviewer ran the diff check and it is clean. The diffstat shows the changes to AGENTS.md and docs/10.
10. Codex prompt: met, and I checked it myself. Sections a-i are all present (5 headings match `^## [a-i]\.`). The schema id appears 5 times, the `REAL_PLAY_RESULT ` marker 5 times, the literal usage line once, and SEARCH_BUDGET 4 times.
11. CI inclusion: met. I checked the workflow myself: the suite is in the loop at l.133 and the exact guard `REAL PLAY FILE CLI: PASS (6/6 cases, 0 fail)` is at l.274.
