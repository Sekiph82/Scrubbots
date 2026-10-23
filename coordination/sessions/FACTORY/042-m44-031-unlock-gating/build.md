STATUS: READY

# Build: Feature unlock gate (SB-M44-031 part 1): data table, Home + booster locking, grandfather rule

## Summary
Branch `factory/042-m44-031-unlock-gating` (commits bd5e3de9, ea0cc0ad, 25eb986b) adds the owner feature unlock table as data and gates Home entries, the booster bar and FTUE coachmarks with it.
- `data/config/feature_unlocks_v1.json` (new): schema `scrubbots.feature_unlocks.v1`, version 1, exactly the 15-entry owner table.
- `scripts/progression/feature_unlocks.gd` (new): strict reader, `load_config`, `validate`, `unlock_level(id)`, `is_unlocked(id, frontier, grandfathered)`. It fails open: a missing or malformed file gives `ok:false` and unlocks everything, and an unknown id is unlocked.
- `scripts/app/app_state.gd`: loads the table once (`unlocks`) and exposes `feature_unlocked(id)` and `feature_unlock_level(id)`. Grandfathered = `not economy.ftue.is_new_profile()`.
- `scripts/ui/home/home_screen.gd`: `GATED_ENTRIES` covers the shop/collection/tasks/daily shortcuts and the robots/events/leaderboard (RANKS) tabs. While locked, an entry is disabled, its tooltip says "Unlocks at level N" (new key `HOME_UNLOCKS_AT_LEVEL` in `scripts/ui/ui_text.gd`), its badge is 0/hidden, and a press emits no `shortcut_requested`/`nav_requested`. Unlocked entries and established saves behave as before; RANKS goes back to "Coming later" once unlocked.
- `scripts/gameplay/runtime/production_gameplay_host.gd`: `booster_states()` returns `"locked"` over every other state, with charges unchanged. `request_booster` and `execute_booster` return reason `locked` and change nothing. The stale doc comment is replaced.
- `scripts/app/ftue_director.gd`: `current_step` skips a `shortcut:<id>` step while that feature is locked and drops locked boosters from a `boosters` step, skipping the step if none remain. Skipped steps are not marked seen.
- `scripts/app/ftue_config.gd` and `data/config/ftue_onboarding_v1.json`: the `soft_no_hard_locks` / `available_from_first_home` requirement is removed. `feature_discovery` is now only a note pointing at `feature_unlocks_v1.json`.
- Docs: `AGENTS.md`, `docs/16_FTUE_FEATURE_UNLOCK_AND_RETENTION_SURFACES.md` (new section 1.2, with part 2 marked pending), `scripts/progression/README.md`.
- Tests: new `tests/m44_unlock_gate.gd`, also added to the `.github/workflows/android-family-first10.yml` suite list (45 suites). Existing tests edited as listed below.
- `TASKS.md`: SB-M44-010 checked off with evidence that includes SB-M44-011. SB-M44-031 is split into part 1 (done) and a new open part 2 line covering per-booster lessons at 6/11/16/21, Daily/Tasks coachmarks after L4/L12, deferring the starter grant and the 100 SB welcome task, and the interim state. Queue rows are updated.

Not changed: the starter grant, the welcome task install, lesson ids/levels, rewards, Gift Bar and pending packs.

