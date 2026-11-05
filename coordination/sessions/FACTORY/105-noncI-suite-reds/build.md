STATUS: READY

# Build: SB-TEST-RED-2026-11-06 non-CI suite reds

## Summary
Five non-CI suites went red after owner product changes. In every case the test was out of date. None of the failures was a product bug, so no product file changed. Each test now asserts the current intended behaviour and still protects the same property.

Commits on factory/105-noncI-suite-reds:
- 959bdbad: test fixes
- 3fb8c87a: TASKS.md queue row

Files changed:
- tests/m46_slot_rebuild.gd
- tests/m42_assets.gd
- tests/m43_c001b_won_results_visual.gd
- tests/m43_c004_c001_fail_need_a_hand.gd
- tests/m43_c001r_c001_results_momentum.gd
- TASKS.md

## Acceptance criteria
1. [x] **m46_slot_rebuild "+1 Slot -> 6 slots":**
   - Root cause: SB-M44-032 locks +1 Slot until L6, so on a fresh L1 save it returns `locked`.
   - Fix: the suite sets the documented seam `AppState.test_unlock_all = true` (AGENTS.md, Feature unlock gate). The 5-slot and 6-slot rebuild assertions are unchanged.
   - Before: FAIL (1). After: PASS, exit 0.
2. [x] **m42_assets approved count:**
   - Root cause: HOME-123 (SB-POLISH-009 Home video still) is APPROVED and hash-pinned, so there are now 54 approved entries, not 53.
   - Fix: both exact counts (APPROVED and APPROVED_BOUND) are now 54 and the message names HOME-123. An exact count still fails on any unexpected addition or removal. The generation_required count stays 52 because HOME-123 is not generated.
   - Before: FAIL (2). After: PASS, exit 0.
3. [x] **m43_c001b WON results visual (3 fails):**
   - Root cause: SB-VIDEO-001/002 (factory 093) changed Scrubby's robot slot. It now plays the keyed Flow video and holds the keyed still. WON binds `WIN_STILL`; LOST binds `LOSE_STILL`.
   - The leak case measured its base node count while the transient VideoBox and ResultVideo existed. The count then dropped from 50 to 48 when the clip ended.
   - Fix: WON asserts `WIN_STILL` and LOST asserts `LOSE_STILL`. All other layout and visual assertions are unchanged. The node count now excludes only the nodes named exactly "VideoBox" and "ResultVideo". A leaked second video would get a renamed duplicate and still be counted. The case also asserts at most one VideoStreamPlayer.
   - Before: FAIL (11/11 cases, 3 fail). After: PASS (11/11, 0 fail), exit 0.
4. [x] **m43_c004 help-Scrubby art:**
   - Suite: tests/m43_c004_c001_fail_need_a_hand.gd, t05.
   - Root cause: same as item 3. The Fail robot is the keyed LOSE still, not the `FAIL_ROBOT_ART` help pose.
   - Fix: asserts `LOSE_STILL` plus the fail emblem. The "no Victory art on Fail" check now also rejects `WIN_STILL`.
   - Before: 1 FAIL. After: PASS (40/40, 0 fail), exit 0.
5. [x] **m43_c001r results momentum (22 fails):** there were three root causes.
   - **Catalog-size assumption (8 fails).** The catalog now has 30 levels. Fix: the suite reads the size N from the catalog and asserts N >= 10 with orders exactly 1..N. The missing-frontier, coming-soon, injected next-level and responsive cases now use N and N+1. The cycle numbers in the injected case come from `ResultsMomentum.cycle_of`/`slot_of`.
   - **Gift ceremony barrier (13 fails).** SB-POLISH-002 added a Gift ceremony. A fresh save's first win crosses Gift milestone 1, and that ceremony holds the teaser and CLEAN NEXT. This caused the 0-Hearts, rapid-tap, barrier-release, Reduced Effects, responsive "NextCleanup outside panel", malformed-config and available-copy fails. Fix: `_boot` seeds the meter at 1 with that ceremony marked seen, the same fixture m43_c001b already uses. The barrier itself is still covered by t30/t31.
   - **Video nodes (1 fail).** The t34 node count dropped from 541 to 538 because of the result-video nodes. Fix: the same exclusion as item 3, plus a check of at most one decoder.
   - Before: FAIL (40/40 cases, 22 fail). After: PASS (40/40, 0 fail), exit 0.
6. [x] **m44_ftue:** left unchanged, as instructed.
7. [x] **m46_performance:**
   - Ran alone. tasklist showed no other Godot engine running, only idle godot-ai.exe helper processes.
   - Result: FAIL 1 of 22 cases. The failing check is "retry() on 59x59 worst 50.18 ms (one-off, <= 50.1)", which is 0.08 ms over budget.
   - Thresholds were not changed.

## Validation
- Godot 4.7.2 console, headless, run in the worktree after one `--import`.
- Before (HEAD versions): all five suites FAIL, as listed above.
- After, all LOCAL_PASS with exit 0:
  - m46_slot_rebuild
  - m42_assets
  - m43_c001b_won_results_visual
  - m43_c004_c001_fail_need_a_hand
  - m43_c001r_c001_results_momentum
- None printed SCRIPT ERROR or Parse Error.
- m46_performance: FAIL (1/22), as reported in item 7.
- No product file changed, so no product suites were needed.
- `git diff` was inspected before the commit.
- Import churn (project.godot, .import, .uid, .translation) was restored or removed, and `git status --porcelain` is clean.
- Not pushed; no CI.

## Log
### Round 1
- Ran every suite on HEAD to confirm each failure, then traced each one to its root cause: the SB-M44-032 booster gate, HOME-123, SB-VIDEO-001/002 stills and the transient video nodes, the 30-level catalog, and the SB-POLISH-002 Gift ceremony barrier.
- Updated the five tests and re-ran them; all pass.
- Ran m46_performance once on a quiet machine: 1 timing fail, 0.08 ms over budget, thresholds untouched.
- Committed the tests and the TASKS.md row.
