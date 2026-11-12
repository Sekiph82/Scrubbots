STATUS: READY

# Build: SB-PHONE-2026-11-12-B — after a win the player goes back to Home

## Summary
Branch `factory/149-win-to-home`, commit `0ecbb4d8` ("Results: a win goes Home; drop CLEAN NEXT and Next Cleanup teaser").

Owner decision 2026-11-12 (supersedes the M43-C001R next-level CTA): the WON Results screen now has exactly one visible action, the green primary **ANA SAYFA / HOME**. The SIRADAKİNİ TEMİZLE / CLEAN NEXT button and the SIRADAKİ TEMİZLİK / BÖLÜM N teaser card are gone. The reward rows, journey strip, ceremonies (Gift Bar popup etc.), robot video and emblem stay. The next level starts only from Home PLAY. The LOST flow (Retry primary + Home secondary) is unchanged.

Every path that could start a level from a WON Results is closed:
- `ResultsScreen`: `continue_requested`, the Continue latch, the teaser card nodes, `get_teaser_image` / `get_next_cleanup_panel`, the "Level N is coming soon" note and the M42 `show_result(payload, available)` shim were removed. On WON the primary emits `home_requested`, and the secondary Home button is hidden. A ceremony barrier now holds only the primary's emphasis pulse. It never disables HOME.
- `main.gd`: `continue_from_results` / `_continue_from_results` were removed. `_results_model` no longer carries `continue` availability. `retry_from_results` refuses after a WON.
- `NavigationController.can_go`: RESULTS → GAMEPLAY is refused while the shown Results is WON. This is the root guard: Retry still works after a LOST, and Back from Results still goes HOME.
- `ResultsMomentum`: the Next Cleanup read model (`next_cleanup`, `crop_rect`, `stable_hash`, the preview image load on every win) was removed. `results_model(app_state, level, cfg)` returns only the journey.
- **Interstitial ads:** the SB-M57-001 every-5-plays interstitial used to fire at Results → CLEAN NEXT. That transition no longer exists, so it now fires at Home PLAY (and at Retry as before). This keeps the owner's "between levels" ad cadence. Without it, wins would never show an interstitial.
- **Analytics:** `next_cleanup_shown` and `next_cleanup_tap` (SB-M56-017, the CLEAN NEXT conversion measure) were removed from the code, `analytics_taxonomy_v1.json`, `docs/ANALYTICS_TAXONOMY_V1.md` (the KPI row is marked retired) and `docs/PRIVACY_DATA_INVENTORY.md`. The `hearts_empty.at` value `results_continue` was dropped. `journey_progress` (018) stays. The next-level start is now measured as the Home PLAY `level_start`.
- **UiText:** `RESULTS_CLEAN_NEXT`, `NEXT_CLEANUP_TITLE/LEVEL/FACTS/SOON` and `RESULTS_NEXT_UNAVAILABLE` were removed from EN and TR. They are no longer used anywhere.
- **Registry / docs:** the `results.clean_next` route was removed from `ui_surface_registry_v1.json`. `docs/RELEASE_GATES.json/.md` were regenerated with `m60_release_gates -- --write`, so verdicts are unchanged and only the evidence text changed. A superseded note was added to `coordination/sessions/M43-C001R-C001/MOMENTUM_MATRIX_V01.md` (the M43-C001R spec matrix). The `docs/ACCESSIBILITY.md` row was updated.

Files changed: `scripts/ui/results_screen.gd`, `scripts/app/main.gd`, `scripts/app/navigation_controller.gd`, `scripts/progression/results_momentum.gd`, `scripts/ui/ui_text.gd`, `scripts/ui/ui_text_tr.gd`, `data/config/analytics_taxonomy_v1.json`, `data/config/ui_surface_registry_v1.json`, `docs/ACCESSIBILITY.md`, `docs/ANALYTICS_TAXONOMY_V1.md`, `docs/PRIVACY_DATA_INVENTORY.md`, `docs/RELEASE_GATES.json`, `docs/RELEASE_GATES.md`, `coordination/sessions/M43-C001R-C001/MOMENTUM_MATRIX_V01.md`, and 22 test files (listed under Validation).

