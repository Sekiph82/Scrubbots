STATUS: READY

# Build: SB-M54-028..030 + 033..036 regressions (Tasks/Daily/Gift/badges, BottomNav/modal stack, FTUE once-only, Next Cleanup/journey, Collection pity, Daily/Event retention, Comeback/notifications)

## Summary
I mapped every checklist row to assertions that already exist and added one consolidated suite for the real gaps. No product bug turned up, so no product code changed. One local-only suite in the coverage map, `m43_c002_c001_popup_modal_pause`, had gone stale: since the SB-M44-032 booster gate its L2 fixture saw locked boosters. I moved it onto the documented `AppState.test_unlock_all` seam.

Files changed (branch `factory/125-regressions-tasks-nav-ftue`, not pushed):
- `tests/m54_regression_pack_028_036.gd` (new, 12 cases, about 47 s locally). It uses the real app root (main.tscn) on throw-away saves, with an injected clock and local day. AppState-level cases use CloudSave envelopes. `test_unlock_all` is reset at the end.
- `.github/workflows/android-family-first10.yml`: header comment added, the suite appended to the shared validate list, and an exact guard `M54 regression pack 028-036: PASS (12/12 cases, 0 fail)`.
- `tests/m43_c002_c001_popup_modal_pause.gd`: `test_unlock_all = true` at start and false at the end, the same pattern as m43_master_c010_meta.
- `TASKS.md`: two queue lines set to DONE, and the seven checklist rows (028, 029, 030, 033, 034, 035, 036) marked [x] with their coverage.

Commits: `ae974f0e` (suite + CI), `b7413dfc` (c002 seam fix), `b79f2c3f` (docs/tasks).

## Coverage map (row -> existing assertions -> gap filled)
| Row | Already covered by | New in m54 pack 028-036 |
|---|---|---|
| 028 Tasks/Daily/Gift/badges | m43_master_c009_daily t01..t12 (orders, claim once + relaunch, ScrubBox once, Daily states / rollover / rollback, Gift claim + history, duplicate taps). m43_master_c010_meta m10 (HomeBadges per surface, cleared when handled). sb_polish_002_gift_meter. m47_touch_r01 r01/r02 (Rewarded Ads badge + relaunch). m44_new_badge | `m028_badges_claims_relaunch`: the Home Tasks/Daily pills equal HomeBadges after a partial claim, after a relaunch, and after claiming everything plus a relaunch (all 0). Relaunched re-claims of a task, the ScrubBox and the login are refused and pay nothing. `m028_badges_next_day`: the next local day brings back Daily 1 and leaves Tasks at 0 |
| 029 BottomNav/modal stack | m43_master_c010_meta m01/m02. m42_navigation (back, settings overlay, duplicate transitions). m43_c002_c001_popup_modal_pause (stack order, top-only input, back closes the top; local). m49_surface_stress v04 (LIFO; local). m55_player_chaos 021 (200x churn; local) | `m029_tab_double_tap_one`: a double press on EVENTS/ROBOTS/RANKS opens exactly one destination, and back closes it. `m029_modal_lifo_back`: Profile -> Achievements, back closes Achievements then Profile, and back on a bare Home does nothing. `m029_settings_back`. All are now in CI, where before only the local suites asserted LIFO |
| 030 FTUE / feature-unlock once-only | m44_ftue t03/t17/t19/t22/t23. m44_meta_l1_unlock_ftue booster_intro_once / old_save_same_gate. m44_contextual_coach c05/c06. m44_unlock_gate. m43_c005_c072 c/d (reload/import never replays) | `m030_ftue_once_cloud_restore`: the L6 +1 Slot intro and the first-win tip are acknowledged and cloud-restored onto a fresh device. The bootstrap is a replay (charges still 2/2/2/2), nothing is replayed, there is no What's New, the relaunch is the same, and the next intro (Random) still comes at L11. Runs with the real unlock table |
| 033 Next Cleanup / journey | m43_c001r_c001_results_momentum t01..t35 (exact next, missing frontier, L10/L11 cycle boundary, injected next-cycle transition, nodes inert, save/reload, CLEAN NEXT rapid taps). m42_navigation duplicate_transitions / no_shipping_level_select | none needed (c001r LOCAL_PASS 40/40; it is not in the CI list) |
| 034 Collection pity | m43_master_c007r_pity p01..p11. m43_master_c011_c014 s03 (byte-identical economy restore) | `m034_pity_source_idempotent`: the same reward source granted twice gives one pending pack, a replayed open returns the same receipt and counts once, and a second ack does nothing. `m034_pity_relaunch_cloud`: the sprint counter and guarantee survive a relaunch and a cloud restore, a relaunched re-grant is refused, and the next pack on the new device holds the missing s1_c8 and resets the counter |
| 035 Daily/Event retention | m43_master_c009_daily t02/t05/t07/t12. m43_master_c010_meta m06 (replay farming in one session), m07, m08 (First-Try loss reset), m09 (bests) | `m035_event_rollover_relaunch`: event progress, the claimed milestone, the First-Try run and the best streak/run survive a local-day rollover and a relaunch, a re-claim is refused, and the Profile Best row shows 3/3. `m035_replay_after_relaunch`: a replay after the relaunch farms nothing, and a first-try loss gives run 0 / best 3 / progress 3, which also survives a relaunch. The ScrubBox re-claim after relaunch is in m028 |
| 036 Comeback/notifications | m43_master_c011_c014 c01..c05 (absence, rollback, Catch-Up incl. Daily untouched), n01..n05 (opt-in, priority collapse, cap, quiet hours, rollback cap across reload, timezone). m43_146_notification_permission (local) | `m036_comeback_keeps_reminders`: the reminders are set through the real Notifications screen. A 49 h relaunch opens one window and leaves the prefs and last-sent untouched; with Daily OFF the single message is Hearts and there is no comeback category; quiet hours still apply; a Catch-Up first clear changes neither the reminders nor the Daily login rule. `m036_rollback_no_window_cap`: with the clock rolled back 10 days no new window opens and the cap holds; once the clock passes the cap one reminder is allowed in the same window |

