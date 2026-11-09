STATUS: READY

# Build: Analytics feature measures (SB-M56-011, SB-M56-017..023)

## Summary
The analytics taxonomy now has the events each feature needs for measurement. Every param is an int, bool or enum. No config ids, no PII, no timestamps. Each event is tracked by one guarded line at a real call site, and no game-logic order changed. Built on factory 116+122.

- New events: `next_cleanup_shown`, `next_cleanup_tap` (017); `journey_progress` (018); `daily_order_done`, `daily_order_claim` (020); `weekly_event`, `first_try` (021); `comeback_window`, `catchup_step` (022); `ranks_view` (011).
- Extended events (new optional params, so `version` stays 1): `pack_opened` gets `pity` (the guarantee was due) and `dry_streak` (pity count bucket); `collection_set_complete` gets `level` (019).
- 023: no new event. The game has no notification delivery path yet, so eligible/suppressed/sent/opened cannot be measured. The doc says so. Measured today: `notify_toggle`, `notification_prompt` and `deep_link_open`.
- Weekly and Catch-Up expiry have no client path. They are derived offline (formulas in the doc). No Weekly event or First-Try is scheduled in `events_v1.json`, so those events stay silent in the shipped build.

Files changed:
- `data/config/analytics_taxonomy_v1.json`
- `scripts/app/main.gd`: WON Results momentum tracking, `continue_from_results` wrapper (body moved to `_continue_from_results`), return window at boot and resume
- `scripts/app/app_state.gd`: pack pity/dry streak, set level, daily/event/First-Try claims via `action_committed`
- `scripts/economy/production_action_facade.gd`: `claim_event_milestone` result carries the input `milestone` index (presentation identity, like `task_index`)
- `scripts/gameplay/runtime/production_gameplay_host.gd`: orders done on the committed win; Weekly/First-Try diff around `events.on_progression_terminal`; Catch-Up steps granted
- `scripts/ui/profile/profile_screens.gd`: `ranks_view` in `open_ranks`
- `tests/m56_analytics_taxonomy.gd`: 21 -> 27 cases
- `.github/workflows/android-family-first10.yml`: exact guard set to 27/27
- `docs/ANALYTICS_TAXONOMY_V1.md`: new events table, not-sent notes, a KPI formula per feature
- `docs/PRIVACY_DATA_INVENTORY.md`: rows for the new events
- `TASKS.md`

Commits: ad0c4137 (taxonomy + tests + CI guard), 9b2b0b7b (call sites), 90848a3c (docs/tasks). Not pushed.

## Acceptance criteria
1. [x] Events/params to measure Next Cleanup shown/accepted: `next_cleanup_shown` {available, image, reason}, `next_cleanup_tap` {ok, reason}. Evidence: m56 `next_cleanup_journey`. Two WON Results gave a teaser with available/ok. CLEAN NEXT gave ok, a stale second tap gave `not_results`, and the accepted tap started L3 (`level_start` launch).
2. [x] Journey node progress (bucketed position): `journey_progress` {slot 1..10, cycle, cycle_complete, first_clear}. m56 shows slot 2 and slot 3, cycle 1. cycle_complete was checked on the L10 journey (slot 10 = length).
3. [x] Pack open new vs duplicate + pity-triggered flag: `pack_opened` pity + dry_streak. m56 `collection_pity`: a pity-due pack had pity true, a new card and dry_streak "0". A non-due pack had pity false and dry_streak "1". Set completion carries `level` (`collection_robot_events`).
4. [x] Daily Scrub Orders progress/claim: m56 `daily_orders`. The orders win_1/win_2/win_3 gave `daily_order_done` easy/normal/stretch on the committed wins. Claims came out as easy, normal, stretch, scrubbox.
5. [x] Weekly join/milestone (+ claim), First-Try start/success/fail: m56 `weekly_first_try`. Weekly sent joined, milestone 1 and 2 reached, then 1 claimed. First-Try sent joined (run 0), advanced 1, completed 2, claimed 2. A first-attempt loss gave reset run 0, and the Weekly event counted nothing for it. Expire: no path exists; it is derived offline (documented).
6. [x] Comeback window opened + Catch-Up step granted: m56 `comeback_catchup`. A 3-day absence plus OS resume opened one `comeback_window` with catchup_offered true. Two first-clear wins sent steps 1 and 2. A second resume opened nothing. Expired is derived (documented).
7. [x] Notification outcomes: toggle and permission result already exist (`notification_events`). The doc states that no delivery exists yet.
8. [x] Ranks view + rank band: m56 `ranks_view` gave {table all_time, band 1}. `weekly` is declared but never sent, because the RANKS screen is a personal all-time ladder (documented).
9. [x] KPI doc extended with each feature's formula: `docs/ANALYTICS_TAXONOMY_V1.md` "Dashboard metrics", rows 017..023 and 011.
10. [x] m56 extended. Schema: `config_schema` covers the task list and requires every event in the taxonomy doc and the privacy inventory. Emission was checked on real paths with throw-away saves. Consent ON vs OFF gives identical economy and progression: `no_economy_change` now also runs `_tour_features`, with differing [] in the log. The PII scan covers every event, there are 0 real drops, and every non-service event was emitted.
11. [x] CI exact guard updated to 27/27 (summary line and verdict echo).

## Validation
All runs were local and are recorded as LOCAL_PASS. A run passes on exit 0 with no SCRIPT ERROR/Parse Error and a final PASS line (`python tools/run_suites.py`, Godot 4.7.2):
- m56_analytics_taxonomy PASS (27/27 cases, 0 fail)
- m58_privacy_inventory PASS (7/7)
- m43_c001a_results_foundation PASS 11/11, m43_master_c007r_pity PASS 11/11, m43_master_c009_daily PASS 12/12, m43_master_c010_meta PASS 12/12, m43_master_c011_c014 PASS 29/29, m39d_daily_collection PASS
- m42_navigation, m40_save_system, m55_economy_release_regression, m39_v04_integration PASS; m43_c003_c001_acquisition PASS 34/34; m43_c005f_phase4_terminal_home_micro PASS 19/19
- m43_c001r_c001_results_momentum (not in the CI list, run directly) PASS 40/40, exit 0
- m43_personal_ranks failed 1 of 8 checks on the first batch run ("snapshot / progression unchanged", the economy snapshot compared across open/close). It then passed in 3 later runs with the change, including the second batch, and passed once with the ranks line reverted. I read it as a timing flake in that check rather than the analytics line, which only calls `track()` and never writes economy. A reviewer may want to look.
- `git diff --check` was clean on all changed files. `--import` churn (.import files, project.godot, generated .uid files) was reverted or removed, and `git status --porcelain` is empty.

## Log
### Round 1
Implemented the taxonomy additions, the call sites, the m56 cases (`next_cleanup_journey`, `collection_pity`, `daily_orders`, `weekly_first_try`, `comeback_catchup`, `ranks_view` and `_tour_features` in the consent OFF/ON economy check), the CI guard, the KPI doc and the privacy inventory, and set TASKS.md queue lines 017..020, 021..023 and 011 to DONE with the checklist marked [x]. Avoided UiText tables and the notification scheduling code (parallel jobs 124/127).
