STATUS: READY

# Build: SB-TF-03 Home + Profile redesign

## Summary
Branch `factory/183-tf03-home-profile` has three commits:
- `a008c90d`: new Home wave video.
- `eb6f352d`: the redesign, plus its tests and docs.
- `5bab8b68`: round-2 review fixes.

TASKS.md is not edited; the orchestrator owns it.

What Home looks like now:
- **Removed:** the BottomNav, the Shop and Collection tiles, and the win-streak strip.
- **Top HUD:** profile card, then a new `SettingsButton` (the former nav settings art, HOME-105, through `HomeArtBinder`), then the Scrub Bucks and Hearts chips. The profile card badge shows the Bot Parts icon instead of the level.
- **PLAY:** reads `PLAY · LEVEL N` (`OYNA · LEVEL N` in TR) from the new key `HOME_PLAY_LEVEL`. The font is fitted to the 470 px button. Since round 2 the old `PlaySubtitle` line is gone, so the level shows once.
- **Activity buttons in the world columns:**
  - Size and look: 147x109 (0.7x), glass alpha 0.255, with the icon box, label band and font scaled to match.
  - Which buttons: Rewarded Ads, Tasks and Daily are fixed in the left column. There is one button per active Events V02 instance; events fill the right column first, then any free left slots.
  - Limits: at most 4 per column and 8 in total.
  - Auto-hide: each button hides in `refresh()` once there is nothing left to do today.
- **Banner area:** `AdBannerSlot` is 320x50 scaled to the width, clamped to 72..112. `main.gd` collapses it when `AdService.allowed("banner")` is false (No Ads owned).
- **Below the world image:** a mirrored floor continuation, `WorldEdgeBottom`, now covers the gap the opaque nav dock used to hide. The world transform itself is unchanged.

What Profile, Settings and the popups look like now:
- **Profile:** a row of ROBOTS / RANKS / COLLECTION buttons.
  - They open `RobotsScreen.open`, `open_ranks` and `CollectionScreen.open_album`.
  - Each is gated by its unlock level, with the "Unlocks at level N" text.
  - Each carries a count badge, or the SB-M44-013 NEW pill.
  - The Notifications action is gone from Profile.
- **Settings:** has a NOTIFICATIONS card that opens `ProfileScreens.open_notifications`.
- **Hearts (+) popup:** gained a MORE IN SHOP `shop` action. Its analytics source is `home_heart_plus`, which I added to the taxonomy enum.

Badges and reward flights:
- The profile card badge = achievements + unseen robots + new collection cards, or NEW.
- Reward flights: Collection cards now fly to the profile card. The win-streak flight and micro-pop are gone, because the strip no longer exists.

Wave video:
- Re-keyed from `Robot_Scrubby_waving_hello_640858a4.mp4` by `factory/jobs/183-tf03-home-profile/make_wave.py`.
- Each frame's background colour is sampled from the frame border (it drifts from #F901FB to #E928D5), Scrubby's alpha is computed from it, and the background is unmixed to exact #FF00FF.
- Kept frames 0..184, encoded libtheora -q:v 8, 720x1280, 24 fps.
- The manifest sha and provenance are updated.

Files changed:
- **Code:**
  - `scripts/ui/home/home_screen.gd`, `home_presentation_map.gd`, `home_reward_flight.gd`, `home_badges.gd`
  - `scripts/ui/feel/home_micro_feel.gd`
  - `scripts/app/main.gd`
  - `scripts/ui/profile/profile_screens.gd`, `scripts/ui/settings_panel.gd`, `scripts/ui/popup/acquisition_flow.gd`
  - `scripts/ui/ui_text.gd`, `ui_text_tr.gd` (added `HOME_PLAY_LEVEL`, removed `HOME_NAV_*`)
  - `scripts/ui/robots/robots_screen.gd` (comment only)
- **Data and docs:**
  - `data/config/ui_surface_registry_v1.json`, `analytics_taxonomy_v1.json`
  - `docs/ANALYTICS_TAXONOMY_V1.md`, `docs/HOME_UI_ASSET_PLAN.md`, `AGENTS.md` (new "Home layout (SB-TF-03)" section)
  - `assets/ui/HOME_ASSET_MANIFEST.json`, `assets/ui/final/home/videos/home_scrubby_wave_keyed.ogv`
  - `.github/workflows/android-family-first10.yml` (adds `sb_tf03_home_profile` with an exact 11/11 guard)
- **Tests:**
  - New: `tests/sb_tf03_home_profile.gd`, and the GPU capture tool `tests/tools/sb_tf03_capture.gd`.
  - Updated: 29 suites plus 3 tools. Each assertion was rewritten to the new layout; no suite or case was deleted.