## Acceptance criteria
1. [x] SB-M54-028: the table above, plus `m028_*` 2/2 ok.
2. [x] SB-M54-029: the table above, plus `m029_*` 3/3 ok. The c002 local suite is repaired and passes 23/23.
3. [x] SB-M54-030: the table above, plus `m030_ftue_once_cloud_restore` ok.
4. [x] SB-M54-033: covered by existing suites (m43_c001r 40/40 LOCAL_PASS, m42_navigation PASS). No gap.
5. [x] SB-M54-034: the table above, plus `m034_*` 2/2 ok.
6. [x] SB-M54-035: the table above, plus `m035_*` 2/2 ok. Mutation check: with `EventService.snapshot()` saving `first_try: {}`, the suite FAILS (2 assertions in m035). The change was reverted.
7. [x] SB-M54-036: the table above, plus `m036_*` 2/2 ok.
8. [x] One consolidated suite under ~3 min, wired into CI validate with an exact 12/12 guard. CI has not run yet.
9. [x] Real bugs found: none in product code. One stale local test fixture was fixed (c002, see Summary).

## Validation
- `"$GODOT" --headless --path . --import` was run. Restoring the generated untracked `.import` files mid-job broke resource loading (the "No loader found" errors), so I killed that first mapped run and re-imported. At the end I restored project.godot and the churned tracked `.import` files and deleted the generated untracked `.import` / `.uid` / `.translation` files. Tree clean.
- `python tools/run_suites.py --selftest` -> selftest PASS.
- `python tools/run_suites.py m54_regression_pack_028_036 m43_master_c009_daily m43_master_c010_meta m43_master_c011_c014 m43_master_c007r_pity m44_ftue m44_meta_l1_unlock_ftue m44_new_badge m42_navigation m44_unlock_gate m44_contextual_coach sb_polish_002_gift_meter m47_touch_r01_mobile_ux` -> aggregate=PASS (13/13), each exit 0 diag 0 (LOCAL_PASS). The new suite printed `M54 regression pack 028-036: PASS (12/12 cases, 0 fail)`.
- Local-only suites (direct Godot): m49_surface_stress PASS 4/4, m43_c001r_c001_results_momentum PASS 40/40, m43_146_notification_permission PASS 8/8, m43_c002_c001_popup_modal_pause FAIL 20/23 before the fix and PASS 23/23 after (exit 0, no SCRIPT ERROR / Parse Error).
- Mutation run (EventService first_try snapshot dropped): suite FAIL as expected, then reverted.
- `git diff --check` clean. `git status --porcelain` empty.

## Log
### Round 1
I mapped SB-M54-028..030 and 033..036 onto the existing suites. Then I wrote one 12-case gap suite covering:
- badge consistency across claims, relaunch and a new day;
- the nav double tap and modal LIFO, now in CI;
- FTUE once-only across a cloud restore;
- pity reward-source idempotency plus relaunch and cloud restore;
- event, First-Try and bests across day rollover, relaunch and replay;
- the comeback against reminder preferences and the rollback cap.

I added the suite to CI validate with an exact guard. I found the local c002 popup suite stale after the booster gate and moved it onto the documented test seam. No product bug was found and nothing was pushed or rebased.
