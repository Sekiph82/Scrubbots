STATUS: READY

# Build: SB-TF-02 Small gameplay fixes (TestFlight feedback 2026-11-18)

## Summary
Branch `factory/181-tf02-gameplay-fixes`, commits `8cebd345` (Scrubbot size), `fff55d24` (Collection tap), `844a6947` (auto 3x, slot hold, intro gate, booster icons, tests, CI guard), `0f46c1be` (speed rule doc wording), `89268dbd` (TASKS.md).

- **Booster icons:** the icon inside each booster button is now 1.05 x the button instead of 0.76 x, so it is 1.38x the old size. `scripts/ui/gameplay_screen.gd` `_make_booster`.
- **Slot pop root cause and fix:** the finish hold was a second countdown in `FiveSlotBatchEngine`, ticked by the runtime controller. It ran next to the pop's own clock in `BoosterVfx._process`. The countdown starts one tick after the pop's clock, so at 120 Hz (the owner's iPhone 17) or with uneven frames it outlasted the visible pop by one frame. The first tap on the frame after the pop had gone was then refused with `slots_full`. I reproduced this on the real panel touch path with the old code: the `120hz` and `jitter` cases each needed 1 extra tick. A pop pushed out of the overlay at `POP_MAX` also left its hold running.
  - Fix: each pop is tagged with its slot (`BoosterVfx.pop_batch(..., slot)`, `is_slot_popping`, `GameplayScreen.is_slot_popping`). A slot's hold is released as soon as its own pop has left the overlay (`FiveSlotBatchEngine.release_finish_holds_if`). That check runs on every runtime sync (`ProductionGameplayHost._refresh_slots`) and again at tap time in `ProductionInputController._commit_activation`.
  - The countdown (`pop_duration()`) remains as the upper bound, so a hold cannot stick. No other lock was found on the real path: the panel front enabled state depends only on supply, and the busy/reentrant guards are synchronous.
  - Limit: this fix gains at most one frame. If the owner's "Olmuyor" means the faint end of the stars phase, that is the preset C timing (1.60 s), which this spec puts out of scope.
- **Scrubbot size:** `ScrubbotVisual.BODY_SPAN_CELLS` 2.4 -> 3.0 and `RetireEcho.ECHO_SPAN_CELLS` 2.1 -> 2.625, still multiplied by the board compensation.
- **Collection:** owned cards no longer have a "Details" button. An invisible full-face Button on the card face carries the same `card:<id>` action, with accessibility name "<card name>, <Details>". Unowned cards have no button. The `COLLECTION_DETAILS` key is kept. `scripts/ui/collection/collection_screen.gd`.
- **Level intro root cause and fix:** the supply front HitAreas are `top_level`, so they are picked above every non-top-level Control, the intro overlay included. Taps on Supply therefore went through the intro.
  - Fix: `main._show_level_intro` calls `host.hold_input_for_intro(intro)`. While the overlay is in the tree, `ProductionInputController.set_intro_blocked(true)` turns off HitArea picking, `activate_front` returns `intro`, `request_booster` returns `intro`, and the speed press is ignored.
  - The gate is released on the overlay's `tree_exited`. Tapping to skip the intro still works and the tap is consumed.
- **Speed:** `GameplaySpeedAuthority` has a separate auto state (`FACTOR_AUTO_3X = 3.0`, `set_auto_3x`, `is_auto_3x`); the paid/manual `set_2x` stays 2.0.
  - Auto wins over a paid 2x. `set_2x(...)`, `toggle()` from any speed-up, and `reset()` all leave auto mode.
  - The input controller sets auto 3x when M23 is exhausted. The host speed button treats auto 3x as "fast", so a press goes to 1x.
  - HUD: `GameplayScreen.set_speed_auto_3x` shows "3x" on the green auto fill; `get_speed_state()` and `get_speed_label()` return "3x".
- **Docs:** `coordination/OWNER_GAMEPLAY_SPEED_RULE_V01.md` (auto 3x amendment), `coordination/OWNER_SCRUBBOT_SIZE_AND_GAMEPLAY_TEMPO_V01.md` (3.0 amendment, 2.4 marked historical), one line each in `docs/01_GAMEPLAY_SPEC.md`, `docs/06_TEST_STRATEGY.md`, `docs/10_LEVEL_FACTORY_GENERATION_SCORING_ARCHITECTURE.md` and `docs/MASTER_UI_SYSTEM.md`, plus comments in the code. AGENTS.md does not mention 2.4 or auto 2x.
- **CI:** the exact guard for `sb_phone_2026_11_12_f_slot_pop_hold` in `.github/workflows/android-family-first10.yml` changes from 46/46 to 100/100.

Files: scripts/app/main.gd, scripts/gameplay/presentation/{scrubbot_visual,scrubbot_retire_echo_controller}.gd, scripts/gameplay/runtime/{gameplay_speed_authority,production_gameplay_host,production_runtime_controller}.gd, scripts/gameplay/slots/five_slot_batch_engine.gd, scripts/gameplay/solver/real_play_driver.gd (comment only), scripts/ui/{gameplay_screen,production_input_controller}.gd, scripts/ui/feel/booster_vfx.gd, scripts/ui/collection/collection_screen.gd, the tests listed below, the docs above, the workflow and TASKS.md.

## Acceptance criteria
All suites were run with Godot 4.7.2 console (`--headless --path <worktree> -s res://tests/<suite>.gd`), either directly or through `python tools/run_suites.py`, which applies the CI PASS rule. The results are LOCAL_PASS.

1. [x] **Pop pickability on the real input path.** `tests/sb_phone_2026_11_12_f_slot_pop_hold.gd` has a new `_real_tap_path` for each of the modes 1x, paid 2x, auto 3x, pause/resume, 120 Hz and uneven frames.
   - Taps go through `BatchSupplyPanel._on_front_gui_input`, then `front_batch_activated`, the input gate and M24. Slots 0..3 hold 30-robot batches.
   - A tap on every tick while the pop is visible is refused (`slots_full`, or `paused` while paused) with supply unchanged. That includes the tick just before the pop ends.
   - The tap on the first tick after the pop lands in slot 4.
   - Output: `SB-PHONE-2026-11-12-F SLOT POP HOLD: PASS (100/100 cases, 0 fail)`; run_suites `status=PASS`.
   - With the old countdown logic swapped back in, the same suite printed `FAIL: 120hz: tap on the first tick after the pop -> accepted into slot 4` and the same for `jitter` (98/100).
2. [x] **Hold equals effect.** In every mode the same suite checks `hold == shown pop: 96 ticks = 1.600 s vs pop_duration 1.60 s (<= one tick)` (at 120 Hz and with jitter the tolerance is the largest frame used) and `pop left the overlay on the release tick` (`vfx.pop_count() == 0`). The existing "hold released on the same tick the pop left the overlay" case still passes.
3. [x] **Scrubbot size.**
   - `tests/m28_c002_c002_r01_visual.gd`: asserts `BODY_SPAN_CELLS == 3.0` and that every live agent body spans exactly 3.0 cells (case renamed `body_span_3_0`). Output: `M28-C002-C002-R01 visual remediation evidence: PASS (10/10 cases, 0 fail)`.
   - `tests/m32_c002_board_independent_size.gd`: asserts the 3.0 / 2.625 constants and an equal on-screen size across boards. Output: `M32-C002 BOARD-INDEPENDENT SIZE: PASS (86 checks, 0 failed)`.
   - `tests/tools/m32_c002_size_snapshot.gd` (rendering run, output written to a scratch folder): the 32x32 reference has local span 3.0000 and compensation 1.0. Body is 65.32 px and echo 57.15 px on every board (20, 32, 38, 59, 59x40, 24x40, 100x100), with measured live bodies at 65.32 px.
   - `grep "BODY_SPAN_CELLS := 3.0"` matches line 52. The size doc now gives 3.0 as current; 2.4 appears only as "historical".
4. [x] **Collection.** k03 in `tests/m43_master_c007_collection.gd` now asserts:
   - no Button whose text is `UiText.t("COLLECTION_DETAILS")`;
   - the owned face has exactly one full-face, focusable Button with empty text whose accessibility name contains Details;
   - the unowned tile has no Button;
   - `pressed` opens `collection_card` for `s2_c0`.

   Output: `M43 master C007 Collection evidence: PASS (19/19 cases, 0 fail)`. Also passing: `M39 Phase D evidence: PASS`, `M54 COLLECTION SET/MASTER EXACTLY-ONCE: PASS`. `tests/m22_028_collection_card_lru.gd` fails one check on thumbnail import format (lossy WebP since SB-AAB-SIZE). That check does not involve the button, and the suite is not in the CI list.
5. [x] **Level intro.** `tests/sb_video_005_level_intro.gd` adds case `intro_blocks_selection` (added to `EXPECTED_CASES`). It runs the real app in a 1080x2160 SubViewport.
   - With the intro up, mouse and touch events at the Supply front, slot 4 and the +1 Slot booster change nothing: supply, slots, booster charges, speed factor and pause are unchanged. `activate_front` returns `intro` and `request_booster` returns `intro`.
   - After `close()` and free, the gate is released, the Supply taps place batches and the booster tap works.
   - Output: `SB-VIDEO-005 level intro: PASS (9/9 cases, 0 fail)`. With the `hold_input_for_intro` call removed, the same case fails 4 checks, which confirms the top_level bypass.
6. [x] **Speed.**
   - `tests/m29_speed_authority_evidence.gd`: auto factor 3.0, `cadence_interval() == base/3`, paid `set_2x(true)` 2.0, reset 1.0, auto takes over a paid 2x, toggle from auto gives 1x, and an auto-3x agent travels 3x the 1x distance per tick. Output: `M29 speed authority evidence: PASS`.
   - `tests/m29_input_gate_evidence.gd`: real panel taps; non-final placements stay at 1x, the final placement gives factor 3.0 even over a paid 2x, plus an intro gate case. Output: `M29 input gate evidence: PASS`.
   - Host level, `tests/m52_r01_parallel_runtime.gd` `_auto_3x_free`: exhaustion gives 3.0 and a free HUD "3x"; a speed press gives 1x with no popup; retry gives 1x. Paid timed 2x then exhaustion gives 3.0; toggle gives 1.0; retry under the timed entitlement gives the paid default 2.0. Output: `M52 R01 PARALLEL RUNTIME: PASS`.
   - `tests/m29_c002_tempo_retune.gd`: an M23-exhausted auto-3x agent moves at 27 cells/s, versus 9 at 1x. Output: `M29-C002 TEMPO RETUNE: PASS`.
7. [x] **HUD.**
   - `tests/m28_c002_c002_static_shell.gd` timed_2x_wallclock: auto mode shows label and state "3x", factor 3.0; timed shows "15:00"/2x.
   - m52 checks "3x" in auto and "2x" for the paid level purchase (existing check).
   - Output: `M28-C002-C002 static master shell evidence: PASS (16/16 cases, 0 fail)`.
8. [x] **Boosters.** `_booster_icons_ok` in `tests/m28_c002_c002_static_shell.gd` runs on the real booted screen for all six shells (5slot/6slot x 3/4/5col). It checks:
   - icon size is at least 1.35x the old icon (0.76 x button); the measured value is 1.38x;
   - the button is at least `TOUCH_MIN` and lies inside the BOOSTERS band;
   - the icon stays inside the band horizontally;
   - the icon does not intersect the supply panel, Scrubby, props, speech bubble or AD rects;
   - the badge draws above the icon.

   Output: `ok: 5slot_3col: booster icons 1.38x ...`, and the same for 6slot_3col, 5slot_4col, 6slot_4col, 5slot_5col and 6slot_5col.

   **Deviation, flagged for review:** the band is 98 ref px tall and the buttons already fill it, so a 1.35x icon (>= 100.6 ref px) cannot fit inside it vertically. The icon extends 2.45 ref px (2.5% of the button) past the band's top and bottom edges. It stays inside its band column and clear of every listed element: the supply rows end at y 1484, Scrubby/props at 1625, the band starts at 1640, and AD starts at 1762. The test asserts exactly this allowance.
9. [x] **No regressions.** run_suites `status=PASS` for `m49_responsive_matrix` (8/8; the spec's "m49_surface_matrix" does not exist), `m50_accessibility_audit` (11/11) and `m60_release_gates` (6/6, after the test fix described in the Log). `git diff --check` is clean.
10. [x] **Docs.** The speed rule doc shows "`3x` free automatic endgame speed-up only (§3; `GameplaySpeedAuthority.FACTOR_AUTO_3X` = 3.0)", the 2026-11-18 amendment, and §3 retitled "Automatic 3x endgame acceleration". TASKS.md has the queue row and detail entry, with "CLAUDE_PEER_REVIEW pending".

## Validation
`python tools/run_suites.py` uses the CI PASS/FAIL rule (exit 0, no SCRIPT ERROR/Parse Error, last PASS/FAIL line PASS, exact guards). Result: PASS for
- sb_phone_2026_11_12_f_slot_pop_hold (100/100, new guard)
- m39b_hearts_speed, m39_v02_integration, m28_c002_c001_gameplay_v02 (14/14), m43_c003_c001_acquisition (34/34)
- m43_master_c007_collection (19/19), m39d_daily_collection, m54_collection_set_master_exactly_once
- m49_responsive_matrix (8/8), m50_accessibility_audit (11/11), m60_release_gates (6/6)
- sb_m22_008_polish_013_slot_fx, sb_polish_003_booster_vfx, m46_performance (22/22), m44_unlock_gate (6/6), m39c_boosters, m49_ad_store_return_layout (6/6)
- real_play_levels (4/4), campaign_l11_l30 (5/5), campaign_l31_l200 (5/5), real_play_file_cli (6/6), difficulty_v1_identical_output (9/9), m55_long_session
- run_tests (`RESULT: ALL PASS`)

The first run of m60 failed, and so did the slot pop hold suite (its old 46/46 guard). Both passed when re-run after the fixes.

Run directly (not in the CI list): all exit 0 and print PASS:
- m29_speed_authority_evidence, m29_input_gate_evidence, m29_c002_tempo_retune, m52_r01_parallel_runtime, m52_owner_supply_plans
- m55_player_chaos (its 5 SCRIPT ERRORs are its own `EXPECTED_FAULT_INJECTION` Spark faults)
- m55_c002_timed_2x_anti_rollback
- m28_c002_c003_r01_remediation (24/24), m28_c002_c003_final_gate (22/22), m28_c002_c002_r01_visual (10/10), m28_c002_c002_static_shell (16/16)
- m32_c002_board_independent_size (86 checks), m22_023_booster_state_art, m28_gameplay_layout_smoke, sb_video_005_level_intro (9/9)

Failures that are not from this change (these suites are not in the CI list and the failing checks are unrelated):
- `m22_028_collection_card_lru` 1 fail: thumbnails are no longer lossless (SB-AAB-SIZE).
- `m43_c005f_phase3_meta_rewards_acquisition` 1 fail: `events_v02_service.gd` names a plugin.

`git diff --check` is clean on every committed file.

Worktree state: the tracked `.import`/`project.godot` changes and the untracked `.uid`/`.import` files were already in the worktree from the Godot import before this build. They were not staged and are left as they were. Test runs modified `coordination/sessions/M28-C002-C002/layout_smoke/*`, which I restored, and wrote `validate_logs/`, which is gitignored.

## Log
### Round 1
- Read the spec, the feedback (fb01 to fb08) and the code paths.
- **Slot pop.** A lockstep 60 Hz probe and a natural-loop probe both showed the hold and the pop ending on the same frame. Running the real panel tap path at 120 Hz and with uneven frames reproduced a one-frame refusal right after the pop, caused by the parallel countdown. Fixed by making each hold follow its own live pop, checked at sync and at tap time.
- **Intro.** Found the top_level supply HitArea bypass: with no gate, the real app test fails. Added the host/input-controller intro gate, the booster refusal and the speed-press guard.
- **Speed.** Implemented the auto 3x as a distinct authority state and updated the HUD.
- **Size, Collection, booster icons.** Implemented the 3.0 span, the Collection face tap and the larger booster icons. Booster icons need about 2.5% overflow past the band (see criterion 8).
- **Tests updated for auto 3x:** m29_c002_tempo_retune (1x/2x pins compare factor; M23 rows expect 27 cells/s), m55_c002, m28_c002_c003_r01_remediation, m28_c002_c002_static_shell.
- **m29_c002_tempo_retune s5.** The 1x-vs-2x truth equivalence was already failing with the old hold logic swapped back in. The cause is the SB-PHONE-F wall-clock holds, which do not scale with tempo. The truth runs now use Reduced Effects (no pop, no hold).
- **m60 g003.** Now taps the Level Intro away before RealPlayDriver plays L2, as a player would. Before this, the new gate correctly refused the driver's clicks with `intro`.
- **Campaign proofs.** The auto 3x endgame does not change any of them: campaign L11-L30, L31-L200, real_play_levels and m52_owner_supply_plans all PASS.
