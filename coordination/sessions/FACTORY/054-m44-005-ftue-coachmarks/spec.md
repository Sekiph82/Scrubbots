# M44 contextual coachmarks: first WAITING, first win/fail/Retry/Heart

> Feature: Tasks SB-M44-005 (teach WAITING/no-current-target behaviour only when the player first encounters it, contextual coachmark/highlight) and SB-M44-006 (teach win/fail/Retry and Heart consequence at first relevant occurrence).

## Context
Worktree: `C:/Users/sekip/Desktop/ScrubBots-factory/054-m44-005-ftue-coachmarks`. TASKS.md lines 1347-1348 (and queue line 43).

Existing FTUE (all presentation-only, native Controls, approved art already in `assets/ui/final/gameplay/tutorial/`):
- `scripts/app/ftue_director.gd` picks ONE scheduled step from `data/config/ftue_onboarding_v1.json` (reader/validator `scripts/app/ftue_config.gd`), gated by `tips_active()` = new profile, not skipped, window not closed (closes when frontier > L3). Acknowledge/Skip only write `FtueState` and request a save.
- `scripts/economy/ftue_state.gd`: durable `{version, profile, skipped, closed, seen[]}` in the economy snapshot (section `ftue`). `profile == ""` = established/grandfathered (no tips); `"new"` = fresh profile.
- `scripts/ui/tutorial/coachmark_layer.gd` (layer 40, ring + pointer + speech bubble, GOT IT / SKIP TIPS, non-blocking). Driven by `scripts/app/main.gd` `_coach_want()` / `refresh_coachmark()` / `_coach_target()` (0.2 s poll; only HOME and GAMEPLAY routes; hidden under modals/settings and when the completion is terminal).
- Today WAITING and Hearts are only taught as SCHEDULED, non-contextual L3 steps `l3_waiting` (target `slots`) and `l3_hearts` (no target) in the `l3_rules` lesson, shown whether or not the player ever met the situation. Copy: `FTUE_L3_WAIT_*`, `FTUE_L3_HEARTS_*` in `scripts/ui/ui_text.gd` (~line 451).
- Truth sources the trigger must READ (never recompute): WAITING = `host.get_scheduler().is_slot_waiting(slot)` (`scripts/gameplay/dispatch/auto_dispatch_scheduler.gd:181`, host accessor `production_gameplay_host.gd:1546`); terminal outcome = RESULTS route payload `status` ("WON"/"LOST", `main.gd` `_results_model`) plus `host.get_terminal_receipt()`; Heart consequence = `host.attempt_consequence()` / receipt (`production_gameplay_host.gd:~1299`), HeartService is canonical. Results UI: `scripts/ui/results_screen.gd` (`get_primary_button()`, `get_home_button()`, `get_panel()`).
- Tests: `tests/m44_ftue.gd` (t15 asserts `l3_waiting`/`l3_hearts` at lines ~514-517), `tests/m44_unlock_gate.gd`, `tests/m46_rm003_ftue_coach_performance.gd`, `tests/m46_r07_ui_legality.gd`, `tests/m51_localization_readiness.gd`, `tests/m55_heart_900_authority.gd`.
- Docs: `docs/16_FTUE_FEATURE_UNLOCK_AND_RETENTION_SURFACES.md` (section 1, ~line 13 L3 line and ~87 "first fail ... first Heart shortage"), `scripts/progression/README.md`.