## Acceptance criteria
1. [x] `"$GODOT" --headless --path <worktree> -s res://tests/m44_unlock_gate.gd` prints `M44 unlock gate evidence: PASS (6/6 cases, 0 fail)`: exit 0, no SCRIPT ERROR. Its cases (config_reader, level_walk, grandfather, home_gating, booster_gating, ftue_director) cover criteria 2-6.
2. [x] Level walk: one fresh bootstrapped profile is advanced only with `progression.record_win(current)` from L1 and checked at L1, 3, 4, 5, 6, 8, 11, 12, 16, 20, 21, 25, 30, 35, 39 and 40. At each level the 15-feature unlocked set equals `frontier >= table level`, which covers the L3/L4, L5/L6, L11/L12 and L39/L40 boundaries. The L40 save is then written and relaunched, and it is still a new profile with everything unlocked.
3. [x] An established L1 save has all 15 unlocked. A fresh L1 profile has only `["gift_bar","hearts"]`. An unknown id is unlocked. Eight malformed tables are rejected by `validate`, and a malformed file or missing path gives `ok:false` with all 15 unlocked. The shipped config equals the owner table exactly.
4. [x] Home on a fresh L1 profile (with main's APP_SHORTCUTS/APP_NAV): Shortcut_daily/tasks/shop/collection and Nav_robots/events/leaderboard are disabled, each with "Unlocks at level N" from the table, no badges, and no signals when pressed. GiftMeterButton is enabled. At L4 only Shortcut_daily is enabled. At L12 daily, tasks and shop are enabled. At L40 all served entries are enabled. An established save shows exactly today's state (six enabled, RANKS "Coming later"). m42_home, m42_navigation and m42_opening PASS.
5. [x] Real app root, fresh boot, L1: all four boosters `"locked"` with 2 charges each and their buttons disabled. `request_booster` and `execute_booster` return `locked` for all four, with charges, SB and boosters-used unchanged. Locked sets: at L6 random/selector/tornado, at L11 selector/tornado, at L16 tornado, at L21 none. Charges stay 2 each throughout.
6. [x] On a fresh L1 profile the director offers `home_play`, never `home_daily`/`home_tasks`, even when both are claimable, and neither is marked seen. The L1 lesson runs. Both L2 booster steps are skipped and not seen. With one booster opened in the table, the step keeps only that booster. The L3 lesson runs, the window stays open during L3, and `settle()` closes it after the L3 win.
7. [x] The regression suites print their PASS lines: m44_ftue `PASS (23/23 cases, 0 fail)`, m42_home, m42_navigation, m42_opening, m28_c002_c001_gameplay_v02 (14/14), m39c_boosters, m43_c003_c001_acquisition (34/34), m46_rm003_ftue_coach_performance (4 groups). Edits to existing tests, all of which encoded the old fresh-profile behaviour:
   - `tests/m44_ftue.gd`:
     - t11: dropped the "hard lock policy" mutation and asserts the policy is retired.
     - t12: asserts fresh L1 gives `home_play` first, then opens daily/tasks/boosters in the in-memory unlock table (`_unlock_at_l1`, documented test seam) and keeps every original assertion.
     - t13: opens the table so "no tips at L4+" is not masked by locks.
     - t14: asserts the four panels are locked with the tip on PLAY, then opens them and keeps the original claim flow.
     - t15: asserts fresh L2 shows no booster tip and all boosters locked, then opens boosters and keeps the original L2 assertions.
     - No economy, charge or reward assertion was weakened.
   - `tests/m46_rm003_ftue_coach_performance.gd`, `tests/m46_r07_ui_legality.gd` and `tests/m46_rm002_adversarial.gd` (`_boot_play`): open the four boosters in the in-memory unlock table before the L2 FTUE boot so the L2 booster coach they measure still runs. These suites are not in the spec's edit list but encode the same L2-booster-coach-on-fresh-profile behaviour. Without the edit they failed (rm003 crashed in `_oracle` on the missing step). All three PASS now.
   - m42_home*, m42_navigation, m28, m39c and m43_c003 needed no edits because their saves are not new FTUE profiles, so they are grandfathered.
8. [x] `git diff --check HEAD~3 HEAD` is clean. `feature_unlocks_v1.json` and `ftue_onboarding_v1.json` parse with Python `json.load` and Godot. `feature_unlocks_v1` and `feature_unlocked` appear in AGENTS.md, docs/16 and scripts/progression/README.md.

## Validation
- `python tools/run_suites.py` (full CI list, 45 suites including m44_unlock_gate) gave `aggregate=FAIL (44/45)`. The only failure is `m46_performance`, on the `retry() on 59x59 worst` timing check: 52.35 / 58.68 / 56.90 ms against a 50.1 ms limit. The same suite on the pre-change scripts (HEAD~1 versions of the changed scripts checked out temporarily, then restored) measured 50.05 ms (PASS) and 60.00 ms (FAIL, 2 fails). So this is machine timing noise with the baseline itself at the limit, not a regression; the change adds four dictionary lookups per HUD refresh. CI on a GitHub runner should be checked.
- Run individually, all LOCAL_PASS (exit 0, no SCRIPT ERROR/Parse Error): m44_unlock_gate, m44_ftue, m42_opening, m46_rm003_ftue_coach_performance, m46_r07_ui_legality, m46_rm002_adversarial.
- `git diff --check` is clean, and the JSON parses.
- Tree: the only changes are committed. `git status --porcelain` still lists about 1,300 untracked Godot `.import`/`.uid` files that the worktree's Godot import created before the build. They are not part of the job and were not committed.

## Log
### Round 1
- Implemented the reader, config, AppState gate, Home, booster and director gating, FTUE config cleanup, docs, TASKS, the new suite and its CI-list entry.
- Interim behaviour (documented in TASKS part 2): a fresh profile keeps its 8 starter charges and the welcome task, unusable until the features unlock.
- Unlock text is a tooltip only (the spec allows "tooltip/label"). Touch devices don't show tooltips, so a visible label on the panel could follow if wanted.
- Grandfather rule = "not a new FTUE profile" (orchestrator default).
