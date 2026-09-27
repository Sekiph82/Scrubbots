# M55-C002 — TIMED 2X ANTI-ROLLBACK MATRIX V01

Status: implementer evidence, AWAITING_CHATGPT_AUDIT (no verdict claimed)
Date: 2026-09-28
Owner authority: `coordination/OWNER_TIMED_2X_CLOCK_ROLLBACK_V01.md` (timed 2x fails closed on backward device-clock movement)
Build: Godot 4.7.2.stable.official.ed1daf0bf, headless
Focused suite: `tests/m55_c002_timed_2x_anti_rollback.gd` — exit 0, 53 ok, 0 FAIL, 0 SCRIPT ERROR, case ledger 10/10

## Mechanism

`SpeedEntitlementService` gains a persisted, non-decreasing high-water clock `clock_high_water`:

- Every timed-2x read (`timed_seconds_remaining`, `is_manual_2x_entitled`, `purchase_timed`, `snapshot`) observes the wall clock into the high-water mark.
- Timed truth is computed against **effective time = max(wall clock, high-water)**:
  - a backward jump freezes the countdown;
  - normal forward movement expires the entitlement as before.
- The only way to add time is an explicit purchase. It extends from `max(effective time, expiry)`.
- **Snapshot:** `{entitled_level, timed_expiry, clock_high_water}`.
- **Import:**
  - a guard that is present must be an exact non-negative integer, otherwise the whole import fails closed;
  - a guard that is absent (legacy save) is initialized at the import boundary from the observed current clock.

## Owner invariants → evidence

| # | Requirement | Evidence (exact values, clock T = 50,000,000) | Result |
|---|---|---|---|
| 1 | Active entitlement + backward jump: remaining never increases | 30-minute 2x bought at T; remaining at T+600 = **1200**. After rollbacks of 1 s / 60 s / 5000 s / 1 day / 1 year → **1200, 1200, 1200, 1200, 1200**, still entitled; high-water = T+600 | PASS |
| 2 | Expired entitlement never revives | 15-minute 2x expired at T+901. Rolled back to T−1, T+451, T, T−4099, T−999099 → remaining 0 and `is_manual_2x_entitled` false every time (**0 revivals**) | PASS |
| 3 | Forward time after rollback resumes only beyond the high-water mark | Rolled back to T−3000, then climbing to T+599 → **1200** frozen at every step. At T+700 → **1100**; at T+1800 → 0 and not entitled | PASS |
| 4 | Survives save/relaunch | Bought via `ProductionActionFacade`, flushed at T+600. The save file holds `economy.speed.clock_high_water = T+600`. Relaunch at T−4400 → **1200** (pre-fix **6200**). Expires at T+1801. Relaunch at T−100,000 → still 0; the relaunched guard equals the persisted T+1801 | PASS |
| 4b | Survives background/foreground | Production host (Level 2), bought in gameplay, 600 s left at T+300. `APPLICATION_PAUSED` + flush, then a 7200 s backward jump, then `APPLICATION_RESUMED` → **600** (pre-fix **7800**). After expiry, a rollback in gameplay cannot re-enable manual 2x | PASS |
| 5 | Legacy save / snapshot without the guard | **Snapshot:** a legacy snapshot imports, keeping the active 1000 s, with the guard initialized to T at the boundary. A −20,000 s rollback still leaves **1000**; +400 s → 600; the next snapshot writes the guard. A legacy current-level entitlement is preserved. **Real save file with the field stripped:** loads from **primary**, app not blocked, active 3600 s entitlement kept (2600 at T+1000). A −50,000 s rollback still leaves **2600**; the first upgraded save writes `clock_high_water = T+1000` | PASS |
| 6 | Malformed present guard fails closed | 10/10 rejected with the service state untouched: −1, 1.5, −0.5, `"100"`, null, true, array, dict, NaN, INF. An integral float (JSON number) is accepted. `SaveService.validate_candidate` rejects −5 and 12.5 as `economy_import`; a relaunch with a malformed primary guard falls back to the backup, and the value is never adopted | PASS |
| 7 | A new purchase may extend, charged exactly once | 1200 left, clock rolled back 4600 s below the high-water mark, buy 15 minutes → exactly **−300 SB once**; remaining **2100** (expiry T+2700, extended from max(effective, expiry), not from the rolled-back clock). After expiry, buy 60 minutes → 3600, −750 SB once. Insufficient SB → no charge, no time | PASS |
| 8 | Current-level 2x and free auto-2x unchanged | Current level = 200 SB, entitled for that level only, unaffected by a −999,999 s rollback, survives a failed attempt, cleared on success. **Production Level 2 with the clock rolled back one day and no entitlement:** supply exhausted → automatic 2x on, 0 SB charged | PASS |
| 9 | Product table unchanged | 900 / 300, 1800 / 500, 3600 / 750; current level 200; Heart regen 900 s | PASS |
| 10 | Existing suites green | See the regression table in `CLAUDE_LOG_V01.md` | PASS |

## Sensitivity

`_effective_now()` was temporarily bypassed to return the raw wall clock (the pre-fix behaviour). The focused suite then **exits 1 with FAIL (10)**. It reproduces the pre-fix values exactly:

| Case | Pre-fix value |
|---|---|
| remaining under rollbacks of 1 s / 60 s / 5000 s / 1 day / 1 year | 1201 / 1260 / 6200 / 87,600 / 31,537,200 |
| expired entitlement | revived 5 times |
| relaunch after 5000 s rollback | 6200 |
| foreground after 7200 s rollback | 7800 |
| legacy entitlement after rollback | extended |
| rolled-back purchase | extends from the rolled-back clock |

With the clamp restored it exits 0 (PASS). The file was restored byte-for-byte from a copy.

`tests/m55_core_chaos.gd` SB-M55-015 is also updated. Its former "OBSERVED: 5000 s revived" print is now an assertion: after a 5000 s rollback an expired timed 2x stays expired.

## Scope locks

No change to:
- 2x prices or durations;
- current-level 2x;
- the free M23 auto-2x;
- Heart rules;
- Levels 1–10 content, supply plans, owner click sequences or difficulty systems;
- M43+ surfaces.

The only production file changed is `scripts/economy/speed_entitlement_service.gd`.