## Requirements
1. Add three CONTEXTUAL (event-triggered, not level-scheduled) FTUE entries, defined in `ftue_onboarding_v1.json` under a new strict top-level array `contextual` (validated in `FtueConfig.validate`; malformed rejects the whole file like the rest): `ctx_waiting`, `ctx_result_won`, `ctx_result_lost`. Each has `id`, `trigger` (one of `slot_waiting`, `result_won`, `result_lost`), `target`, `title`, `body` (UiText keys).
2. Triggers (first occurrence only, read from canonical state):
   - `ctx_waiting`: on GAMEPLAY, any slot of the live host reports `is_slot_waiting` true. Target = five-slot strip (`slots`). Copy = reuse the meaning of `FTUE_L3_WAIT_*` ("waits until cleaning opens a path"). No forced stall is ever created.
   - `ctx_result_won`: RESULTS route with status WON. Copy states a win costs no Heart and extends the Win Streak (text only, no numbers invented; stay consistent with `economy_rewards_v1.json`).
   - `ctx_result_lost`: RESULTS route with status LOST. Copy states the lost attempt cost 1 Heart (only claim "cost 1 Heart" if the receipt's Heart loss is true, otherwise a neutral no-loss sentence), that RETRY starts again, and that Hearts refill over time. Target = Results primary/Retry button rect when visible, else no pointer.
3. Contextual entries are one-shot: acknowledged (GOT IT, or the real action: leaving the state / pressing the Results button) by `FtueDirector.acknowledge` into the existing `FtueState.seen` list (no schema bump, no new state section), persisted via the canonical save; never shown again after save/load or relaunch.
4. Eligibility (decision): `FtueState.is_new_profile()` and not `skipped`. They are NOT limited to the L1-L3 window or `closed` (a first WAITING/loss may happen at L4+), but Skip Tips suppresses them. Established/grandfathered profiles (`profile == ""`) NEVER see them (no beginner coachmarks for existing saves). Add `FtueDirector.contextual_step(trigger_ctx)` (or equivalent) beside `current_step`; one coachmark at a time, scheduled L1-L3 step wins if both are due.
5. Remove `l3_waiting` and `l3_hearts` from the `l3_rules` lesson (superseded by the contextual entries; keep `l3_speed`). Old saves that already marked those ids seen stay valid (seen ids are free strings). Update `tests/m44_ftue.gd` t15 to the new L3 sequence and add new coverage in the new suite.
6. Presentation: reuse `CoachmarkLayer` unchanged in look (ring, pointer, bubble, GOT IT, SKIP TIPS, non-blocking, Reduced Effects). `main.gd` `_coach_want()` is extended to also serve the RESULTS route and the waiting trigger; hidden while a modal/settings is open or the Results reveal/ceremony is still running (`is_revealing()`/ceremony barrier), so it never covers a reward claim.
7. Pure presentation: the director/layer never grant, claim, spend, consume a Heart, retry, start a booster, change progression, touch board/supply/solver/scheduler, or add timers/limits. Reads only.
8. Localization: all new copy as `FTUE_*` keys in `ui_text.gd` (passes `m51_localization_readiness`); bodies use the existing `UiText.t` path.
9. Docs: update `docs/16_FTUE_FEATURE_UNLOCK_AND_RETENTION_SURFACES.md` section 1 (contextual entries, eligibility, one-shot, removal of the scheduled L3 waiting/hearts steps), the header comment of `ftue_director.gd`/`ftue_state.gd` if wording drifts, and mark SB-M44-005 and SB-M44-006 done in `TASKS.md` with `LOCAL_PASS` evidence (queue line 43 updated per the factory convention).

## Acceptance criteria
GODOT = `C:/Users/sekip/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe`; W = worktree. Never boot `main.tscn` against the owner save (tests use the existing temp-save override pattern from `tests/m44_ftue.gd`).

1. New suite `tests/m44_contextual_coach.gd` runs: `"$GODOT" --headless --path W -s res://tests/m44_contextual_coach.gd` and prints `M44 CONTEXTUAL COACH: PASS` (every case id in an EXPECTED_CASES list completed, as `m44_ftue.gd` does).
2. Config: valid `contextual` block loads; a missing/duplicate id, unknown trigger, bad target or missing UiText key rejects the whole file (`ok:false`); `l3_rules` no longer contains `l3_waiting`/`l3_hearts`.
3. WAITING first encounter: new profile on a real host with a slot driven into WAITING (real scheduler state) shows `ctx_waiting` with pointer on the slot strip rect; before any slot waits nothing contextual shows; after GOT IT it is in `ftue.seen_steps()` and does not re-show when WAITING recurs.
4. Win/Loss: a real WON terminal shows `ctx_result_won` on RESULTS once; a real LOST terminal shows `ctx_result_lost` once, with the Heart sentence matching the receipt's heart-loss truth; a second win/loss never re-shows its entry; won and lost entries are independent.
5. Persistence: after acknowledging, save, rebuild the app from the same save: entries remain seen and do not show; Skip Tips set before the first occurrence means none show.
6. Grandfathered: an established profile (`profile == ""`, e.g. loaded pre-M44 save) hits WAITING, a win and a loss and no contextual coachmark ever shows and `seen` stays empty.
7. Window independence: a new profile with `closed == true` (frontier > L3) still gets each contextual entry once; a skipped one gets none.
8. No economy mutation: Hearts, SB, boosters, streak, progression snapshot are byte-identical before/after showing and acknowledging a contextual coachmark (compare `economy.snapshot()` excluding the `ftue` section); modal-open and Results-reveal suppress display.
9. Regression, each must print its PASS line: `m44_ftue.gd` (`M44 FTUE`-style PASS, with t15 updated), `m44_unlock_gate.gd`, `m46_rm003_ftue_coach_performance.gd`, `m46_r07_ui_legality.gd`, `m51_localization_readiness.gd`, `m55_heart_900_authority.gd`, all via `"$GODOT" --headless --path W -s res://tests/<name>.gd`. (Builder records the exact PASS line each prints; the coach performance suite's budget must not regress.)
10. `git -C W diff --check` is clean; `grep -n "ctx_waiting\|ctx_result_lost" W/docs/16_FTUE_FEATURE_UNLOCK_AND_RETENTION_SURFACES.md` finds the doc update; `grep -n "SB-M44-005\|SB-M44-006" W/TASKS.md` shows both `[x]` with evidence.

## Out of scope
- Any new art, new coachmark visual style, animation, or sound.
- Changing Hearts/Retry/win-streak rules, the Heart popup, Need a Hand, 2x, or any economy value; no UI-triggered economy mutation.
- Forced/scripted loss or stall; timers, move limits, cooldowns.
- Teaching other situations (Heart shortage, third fail, booster-specific, store) - those are other SB-M44 IDs.
- Showing anything to established/grandfathered profiles; migrating or re-classifying saves; a save schema version bump.
- Reworking `l3_speed` or Help/Tips screen content.

## Assumptions
- Contextual entries live in the existing FTUE config and `seen` ledger: reuses strict validation and persistence, no new state section.
- Not tied to the L1-L3 window (a first loss/WAITING can happen later), but suppressed by Skip Tips and absent for established profiles: conservative, avoids re-teaching veterans.
- Scheduled `l3_waiting`/`l3_hearts` removed rather than kept: otherwise the player is taught twice and "only on first encounter" is violated.
- Win entry is included because SB-M44-006 says win/fail/Retry; it is copy-only and costs nothing.
- Retry is taught inside the lost entry (pointer on the Results primary button) rather than a separate step, to stay minimal.
- If the Results screen exposes no stable Retry control rect in LOST, no pointer is shown (text-only), matching how `l3_hearts` already had no target.