## Acceptance criteria
1. [x] **Removed nodes, Settings icon and banner area.** `sb_tf03_home_profile` t01–t03.
   - (a) No `BottomNav`, `Nav_*`, `WinStreakRewardTrack`, `Shortcut_shop` or `Shortcut_collection` node exists anywhere under Home, and the `nav_requested` / `set_app_nav` plumbing is gone.
   - (b) `SettingsButton` sits inside `TopCurrencyHUD`. Its x lies between the profile card's end and the Scrub Bucks chip, it is at least 88 px, and pressing it fires `settings_requested` and opens the Settings panel.
   - (c) The banner height equals `clamp(w*50/320)` within 1 px at 1080x1920, 1080x2160 and 1620x2160. It is bottom-anchored and below PLAY. After No Ads (`grant_no_ads` then `set_ad_slot_enabled(ads.allowed("banner"))`) it is hidden and the PLAY stack moves down.
   - The PASS line is `SB-TF-03 home/profile evidence: PASS (11/11 cases, 0 fail)`.
2. [x] **Activity button size and columns.** t04 and t05.
   - Each button is 147x109 ±1, with normal alpha 0.255 ±0.02, an opaque border and font ≤ 20.
   - With 10 eligible buttons: left = Rewarded Ads, Tasks, Daily plus 1 event; right = 4 events. That is at most 4 per column and 8 in total, and the 6th event is not shown.
   - The columns are contiguous (no gap over `PANEL_GAP`) before and after Daily hides.
3. [x] **Auto-hide.** t06 and t07.
   - Tasks hides only after all orders and the all-tasks bonus are claimed.
   - Rewarded Ads hides once all 5 slots are granted.
   - Daily hides when `daily.claimed_today()`.
   - The next local day shows all three again.
   - For events:
     - inactive or fully claimed events get no button;
     - an active event with unclaimed rewards gets one button titled `EventsV02Ui.title(id)`;
     - a real scheduled event's button opens its own `event_details` (matched by iid);
     - two active events give two buttons.
4. [x] **Profile card badge and PLAY text.** t08.
   - `ProfileLevel` is gone.
   - `ProfileBotPartsIcon` is a TextureRect showing `bot_parts_icon.png` inside `ProfileRankBadge`.
   - PLAY equals `UiText.t("HOME_PLAY_LEVEL",[7])`, which is `PLAY · LEVEL 7` in EN and `OYNA · LEVEL 7` in TR.
   - The text fits the button for levels 7, 123 and 4321.
   - The key exists in both the EN and TR tables. Full parity is covered by m51, which passes.
5. [x] **Profile destinations, Notifications and the new-card badge.** t09 and t10.
   - Profile ROBOTS / RANKS / COLLECTION open `robots` / `ranks` / `collection`, and there is no Notifications action.
   - The Settings NOTIFICATIONS entry opens `notifications`.
   - An unseen owned card shows badge 1 on Profile COLLECTION and on the Home profile card. After the card's set is viewed in the album, both clear.
6. [x] **Shop entry points.** t11.
   - Hearts (+) shows a `shop` action reading "MORE IN SHOP", which opens `shop` with source `home_heart_plus`.
   - The Scrub Bucks popup is unchanged.
   - I pressed every other visible Home button; none reached the Shop.
7. [x] **Responsive and touch suites.**
   - `m49_responsive_matrix` PASS 8/8. I extended it with a pairwise no-overlap check across Settings, profile card, both currency widgets, PLAY, the banner and the activity buttons, at every matrix viewport, with and without the notch.
   - `m49_touch_targets_text_stress` PASS 5/5, covering EN, TR and pseudo-locale.
   - `m49_surface_matrix` PASS 3/3 and `m49_surface_stress` PASS 4/4.
8. [x] **Home and related suites all pass** (summary lines in Validation):
   - Home layout: m42_home, m42_home_composition 9/9, m42_home_v04 18/18, m42_home_v05 13/13, m42_home_v06 13/13, m42_home_v07_safe_area 9/9, m42_navigation, m42_c002 7/7.
   - Destinations and gating: m43_master_c008 10/10, m43_master_c010 12/12, m43_personal_ranks 8/8, m43_r15_owner_remediation 18/18.
   - Regression packs: m49_ad_store_return_layout 6/6, m54_regression_pack_028_036 12/12, m55_player_chaos PASS, m56 27/27, m60 6/6.
   - Assets: maint_home_export_asset_gate_c001 11/11.
   - In every suite the assertions were rewritten to the new layout, never removed wholesale.
