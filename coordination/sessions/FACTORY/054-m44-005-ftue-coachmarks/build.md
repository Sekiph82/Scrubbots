STATUS: READY

# Build: M44 contextual coachmarks: first WAITING, first win/fail/Retry/Heart

## Summary
Branch `factory/054-m44-005-ftue-coachmarks`, commits `23583381` (code, suite, docs) and `6620e38c` (TASKS).

The branch adds three one-shot coachmarks. Each is triggered by an event, not scheduled for a level:
- `ctx_waiting` targets the five-slot strip. It shows the first time the live host's scheduler reports `is_slot_waiting` for any slot.
- `ctx_result_won` has no pointer. It shows on the first WON Results.
- `ctx_result_lost` points at the Results RETRY button. It shows on the first LOST Results. Its Heart sentence comes from the committed receipt.

Eligibility and one-shot rules:
- Only a NEW profile that has not chosen Skip Tips can see them, at any level, so they do not depend on the L1-L3 window. Established profiles never see them.
- A due scheduled step wins.
- An entry is acknowledged by GOT IT or by the real action: the trigger ends (WAITING resolves, or Results is left via RETRY, CONTINUE or HOME). The acknowledgement goes into the existing `FtueState.seen` ledger. There is no schema bump.
- The scheduled `l3_waiting` and `l3_hearts` steps are removed; `l3_rules` now holds only `l3_speed`.

The change is presentation only. Triggers are read-only (`_coach_trigger`). Nothing shows under modals or Settings, or while a Results reveal or ceremony barrier is running.

Files changed:
- `data/config/ftue_onboarding_v1.json`: new `contextual` array; `l3_waiting` and `l3_hearts` removed.
- `scripts/app/ftue_config.gd`: strict `contextual` validation. Ids must be unique across lessons and entries, with one entry per trigger, a known target (new `results_retry`) and existing `UiText.EN` keys. Any malformed entry rejects the whole file.
- `scripts/app/ftue_director.gd`: new `contextual_active()`, `contextual_step(trigger)` and `contextual_trigger(id)`; Heart-truth copy for `ctx_result_lost`; header comment updated.
- `scripts/app/main.gd`: new `_coach_trigger()`; `_coach_want(trigger = null)` now also serves RESULTS; acknowledge-on-trigger-end via `_coach_ctx_id`; `results_retry` target.
- `scripts/ui/ui_text.gd`: `FTUE_CTX_*` keys replace the now-unused `FTUE_L3_WAIT_*` and `FTUE_L3_HEARTS_*`.
- `tests/m44_contextual_coach.gd`: new suite.
- `tests/m44_ftue.gd`: t15 updated to the new L3 sequence.
- `tests/m44_unlock_gate.gd`: the L3 lesson's first step is now `l3_speed`.
- `docs/16_FTUE_FEATURE_UNLOCK_AND_RETENTION_SURFACES.md`: L3 bullet changed and new section 1.3 added.
- `TASKS.md`: SB-M44-005 and SB-M44-006 checked off; queue row 43 set to DONE.

Copy, checked against `OWNER_ECONOMY_REWARDS_V01.md` and `economy_rewards_v1.json`:
- Win: "A win never costs a Heart, and each new level you clear in a row grows your Win Streak." It says "new level" because replays do not advance the streak, and it states no numbers.
- Loss: "This try cost 1 Heart." when the receipt's `hearts.after < before`, otherwise "This try did not cost a Heart." The sentence continues: "RETRY starts this level again, and Hearts refill over time."

## Acceptance criteria
1. [x] The new suite runs and passes. `"$GODOT" --headless --path W -s res://tests/m44_contextual_coach.gd` exits 0 with no SCRIPT ERROR or Parse Error and prints `M44 CONTEXTUAL COACH: PASS (7/7 cases, 0 fail)` (EXPECTED_CASES ledger c01..c07).
2. [x] Config: c01 shows the shipped config is ok with 3 contextual entries and their triggers. 12 out of 12 malformed variants reject the whole file: missing id, duplicate contextual id, id clashing with a lesson step, unknown trigger, duplicate trigger, bad target, missing target, unknown title key, unknown body key, block missing, block not an array, entry not a dict. `l3_rules == ["l3_speed"]`.
3. [x] First WAITING (c03): the test plays the real L4 with the real runtime ticking and fronts placed until the scheduler itself reports a lane WAITING.
   - At gameplay start with no lane waiting, nothing contextual shows (c04).
   - `ctx_waiting` then shows with the pointer visible and its target equal to `get_five_slot_strip_rect()`.
   - After GOT IT it is in `seen_steps()` and is not shown while the lane is still WAITING, nor when WAITING recurs on a later attempt.
   - Leaving the WAITING state without pressing GOT IT also acknowledges it (c03b).
