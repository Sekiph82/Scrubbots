STATUS: READY

# Build: Localization EN + TR (SB-M51-001, -003, -005, -006, -007, -008, -009)

## Summary
Branch `factory/124-localization-en-tr`, commits 8ad39e31 (code + TR table), 933b6c8a (tests + CI guard), a7274e65 (m43 c011 test for the singular Comeback line), a4919ae7 (docs/tasks).

- `scripts/ui/ui_text_tr.gd` (new): a Turkish `TR` entry for every UiText key (same placeholders in the same order) and `DATA` (Turkish copy for 50 achievement names and descriptions, the roles and perks of 10 robots, and 15 Collection set names).
- `scripts/ui/ui_text.gd`: `locale` ("en" / "tr") picks the built-in table (falls back to EN). New helpers: `tn()` for plurals (EN one/other through `_ONE` keys, TR none), `data()` for data-file copy, and `resolve_language()` (saved choice > device > EN). `num()` groups as "1.000" in TR. "(s)" strings now use real plural pairs. New keys SETTINGS_LANGUAGE and LANGUAGE_NAME_EN / _TR.
- `scripts/settings/effects_settings_service.gd`, `scripts/save/save_service.gd`: `settings.effects.language` is written only once the player chooses. Only "en" / "tr" are accepted; any other value rejects the save candidate.
- `scripts/app/app_state.gd`: `set_language()` applies and saves the choice. At boot, the shipping save follows the saved choice or the device language. A test save only applies an explicit choice.
- `scripts/ui/settings_panel.gd`: one LANGUAGE card after COLOR SYMBOLS. It has a title and ENGLISH / TÜRKÇE buttons (88 px tall); the active one shows pressed. Reduced Effects stays where it was. It emits `language_changed`.
- `scripts/app/main.gd`: on `language_changed` it reloads the app root, but only when it is the current scene (the shipping app). LaunchSession stops the opening from replaying.
- Call sites switched to `tn` / `data`: home_screen, results_screen, meta_ceremonies, robots_screen, daily_screens, profile_screens, collection_screen.
- Tests: m51 readiness l05..l08, m49 touch t04, m49 surface v03 Turkish walk. CI M51 guard changed from 4/4 to 8/8.
- `docs/LOCALIZATION.md`: covers brand names ("Scrub Bucks" / SB stay as they are; robot, card and product names stay), plural rules, number grouping, the store price policy and the tests.

## Acceptance criteria
1. [x] SB-M51-001 remaining hard-coded user text moved and a guard added. Evidence: the guard (m51 l08) scans 94 files in scripts/ui, scripts/app and scenes and finds no `text = "..."` with words, no multi-word literal and no hand-formatted currency (allow-list: only the "II" pause glyph). Every literal `UiText.t` / `tn` key exists. Its self-check catches 4 of 4 planted violations. What remained was data-file copy (achievements, robot roles and perks, set names), now routed through `UiText.data`. The pseudo scan (l04) finds no untranslated literal except the robot name "Scrubby".
2. [x] SB-M51-005/006 a real TR table for every key, device locale with EN fallback, and a persisted Settings LANGUAGE option. Evidence, m51 l05: every EN key has non-empty TR copy with matching placeholders, there are no stray keys, and all 105 data-copy entries are present. Evidence, m51 l07: the resolve order is checked; the strict save field rejects 5 of 5 bad values; the card order ends Haptics, ReducedEffects, ColorSymbols, LanguageRow; pressing TÜRKÇE applies the language, emits `language_changed` and saves `language: tr`; rebooting on that save shows Settings "AYARLAR" and no English-only copy on Home.
3. [x] SB-M51-007 no hand-formatted currency, and the "store unavailable" copy is localized. Evidence: the l08 currency regex finds nothing. SHOP_STORE_LATER, SHOP_UNAVAILABLE and SHOP_SOON have TR entries. Policy is in docs/LOCALIZATION.md.
4. [x] SB-M51-008 plural helper with tests. Evidence, m51 l06: EN one/other for Cards, Bot Parts, Hearts, days, gifts, packs and ranks ("1 more level"); 0 takes the other form; the real `ResultsScreen.reward_rows` gives "+1 Bot Part" / "+3 Cards"; TR gives "+1 Robot Parçası" / "+3 Kart"; TIME_DHM "1g 2sa 3dk". No player-facing copy counts attempts (documented).
5. [x] SB-M51-003/009 m49 stress in TR and pseudo, with Shop scroll proven. Evidence: m49_touch_targets_text_stress PASS 5/5. t04 (real TR table) measured 1732 text controls on every surface at 4 sizes with no clipping or overflow and the Turkish glyphs present. t01 touch targets include the new Settings row. m49_surface_stress PASS 4/4: the v03 TR walk measured 1786 controls, and v05 shows the Shop "scroll area reach first + last row" at 720x1280 and 1440x3200.

## Validation
- `godot --headless -s res://tests/m51_localization_readiness.gd`: PASS (8/8 cases, 0 fail), LOCAL_PASS
- `tests/m49_touch_targets_text_stress.gd`: PASS (5/5, 281 s); `tests/m49_surface_stress.gd`: PASS (4/4, 202 s), LOCAL_PASS
- `python tools/run_suites.py` on 32 related CI suites, all PASS: m41_settings, m40_save_system, m40_v04_bootstrap, m50_color_symbols, m43_master_c005_meta_ceremonies, m43_master_c007_collection, m43_master_c008_robots, m43_master_c010_meta, m43_master_c011_c014, m43_master_c009_daily, m43_c001a_results_foundation, m42_home, m42_navigation, m44_meta_verify_achievements_gift, m43_personal_ranks, m43_master_c006_shop, m44_ftue, m43_r15_owner_remediation, m43_c005_c074_c077_celebrations, m55_economy_release_regression, m54_collection_set_master_exactly_once, m43_c003_c001_acquisition, m51_localization_readiness, m49_responsive_matrix, m50_accessibility_audit, m47_touch_r01_mobile_ux, m44_unlock_gate, m44_meta_l1_unlock_ftue, m43_master_c007r_pity, m43_c005f_phase6_unlock_feel, m44_new_badge, m44_contextual_coach.
  - In the first parallel run, m43_master_c011_c014 failed 2 checks. The test expected `t("COMEBACK_TASKS"/"EVENTS", [1])`, and the line is now the singular form. I updated the test to use `tn` (a7274e65), and it now PASSES 29/29.
  - m50_color_symbols failed its 3000 ms timing check (5026 ms for 300 rebinds) while 3 Godot processes were running. Run alone, it PASSES 10/10.
- `git diff --check` was clean on the staged files. project.godot and the .import churn were restored; the import-generated untracked files were removed; `git status --porcelain` is empty.
- No phone build. Throw-away saves only.

## Log
### Round 1
Built everything above. Notes for the reviewer:
- Changing the language reloads the app root only in the shipping app (`current_scene == main`). Under test, the reload is not exercised; l07 proves the effect by rebooting on the saved file.
- The language is stored inside `settings.effects` (an optional key, written only once chosen), so existing exact-snapshot tests stay valid.
- The Turkish copy is my own translation and needs an owner read-through on the phone (noted in TASKS.md). Wording choices: Level = Bölüm, Hearts = Kalp, Bot Parts = Robot Parçası, boosters = Güçlendirici. Booster names are translated (KARIŞTIR, SEÇİCİ, KASIRGA, +1 YUVA). The locked plate reads "BÖL N".
- Job 123's theme-colour code was not touched. The Settings language buttons reuse the existing BasePopup ROW / ROYAL constants.
