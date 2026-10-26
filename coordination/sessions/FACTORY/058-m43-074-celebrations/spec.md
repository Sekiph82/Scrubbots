# M43-C005 meta celebrations: Gift milestone, Daily cycle, 3/3 Tasks, Reduced Effects (SB-M43-074..077)

> Feature: Tasks SB-M43-074..077 (Gift Meter milestone, Daily cycle and 3/3 Tasks celebrations; Reduced Effects collapse without changing grants)

## Context
Job 057 found 068-071 already built. Same finding here: almost everything for 074/075/077 already exists. Worktree: `C:/Users/sekip/Desktop/ScrubBots-factory/058-m43-074-celebrations`.

- **074 Gift milestone (EXISTS):** `scripts/economy/ceremony_events.gd` derives `gift:<occurrence id>` events (milestone, cycle, claimed, cycle_max, rewards = `economy.config.gift_meter_milestone(m)` bundle) from `economy.gift.gift_bar_queue()`, read-only. `MetaCeremonies.gift_milestone` (`scripts/ui/ceremony/meta_ceremonies.gd`) renders it, the CTA only acknowledges (`CeremonyPresenter` -> `MetaUiState.mark_seen`); claiming stays in the Gift Bar (`GiftMeterService.claim`). Covered by `tests/m43_master_c005_meta_ceremonies.gd` e23-e28 (10 exact queued bundle, 1000 crate + fallback note, claimed copy, all five once in order, reload none pending, Results handoff) and `tests/m43_c005f_phase3_meta_rewards_acquisition.gd` d01/d02. The Gift builder takes the `reduced` flag, but no existing case compares FULL vs Reduced for `gift_milestone` (e08/e14/e22/e29 do it for set/master/robot/feature).
- **075 Daily cycle + 3/3 Tasks (EXISTS as claim popups):** `DailyScreens.open_daily_reward` (popup id `ceremony_daily`, `scripts/ui/daily/daily_screens.gd` ~L323; day title, `UiText.reward_text(result.reward)`, Day-5 `DAILY_CYCLE_DONE` copy) opens only after `app.actions.claim_daily_login()` succeeds. `DailyScreens.open_scrubbox` (`ceremony_scrubbox`, ~L153) opens only after `claim_daily_all_tasks()` succeeds and shows `random_any_booster_charges` from the committed result (config `daily.all_tasks_random_any_booster_charges`). Feel hooks exist in `scripts/ui/feel/meta_reward_feel.gd`. Existing tests: `tests/m43_master_c009_daily.gd` t05 (ScrubBox once, +1 charge), `m43_c005f_phase3...` d03/d04. Gap: no test asserts the Daily login popup content for every cycle day against `data/config/economy_rewards_v1.json` `daily.login_rewards` (days 1-5), that Day 5 shows the cycle-done copy, that opening either popup grants nothing, nor that FULL vs Reduced shows identical labels with no motion/tween nodes.
- **077 Reduced Effects (PARTIAL):** `CeremonyPresenter._reduced()` -> `MetaCeremonies.build(e, reduced)` removes only the glow turn; Daily/ScrubBox popups have no motion at all (comment "identical in Reduced Effects (SB-M43-077)"); feel plugin work is zero under Reduced (`m43_c005f_phase3` s03/b02). Gap is the missing explicit regression for gift/daily/scrubbox (above).
- Ordering/no-stacking: Gift/set/master/robot ceremonies are drained one at a time by `CeremonyPresenter` (after Results reward reveal; feature-unlock `unlock:*` events come after them; NEW badge m44_new_badge and coach m44_contextual_coach are separate and untouched). Daily and ScrubBox popups are player-initiated from the Daily/Tasks screens, never drained by the presenter, so they cannot stack with it. Do not change this.

Task status for this job:
- SB-M43-074: **verify-close** (e23-e28 plus the new Reduced case).
- SB-M43-075: **verify-close after adding a test** (production code exists; add the missing assertions).
- SB-M43-076: no entry exists in TASKS.md (numbering skips 076); do not invent one.
- SB-M43-077: **verify-close after adding a test** (Reduced equivalence for gift/daily/scrubbox).
Only if the new test exposes a real defect, fix the smallest production code in `daily_screens.gd` / `meta_ceremonies.gd`; otherwise no production change.

