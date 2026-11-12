STATUS: READY

# Build: SB-PHONE-2026-11-12-E — a win plays its animation, then Home opens and the rewards fly in

## Summary
Branch `factory/152-win-home-rewards` (commit listed in the Log). Owner decision 2026-11-12 ("ben arada bir popup yada button istemiyorum ..."): a WIN no longer shows Results.

- **Win animation over the board** (`scripts/ui/win_overlay.gd`, new). On a WON terminal the navigation latches the attempt but stays on GAMEPLAY. `main.gd` adds a WinOverlay to the finished host:
  - a light 0.35 scrim with the existing "BÖLÜM TAMAM / LEVEL COMPLETE" title (`RESULTS_WON`);
  - the existing keyed Scrubby WIN Flow video from factory 093, played once (another robot gets its approved victory pose with CharacterMotion `win` for 2.0 s);
  - the existing WIN confetti through the app feel adapter, key `win:a<attempt>:L<level>`.
  When the animation ends, `finished` fires and the app goes **HOME by itself** (payload `via: "win"` + the host's committed receipt). Taps are consumed but never skip. **Back skips straight to Home** (`handle_back` → `finish_win_animation`). The only edge taken is GAMEPLAY → HOME, so nothing can start a level. Test saves boot with the animation off (`boot_win_animation_override`, same policy as the Level Intro seam), so legacy suites go WON → HOME at once.
- **Reward fly-ins on Home** (`scripts/ui/home/home_reward_flight.gd`, new). The flight runs on the shared `RevealSequencer` and is built only from the win's receipt plus the live Home view model. Each reward fades in at the screen centre, flies to its HUD node, and that node then counts up from the pre-win value to the live value, with an adapter REWARD pickup:
  - SB → `ScrubBucksChip`;
  - Bot Parts → `ProfileBotParts`;
  - Gift Meter → `GiftMeterBar`; the existing GiftTickOverlay pulses as the count crosses ticks;
  - Win Streak → `TrackGift<n>` with the streak value count-up;
  - Collection cards → `Shortcut_collection` (fly only).
  The journey strip and streak track keep their existing HomeMicroFeel pops on the same Home entry. The flight is one-shot per win key. A Home refresh mid-flight keeps the counters (`reapply`). Home hidden mid-flight lands the final state at once. Reduced Effects lands the final state at once (no flight).
- **Ceremonies after the fly-ins.** `_drain_home_ceremonies` / `_drain_earned_packs` wait while the flight runs. `reward_flight_finished` then drains the existing CeremonyPresenter in its existing order (Gift milestone, set, Master, robot, feature, world), then earned packs, What's New and comeback. The Results ceremony barrier / `drain("results")` path is gone, so the Gift Bar popup can no longer appear before Home.
- **No grant and no replay.** The economy granted and saved inside the host terminal, before the animation. The flight and overlay only read state. A relaunch boots Home without a `win` payload, so nothing replays.
- **Interstitial:** still only at Home PLAY / Results Retry (`_between_levels_ad`). The win → Home path never calls it.
- **LOSS unchanged:** LOST → Results with RETRY primary + HOME secondary, Need a Hand, lose video.
- **Results WON branch removed** (`scripts/ui/results_screen.gd`): Victory layout/art, reward rows (`reward_rows`/`reward_lines`), journey section, ceremony barrier, reveal sequencer, WIN video, feel/confetti/emphasis code, `set_feedback`, `stop_result_video`. The surface is now LOST/ERROR only. `navigation_controller.gd` lost its WON Results guard (WON never enters RESULTS).
- **FTUE:** the first-win contextual tip `ctx_result_won` now shows on the Home the win lands on, after the flight and any ceremony (it used to show on WON Results).
- **Analytics (honest):** `screen_view{screen: results}` now fires only for LOST/ERROR. The win shows no Results, so a win emits no results screen_view, and there is no separate results_shown event. `journey_progress` (SB-M56-018) now fires on win → Home (`_track_win_journey`, same params, anchor = the won level). The taxonomy JSON is unchanged. `docs/ANALYTICS_TAXONOMY_V1.md` rows were updated, including the stale `results_continue` value.
- **Text keys removed** (EN + TR, used only by WON Results): `RESULTS_FIRST_CLEAR_SB`, `RESULTS_STREAK_SB`, `RESULTS_BOT_PARTS(_ONE)`, `RESULTS_GIFT_METER`, `RESULTS_GIFT_READY`, `RESULTS_CARDS(_ONE)`, `RESULTS_CATCHUP`, `RESULTS_ALREADY_CLEARED`, `JOURNEY_CAPTION`. `RESULTS_WON` is kept (win animation title).
- **Manifest/docs:**
  - `PLAYER_EXPERIENCE_ASSET_MANIFEST.json` `victory_results` now points at `win_overlay.gd` + the new suite, with a gap note. The status was left untouched (owner-owned).
  - `docs/ACCESSIBILITY.md` Reduced rows were updated.
  - `AGENTS.md` ad line corrected: the interstitial is at Home PLAY / Retry.
  - `docs/RELEASE_GATES.json/.md` were regenerated (`m60 -- --write`). Verdicts are unchanged; only evidence text changed.

Files (product): `scripts/app/main.gd`, `scripts/app/navigation_controller.gd`, `scripts/ui/win_overlay.gd` (new), `scripts/ui/home/home_reward_flight.gd` (new), `scripts/ui/home/home_screen.gd`, `scripts/ui/results_screen.gd`, `scripts/ui/ui_text.gd`, `scripts/ui/ui_text_tr.gd`, `assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json`, `docs/ACCESSIBILITY.md`, `docs/ANALYTICS_TAXONOMY_V1.md`, `docs/RELEASE_GATES.json`, `docs/RELEASE_GATES.md`, `AGENTS.md`, `.github/workflows/android-family-first10.yml`.
Tests:
- New: `tests/sb_phone_2026_11_12_e_win_home.gd` and the capture tool `tests/tools/win_home_capture.gd`.
- Updated: m42_home, m42_navigation, m43_c001a, m43_c001r (trimmed to Home/authority cases), m43_c004, m43_c005_c005 (r* now cover the flight), m43_c005_c072, m43_c005f_phase2 (w*/r* removed), m43_c005f_phase4, m43_master_c005, m43_master_c005r, m43_master_c008, m43_master_c011_c014, m44_contextual_coach, m44_ftue, m46_performance (p19 on the win animation), m49_responsive_matrix, m49_surface_matrix, m49_surface_stress, m50_accessibility_audit, m50_contrast_surfaces (comment), m51_localization_readiness, m54_regression_pack_037_038, m55_long_session, m55_player_chaos, m60_release_gates, sb_polish_004_006_ui_batch, sb_polish_011.
- Deleted (WON Results only): `tests/m43_c001b_won_results_visual.gd`, `tests/tools/results_snapshot.gd`, `results_momentum_snapshot.gd`, `results_ceremony_snapshot.gd`.

TASKS.md not edited (per orchestrator instruction).

## Acceptance criteria
1. [x] **The existing win animation plays over the board.** sb_phone_e `win_animation_then_home`: a real L1 WON stays GAMEPLAY with `is_won_pending()`. The WinOverlay is a child of the host, the keyed WIN video plays, and the title is `RESULTS_WON`. The WIN confetti is the one adapter WIN (`win:a1:L1`, m43_c005f_phase4 t08). Capture `captures/01_win_animation_end.png`.
2. [x] **Home opens automatically; no Results, no button, no tap; Back skips and never starts a level.** sb_phone_e: Home opened by itself after about 7.8 s with no input. The route sequence after the terminal is exactly `[HOME]`, Results is never visible, the host is released, attempt stays 1, and the frontier waits at 2. `back_skips_to_home`: Back → HOME, a second Back → none, no host. sb_polish_004 p004: 15 points across the screen pick the overlay, and a real tap neither skips nor reaches the board. m60 g003: L1..L3 shipping-policy real play, each win → animation → Home with no input.
3. [x] **Rewards fly into their Home targets; HUD final values equal the receipt; granted exactly once; relaunch never replays.** sb_phone_e:
   - `flight_targets_hud`: icons map to `ScrubBucksChip` / `ProfileBotParts` / `GiftMeterBar` / `TrackGift1`. The SB count runs pre-win → pre + receipt delta, the HUD starts at the pre-win value, a mid-flight refresh keeps it, and the SB icon lands on the chip centre.
   - `ceremony_after_flight`: SB chip = receipt final = wallet, Bot Parts meter = before + delta, Gift = receipt after (10), streak = receipt after.
   - `granted_once_no_replay`: the ledger and SB are unchanged by the flight, the same win key is refused, and a relaunch shows Home with no flight and the same wallet / ledger / frontier.
   - m43_c001a `duplicate_terminal_open_refresh`: 5 Home re-shows + duplicate terminals change no economy / save / route, and the flight never replays.
   Captures `02_home_mid_flyin.png` (Bot Parts icon in the air, SB already counted) and `03_home_after_flyin.png` (1.051 SB, 1/250, 2/5, streak 1).
4. [x] **Ceremonies on Home after the fly-ins, in their existing order.** sb_phone_e: no ceremony or modal while flying, then exactly the Gift milestone ceremony on Home. m43_master_c005 e27 (Gift 10 after the flight; granted nothing; acknowledged; still Home) and m43_c005_c072 i (Daily feature unlock after the flight). Capture `04_home_first_ceremony.png` (HEDİYE BARI 10!).
5. [x] **Reduced Effects.** sb_phone_e `reduced_effects`: no decoder (keyed still), Home after the 1.0 s hold (<2.5 s), the flight lands at once (key consumed, no layer), the HUD is at final values, and the ceremony follows at once. m43_c005_c005 r04 and m43_c005f_phase4 t06 (zero plugin work).
6. [x] **LOSS unchanged.** sb_phone_e `loss_results_unchanged` (Results, RETRY + HOME, Retry works), m43_c004_c001 (Need a Hand matrix), m43_c001a `lost_retry_regression`, m60 `results_buttons`.
7. [x] **Interstitial only at Home PLAY.** sb_phone_e `no_interstitial_before_home`: the 5th play is due, but nothing is shown during the animation or on the way Home; it is shown at Home PLAY. m57_ads_cadence passes unchanged.
8. [x] **Analytics honest.** See Summary. m56_analytics_taxonomy passes unchanged.
9. [x] **Dead WON Results code / keys removed.** sb_phone_e `results_won_branch_removed` (no `reward_rows` / barrier / Victory API; flight and overlay never grant, save or acknowledge). m51 still checks EN/TR plurals on the ceremony keys.
10. [x] **Tests / CI.** Every CI suite keeps its case count. The new suite was added to the CI list with an exact `9/9` guard (about 50 s headless locally). RELEASE_GATES regenerated.

## Validation
All LOCAL_PASS, Godot 4.7.2 (Windows), after a fresh `--import` in the worktree. CI rule via `python tools/run_suites.py` (exit 0, no SCRIPT ERROR/Parse Error except the documented injected `explode` lines, last PASS line).

**All CI suites** (the `android-family-first10.yml` list, 92 incl. the new one): `python tools/run_suites.py` in 3 parallel shards → **92/92 PASS**. Every suite kept its exact case count, so no guard change was needed except the new one. Key results:
- m43_c001a 11/11
- m42_navigation PASS
- m55_long_session PASS (30 levels back-to-back: win → Home → PLAY; memory rules untouched)
- m43_c005f_phase4 19/19 (only the 2 documented injected `explode` lines)
- m44_contextual_coach 7/7
- m44_ftue 23/23
- m46_performance 22/22
- m43_master_c005 33/33
- m43_master_c005r 8/8
- m49_responsive_matrix 8/8
- m50_accessibility_audit 11/11
- m51 8/8
- m60_release_gates 6/6
- sb_polish_004_006 10/10
- m57_ads_cadence 6/6
- m56_analytics_taxonomy 27/27
- m54_regression_pack_037_038 6/6 (only injected lines)
- m43_c005_c072 9/9
- m43_master_c008 10/10
- m43_master_c011_c014 29/29
- real_play_levels 4/4
- **sb_phone_2026_11_12_e_win_home 9/9** (about 50 s alone)

m41_settings failed once in the first 3-shard run (a save re-save byte comparison, unrelated to this change). It passed alone and in the second full run.

Two small edits were made after the full run: a Home variable rename (`_feel_adapter`) and removing an unused `_key` in the flight. The Home/flight suites were rerun afterwards: sb_phone_e 9/9, m43_master_c005r 8/8, m42_home PASS, m43_c005f_phase4 19/19.

**Non-CI suites touched / covering changed files** (direct `$GODOT --headless`), all exit 0:
- m43_c001r 17/17 (was 27; the WON-Results cases were removed with the surface)
- m43_c004_c001 40/40
- m43_c005_c005 12/12
- m43_c005f_phase2 9/9 (3 injected)
- sb_polish_011 16/16
- m43_master_c005f_feel 10/10
- m43_c005f_phase1 23/23 (1 injected)
- m43_c005f_phase2_r01 22/22 (3 injected)
- m43_c005f_015_e2e_feel 6/6 (30 injected, documented)
- m28_c002_c003_r01 24/24
- m22_026_texture_budget PASS
- m49_touch_targets_text_stress 5/5
- m42_opening PASS
- m49_surface_matrix 3/3
- m49_surface_stress 4/4
- m55_player_chaos PASS (3 injected)

Not run (windowed / capture tools): `m50_contrast_surfaces` (windowed; comment-only change), `m54_visual_regression_038`. These capture tools still drive the removed WON Results at runtime and were not updated: `tests/tools/c005f_phase2_capture.gd`, `c005f_phase4_capture.gd`, `character_motion_capture.gd`, `gameplay_v02_r01_motion_capture.gd`, `result_video_capture.gd`, `m22_026_texture_measure.gd`. They still parse; they are evidence tools for closed jobs.

**Release gates:** `m60_release_gates -- --write` regenerated `docs/RELEASE_GATES.json/.md`. The verdicts are the same as committed; SB-M60-006 FAIL was already there.

**GPU captures** (windowed Godot 4.7.2, real renderer, TR, SubViewport at the 720x1520 logical size 1080x2280, saved 720x1520) via `tests/tools/win_home_capture.gd`, in `factory/jobs/152-win-home-rewards/captures/`:
- `01_win_animation_end.png`: finished board, "BÖLÜM TAMAM", keyed Scrubby WIN video near its end.
- `02_home_mid_flyin.png`: Home, SB already counted to 1.051, Bot Parts icon in flight to the profile meter (still 0/250), Gift 1/5, streak 0.
- `03_home_after_flyin.png`: 1.051 SB, Bot Parts 1/250, Gift 2/5, streak 1.
- `04_home_first_ceremony.png`: Gift 9 → 10 run; after the flight, HEDİYE BARI 10! ceremony on Home.

**Other:**
- `git diff --cached --check`: clean.
- `git status --porcelain`: only untracked `.uid` / `.import` files from the worktree import. These were left in place as instructed. Import churn on tracked files was restored.

## Log
### Round 0
- Implemented the owner 2026-11-12 flow:
  - WON → WinOverlay (existing WIN video + WIN confetti) over the board → Home by itself, with Back to skip;
  - Home reward flight from the receipt on the shared RevealSequencer (+ GiftTickOverlay pulses, HomeMicroFeel pops);
  - ceremonies and earned packs held until the flight ends, then the existing CeremonyPresenter order;
  - the first-win tip moved to that Home;
  - `journey_progress` moved to win → Home;
  - the interstitial stays at Home PLAY.
- Removed the ResultsScreen WON branch, its UiText keys and the WON-only Results tests/tools. The navigation WON guard was replaced by the WON latch (`is_won_pending`).
- Updated 30 test files to the new flow and added `tests/sb_phone_2026_11_12_e_win_home.gd` (9 cases, in CI with an exact guard).
- Commit `82db06d5` ("Win plays its animation then goes Home; rewards fly into the Home HUD"). Not pushed. TASKS.md untouched per instruction.
- Choices to flag for review:
  - The WIN video is played in full (about 7.7 s, the existing 185-frame clip) before Home. Back skips; a tap does not, so rapid board taps cannot skip it by accident.
  - The flight takes about 1.07 s per reward (4 rewards on a typical win ≈ 4.3 s) before ceremonies. PLAY during the flight lands it at once, and pending ceremonies then wait for the next Home.
  - The `victory_results` manifest status (MASTER_OWNER_APPROVED) was not changed. The approved Victory Results panel is no longer shown; a gap note records it.