TASKS.md was not edited, per the orchestrator's instruction (the orchestrator updates the SB-PHONE-2026-11-12-B row).

## Acceptance criteria
1. [x] **WON Results offers no CLEAN NEXT and no next-cleanup teaser; reward breakdown, journey and ceremonies kept.** m43_c001r `w01_won_no_next_offer` checks exactly one visible button (primary HOME), no `NextCleanup` / `TeaserImage` / `NextLevel` node, no `momentum.next`, no `continue` in the model, and the journey strip still visible. m43_c001a `level30_won_home_only` and m43_c001r `w03_last_level_no_coming_soon` check that no coming-soon or next-level copy appears. Ceremony suites pass: m43_master_c005 33/33 (the Gift ceremony over Results, then HOME is live) and m43_c001b reward rows.
2. [x] **The only action after a win is ANA SAYFA, styled as the green primary.** m43_c001b `won_composition_bound` checks that the primary uses the `HomeStyle.GREEN` CTA, its text is `RESULTS_HOME`, and the secondary Home button is not visible. m60 `results_buttons` reports `won_home_only: true`. TR text comes from the existing `RESULTS_HOME` key ("ANA SAYFA").
3. [x] **Pressing the primary goes Home and no level starts.** m43_c001a `rapid_home_once`: 10 taps give one HOME transition, the same attempt id, no host, no economy or progression change, and frontier 2 waits. m43_c001r `w02_won_home_then_play`: 5 taps give one HOME. m42_navigation `results_on_real_won` and m43_c001b `home_once_visual` / mid-reveal HOME show the same result.
4. [x] **No other path starts the next level from a win.** m43_c001a `won_never_starts_level`: no `continue_from_results` method and no `continue_requested` signal exist. `nav.can_go/go(GAMEPLAY)` and `resume_gameplay_after_retry` are refused on a WON Results, and so is `retry_from_results`. Back goes HOME with no host. Home PLAY then starts L2. m42_navigation `nav_terminal_latch` covers this at the navigation level, including that LOST still allows Retry. Ceremony and gift popups have no path to GAMEPLAY (m43_master_c005 e27 asserts the route stays RESULTS after the barrier releases), and nothing auto-advances (the code no longer contains a Results → GAMEPLAY launch).
5. [x] **The player starts the next level from Home PLAY.** m60 `l1_l3_real_play`: L1..L3 are played for real through Results HOME → Home PLAY, ending at Home L4 with the FTUE window closed. m55 long session: every level is played back-to-back via Results HOME → Home PLAY. m60 `results_buttons` reports `home_play: true`.
6. [x] **LOST / Retry flow unchanged.** m43_c004_c001 40/40, m43_c001a `lost_retry_regression`, and m60 `results_buttons` (`lost` / `retry` / `lost_again` / `home`) all pass.
7. [x] **Dead code and keys removed only where unused; analytics adjusted honestly.** A grep for `RESULTS_CLEAN_NEXT|NEXT_CLEANUP_|RESULTS_NEXT_UNAVAILABLE|continue_requested|continue_from_results|get_next_cleanup_panel|get_teaser_image|next_cleanup(|crop_rect|show_result(` in scripts/tools finds nothing. The only test hits are the negative assertions. m56: no `next_cleanup_*` events emitted and neither is in the taxonomy. The SB-M56-017 events and KPI are retired as described in the Summary.
8. [x] **Tests updated, CI exact guards unchanged.** Every CI suite kept its case count (m44 23/23, m49 responsive 8/8, m50 11/11, m51 8/8, m43_master_c005 33/33, m56 27/27, m57 ads 6/6, ranks weekly 7/7, m49 ad/store 6/6), so `.github/workflows/android-family-first10.yml` needed no change.

## Validation
All runs are LOCAL_PASS with Godot 4.7.2 headless, after a fresh `--import` in the worktree. "diag" counts SCRIPT ERROR / Parse Error lines.

