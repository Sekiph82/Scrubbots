APPROVE

## Why
The solver now plays the unchanged runtime with the human policy (fill all 5 slots, refill any freed slot at once). Six plans that dead-ended under real play (L18, L20, L22, L23, L25, L30) were regenerated, and only their `intendedColumnClicks` changed. All three round-1 reviews (code, rules, tests) are PASS. CI validation_only run 41192324690 is green, and merge-tree reports no conflicts.

## Acceptance criteria
1. real_play_levels passes: met. build.md and the CI log show PASS. The review-tests reviewer reproduced the related suites.
2. real_play_verify `--levels all` is idempotent: met. build.md records the reruns.
3. Level JSON changes are only `intendedColumnClicks`: met. The rules reviewer diffed old and new for all six and found the rest identical, with the same column multisets.
4. Provenance file: met. It has original sha256 and old click lists for the regenerated plans.
5. Determinism and investigation: met. build.md records numbers for determinism, FPS sensitivity and layout.
6. Negative control: met per build.md. The old L22 plan is stuck at click 12 on a bare host, or 27 on the laid-out app root, and the search finds a win.
7. m55 passes: met. CI shows `M55 LONG SESSION: PASS`.
8. m52 and campaign_l11_l30 pass: met. The reviewer reproduced both locally.
9. Runtime untouched: met. I checked it myself. `git diff --stat origin/main...HEAD` over scripts/gameplay/dispatch, runtime, targeting, routing and agents is empty. The proof_kernel change is comment-only per the rules review.
10. Regression suites: met per build.md.
11. Importer: met. It hard-fails without Godot and runs the real-play gate.
12. Docs and TASKS rows: met. The rules review confirms both rows and the follow-up READY SB-STUDIO-REAL-PLAY-GATE.
13. CI run: met. Run 41192324690 is green.