## Requirements
1. Add one new headless suite `tests/m43_c005_c074_c077_celebrations.gd` (`extends SceneTree`, per `docs/TESTING_CONVENTIONS.md`), ending with `M43 C005 gift/daily/tasks celebrations evidence: PASS (N/N cases, 0 fail)` (exit non-zero on failure). Reuse the app/economy setup helpers pattern of `tests/m43_master_c005_meta_ceremonies.gd` and `tests/m43_master_c009_daily.gd`; no new fixtures if avoidable.
2. Cases (each named `cNN_...`, listed in EXPECTED_CASES so skipped cases fail):
   - c01 Gift milestone, FULL vs Reduced: for each milestone 10/50/250/500/1000, `MetaCeremonies.build(event, false)` and `(event, true)` have identical label texts, reward rows equal the `economy_rewards_v1.json` `gift_meter` milestone bundle (read from the config file), and the Reduced popup has no `HeroGlow` spin meta.
   - c02 Gift presenting grants nothing: after a `CeremonyPresenter` ceremony for a queued milestone is shown under Reduced Effects and acknowledged, wallet/booster/pack authority snapshot is unchanged and the occurrence is still claimable; a reload shows none pending (exactly once).
   - c03 Daily cycle: for days 1..5, `DailyScreens.open_daily_reward(stack, app, result)` where `result` comes from a real `app.actions.claim_daily_login()` on consecutive injected days shows `UiText.reward_text` of the config `login_rewards[day]` exactly; Day 5 shows `DAILY_CYCLE_DONE`, days 1-4 show the streak copy; the wallet/inventory delta equals that config reward (shown == granted); opening the popup performs no grant (authority snapshot identical before/after open).
   - c04 3/3 Tasks: after all three tasks are done, `claim_daily_all_tasks()` then `open_scrubbox` shows `random_any_booster_charges` == config `all_tasks_random_any_booster_charges` and the committed result; a second claim returns not-ok and grants nothing (exactly once); the popup is not offered/opened when the claim fails.
   - c05 Reduced collapse: with `set_reduced_effects(true)`, the Daily and ScrubBox popups have identical label texts to FULL and contain no running Tween/animation child; all grants in c03/c04 are the same amounts under Reduced.
   - c06 No stacking: while a `CeremonyPresenter` ceremony is on the ModalStack, `drain()` opens no second one; opening Daily/ScrubBox popups never marks any `MetaUiState` key seen (presentation-only boundary).
3. Add the new suite name to the `for s in ...; do` list in the `validate` job of `.github/workflows/android-family-first10.yml` (tools/run_suites.py reads it from there) and an exact-summary `grep -qxF` guard following the m46_performance pattern; update the workflow header comment (suite count 48 -> 49).
4. Docs: tick SB-M43-074, 075, 077 in `TASKS.md` with the evidence line format used for 072 (suite name, case count, run_suites result), update the queue READY line, and add one line to `docs/06_TEST_STRATEGY.md` if it lists suites per milestone. Do not touch AGENTS.md unless it lists suites (then add the new one).
5. No new art, copy keys only if a missing `UiText` key is needed (none expected), no new mechanics, no grants from UI.

## Acceptance criteria
GODOT = `C:/Users/sekip/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe`
1. `"$GODOT" --headless --path <worktree> -s res://tests/m43_c005_c074_c077_celebrations.gd` prints as its last PASS/FAIL line `M43 C005 gift/daily/tasks celebrations evidence: PASS (6/6 cases, 0 fail)` (or the final case count if cases are split, but every case in EXPECTED_CASES) with no `SCRIPT ERROR`/`Parse Error` lines.
2. The same command fails (non-zero exit / FAIL line) if a case is skipped or an assertion is broken (EXPECTED_CASES guard present in the file).
3. Existing suites still pass with their exact summaries: `res://tests/m43_master_c005_meta_ceremonies.gd` -> `M43 master C005 meta ceremonies evidence: PASS (32/32 cases, 0 fail)`; `res://tests/m43_master_c009_daily.gd`; `res://tests/m43_c005f_phase3_meta_rewards_acquisition.gd` (15/15); `res://tests/m43_c005_c072_feature_unlock_ceremony.gd` (9/9).
4. `.github/workflows/android-family-first10.yml` contains `m43_c005_c074_c077_celebrations` in the `for s in` loop and a matching `grep -qxF` guard; `python tools/run_suites.py` runs it and reports ALL PASS (49 suites) with no failures.
5. `git diff --check` clean; `git diff --stat` shows only the new suite, the workflow, TASKS.md and doc lines (plus a minimal production fix only if a case exposed a defect, named in the evidence).
6. `grep -n "SB-M43-07[457]" TASKS.md` shows 074, 075, 077 ticked with LOCAL_PASS evidence naming the new suite; 076 untouched.

## Out of scope
- World unlock ceremony (SB-M43-073), Gift micro-progress (R05), new animations/art/sounds, new reward values, new presenter kinds for Daily/Tasks (they stay player-initiated claim popups), changing drain order, NEW badge or coach logic, refactoring MetaCeremonies, adding a Daily/Tasks kind to `CeremonyEvents`.
- Any grant, claim or save from UI code.

## Assumptions
- The existing Daily claim popup and ScrubBox popup ARE the Daily-cycle and 3/3 celebrations (owner-accepted shells, SB-M39-054 neutral Mystery Booster art); adding a second presenter-driven ceremony would duplicate them and risk double grant/replay.
- Reduced Effects "concise accessible presentation" is already satisfied: same labels/values, motion removed; the task is evidence, not a new layout.
- SB-M43-076 does not exist in TASKS.md; left alone.
- Day-by-day login claims in c03 use the injected local-day provider (as `m43_master_c009_daily.gd` / `m39d_daily_collection.gd` do), not real time.
