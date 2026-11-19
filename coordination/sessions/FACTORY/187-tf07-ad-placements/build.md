STATUS: READY

# Build: New ad placements: event +1 rewarded ad, App Open ad, interstitial every 4 from level 10

## Summary
Branch `factory/187-tf07-ad-placements` (from main cce20687), commits `6d8f9f6a` (feature + docs) and `555150cc` (tests + CI).

- **Policy record:** the new file `data/config/ad_placements_v1.json` (`policy_version` 2, with a `supersedes` note for v1) sets interstitial 10/4, App Open 20/1/skip_install_day, event ad 1/1. `AdService` reads and validates it. If the file is missing, corrupt or the wrong version, interstitial and App Open are switched off; banner and rewarded keep working. No cadence or level numbers are hard-coded any more. The owner amendment (2026-11-18, SB-TF-07) is added to `coordination/OWNER_ECONOMY_REWARDS_V01.md` right after SB-TF-05.
- **Interstitial:** `on_play_finished(level)`. The host passes `progression_level`. A play below level 10 still counts in `plays()` but does not count toward the 4-play cadence (`_last_interstitial = _plays`). From level 10 an ad is due every 4 plays. A due ad the provider could not show stays due.
- **App Open:**
  - `AdProvider.show_app_open` (the null provider returns false).
  - `AdmobAdProvider` uses the pinned plugin's API: `load_app_open_ad` / `show_app_open_ad` and the signals `app_open_ad_loaded`, `app_open_ad_failed_to_load`, `app_open_ad_failed_to_show_full_screen_content`, `app_open_ad_dismissed_full_screen_content`. The ad loads after SDK init and is used once, then reloads. It uses the same 5/15/45 s retry as the other kinds. `auto_show_on_resume = false`. The Google TEST unit is used unless the release ids file has a non-empty `app_open`. A real-id build without one never loads or shows it and logs `ADS_APP_OPEN_NO_ID`.
  - `AdService.note_launch()` records `first_day` once. `try_app_open()` gates on No Ads, a valid config, frontier >= 20 (`bind_level`), local day > `first_day` and > `app_open_day`, then asks the provider. Only an ad that was actually shown writes `app_open_day`. Both days persist in section `ads`; when absent they import as -1, and a non-int or a value < -1 is rejected.
  - `main.gd` calls `note_launch` once at boot. It calls `_try_app_open()` once per boot, right after the Home entry that follows the opening (completed or failed) or after the direct boot Home. It never fires during OPENING, over a coachmark, or on a blocked save. A shown ad marks the save dirty.
  - New test seam: `MainScript.boot_ad_provider_override`.
- **Event +1:**
  - `RewardedGrantService.start_event_ad` / `can_start_event_ad`: product `event_ad:<iid>`, placement `rewarded_event_progress`, tx `event_ad:<iid>:<day>`, reward `{event_ad_progress: 1}`. Refusal reasons: already_claimed, clock_rollback (day below the highest `event_ad` day on the ledger), not_found / not_joined / not_active / ineligible_kind (from `EventsV02Service.ad_refusal`), pending, unavailable.
  - The `event_ad_progress` handler calls `EventsV02Service.add_ad_progress(iid)`. This uses the shared `_add` tail that `_apply` now also uses (reach_t, log, race finish_t, streak best). It never touches receipts or claims.
  - Facade: `event_ad_available` / `start_event_ad` (Events gate, `ads.allowed("rewarded")`, day from `daily.local_day()`).
  - Event details popup: a "WATCH AD · +1" / "REKLAM İZLE · +1" action (`EV2_WATCH_AD`) with a 60 s abandon timeout and a refresh on `resolved`.
  - Event ads are excluded from the reward-reveal flight in `main._reveal_rewarded`.
- **Analytics:** `ad_product` enum gains `event_progress`. New event `ad_placement` (task SB-TF-07), emitted by `AdService` through `on_placement`, which AppState wires to `analytics.track`. `ad_request` comes from the UI; `ad_result` maps the `event_ad:` prefix to `event_progress`.
- **CI / docs:**
  - Both workflows pass an optional `ADMOB_{ANDROID,IOS}_APP_OPEN_ID` secret into `scrubbots_real_ids.gd` as `app_open`. It is not required.
  - The android validate loop and an exact 14/14 guard now include the new suite; the SB-M57 comment is updated.
  - Also updated: AGENTS.md Ads section, `docs/ANALYTICS_TAXONOMY_V1.md`, `docs/PRIVACY_DATA_INVENTORY.md`, `docs/RELEASE_BUILDS.md`, `store/DATA_SAFETY_AND_RATINGS.md`, and the comments in `store_service.gd` / `economy_services.gd`.

