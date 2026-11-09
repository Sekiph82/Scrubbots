STATUS: READY

# Build: CI red at 8b157a58: m55_long_session and m39e_full_matrix

## Summary
Branch factory/144-ci-red-m55-m39e (base 1e9c5bf3), 3 commits, not pushed:
- 99e350a4 app: dispose the AppState economy when the app root is freed
  - scripts/app/main.gd: `NOTIFICATION_PREDELETE` -> `app_state.economy.dispose()`
  - scripts/economy/economy_services.gd: dispose() doc comment updated
  - tests/m55_long_session.gd: weakref assert that the freed lap-1 root releases AppState / EconomyServices / StoreService
- b3c9e629 tests: m39e removed-economy check uses whole-word key/value match (tests/m39e_full_matrix.gd)
- f723cb6c docs/tasks: SB-CI-RED-2026-11-09 done (TASKS.md, one queue line)

### Root cause 1: m55 "objects drift 70 > 64"
No single new feature leaks per lap. The canonical AppState EconomyServices graph was never disposed. Its reward-handler lambdas capture the graph, which makes a RefCounted cycle. The code comment said the graph "lives for the app lifetime", but m55 frees the lap-1 app root and boots a fresh one for lap 2. So every boot leaked the whole graph: AppState, every economy service, and everything they hold.

A boot/free probe (5 boots, no play) measured this:
- 33 Objects per boot at c1e1560b, before factory 138.
- 35 per boot at 77a88a87 (138: StoreService + StoreProvider).
- 36 per boot at head (with 141 AdService and 142 CloudSaveService).

The growth from 138/141/142 pushed the lap drift over 64. The underlying cycle is older.

Fix: main.gd releases the handlers on PREDELETE. This is the same dispose() that ProductionGameplayHost already calls for its private economy. A real app frees the root only on exit, so nothing changes in normal play.

Results after the fix:
- Boot/free probe: 36 per boot -> 0 (2182 Objects after each of 5 boots).
- Play probe, 3 boots x 30 production levels each: flat at 2233 Objects, app_state freed every time.
- m55 lap drift went from +70 to +36/+39. The 64 threshold is untouched.
- The remaining ~36 is below the threshold and does not come from product code: the 30-level boot probe is flat. It likely comes from the suite's own transition/chaos harness. I did not chase it further.

### Root cause 2: m39e "no star currency key in snapshot"
The substring "star" matched the ranks key `week_start` (factory 134, ranks weekly). Saves in the wild already contain it, so renaming it is not save-compatible.

Fix: the test now walks every key and string value of the snapshot recursively and matches whole `_`-delimited words, case-insensitive:
- `(^|_)stars?(_|$)`
- `(^|_)event_points?(_|$)`
- `(^|_)(profile_xp|xp_bar)(_|$)`

New negative self-checks:
- Caught: `stars`, a nested `star_currency`, the value `Gold_Stars`, `event_points`, a nested `profile_xp`, `xp_bar_fill`.
- Not caught: `week_start`, `restart`, `started`.

## Acceptance criteria
1. [x] m55_long_session leak found and fixed in product code (threshold not raised): the AppState economy cycle is disposed on root PREDELETE. LOCAL_PASS "M55 LONG SESSION: PASS", STEADY lap2-vs-lap1 objects +39 (was +70), "ok: freed app root releases AppState / EconomyServices / StoreService".
2. [x] m39e precise star check, still fails on a real star key: LOCAL_PASS "M39 Phase E evidence: PASS", snapshot hits [] for all three rules, both self-check lines ok.
3. [x] Listed suites run (results below).
4. [x] TASKS.md note: SB-CI-RED-2026-11-09 line in the Autonomous Queue.
5. [x] Not pushed. The worktree was reset with `git checkout -- .`, and only the untracked `.uid`, `.import` and `.translation` files from the import were deleted. `git status --porcelain` is empty. The probe saves were deleted from user://.

## Validation (local Godot 4.7.2, headless, worktree, after the fix)
All exited 0 with 0 script diagnostics unless noted:
- m55_long_session: PASS
- m39e_full_matrix: PASS
- m57_ads_cadence: PASS 6/6
- m54_cloud_save_seam: PASS 7/7
- m57_store_products: PASS 9/9
- m44_robot_assembly_stages: PASS 4/4
- m54_regression_pack_037_038: PASS 6/6. Its 11 diagnostics are all the documented injected "explode" line, which CI excludes.
- m60_release_gates: PASS 6/6
- m40_v04_bootstrap: PASS
- m42_navigation: PASS
- m55_core_chaos (not in CI): FAIL (11), booster cases. The fail is identical with main.gd restored to HEAD, so it is pre-existing and not caused by this change.

Limits:
- No CI run.
- Not proven: that the new weakref assert fails without the fix. That would need a 6-minute run. The boot probe showed the graph leaking every boot before the fix.

## Log
### Round 1
- Read the CI logs. The m55 per-level counts showed the jump only at the lap boundary (lap 2 boots a new root), so the leak was per boot, not per level.
- Bisected with a boot/free probe across c1e1560b, 77a88a87, 96f773b0 and 8b157a58, then confirmed the dispose fix with the boot and 12- and 30-level play probes. All probe scripts were temporary and have been deleted.
- Found "star" in the snapshot with a probe (ranks `week_start`) and rewrote the m39e check.
- Ran the suites, committed, added the TASKS line, and cleaned up.
