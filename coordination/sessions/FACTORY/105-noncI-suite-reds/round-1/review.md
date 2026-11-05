# Round 1 review: 105-noncI-suite-reds

No product file changed. The diff origin/main...branch touches 5 tests plus TASKS.md only.

## Suite re-runs (own, headless, after a fresh `--import`)
My first pass used a stale `.godot`: m42_assets, m43_c001b and m43_c001r showed texture "No loader found" fails. After re-importing, all pass:
- m46_slot_rebuild: exit 0, "M46 SLOT REBUILD: PASS"
- m42_assets: exit 0, "M42 assets evidence: PASS"
- m43_c001b_won_results_visual: exit 0, "PASS (11/11 cases, 0 fail)"
- m43_c004_c001_fail_need_a_hand: "PASS (40/40 cases, 0 fail)"
- m43_c001r_c001_results_momentum: exit 0, "PASS (40/40 cases, 0 fail)", 0 SCRIPT ERROR / Parse Error

The only worktree changes are import artifacts: `.import` files, `project.godot` and `.uid` files. They are not part of the branch.

## Honesty check per suite
- m46_slot_rebuild: adds only `AppState.test_unlock_all = true`. The 5-slot and 6-slot assertions are untouched. Honest.
- m42_assets: 53 becomes 54 for both APPROVED and APPROVED_BOUND. Both are still exact equalities, and the message names HOME-123. Honest.
- m43_c001b: WIN_STILL and LOSE_STILL are equality asserts on the bound texture path, so they fail if the wrong art is bound. `_count_static` excludes only nodes named exactly VideoBox or ResultVideo. The leak case also asserts at most one VideoStreamPlayer. This is a narrow exclusion that still catches leaks.
- m43_c004 t05: asserts LOSE_STILL plus the fail emblem. The "no Victory art" check gains WIN_STILL on top of ROBOT_ART and EMBLEM_ART, so it is stronger. Honest.
- m43_c001r: the catalog size is derived, but still `>= 10` with orders exactly 1..N. The frontier cases move to N and N+1. The seed pre-marks the gift milestone-1 ceremony as seen on boot, as m43_c001b does. t30 and t31 still assert the barrier holds and releases, through the `set_ceremony_barrier` seam. t34 uses the same narrow exclusion plus the at-most-one-decoder check.

## Findings
None blocking.

## Notes
- t30 and t31 exercise the barrier through the seam, not the real gift ceremony. The real gift-ceremony hold is therefore not asserted in this suite. That is no regression: the old test also used the seam for the barrier. If you want it covered, check that another suite does so.
- m46_performance is a 0.08 ms timing flake left alone, which is correct.

VERDICT: PASS