Files changed:
- Config: `data/config/ad_placements_v1.json` (new), `data/config/analytics_taxonomy_v1.json`
- Scripts:
  - App: `scripts/app/app_state.gd`, `scripts/app/main.gd`
  - Economy: `scripts/economy/{ad_service,ad_provider,admob_ad_provider,economy_services,events_v02_service,production_action_facade,rewarded_grant_service,store_service}.gd`
  - Gameplay: `scripts/gameplay/runtime/production_gameplay_host.gd`
  - UI: `scripts/ui/events/events_v02_ui.gd`, `scripts/ui/ui_text.gd`, `scripts/ui/ui_text_tr.gd`
- Tests: `tests/sb_tf07_ad_placements.gd` (new), `tests/m57_ads_cadence.gd`, `tests/m57_native_providers.gd`, `tests/sb_phone_2026_11_12_e_win_home.gd`, `tests/m56_analytics_taxonomy.gd`
- Workflows: `.github/workflows/android-family-first10.yml`, `.github/workflows/ios-ipa.yml`
- Docs: `AGENTS.md`, `coordination/OWNER_ECONOMY_REWARDS_V01.md`, `docs/ANALYTICS_TAXONOMY_V1.md`, `docs/PRIVACY_DATA_INVENTORY.md`, `docs/RELEASE_BUILDS.md`, `store/DATA_SAFETY_AND_RATINGS.md`

## Acceptance criteria
1. [x] `sb_tf07_ad_placements` prints `SB-TF-07 ad placements evidence: PASS (14/14 cases, 0 fail)`. It exits 0 with no SCRIPT ERROR or Parse Error. The `ERROR: Parse JSON failed` line is the deliberately corrupt config in c01 and does not match the CI DIAG pattern. Cases c01..c14 all run on a real EconomyServices, AppState or main.tscn with a mock provider, a fake day and a fake clock:
   - c12 records `nav.current()` inside the mock: the ad is never called while OPENING, and called once on HOME after the opening completes or fails, and once after a direct boot.
   - c13 taps the real popup button.
   - c14 uses a MemorySink, with consent on and off.
2. [x] `m57_ads_cadence` prints `M57 ads cadence evidence: PASS (6/6 cases, 0 fail)`.
   - a02 is renamed `a02_every_fourth_play_from_level_10`: shown `[4, 8, 12]`, and 9 plays below level 10 are never due.
   - a01 uses 4 plays at level 10.
   - a03 and a06 boot at frontier 10. a03 shows the interstitial at the Retry after play 4.
   - a06 now checks the 4-field snapshot, an old 2-field import, and rejects `first_day: -2` and `app_open_day: "4"`.
3. [x] `m57_native_providers` prints `M57 native providers evidence: PASS (14/14 cases, 0 fail)` (summary unchanged). FakeAdmob gains the App Open signals and methods.
   - n06: App Open loads once, only after `initialize`, and `auto_show_on_resume` is false.
   - n08: not shown and nothing loaded before SDK init; false while loading; true after loading; single use; reloads after dismissal; a failed load gives one 5 s retry, which reloads.
   - n09: a test build uses the TEST unit; a real-id build without `app_open` never loads or shows, and the source logs `ADS_APP_OPEN_NO_ID`; a real-id file with `app_open` on iOS sets `ios_real_app_open_id`.
4. [x] `sb_phone_2026_11_12_e_win_home` prints `SB-PHONE-2026-11-12-E win home evidence: PASS (10/10 cases, 0 fail)`. The interstitial case now runs at frontier 10: 3 plays plus the real 4th play at level 10, shown at Home PLAY only.
5. [x] Green with their PASS lines: `ev02_events_v02` (10/10), `ev02_events_ui` (6/6), `m56_analytics_taxonomy` (27/27), `m58_privacy_consent` (7/7), `m58_privacy_inventory` (7/7), `m57_store_products` (9/9), `m49_ad_store_return_layout` (6/6), `sb_tf05_reward_reveal` (16/16), `m43_r15_owner_remediation` (18/18), `m60_release_gates` (6/6).
   - `m56_analytics_taxonomy`: the task list gains SB-TF-07, and `_tour_ads` now drives one real due-interstitial no-fill so `ad_placement` is emitted on a real path.
   - Save suites: `m40_save_system`, `m40_v02_safety`, `m40_v03_canonical`, `m40_v04_bootstrap`, `m55_core_chaos`, `m55_economy_release_regression`, `m55_player_chaos`, `m55_long_session`, `m55_heart_900_authority`, `m55_c002_timed_2x_anti_rollback` all PASS. `m55_player_chaos` prints 3 SCRIPT ERROR lines; all of them are the test's own injected `explode` fault, which CI excludes as INJECTED.
   - Also run: `m43_r15_001_r01_sequential_unlock` (14/14), `m43_c001a_results_foundation` (11/11), `m42_opening` PASS, `m44_ftue` (23/23), `m43_master_c010_meta` (12/12).