9. [x] **Wave video.**
   - m42_c003_scrubby_animation is 25/25, including the binder serving 5 Theora streams and real playback.
   - `sha256sum` of the new file is `ee968d6ecc14aaee8ece0f44168decc223f2d48ef461576c47963c57c3ab7957`, which equals the manifest pin. maint_home_export_asset_gate_c001 is 11/11.
   - Frame 0 overlays the keyed still at 0 px offset (IoU 0.985 from job 166's `check_overlay.py`), so the still-match test needed no change.
   - Frame strip: `factory/jobs/183-tf03-home-profile/wave_frame_strip.png` shows frames 0, 46, 92, 138 and 184, composited through the shader formula on slate and light bands. It shows one brush and no magenta fringe.
   - Size: 2,771,570 bytes, against 3,584,972 for the old file (smaller).
10. [x] **Diff and leftover strings.**
    - `git diff --check` is clean.
    - `grep -rn "BottomNav\|WinStreakRewardTrack" scripts` returns nothing.
    - No `HOME_NAV_` remains in scripts or tests.
11. [x] **Owner captures.**
    - Made on the GPU (non-headless) with `tests/tools/sb_tf03_capture.gd`, which runs main.tscn on a temp save with `boot_opening_override = 0`, never on the canonical save.
    - Files: `factory/jobs/183-tf03-home-profile/captures/home_en.png`, `home_tr.png` and `profile.png`, all 1080x2160.
    - The fixture shows 3 activity buttons on the left and 4 event buttons on the right (event views injected), the new-card badge on the profile card and on Profile COLLECTION, PLAY · LEVEL 12, and the Settings gear.

## Validation
- Godot 4.7.2 headless, one log per suite. Each counts as LOCAL_PASS only when it exits 0, prints no SCRIPT ERROR or Parse Error outside the documented injected `explode` lines, and its last summary line is PASS.
- The final run of all 45 affected suites, after the last code change, passed all of them:
  - sb_tf03_home_profile 11/11
  - m42 suites: m42_home, m42_home_composition 9/9, m42_home_v04 18/18, m42_home_v05 13/13, m42_home_v06 13/13, m42_home_v07_safe_area 9/9, m42_navigation, m42_c002 7/7, m42_c003 25/25
  - m43 suites: m43_146 8/8, m43_c001r 17/17, m43_c005f_phase4 19/19, c006 15/15, c007 19/19, c008 10/10, c009 12/12, c010 12/12, personal_ranks 8/8, r15_001 14/14, r15_owner 18/18, m43_c003_c001_acquisition 34/34
  - m44 suites: m44_ftue 23/23, m44_meta_l1 6/6, m44_new_badge 7/7, m44_unlock_gate 6/6
  - m47_touch 14/14
  - m49 suites: m49_ad_store 6/6, m49_responsive 8/8, m49_surface_matrix 3/3, m49_surface_stress 4/4, m49_touch_text_stress 5/5
  - m50 11/11, m51 8/8, m54 12/12, m55 PASS, m56 27/27, m60 6/6
  - sb_phone_e 10/10, maint_home_export 11/11, ev02_events_ui 6/6, sb_polish_004_006 10/10, m41_settings PASS, m28_c002_c002 16/16, m28_c002_c003_r01 24/24
- `m43_personal_ranks` p07 failed once in the full run: the hearts / speed snapshot ticked on the wall clock across the longer Profile→Ranks path. I froze the clock in p07 and re-ran it: PASS 8/8.
- `python tools/run_suites.py sb_tf03_home_profile` gives `status=PASS`, with the new exact CI guard matched.
- Baseline, from a detached HEAD worktree before my changes:
  - m42_home_v07_safe_area already failed 9 world-matrix rows. They pinned a 940 px canvas; the real canvas is 941. I re-baselined those x offsets to the values m42_home_v06 already uses.
  - m43_master_c010_meta already had one failing "badge icon art" check; it now passes.
- The "FAIL SB-M60-006" inside the m60 log is a gate verdict that was already present in the baseline. The suite itself passes 6/6.
- `git diff --check` is clean. The worktree is clean: I restored Godot's import churn and deleted the generated .uid / .translation files. I created a temporary baseline worktree, then removed and pruned it.

## Notes for review
- **Weekly v1 events have no Home entry now.** The EVENTS tab is gone. V02 events surface as activity buttons, and the `events` deep link still opens `ProfileScreens.open_events`. A claimable v1 weekly reward still counts in `HomeBadges.events` but shows nowhere on Home; the m43_master_c010 assertion says so explicitly.
- **SB-M44-013 NEW pills moved with the destinations.** They now appear on the Profile buttons and the profile card, and on the Event buttons for Events. The Shop has no Home NEW any more.
- **The REWARDED ADS label is 16 px in EN.** That is the 0.7x scale (24 → 16.8 px), so m50's floor for this one label is now 16 px; the other floors stay at 18. Long event names shrink down to 10 px, then wrap to two lines. They are never cut off.
- **The Bot Parts icon is loaded directly**, from the same approved path the reward flight already uses (`HomeRewardFlight.ICONS["bot_parts"]`). It is not a HOME_ASSET_MANIFEST entry.
- **The retired Home art (HOME-064/065/086/090..094/101..104) is now OWNER_RETIRED** in the presentation map. Its files are kept.

## Log
### Round 1
- Read the spec, the Home, Profile, Settings, acquisition and Events code, and the job 160 / 166 / 173 video tooling. Ran a baseline in a detached worktree.
- Built the wave video (`make_wave.py`, per-frame sampled-background key), pinned it in the manifest, and reviewed the frame strip.
- Implemented every requirement listed in the Summary.
- Added `sb_tf03_home_profile` (11 cases) to the CI list with an exact guard. Updated the affected suites and tools, and the docs.
- Fixed the regressions that suites surfaced:
  - the world gap without the nav dock (`WorldEdgeBottom`);
  - PLAY font fitting, including the outline width;
  - Profile row overflow and badge placement;
  - long activity labels, which now wrap;
  - locked `event:*` presses;
  - the forbidden-word check in profile_screens.
- Made the GPU captures. Ran all 45 affected suites; LOCAL_PASS.

### Round 2
Review findings (`round-1/review.md`, REWORK) and what I did:

1. **PLAY showed the level twice** ("PLAY · LEVEL 12" over an old "LEVEL 12" line).
   - Removed the `PlaySubtitle` label, its render code and the now-unused `HOME_START_LEVEL` / `HOME_CONTINUE_LEVEL` keys (EN and TR).
   - The label is re-centred on one line: bottom margin 40 → 22, triangle moved down 8 px.
   - Rewrote the m42_home and m42_home_v04 assertions that pinned the subtitle: they now check PLAY's text and that no subtitle exists.
   - sb_tf03 t08 asserts the level appears exactly once under PLAY.
2. **Profile COLLECTION label was clipped** ("COLLECTI").
   - The three Profile destination buttons share one fitted font (`ProfileScreens._fit_destinations`, FONT_BUTTON down to 16), so text never widens a button and every button gets an equal share of the row.
   - The badge is now a compact 40 px pill inside the button's top-right corner. While a badge shows, that button's label aligns left and is fitted to `destination_text_width` (content width minus the badge).
   - Refits run on resize and whenever the badges are re-rendered.
   - New assertions in `sb_tf03_home_profile`:
     - t09: EN and TR labels fit their buttons (ROBOTLAR / RÜTBELER / KOLEKSİYON).
     - t10: with the badge shown, every label still fits and the badge lies inside its button.
   - Cropped captures show "COLLECTION" and "KOLEKSİYON" whole beside the "1" badge.
3. **m42_home_v04 "economy untouched" flake.** The cause is wall-clock state (Heart regen / 2x) ticking between the two economy snapshots, the same as p07. `_home()` in m42_home_v04 now builds its AppState with a frozen clock and local day. It passed 18/18 on both runs afterwards.

Re-captured into `captures/`: home_en.png, home_tr.png, profile.png and the new profile_tr.png. `tests/tools/sb_tf03_capture.gd` now also captures Profile in TR.

**Environment issue I caused, and fixed.** My round-1 cleanup deleted Godot's untracked import files (`.import` / `.uid`). After that, assets without an import failed to load, for example `ResourceLoader.exists` for achievement icons and `dispatch.wav`. That made `m43_master_c010_meta` fail one check in a mid-round run. I re-ran `--import` in the worktree. The worktree now carries the same untracked and modified import artifacts it had when I started (about 1,740 entries, all generated, none committed). I left them in place, because the suites need them.

**Validation after the last change**, with a healthy import: all 45 affected suites pass (LOCAL_PASS):
- sb_tf03_home_profile 11/11
- m42 suites: m42_home, composition 9/9, v04 18/18, v05 13/13, v06 13/13, v07 9/9, m42_navigation, c002 7/7, c003 25/25
- m43 suites: c001r 17/17, c005f 19/19, c006 15/15, c007 19/19, c008 10/10, c009 12/12, c010 12/12, personal_ranks 8/8, r15_001 14/14, r15_owner 18/18, m43_146 8/8, m43_c003_c001 34/34
- m44 suites: m44_ftue 23/23, meta_l1 6/6, new_badge 7/7, unlock_gate 6/6
- m47 14/14
- m49 suites: ad_store 6/6, responsive 8/8, surface_matrix 3/3, surface_stress 4/4, touch/text 5/5
- m50 11/11, m51 8/8, m54 12/12, m55 PASS, m56 27/27, m60 6/6
- sb_phone_e 10/10, maint_home_export 11/11, ev02_events_ui 6/6, sb_polish 10/10, m41 PASS, m28 16/16 and 24/24

`git diff --check` is clean. TASKS.md is not edited.
