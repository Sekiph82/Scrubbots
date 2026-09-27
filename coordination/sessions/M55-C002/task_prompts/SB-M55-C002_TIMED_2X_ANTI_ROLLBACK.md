# SB-M55-C002 — TIMED 2X ANTI-ROLLBACK REMEDIATION

Status: READY FOR CLAUDE
Date: 2026-09-28
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/OWNER_TIMED_2X_CLOCK_ROLLBACK_V01.md`
4. `coordination/sessions/M55-C001/CHATGPT_AUDIT_V01.md`
5. `coordination/sessions/M55-C001/CLAUDE_LOG_V01.md`
6. `scripts/economy/speed_entitlement_service.gd`
7. M39/M40 save + speed entitlement tests relevant to this subsystem

Do NOT edit root `TASKS.md`.

## Owner-locked ruling

Timed 2x is **fail-closed against backward device-clock movement**.

Without a new paid purchase:
- remaining timed-2x seconds must never increase;
- expired timed 2x must never revive;
- backwards clock movement must never turn an expired entitlement valid again;
- the anti-rollback state must survive save/relaunch/background/foreground.

## Required implementation

Implement the smallest production-safe anti-rollback authority inside the existing timed-2x/save architecture.

Preferred contract:

- maintain a persisted highest-seen/effective wall-clock value, or an equivalent mechanism;
- compute timed entitlement truth/remaining time against a non-decreasing effective time;
- normal forward wall-clock movement still expires entitlement naturally;
- backwards movement freezes/clamps effective time rather than granting extra entitlement;
- a new explicit timed purchase may extend remaining time according to canonical purchase rules;
- current-level 2x remains independent;
- free M23 endgame auto-2x remains independent.

## Backward-compatible migration

Existing saves contain `entitled_level` and `timed_expiry` but no anti-rollback field.

Requirements:
- legacy saves must still import;
- do not wipe a legitimately active legacy timed entitlement simply because the new field is absent;
- initialize the anti-rollback guard at first upgraded import/load from observable current state;
- after that upgraded boundary, save the guard and enforce monotonic remaining time across relaunch;
- do not invent historical clock data that the legacy save never recorded.

If a save already contains the new guard field, validate it strictly and fail closed on malformed values.

## Canonical products unchanged

Do not change:
- current-level 2x: 200 SB;
- 15 minutes: 300 SB;
- 30 minutes: 500 SB;
- 60 minutes: 750 SB;
- free automatic M23-exhausted 2x.

Do not change Heart rules.

## Tests

Add focused tests proving at minimum:

1. Active timed 2x + backward clock jump:
   - remaining seconds do not increase.
2. Expired timed 2x + backward jump:
   - remains 0;
   - `is_manual_2x_entitled()` remains false.
3. Forward time after rollback:
   - countdown resumes only when effective time advances beyond the high-water mark.
4. Save/relaunch:
   - anti-rollback state persists;
   - rollback after relaunch cannot revive or extend.
5. Legacy snapshot without new field:
   - imports successfully;
   - legitimate active entitlement is preserved at migration boundary;
   - subsequent rollback is protected.
6. New-field malformed/fractional/negative data:
   - import fails closed.
7. Explicit new timed purchase:
   - may extend from the canonical effective base and charges exactly once.
8. Current-level 2x and free auto-2x:
   - unchanged.
9. Product table:
   - remains 900/300, 1800/500, 3600/750.
10. Existing M39/M40/M55 tests remain green.

Add a sensitivity check proving the new rollback regression fails if the clamp/high-water logic is removed.

## Scope locks

Do not touch:
- Levels 1–10 content;
- supply plans / owner click sequences;
- difficulty systems;
- M43+ surfaces;
- Heart timing/pricing;
- unrelated economy behavior.

## Required evidence

Create:

- `coordination/sessions/M55-C002/TIMED_2X_ANTI_ROLLBACK_MATRIX_V01.md`
- `coordination/sessions/M55-C002/CLAUDE_LOG_V01.md`

Record exact before/after rollback values, save/relaunch evidence, migration cases, sensitivity result and full regression results.

## Regression

Run at minimum:
- new C002 focused suite;
- `tests/m39b_hearts_speed.gd`;
- relevant M39 speed/economy suites;
- M40 save suites;
- `tests/m55_core_chaos.gd`;
- `tests/m55_long_session.gd`;
- `tests/m55_heart_900_authority.gd`;
- `tests/m55_economy_release_regression.gd`;
- root `tests/run_tests.gd`;
- `git diff --check`.

Reject false-green output via exit code, `FAIL:`, `SCRIPT ERROR` and new unexplained runtime `ERROR:`.

## Handoff

Commit and push.

Finish with:

`AWAITING_CHATGPT_AUDIT / M55-C002 TIMED 2X ANTI-ROLLBACK`

Do not edit TASKS.md.
