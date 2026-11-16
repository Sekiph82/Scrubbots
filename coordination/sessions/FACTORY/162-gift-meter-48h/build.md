STATUS: READY

# Build: 162-gift-meter-48h (SB-GIFT-METER-48H-2026-11-17)

## Summary
Branch `factory/162-gift-meter-48h`, one commit `c1c12590` (not pushed). Each Gift Meter cycle now lasts at most 48 h, counted from its first progress. The window lives in GiftMeterService, behind the M39 boundary. Expiry is checked lazily on every read, progress, snapshot and import, using the injected economy wall clock (same pattern as HeartService). When the window runs out:
- unfinished progress is dropped and the meter goes back to 0/1;
- `cycles_expired` and `expired_progress` are recorded;
- the next progress starts a new cycle index, so milestone occurrence ids stay unique (`gift_ms:c<completed+expired>:m<N>`);
- queued milestones are kept and stay claimable;
- `cycles_completed` (used by achievements) counts only cycles that reached 1000.

If 1000 is reached inside the window, the cycle rolls over and the overflow gets a fresh window. If the clock is moved backwards, the window never expires and is never re-anchored, and the time shown is capped at 48 h. Home shows the time left in a small label under the gold bar, between the emblem and the crate. The label is hidden at 0 progress.

Files changed:
- `scripts/economy/gift_meter_service.gd`: clock, window, expiry, `window_seconds_left()`, snapshot fields, migration and strict import
- `scripts/economy/economy_config.gd`: schema 4, validation of `gift_meter.cycle_window_hours`, accessor
- `scripts/economy/economy_services.gd`: passes the clock and the window to GiftMeterService
- `data/config/economy_rewards_v1.json`: `schema_version` 4, `gift_meter.cycle_window_hours: 48`
- `scripts/ui/home/home_view_model.gd`: `gift_window_seconds_left`
- `scripts/ui/home/home_screen.gd`: only the `GiftWindowLeft` label and how it is set
- `scripts/ui/ui_text.gd`: `TIME_DH`/`TIME_M` and `UiText.time_left()`
- `scripts/ui/ui_text_tr.gd`: TR `TIME_DH`/`TIME_M`
- `coordination/OWNER_ECONOMY_REWARDS_V01.md`: dated owner amendment in §4.2
- `tests/sb_gift_meter_48h.gd` (+ `.uid`): new suite
- `.github/workflows/android-family-first10.yml`: suite added to the list, with an exact `grep -qxF` guard

`home_reward_flight.gd` was not touched.

## Acceptance criteria
1. [x] Expiry at 48 h resets progress: g03 checks that progress is still 10 with 1 s left at 48 h - 1 s, then 0 with no window at exactly 48 h, and `cycles_completed` stays 0.
2. [x] Queued milestones are kept: g03 checks that c0:m1/m5/m10 are still claimable after expiry, and that `claim_gift(c0:m5)` succeeds through the AppState actions.
3. [x] 1000 inside the window rolls over with a new window: g04 feeds 990 + 15 at 47 h. Result: m1000, c1:m1 and c1:m5 queued, 5 carried over, a full 48 h window, and no expiry at the old deadline. Exactly 1000 leaves no window.
4. [x] No window at 0: g02 shows that a fresh meter has no window even after 30 days, and that the first progress starts a full 48 h window.
5. [x] Migration of an existing save: g05 covers these cases.
   - A pre-window save with progress 120 imports and its window starts at load; it expires 48 h later and its queue is kept.
   - An old save at 0 gets no window.
   - A saved window that ran out while the app was closed expires on load.
   - Strict rejection, with state left untouched, for: window -1 with progress, window with progress 0, window -5, a fractional window, mismatched expired_progress, negative cycles_expired.
6. [x] Clock rollback: g06 moves the clock back a day. Progress is kept and the time left is capped at 48 h. Progress added during the rollback does not re-anchor the window, and the window expires at the original deadline once the clock is restored.
7. [x] UI countdown EN/TR: g07 runs on the real Home scene.
   - Hidden at 0 progress.
   - 47 h left shows `1d 23h` / `1g 23sa`, 45 min shows `45m` / `45dk`, 30 s shows `1m` / `1dk`.
   - The label's rect does not intersect the bar caption, the emblem or the crate.
   - After expiry the label is hidden and the bar reads `0/1`.
   - Capture: `factory/jobs/162-gift-meter-48h/home_gift_countdown_en_tr.png` (progress 7/10, 1 h into the window; EN `1d 23h` on the left, TR `1g 23sa` on the right).
