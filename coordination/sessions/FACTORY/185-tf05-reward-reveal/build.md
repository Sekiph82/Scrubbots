STATUS: READY

# Build: Shared reward reveal (1.5 s hold, then fly) + rewarded x2 Scrub Bucks on win (SB-TF-05)

## Summary
Branch `factory/185-tf05-reward-reveal` (commits dcf0d059, 3665a7f9, f11af55f, 4afc10aa, 85e3ce81 on e141f988).

Every reward source now goes through one presenter, `scripts/ui/components/reward_reveal.gd` (`RewardReveal`, owned by Home). It shows every entry together (0.12 s fade), holds exactly `HOLD_S = 1.5` s, then flies min(N, 5) staggered copies per entry to the HUD target while the counters step to their exact final values. A full-rect `MOUSE_FILTER_STOP` layer sits on its own CanvasLayer (layer 70, above the ModalStack's 64) and blocks every tap from the first frame to the last arrival. While a reveal runs, `main.handle_back` returns "none", and ceremonies, earned packs and coach tips wait for `reward_flight_finished`. A request that arrives while a reveal runs is queued behind it. The layer dims the screen during the hold. The clock is `advance(dt)`: the layer's `_process` drives it, and tests set `manual_clock`. There is no wall-clock timer. Reduced Effects keeps the appear and the 1.5 s hold, then lands the final values with no copies and no growth. A pack entry grows during the hold and then hands over to the existing earned-pack flow. One-shot per key.

The x2 button ("WATCH AD · x2" / "REKLAM İZLE · x2") appears only during the win hold, and only when the receipt is WON with Scrub Bucks > 0 and the rewarded provider reports `rewarded_win_double` available. A tap pauses the hold clock while the ad plays (bounded by `AD_TIMEOUT_S` 60 s). The grant goes through the facade (`win_double_available` / `start_win_double` / `abandon_rewarded`) and then `RewardedGrantService.start_win_double` / `resolve`. That commits `{scrub_bucks: receipt wallet_delta.scrub_bucks}` under the deterministic tx `win_double:<receipt key>` (M40-persisted ledger). Only `completed` with `verified == true` commits. A granted result doubles the SB "+N" and lets the rest of the hold continue. Anything else starts the flight at once with the normal amount.

`main.gd` `request_reward_reveal(source, rewards, key)` is the single entry for non-win sources. It is wired to:
- facade `action_committed`: Tasks / ScrubBox, Daily, Gift, Events (milestone, First Try, V02), Rewarded Ads slot 1, Achievements, Shop Heart / refill / booster buys
- `RewardedGrantService.resolved`: verified Heart / booster videos and Rewarded Ads slots 2..5
- `StoreService.resolved`: SB packs
- `RewardGrantService.granted`: `collection_set:*` / `collection_master`

Each reveal is built from the committed result or the ledger (`RewardGrantService.applied_rewards(tx)`, a new read-only accessor), never recomputed. Reveals play on the Home route only; on any other route the live values are already shown. `HomeRewardFlight` keeps only `ICONS` + `plan(receipt, vm)`.

Files changed:
- New: `scripts/ui/components/reward_reveal.gd`, `tests/sb_tf05_reward_reveal.gd`, `tests/tools/sb_tf05_reveal_capture.gd`
- Code: `scripts/ui/home/home_reward_flight.gd`, `scripts/ui/home/home_screen.gd`, `scripts/app/main.gd`, `scripts/app/app_state.gd` (ad_result product `win_double`), `scripts/economy/rewarded_grant_service.gd`, `scripts/economy/production_action_facade.gd` (also copies `booster` id into the `buy_booster_charge` result), `scripts/economy/reward_grant_service.gd`, `scripts/economy/heart_service.gd` (refill result carries `added`), `scripts/ui/ui_text.gd`, `scripts/ui/ui_text_tr.gd`, `data/config/analytics_taxonomy_v1.json` (`ad_product` + `win_double`)
- Docs / CI: `coordination/OWNER_ECONOMY_REWARDS_V01.md`, `docs/MASTER_UI_SYSTEM.md`, `docs/ACCESSIBILITY.md`, `docs/ANALYTICS_TAXONOMY_V1.md`, `AGENTS.md`, `.github/workflows/android-family-first10.yml`
- Tests updated for the intentional change (see Log): `sb_phone_2026_11_12_e_win_home`, `m43_c005_c005_reward_reveal_sequencer`, `m42_home`, `m43_c003_c001_acquisition`, `m43_c005f_015_e2e_feel`, `m43_c005f_phase2_r01_earned_pack_runtime`, `m43_c005f_phase3_meta_rewards_acquisition`, `m43_r15_owner_remediation`, `m44_ftue`, `m44_meta_l1_unlock_ftue`, `m47_touch_r01_mobile_ux`, `m49_ad_store_return_layout`, `m50_accessibility_audit`, `m54_regression_pack_037_038`, `m55_player_chaos`, `tests/tools/win_home_capture.gd`

## Acceptance criteria
1. [x] New suite `tests/sb_tf05_reward_reveal.gd` with the fixed `EXPECTED_CASES` ledger (16 cases since round 2). `godot --headless -s res://tests/sb_tf05_reward_reveal.gd` exits 0, has no SCRIPT ERROR, and its last line is `SB-TF-05 reward reveal evidence: PASS (16/16 cases, 0 fail)`. Cases (case 16 `play_label_gap` added in round 2, see Log):
   1. [x] `timeline`: `HOLD_S == 1.5` and APPEAR_S 0.12. At t=0.06 both entries show the same alpha; at 0.12 both are fully shown. The flight starts at exactly APPEAR_S + HOLD_S. After 1.49 s of hold no copy is visible; 0.02 s later copies fly. `completed` fires once after hold + flight, and the counters land exactly on the final values.
   2. [x] `input_lock`: real main root. The layer is `MOUSE_FILTER_STOP`, full-rect, on a CanvasLayer above the ModalStack. Real taps on `ProfileButton` at t = 0 / 1.0 / 1.6 do nothing, and `handle_back()` returns "none". After `completed` the same tap fires.
   3. [x] `empty_entries`: `[]` and zero-amount entries are refused, with no layer, no lock and no pending completion.
   4. [x] `reduced_effects`: shown at once and locked, zero copies, still holding at 1.0 s with counters at the start values. Completes right after the 1.5 s hold with final values and the lock freed.
   5. [x] `one_shot_finish`: the same key is refused the second time. `finish()` completes once, lands the final values and frees the lock. A finished key never replays. A request during a reveal queues behind it.
   6. [x] `win_entries`: from the receipt `plan()` gives scrub_bucks, bot_parts, gift_meter, collection_cards. There is no win-streak target, and LOST gives nothing.
   7. [x] `x2_visibility`: shown for WON with SB > 0 and an ad ready, with the `REVEAL_WATCH_X2` text, and gone when the hold ends. Hidden for LOST, for 0 SB, for a non-win source (daily) and when the provider is unavailable.
   8. [x] `x2_granted_once`: the tap makes one request (placement `rewarded_win_double`) and the button is gone. A verified completion adds exactly +30 SB under `win_double:win:a1:L1`, and the label shows "+60". A second tap, a duplicate callback and a second `start_win_double` grant nothing. The flight counts to the doubled wallet. After save + reload into a new AppState the tx is still applied and a new attempt is refused (`already_claimed`) with the wallet unchanged.
   9. [x] `x2_not_granted`: cancelled, failed, `verified:false`, verified missing and timeout (advance past `AD_TIMEOUT_S`, then a late verified callback) each leave the wallet and ledger unchanged. The flight starts at once (`elapsed == fly_at`), the button is removed and the amount stays "+30".
   10. [x] `hold_pauses_during_ad`: 20 s of advance while the ad is pending leaves the clock still and nothing flying. After a grant the remaining hold is exactly 1.0 s: no copy at +0.99 s, flying at +1.01 s.
   11. [x] `x2_only_scrub_bucks`: SB +30, while Bot Parts, gift snapshot, collection snapshot, streak, hearts and ad plays are unchanged. The cards entry keeps its amount.
   12. [x] `no_ads_and_test_mode`: with No Ads owned the banner is off, rewarded stays allowed, x2 is offered and +25 is granted. A static check finds no `test_mode` / `ads_test` special case in the reveal or the Home x2 path.
   13. [x] `routing_all_sources`: real committed claims on the main root each produce exactly one `reveal_log` entry with the right source, and the reveal changes no economy value. Sources: win (`_start_win_rewards`), daily (`claim_daily_login`), tasks (`claim_daily_task`, wallet = +75 from the result), gift_meter (`claim_gift`), events (`claim_event_milestone`), rewarded_ads (slot-1 claim and a verified booster video), shop (`buy_booster_charge` and a store-delivered `scrubbucks_100`), collection (set 1 completed). A static scan of every `scripts/ui/**.gd` finds no `.grant(` / `.credit(` / `.debit(` / `RewardGrantService.` and no other script that builds a `RewardFlightLayer`.
   14. [x] `card_pack_handoff`: the pack is a grow hero, not a flight burst; its scale goes 1.00 -> 1.35 during the hold, then it hides with no copies. On the main root no pack opens while the reveal runs, and `packs.drain()` is observed exactly once after it.
   15. [x] `presenter_source_clean`: `reward_reveal.gd` contains no `wallet`, `RewardGrantService`, `.grant(`, `save` or `create_timer`.
2. [x] CI guard: `sb_tf05_reward_reveal` is on the suite loop line right after `sb_tf04_gameplay_layout`. A summary step greps `grep -qxF 'SB-TF-05 reward reveal evidence: PASS (16/16 cases, 0 fail)' validate_logs/sb_tf05_reward_reveal.log` and echoes `REWARD-REVEAL verdict=PASS (16/16)`, otherwise FAIL with `fail=1`, mirroring the SB-TF-04 block. `python tools/run_suites.py --list` includes it. `ios-ipa.yml` is untouched.
3. [x] Existing suites: see Validation. The `sb_phone_2026_11_12_e_win_home` exact 10/10 guard is unchanged (still 10/10).
4. [x] `git diff --check e141f988 HEAD` is clean. `godot --headless --path <wt> --quit` prints no SCRIPT ERROR or Parse Error. Every touched script loads in the suites above with diag=0 except documented fault injection.
5. [x] Doc checks: `grep -n "2026-11-18" coordination/OWNER_ECONOMY_REWARDS_V01.md` finds line 441 (the amendment). `grep -n "no rewarded 2x" scripts/economy/rewarded_grant_service.gd` finds nothing, and the header lists `"win_double:<key>"`. `grep -c reward_reveal AGENTS.md docs/MASTER_UI_SYSTEM.md` gives 1 / 1.
6. [x] `grep -rn "wallet\.\|RewardGrantService" scripts/ui/components/reward_reveal.gd scripts/ui/home/home_reward_flight.gd` finds no matches at all.

Evidence captures: `factory/jobs/185-tf05-reward-reveal/evidence/`. They come from `godot --path . -s res://tests/tools/sb_tf05_reveal_capture.gd -- <dir> en` (real main.tscn on a test save, real Level 1 WON, 1080x2280 logical saved at 720x1520):
- `01_win_reveal_hold_x2_button.png`: win reveal holding, +51 SB / +1 Bot Parts / +1 Gift Meter, green WATCH AD · x2 button, dimmed screen
- `02_win_reveal_doubled.png`: after a verified completed view, SB shows +102
- `03_win_reveal_mid_flight.png`: copies flying to the SB chip, profile card and Gift Meter
- `04_daily_claim_reveal.png`: a non-win source (Daily login claim) whose reveal sits over the Daily popup

## Validation
Godot 4.7.2 (`C:/Users/sekip/AppData/Local/Microsoft/WinGet/Links/godot.exe`), headless, run in the worktree. LOCAL_PASS = exit 0, no SCRIPT ERROR / Parse Error, last PASS/FAIL line PASS (same rule as `tools/run_suites.py`).

Final run on HEAD code, 61 suites, the spec list plus every claim-path suite:
- **LOCAL_PASS (55, round 1):** sb_tf05_reward_reveal 15/15 (16/16 in round 2), sb_phone_2026_11_12_e_win_home 10/10, sb_tf03_home_profile 11/11, sb_tf04_gameplay_layout 7/7, m43_c005_c005_reward_reveal_sequencer 12/12, m43_master_c005_meta_ceremonies 33/33, m43_c001a_results_foundation 11/11, m43_c005_c072_feature_unlock_ceremony 9/9, m44_contextual_coach 7/7, m44_pending_packs_gate 6/6, m50_accessibility_audit 11/11 (re-run after the ledger fix), m54_world_regression 8/8, m54_regression_pack_037_038 6/6, m55_long_session, m57_ads_cadence 6/6, m57_native_providers 14/14, m57_store_products 9/9, m49_ad_store_return_layout 6/6, m60_release_gates 6/6, ev02_events_v02 10/10, ev02_events_ui 6/6, m39d_daily_collection, m40_save_system, m40_v02_safety, m40_v03_canonical, m40_v04_bootstrap, m43_master_c005r_gift_micro_progress 8/8, m43_master_c009_daily 12/12, m44_meta_verify_achievements_gift 4/4, sb_gift_meter_48h 7/7, sb_polish_002_gift_meter 11/11, sb_video_006_gift_meter_video 6/6, m39_v04_integration, m42_home, m43_c002_c001_popup_modal_pause 23/23, m43_c003_c001_acquisition 34/34, m43_c004_c001_fail_need_a_hand 40/40, m43_c005_c074_c077_celebrations 6/6, m43_master_c006_shop 15/15, m43_master_c010_meta 12/12, m43_master_c011_c014 29/29, m43_r15_001_r01_sequential_unlock 14/14, m43_r15_owner_remediation 18/18, m43_ranks_weekly 7/7, m44_featured_card_onboarding 8/8, m44_ftue 23/23, m44_meta_l1_unlock_ftue 6/6, m46_r07_ui_legality, m47_touch_r01_mobile_ux 14/14, m54_cloud_save_seam 7/7, m54_regression_pack_022_027 12/12, m54_regression_pack_028_036 12/12, m56_analytics_taxonomy 27/27, sb_phone_2026_11_12_c_copy_state 8/8, m51_localization_readiness 8/8.
- **PASS line and exit 0, but the only SCRIPT ERRORs are the documented `EXPECTED_FAULT_INJECTION` ('explode' on null in a spy plugin):** m43_c005f_phase2_results_pack_feel 9/9, m43_c005f_phase2_r01_earned_pack_runtime 22/22, m55_player_chaos PASS. None of these is on the CI suite list; baseline e141f988 shows the same pattern.
- **Pre-existing failures, identical on baseline e141f988:** I checked these in a temporary detached worktree, since removed. Each fails only on `res://scripts/economy/events_v02_service.gd` containing the robot name "Spark" (its `ROBOT_NAMES` list), which the plugin-name scan reads as a plugin reference. Not touched by this job, and none is on the CI list.
  - m43_master_c005f_feel (2 fail)
  - m43_c005f_015_e2e_feel (1 fail)
  - m43_c005f_phase3_meta_rewards_acquisition (1 fail)

Other CI-list suites I ran on this branch, all LOCAL_PASS: m43_c005f_phase4_terminal_home_micro 19/19, m42_navigation, cp04_remote_content_runtime 28/28, cp05_remote_content_cache 15/15, m55_economy_release_regression, run_tests (ALL PASS), cp05_r01_transaction_cleanup, remote_content_family_fixture, cp06_disabled_levels 16/16, m39a/b/c/e, m39_v02_atomicity / capacity / integration, m39_v03_full_surface / integration, m39_v04_tornado_inflight, m39_c003_random_any_booster_rewards, m41_settings, m59_credits, m45_debug_tooling, m49_responsive_matrix, m44_unlock_gate, m44_new_badge, sb_polish_004_006_ui_batch, sb_polish_003_booster_vfx, sb_m22_008_polish_013_slot_fx, m43_c005f_phase6_unlock_feel, m43_master_c007_collection, m54_collection_set_master_exactly_once, m43_master_c008_robots, m43_master_c007r_pity, m43_personal_ranks, m59_app_version, m58_privacy_inventory, m58_privacy_consent, m43_172_local_notifications, m44_robot_assembly_stages. That run started after commit dcf0d059 and before the reveal's dim / button style change and the m50 comment fix. The later run above covered the Home / claim suites on the final code.

Not run, because they are gameplay / level-data only and untouched by this job: real_play_levels, real_play_file_cli, campaign_l11_l30, campaign_l31_l200, difficulty_v1_identical_output, m35_level_catalog, m37_level_progression, m46_performance, m28_c002_*, ui_vis_006_asset_qa, sb_phone_2026_11_12_f_slot_pop_hold, board_bg01_backdrop, m50_color_symbols.

Other checks:
- `git diff --check e141f988 HEAD`: clean.
- `godot --headless --path <wt> --quit`: no SCRIPT ERROR or Parse Error.
- No APK/IPA builds.
- TASKS.md not edited, per the orchestrator.
- The worktree's remaining dirt is pre-existing Godot import output (`project.godot` re-saved by the editor, `.import` line endings, untracked `.uid` / `.translation` / `.import` files). None of it was staged; I left it as instructed.

## Log
### Round 1
- Built `RewardReveal` (clock-driven timeline, CanvasLayer lock above the ModalStack, queue, Reduced hold, pack grow, x2 seam). Reduced `HomeRewardFlight` to `plan()` + `ICONS`, and rewired Home (`play_reward_flight` / `reveal_rewards` / `is_reward_flight_running` / `reward_flight_finished` unchanged in meaning) and `main.gd`, whose central `request_reward_reveal` takes the four committed-result signals.
- Added the win x2 product to `RewardedGrantService`, sharing a `_request_grant` helper with daily slots, plus the facade entry points, analytics `ad_product` `win_double`, EN/TR text, the economy-doc amendment, the service header fix, and the MASTER_UI_SYSTEM / ACCESSIBILITY / ANALYTICS / AGENTS docs and CI guard.
- Judgment calls:
  - The Daily "Day N" and ScrubBox popups are kept. They carry streak / ScrubBox story copy, not just the reward line, and the reveal plays over them.
  - Story ceremonies are unchanged and queue after the reveal.
  - The safety bound is the deterministic timeline end plus `AD_TIMEOUT_S` while an ad is pending. The layer runs `PROCESS_MODE_ALWAYS`, so no separate scene timer exists. This replaces the old scene timer, which tests could not advance.
- Intentional behaviour changes reflected in existing suites. Every committed reward now shows a 1.5 s+ locked reveal before ceremonies, packs, coach tips, Back and taps. Suites that claimed and then immediately checked the follow-up now land the reveal (`finish()`, looping for queued reveals): m42_home, m43_c003, 015_e2e_feel, phase2_r01, phase3, r15, m44_ftue, m44_meta_l1, m47_touch, m49_ad_store, m54_037_038, m55_player_chaos.
- sb_phone_e and c005_c005: Reduced now holds and then lands, instead of landing at once, and the `_seq` internals are replaced by `elapsed()` / bursts.
- m50 ledger: `reward_reveal.gd` replaces `home_reward_flight.gd`.
- c005_c005 also expected `plan.size() == 4`. That is stale: SB-TF-03 (a9bd6dd6, after the test's last change 53fe4766) removed the streak entry, the suite is not on the CI list, and I did not run it on baseline. It now expects 3 (SB, Bot Parts, Gift Meter).

### Round 2
Review `round-1/review.md` (REWORK). Findings and fixes:
1. **PLAY label touched the triangle** (SB-TF-03 origin). `home_screen.gd`: the label's content area now ends `PLAY_TEXT_RIGHT` = 120 px from the right edge (was 96), 16 px left of `PlayTriangle` (offset_left -104). The fit moved into `fit_play_text(play, text)`, which `_render_play` calls; it fits against the same stylebox margins, so the fit width stays in sync. New sb_tf05 case `play_label_gap` checks the real Home PLAY button for levels 2 / 99 / 999 / 9999 in EN ("PLAY · LEVEL N") and TR ("OYNA · LEVEL N"). The fitted text's right edge, outline included, sits 16.0 to 18.5 px left of the triangle, and the text fits the content width. The font fits at 44 to 34 px. Suite now 16/16; CI guard and comment updated to 16/16. evidence/01 refreshed and shows the gap; the other three captures were refreshed too.
2. **Stray tab run in `win_double_available`.** It was a literal backslash-n left by my scripted edit. It is now a proper `\` line continuation. The same artefact in `sb_phone_2026_11_12_e_win_home.gd` (`_results_won_branch_removed`) is fixed too. A scan of the branch diff finds no other such run.
3. **Hard-coded 1 for Heart / booster buys.** `HeartService.purchase_plus_one` and `BoosterInventory.buy_charge` now return `added` (1) in their committed results, the same as `purchase_full_refill`'s `added`. `main._reveal_action` reads `added` for `buy_heart`, `refill_hearts` and `buy_booster_charge`. `buy_charge` already returned `booster`, so I reverted my round-1 facade line that copied the id.
4. **`AD_TIMEOUT_S` 30 -> 60 s.** sb_tf05 now checks that:
   - the reveal is still pending after 59 s;
   - the timeout fires after 60 s;
   - a late verified completion after the timeout grants nothing (wallet and ledger unchanged);
   - the input lock is released after the flight, for every no-grant outcome;
   - a 59 s ad keeps the clock still and the grant still continues the remaining hold.
5. **m54_regression_pack_037_038 "explode" SCRIPT ERRORs.** I ran it on main e141f988 in a temporary detached worktree, since removed. Main prints the same `EXPECTED_FAULT_INJECTION: THROWING` banner and 13x `SCRIPT ERROR: ... 'explode' in base 'Nil'`. This branch prints the identical banner and 13 errors. The suite's THROWING arm raises them deliberately, `tools/run_suites.py` lists it in `INJECTED_SUITES`, and it ends PASS 6/6 on both. They are not new, so no change was made.

Round 2 validation, all LOCAL_PASS (exit 0, last line PASS, diag 0):
- sb_tf05_reward_reveal 16/16
- sb_tf03_home_profile 11/11
- sb_phone_2026_11_12_e_win_home 10/10
- m54_regression_pack_037_038 6/6 (only the documented injected errors)
- m42_home
- m43_c003_c001_acquisition 34/34
- m43_master_c006_shop 15/15
- m43_c004_c001_fail_need_a_hand 40/40
- m57_ads_cadence 6/6
- m57_native_providers 14/14
- m39c_boosters
- m39b_hearts_speed
- m49_responsive_matrix 8/8

`git diff --check` is clean. TASKS.md not edited.