CI suites (from the `android-family-first10.yml` list) touching the changed files:
- m43_c001a_results_foundation: PASS 11/11, exit 0, diag 0
- m42_navigation: PASS, exit 0, diag 0 (rerun after the retry guard)
- m42_home: PASS, exit 0, diag 0
- m44_ftue: PASS 23/23, exit 0, diag 0
- m43_master_c005_meta_ceremonies: PASS 33/33, exit 0, diag 0
- sb_polish_004_006_ui_batch: PASS 10/10, exit 0, diag 0
- m49_responsive_matrix: PASS 8/8, exit 0, diag 0
- m56_analytics_taxonomy: PASS 27/27, exit 0, diag 0
- m57_ads_cadence: PASS 6/6, exit 0, diag 0
- m43_ranks_weekly: PASS 7/7, exit 0, diag 0
- m49_ad_store_return_layout: PASS 6/6, exit 0, diag 0
- m55_long_session: PASS, exit 0, diag 0
- m60_release_gates: PASS 6/6, exit 0, diag 0 (then `-- --write` → PASS 6/6, regenerating RELEASE_GATES.json/.md)
- m43_c004_c001_fail_need_a_hand: PASS 40/40, exit 0, diag 0
- m43_c005f_phase4_terminal_home_micro: PASS 19/19, exit 0, diag 4. All 4 are the documented injected `'explode' on Nil` lines, which CI explicitly allows.
- m50_accessibility_audit: PASS 11/11, exit 0, diag 0
- m51_localization_readiness: PASS 8/8, exit 0, diag 0
- m43_master_c008_robots: PASS 10/10, exit 0, diag 0

Non-CI suites updated:
- m43_c001r_c001_results_momentum: PASS 27/27, exit 0, diag 0. It was 40 cases. The teaser, crop and CLEAN NEXT cases were removed with the feature, and 3 win → Home cases were added. Factory 141 recorded this suite with 6 failures before this change; it now passes fully.
- m43_c001b_won_results_visual: PASS 11/11, exit 0, diag 0. The first run had 5 failures in the test itself (a mid-reveal case still expected GAMEPLAY, and the responsive check measured the now-hidden secondary button). Both were fixed and the suite was rerun.
- m28_c002_c003_r01_remediation: PASS 24/24
- m43_c005f_phase2_results_pack_feel: PASS 22/22, exit 0, diag 5. All 5 are its own documented `EXPECTED_FAULT_INJECTION` spy-plugin lines.
- m43_c005_c005_reward_reveal_sequencer: PASS 12/12
- sb_polish_011_character_motion: PASS 16/16
- m49_surface_matrix: PASS 3/3

Other checks:
- `tests/tools/results_ceremony_snapshot.gd` and `results_momentum_snapshot.gd` were edited only so they still parse. They are capture tools and were not run.
- `git diff --check`: clean.
- `git status --porcelain` is empty after the commit. Untracked `.import` / `.uid` / `.translation` files produced by the worktree import were removed.

## Log
### Round 1
- Implemented the owner 2026-11-12 decision: a WON Results goes Home only. CLEAN NEXT, the Next Cleanup teaser, the Continue intent and handler, the Next Cleanup read model and the related UiText keys and analytics events were removed. Navigation now refuses RESULTS(WON) → GAMEPLAY, and Retry is refused after a win.
- Moved the every-5-plays interstitial from the removed Results → CLEAN NEXT transition to Home PLAY, so the owner's "between levels" ad cadence still holds.
- Updated 22 test files. Tests that used `continue_from_results` to reach the next level now press the WON primary (HOME) and then call Home PLAY. New direct assertions cover: one visible HOME action, no teaser or note, a HOME tap starts no level, the navigation, Retry and Back guards, and Home PLAY starting the next level.
- Known leftover: `data/config/results_momentum_v1.json` keeps its `teaser.visible_area_fraction*` fields. They are still validated by `load_config`, but nothing uses them now; `teaser.reveal_delay_s` still drives the journey reveal. The versioned config schema was left unchanged on purpose.