8. [x] Config, schema and doc: g01 shows the schema 4 config loads with a 48 h window. Schema 3 is rejected, and so is `cycle_window_hours` when missing, 0, -1, 1.5 or "48". §4.2 has the dated owner amendment.
9. [x] Watched it fail before the fix: with the code files restored to origin/main, `sb_gift_meter_48h` exited 1 with `Parse Error: Too many arguments for "new()" call` (GiftMeterService had no clock/window yet).
10. [x] Must not change: milestone values and rewards, and the progress source (Win Streak SB only). sb_polish_002 (owner table), m38_win_streak and m39* all still pass.

TR copy note: the hour unit follows the existing TR `TIME_DHM` convention (`sa`), not the spec's example `s`, because in Turkish `s` reads as seconds.

## Validation
Godot 4.7.2 console, headless, run in the worktree after a one-off `--import`. Every suite below is LOCAL_PASS: exit 0, no unexpected SCRIPT ERROR or Parse Error, and the last line says PASS.

```
SB-GIFT-METER-48H evidence: PASS (7/7 cases, 0 fail)
SB-POLISH-002 gift meter evidence: PASS (11/11 cases, 0 fail)
M43 master C005R gift micro-progress evidence: PASS (8/8 cases, 0 fail)
M44 meta verify achievements + gift evidence: PASS (4/4 cases, 0 fail)
SB-VIDEO-006 gift meter video: PASS (6/6 cases, 0 fail)
M38 win streak evidence: PASS
M38 V02 strict validation: PASS
M39 Phase A evidence: PASS
M39 Phase B evidence: PASS
M39 Phase C evidence: PASS
M39 Phase D evidence: PASS
M39 Phase E evidence: PASS
M39 V02 atomicity/hardening evidence: PASS
M39 V02 capacity evidence: PASS
M39 V02 production integration evidence: PASS
M39 V03 full-surface evidence: PASS
M39 V03 integration evidence: PASS
M39 V04 integration evidence: PASS
M39 V04 tornado in-flight evidence: PASS
M39-C003 random-any booster: PASS
M40 save system evidence: PASS
M40 V02 safety evidence: PASS
M40 V03 canonical evidence: PASS
M40 V04 bootstrap evidence: PASS
M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)
M42 home evidence: PASS
m42_home_v06: 13/13 cases, 0 failures
M43-C005F-PHASE4 terminal bridge + Home micro feel: PASS (19/19 cases, 0 fail)
M51 localization readiness evidence: PASS (8/8 cases, 0 fail)
M49 responsive matrix evidence: PASS (8/8 cases, 0 fail)
```

- The 3 SCRIPT ERRORs in m43_c005f_phase4 are the injected FaultySpark errors the test expects; CI exempts this suite for them.
- `m42_home` failed once on its source guard ("Home has no calendar/clock logic of its own", which forbids `86400` in home_screen.gd). I moved the formatter to `UiText.time_left()`, then re-ran m42_home, sb_gift_meter_48h, m51_localization_readiness and m42_home_v06, all PASS (above).
- `git diff --cached --check` was clean.
- Import churn (.import, project.godot, generated .uid/.translation files) was restored or removed. `git status --porcelain` is empty.

## Log
### Round 1
- Implemented the 48 h window in GiftMeterService on the HeartService clock pattern, with config schema 4, a save migration (absent keys are treated as an older save) and a Home countdown label.
- Added the `sb_gift_meter_48h` suite (7 cases) and its CI guard, and watched it fail before the fix.
- Fixed the m42_home source-guard failure by moving the duration formatter into UiText.
- Ran 30 affected suites; all LOCAL_PASS. Saved the EN/TR Home capture.
- One commit `c1c12590`, not pushed. TASKS.md was not edited (orchestrator instruction).
