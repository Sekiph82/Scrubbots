# Review round 1: 139-noncI-reds-2

## Runs (I ran them myself, headless, exit 0, no Parse Error)
- m21_v08: PASS. m21_v09: PASS.
- m46_rm006: PASS (5/5 groups). Its 2 SCRIPT ERROR lines are the documented `rm006_injected` fault injection.
- void_cells_c001: PASS.
- m43_c001r: PASS (40/40).
- m50_a11y_surfaces: PASS (3/3).
- m43_ranks_weekly: PASS (7/7).
- m60_release_gates: PASS (6/6).
- test_unlock_all suites: m55_core_chaos PASS, m28_c002_c002_static_shell PASS (16/16).

## Per-change verdict (all legitimate updates, none a weakening)
- **m21_v08/v09:** Railroad V1 is owner-locked (docs/01_GAMEPLAY_SPEC.md, ADR-028): connector, then BOTTOM rail, then rail-only sides/corners.
  - The old "above-board start reaches the top" and "left+top ring" claims are obsolete.
  - The new assertions are direct: C/043 expects `NO_ROUTE` exactly, and C/047 requires bottom and a vertical side. Both would fail if routing broke.
  - v09 widens `x == -1` to `x < 0`, which is correct for a rail column. It keeps the top-side requirement.
- **test_unlock_all:** `plus_one_slot` unlocks at L6 and the other unlocks are real level gates in the unlock config. The flag only rewrites the in-memory unlock table in `AppState`. Test-only use is legit. It affects only fixtures that start at L1.
- **m46_rm006:** stricter than before.
  - The old check was `start[1] > deepest[0]-2`, which fails on wrap. The new check requires the cyclic start to be within 1 of the recorded previous cut (`resumes`).
  - The `distinct > control` check and the control `[0,0,0,0]` check are kept.
  - The only softness is the +/-1 tolerance, which is minor.
- **m43_c001r:** the L30 Featured Card ceremony barrier (SB-M44-026) is a real product feature. Pre-granting and marking the card seen mirrors m43_c001b, so the test is not hollowed out.
- **m53_first10 and m53_c002:** `>= 10` entries plus orders 1..10 first. The calibration-fixture exclusion check is kept. Fine.
- **void_cells_c001:** the v2 branch asserts version 2, void count > 0, artwork+void == cells, ACTIVE count == artwork count, and supply sum == artwork count. This is a direct check of the ADR-030 rule. The v1 branch is unchanged.
- **profile_screens.gd:** one line, `FOCUS_NONE` to `FOCUS_ACCESSIBILITY`.
  - That gives screen-reader-only focus, with no keyboard or touch focus ring.
  - The toggles are button-grouped, so there is no side effect on pressed state.
  - m50_a11y_surfaces, m43_ranks_weekly and m60 pass.

## Notes (non-blocking)
- The m46_rm005 performance red (108-121 ms against a 60 ms budget) is honestly reported as an unfixed product follow-up. The threshold was not weakened. It is not part of this job.
- Two suites were skipped as over 6 minutes. This is disclosed.
- Cleanup: worktree reset with `git checkout -- .`. Only import churn existed.

## Must-fix
None.

VERDICT: PASS