6. [x] `grep -n "ad_placements_v1" coordination/OWNER_ECONOMY_REWARDS_V01.md` finds line 443, the 2026-11-18 SB-TF-07 amendment, which contains "App Open", "level 20", "every 4", "level 10", "event" and "No Ads".
7. [x] `grep -rn "INTERVAL := 5\|every-5\|every 5 plays\|every 5 finished" scripts AGENTS.md .github/workflows/android-family-first10.yml` returns nothing (rc=1).
8. [x] The workflow validate loop contains `sb_tf07_ad_placements`. The guard `grep -qxF 'SB-TF-07 ad placements evidence: PASS (14/14 cases, 0 fail)' validate_logs/sb_tf07_ad_placements.log` is at line 492; its else branch sets `fail=1`.
9. [x] `git diff --check cce20687..HEAD` is clean. The changed files include no `economy_rewards_v1.json`, no `data/levels`, no `assets/`. No price, reward amount, cap or Heart rule changed.

## Validation
Godot 4.7.2 (`C:/Users/sekip/AppData/Local/Microsoft/WinGet/Links/godot.exe --headless --path <worktree> -s res://tests/<suite>.gd`). Every run below is LOCAL_PASS: exit 0, and the last PASS/FAIL line says PASS.
- Main suites on the final code (HEAD 555150cc): sb_tf07_ad_placements, m57_ads_cadence, m57_native_providers, sb_phone_2026_11_12_e_win_home.
- Regression batch on the feature code (the only later change was the m56 test, re-run separately): ev02_events_v02, ev02_events_ui, m58_privacy_consent, m58_privacy_inventory, m57_store_products, m49_ad_store_return_layout, sb_tf05_reward_reveal, m43_r15_owner_remediation, m43_r15_001_r01_sequential_unlock, m60_release_gates, m40_save_system, m40_v02_safety, m40_v03_canonical, m40_v04_bootstrap, m55_core_chaos, m55_economy_release_regression, m55_player_chaos (injected errors only), m55_long_session, m55_heart_900_authority, m55_c002_timed_2x_anti_rollback, m43_c001a_results_foundation, m42_opening, m44_ftue, m43_master_c010_meta.
- m56_analytics_taxonomy: the first run failed on the "every real-path event emitted" check because `ad_placement` had no real path. After the `_tour_ads` addition it PASSES (27/27).
- JSON parse check of both configs: OK. `git diff --check`: clean.

Not done (out of scope or not allowed): CI runs, APK/IPA builds, any edit to TASKS.md (the orchestrator adds the SB-TF-07 status and the "Questions for Şekip" App Open unit line at merge).

AdMob plugin API, what was checked: I downloaded `AdmobPlugin-Multi-v7.0.zip` from the URL pinned in both workflows; its sha256 `d96e1734...cf8a2` matches the pin. `res/addons/AdmobPlugin/Admob.gd` contains:
- methods `load_app_open_ad(LoadAdRequest = null)`, `show_app_open_ad()`, `is_app_open_ad_available()`;
- signals `app_open_ad_loaded(ad_info, response_info)`, `app_open_ad_failed_to_load(ad_info, LoadAdError)`, `app_open_ad_failed_to_show_full_screen_content(ad_info, AdError)`, `app_open_ad_dismissed_full_screen_content(ad_info)`;
- exports `android_real_app_open_id` / `ios_real_app_open_id`, the debug demo units (`ca-app-pub-3940256099942544/9257395921` Android, `.../5575463023` iOS), and `auto_show_on_resume` (default false, passed to the native load).

What could not be checked: the native Android/iOS side of App Open on a device. No build was made, so real fill and the full-screen behaviour on a phone are unverified.

Worktree state: the only uncommitted entries are Godot import artefacts that were already there before this build (`project.godot` rewritten by `--import`, untracked `*.import`, `*.uid`, `docs/*.translation`). I left them alone as instructed; none are part of the branch.

## Log
### Round 1
Built the whole spec in two commits:
- `6d8f9f6a`: config, AdService, AdMob App Open, main boot hook, the event ad through RewardedGrantService / EventsV02Service / facade / UI, analytics, docs, the owner amendment, and the optional App Open secret in the workflows.
- `555150cc`: the new 14-case suite, the CI loop + guard, and test updates (m57 cadence, m57 native providers, sb_phone_e, m56).

Things for the owner to know:
- **Quest / colors events:** the event +1 is hidden for Master Cleaner Quest (quest) and Color Scrub Rush (colors) because their progress is derived. This is the spec's conservative reading of "each active event screen" and needs the owner's attention.
- **App Open on direct boot:** App Open is tried exactly once per cold boot, at the Home entry. On a real device the opening video gives the SDK time to load the ad. If the opening is skipped (it is a once-per-process gate) and the ad has not loaded yet, nothing shows that launch: by design, no retry and no resume ad.
- **Release builds:** they show no App Open until the owner creates the App Open units and adds the `ADMOB_{ANDROID,IOS}_APP_OPEN_ID` secrets. That needs the TASKS.md question line, which the orchestrator adds.
