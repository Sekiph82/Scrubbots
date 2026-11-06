STATUS: READY

# Build: SB-M54-022..027 regressions (Results/fail/Need a Hand, spend/grant idempotency, ad callbacks mocked, Shop, packs, robots)

## Summary
I mapped each checklist row to assertions that already exist. Only the real gaps got new tests, all in one consolidated suite. No product bug turned up, so no product code changed.

Files changed (branch `factory/119-regressions-results-spend-shop`):
- `tests/m54_regression_pack_022_027.gd` (new, 12 cases). It runs the real app root (main.tscn) on throw-away `user://` saves, uses the mocked `tests/support/rewarded_provider_double.gd`, and turns on the `AppState.test_unlock_all` seam, which it resets at the end.
- `.github/workflows/android-family-first10.yml`: the suite is added to the validate loop with an exact `M54 regression pack 022-027: PASS (12/12 cases, 0 fail)` guard and a header comment.
- `TASKS.md`: the queue line is now DONE, and the six checklist rows are checked off with their coverage evidence.

Commits: `dc8180d9` (suite + CI), `201afe72` (docs/tasks).

## Coverage map (row -> existing assertions -> gap filled)
| Row | Already covered by | New in m54 pack |
|---|---|---|
| 022 Results/fail/retry/Need a Hand | m43_c004_c001_fail_need_a_hand t01-t39: one Heart per LOST, Retry/Home take no second loss, 0-Heart Life, Fail truth, counter 1/2/3/4+, win/level/replay reset, two distinct picks proved on next start, fail-closed, cards/CTAs, X/Back zero mutation, buy/insufficient/ad per card, rapid taps, 20-cycle lifecycle, responsive. m43_c001a_results_foundation: receipt = commit, already-cleared, duplicate terminal, rapid/stale Continue, Results never grants | `m022_nah_only_unlocked_pair`: locked boosters prove false and the pair = the unlocked two. `m022_nah_one_unlocked_fail_closed`: only one unlocked -> due but no Need a Hand, Retry usable. `m022_nah_real_table_l2_none`: with the shipped unlock table at L2 there is no Need a Hand and nothing is spent. Every suite before this one ran with test_unlock_all=true, so this gate was never tested |
| 023 Heart/SB/booster/2x spend-grant idempotency | m43_c003_c001_acquisition c05-c08 (Heart +1/refill + insufficient), c17 (booster SB atomic), c24 (2x already_entitled in session), c26 (timed anti-rollback), c29 (rapid taps Heart/booster/2x), c32 (rewarded token idempotent after relaunch). m43_c004 t27 (booster buy persisted), t36 (6 BUY taps -> one). Shop s09/s11 (rapid confirm, lifecycle flush) | `m023_2x_relaunch_idempotent`: level 2x + timed 900 s persist across relaunch. A relaunched re-buy is refused (`already_entitled`) and nothing is debited |
| 024 Rewarded callbacks (mocked) | m43_c003 c09-c12 (Heart grant / cancel / skip / fail / timeout / unverified / UI timeout + late completion / 4 duplicates / background-resume), c18-c19 (booster), c32 (relaunch). m43_c004 t29-t32 (Need a Hand ad per card, background + 4 duplicates, one card unavailable), production_provider_unavailable | `m024_close_then_reward` (late reward after close = 0), `m024_reward_then_close` (close after reward never revokes, one tx), `m024_interleaved_tokens` (out-of-order resolution, each product once), `m024_unknown_token` (economy byte-identical), `m024_pending_at_relaunch` (pending request dropped, stale callback grants 0, committed token not restartable) |
| 025 Shop return context / insufficient SB | m43_master_c006_shop s05 (insufficient blocked with shortfall), s07/s13 (SB pack / No Ads disabled with honest store-later copy, taps inert), s08 (exact return context to Life), s10 (authority failure feedback), s12. m43_c003 c13/c22/c27, m43_c004 t28 (Need a Hand -> insufficient -> Shop -> back resumes). m44_meta_l1_unlock_ftue gate_bypass (locked booster rows not for sale) | none needed |
| 026 Packs / dup/new / Collection / Master | m43_c005_c008_pack_commit_transaction t01-t27 (Standard/Premium commit, NEW/DUPLICATE copies, same tx x10 replay, faults, reload replay, set + master exactly once / rollback). m43_master_c007_collection k01-k19, m43_master_c007r_pity p01-p11, m43_master_c005_meta_ceremonies e03-e14 (set and Master ceremonies once, reload replays none), m54_collection_set_master_exactly_once | none needed |
| 027 Robot unlock/equip/perk persistence | m43_master_c008_robots r01-r10 (states, unlock -> ceremony, equip persists, perk text, out-of-order tap, NEW once). m43_master_c005_meta_ceremonies e16-e20. m44_meta_l1_unlock_ftue (facade refuses locked robots) | `m027_robot_rapid_unlock_once` (5 UNLOCK taps -> Moppy only, 250 parts), `m027_robot_idempotent_calls` (re-unlock refused, locked equip refused, equip twice = equipped/already_active, no parts), `m027_robot_relaunch_persist` (relaunch: unlocked + active + parts, Robots row ACTIVE with roster perk, Home shows Moppy) |

## Acceptance criteria
1. [x] SB-M54-022: the table above plus `m022_*` 3/3 ok. Mutation check: with the `_booster_locked` guard in `next_start_prover` disabled, the suite FAILS (3 assertions). So it really pins the "offer only unlocked boosters" rule.
2. [x] SB-M54-023: covered by the table plus `m023_2x_relaunch_idempotent` ok.
3. [x] SB-M54-024: covered by the table plus `m024_*` 5/5 ok (provider mocked, no real SDK).
4. [x] SB-M54-025: existing coverage (table). No gap found.
5. [x] SB-M54-026: existing coverage (table). No gap found.
6. [x] SB-M54-027: covered by the table plus `m027_*` 3/3 ok.
7. [x] One consolidated suite under ~3 min: `tests/m54_regression_pack_022_027.gd`, about 50 s locally. Wired into CI validate with an exact 12/12 guard. CI has not run yet.
8. [x] Real bugs found: none.

## Validation
- `"$GODOT" --headless --path . --import` once. Afterwards I restored the churned `.import` files and deleted the generated untracked `.uid` / `.import` / `.translation` files. project.godot was untouched.
- `python tools/run_suites.py m54_regression_pack_022_027` -> `status=PASS exit=0 diag=0 | M54 regression pack 022-027: PASS (12/12 cases, 0 fail)`, `aggregate=PASS (1/1)` (LOCAL_PASS, about 55 s wall).
- `python tools/run_suites.py --selftest` -> `selftest PASS`.
- Mutation run (guard disabled, then reverted): suite FAIL (3 fail), as expected.
- `git diff --check` clean, tree clean.
- I did not re-run the other existing suites. No product or script file changed, only a new test and the CI list.

## Log
### Round 1
I mapped SB-M54-022..027 to the existing suites (m43_c004_c001, m43_c001a, m43_c003_c001, m43_master_c006/c007/c007r/c008, m43_c005_c008, m43_master_c005_meta_ceremonies, m44_meta_l1_unlock_ftue). Then I wrote one 12-case suite for the uncovered behaviour:
- Need a Hand respects the owner unlock table.
- 2x purchases stay idempotent across relaunch.
- Rewarded callback ordering and pending-at-relaunch.
- Robot rapid-tap, idempotent calls and relaunch persistence.

I added the suite to CI validate with an exact guard. No product bug was found and nothing was pushed.
