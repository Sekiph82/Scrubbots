# Review round 1: 119-regressions-results-spend-shop (SB-M54-022..027)

Single reviewer. Test-only diff: 3 files (new suite, CI entry, TASKS). No product code changed.

## Re-run
`godot --headless --path <wt> -s res://tests/m54_regression_pack_022_027.gd` gave exit 0 in about 51 s, no SCRIPT ERROR or Parse Error.
Last line: `M54 regression pack 022-027: PASS (12/12 cases, 0 fail)`.
Only the usual ObjectDB leak warnings at exit. The worktree stayed clean and project.godot was not touched.

## Checks
- **022 Need a Hand.**
  - Real assertions: `_lock_all_but` flips the unlock table, then the picks must equal exactly the unlocked pair.
  - One unlocked booster is due but gives `show=false` with reason `insufficient_meaningful`, no Need a Hand modal, and Retry still works.
  - The shipped table at L2 gives nothing offered and no Scrub Bucks (SB) spent.
  - The unlocked pair is the two the ranking would not pick first, so the test cannot pass by accident. Builder reports a mutation run that failed 3 assertions.
- **023.** Level 2x and timed 2x are bought, the app is relaunched on the same save, and the entitlements are checked. A relaunched re-buy returns `already_entitled` and the balance is unchanged. Real property.
- **024.**
  - Close then reward, reward then close plus 3 repeats, out-of-order interleaved tokens, an unknown token and a pending request at relaunch.
  - The assertions check Hearts, booster charges, transaction count and a byte-identical economy snapshot. The provider is the mocked double.
- **027.** 5 same-frame UNLOCK taps leave 250 parts spent. Re-unlock and locked equip are refused, and equip twice gives `equipped` then `already_active`. After relaunch the unlock, active robot, parts, roster UI and Home name all persist.
- **Coverage table, 025/026 spot-check.** The cited cases exist: `s05_insufficient_blocked`, `s07`, `s08_return_context` and `s13` in m43_master_c006_shop; `t18_set_master_once` and `t08_replay_10x` in m43_c005_c008; `k01..k19` in c007. m54_collection_set_master_exactly_once asserts the config and 15 sets with 9 cards each, which is plausible for the claim. Claims are consistent.
- **Throw-away saves.** All saves are `user://m54_022_027_*.save` with a microsecond tag and are removed in `_cleanup`, including `.bak` and `.tmp`. `test_unlock_all` and the boot overrides are reset at the end.
- **CI.** The suite is in the validate loop and has an exact-line guard matching the 12/12 summary line. The guard uses the same `grep -qxF` pattern as its neighbours. The case ledger fails the run if a case is missing. Runtime is about 51 s, under the 3 min limit.
- **No test was weakened or deleted.** The diff is additive.

## Must-fix
None.

Note: CI has not run yet, as build.md states.

VERDICT: PASS
