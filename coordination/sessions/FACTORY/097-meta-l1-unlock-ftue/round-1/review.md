# Review round 1, job 097

1. Gate: feature_unlocks_v1.json matches the owner table (L1 x6, robots 25, events 30, ranks 40, boosters 6/11/16/21). Grandfather parameter removed from FeatureUnlocks.is_unlocked and AppState.feature_unlocked. No inventory/entitlement mutation in the locking path. Facade refuses with reason "locked" for buy/watch(booster:*)/use booster, robot unlock/equip/unlock_next, event join/claim. Grep of scripts/ for direct boosters.buy_charge, robots.unlock, events.join/claim, rewarded.start outside the facade: none from UI. Bound in AppState and in the gameplay host (host uses _booster_locked). OK.
2. test_unlock_all: static var, referenced only in app_state.gd (declaration and the _init read) plus tests/*.gd. No script, scene, tool or workflow sets it. Shipping boot cannot enable it. Reasonable seam (same pattern as main.gd boot_*_override). Minor: it is a static on the production class, so a stray set in a test leaks across AppStates in the process; acceptable.
3. Welcome +100: no code change; suite welcome_claim_once covers single payout on rapid taps, relaunch, replay, re-import. Passes.
4. L2 booster lesson removed; booster_intros are config-validated and the seen ledger is the persisted flag. booster_intro_step is 4 dictionary/ledger lookups, no legality proof on the main thread (hint copy uses the existing off-frame path). OK.
5. CI: suite added to the validate loop and an exact "6/6" grep guard added matching the suite's printed line (verified the line is printed verbatim). The workflow has no numeric total to update; only header comments carry totals, and the new comment line omits the "(65 total)" figure (cosmetic, not blocking).
6. m46_performance: the diff adds no _process/_physics code; the only new per-call work is booster_intro_step (a few lookups, called from _coach_want, not in a frame loop that scales) and a lock check in booster_states/execute_booster. Builder saw timing-only failures that also fail on base; judged noise.

Ran locally: tests/m44_meta_l1_unlock_ftue 6/6 PASS, tests/m44_unlock_gate 6/6 PASS, no script errors. git diff --check clean. project.godot unchanged.

Must-fix: none.

VERDICT: PASS