4. [x] Win/Loss (c04): both terminals are real, sent through `terminal_reached`.
   - First LOST shows `ctx_result_lost`. The receipt says hearts `{before 5, after 4}` and the body starts with "This try cost 1 Heart."
   - The target equals the RETRY button rect.
   - Pressing RETRY acknowledges the entry, and a second LOST does not show it again.
   - First WON shows `ctx_result_won` with no pointer, independent of the loss entry. GOT IT acknowledges it, and a second WON does not show it again.
   - The no-Heart-loss sentence is checked in c02 with a receipt where `before == after`.
5. [x] Persistence (c05): after acknowledging, the test calls `request_save()` (ok) and reboots main.tscn from the same temp save. The entry is still seen and a new LOST shows nothing. When Skip Tips is set at L1 before any occurrence, LOST, WON and WAITING show nothing.
6. [x] Grandfathered (c06): the economy ftue section is imported as null, which is the pre-M44 established path. WAITING, loss and win all show no contextual coachmark, `seen_steps()` stays empty, and no `ctx_*` id is in the shown log. c02 checks the same at director level.
7. [x] Window independence: in c03, c04 and c07 `closed == true` because the frontier is L4 or later, and each entry still shows once (asserted in c03). In c02 the entry is still due after `close()` and is suppressed after skip.
8. [x] No economy mutation and correct suppression:
   - `economy.snapshot()` without `ftue`, plus `progression.snapshot()`, is byte-identical across show and GOT IT (c03, c07) and across the RETRY press (c04).
   - With the Help modal open over Results nothing shows; after the modal closes the entry shows (c07).
   - While the WON reveal runs nothing shows; after `finish_reveal` the entry shows (c07).
9. [x] Regression suites, each with exit 0, no SCRIPT ERROR and no Parse Error:
   - `m44_ftue.gd`: `M44 FTUE evidence: PASS (23/23 cases, 0 fail)`
   - `m44_unlock_gate.gd`: `M44 unlock gate evidence: PASS (6/6 cases, 0 fail)`
   - `m46_rm003_ftue_coach_performance.gd`: `M46 RM003 FTUE COACH: PASS (4 case groups)`. Budgets hold: l2_boosters_a copy mean 0.40 ms (limit 4.0), 59x59 moving hint mean 0.85 ms, 2.5 s of frames gives 1 copy rebuild.
   - `m46_r07_ui_legality.gd`: `M46 R07 UI LEGALITY: PASS`
   - `m51_localization_readiness.gd`: `M51 localization readiness evidence: PASS (4/4 cases, 0 fail)`
   - `m55_heart_900_authority.gd`: `M55 HEART 900 AUTHORITY: PASS`
10. [x] `git diff HEAD~2 HEAD --check` is clean. The `grep` for `ctx_waiting`/`ctx_result_lost` finds docs/16 lines 41 and 43. `grep` for `SB-M44-005`/`SB-M44-006` in TASKS.md shows `[x]` at lines 1347 and 1348 with evidence, and queue row 43 is DONE.

## Validation
All runs used `Godot_v4.7.2-stable_win64_console.exe --headless --path <worktree> -s res://tests/<suite>.gd` and were recorded as LOCAL_PASS:
- `m44_contextual_coach`: PASS, about 12 s. It was re-run after the last comment edit and passed again.
- `m44_ftue`, `m44_unlock_gate`, `m46_rm003_ftue_coach_performance`, `m46_r07_ui_legality`, `m51_localization_readiness`, `m55_heart_900_authority`: all PASS.
- `git diff --cached --check` was clean before each commit.

Every suite ends with the usual Godot "ObjectDB instances leaked at exit" warning, as the existing suites do; it is not a SCRIPT ERROR.

Worktree note: `git status` still lists Godot import artefacts (untracked `*.uid` and `*.import`, modified `*.png.import`). They were present when the job started; I did not create or stage them. Every task file is committed. Nothing was pushed.

## Log
### Round 0
- Implemented the contextual config block, director API, main.gd trigger and want logic, copy keys, docs and TASKS updates, as described in the Summary.
- Wrote `tests/m44_contextual_coach.gd`. The first version could not find a WAITING lane by stepping the scheduler alone, so it now ticks the real runtime with fronts placed until the scheduler reports WAITING (found on L4).
- `debug_set_current_level` fixtures never save, so the suite reaches L4 with `record_win` and the relaunch case can persist.
- Updated `m44_ftue.gd` t15 and `m44_unlock_gate.gd` for the removed L3 steps.
- Ran all suites; all pass.
