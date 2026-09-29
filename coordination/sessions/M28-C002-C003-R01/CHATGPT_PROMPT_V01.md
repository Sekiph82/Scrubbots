# M28-C002-C003-R01 — TIMED 2X CROSS-LEVEL RUNTIME REMEDIATION

Status: READY FOR CLAUDE
Date: 2026-09-29
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Trigger

Owner playtest found a real blocking defect:

- timed 2x purchased on Level 2;
- Level 2 completes;
- Level 3 still shows the timed countdown;
- live gameplay runs at 1x.

Read first:

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/OWNER_TIMED_2X_CROSS_LEVEL_RUNTIME_V01.md`
4. `coordination/OWNER_ECONOMY_REWARDS_V01.md`
5. `coordination/OWNER_TIMED_2X_CLOCK_ROLLBACK_V01.md`
6. `coordination/sessions/M28-C002-C003/CHATGPT_AUDIT_V01.md`
7. `coordination/sessions/M28-C002-C003/OWNER_GAMEPLAY_V02_FINAL_GATE_V01.md`
8. current speed/economy/runtime code and relevant M39/M43/M52/M55 tests.

Do not edit root `TASKS.md`.

## Root cause to verify, not merely trust

Current architecture appears to:

- persist timed entitlement correctly in `SpeedEntitlementService`;
- create a fresh `GameplaySpeedAuthority` at 1x for each new gameplay host;
- refresh HUD countdown from entitlement truth without synchronizing the new live speed factor.

Confirm the exact production path before changing code.

## Required behavior

### A. Cross-level timed 2x

Reproduce through the real app route:

1. launch Level 2;
2. purchase timed 2x;
3. prove live speed is 2x;
4. complete Level 2 through authoritative WON;
5. Results -> Continue -> Level 3;
6. while timed remaining > 0, Level 3 must begin with live gameplay 2x;
7. countdown must continue from the same absolute entitlement, with no new charge and no extension.

Do not fake this by directly toggling the speed authority in the test.

### B. Same entitlement, no duplicate charge

Across the Level 2 -> Level 3 transition:

- wallet must not change because of the transition;
- `timed_expiry` must not change;
- `clock_high_water` may only advance normally;
- no second purchase transaction may occur;
- no new entitlement object may be created outside the canonical AppState economy.

### C. Timed expiry must stop paid/manual timed 2x

Add authoritative runtime synchronization so that when timed remaining reaches zero:

- gameplay must not continue indefinitely at paid/manual 2x solely because the live speed factor was previously 2x;
- it must fall back to 1x when there is no other valid manual entitlement;
- this synchronization should occur promptly from existing runtime/HUD/service refresh infrastructure, not via gameplay delta as the entitlement clock.

Important: preserve M55 anti-rollback. Never compute expiry from gameplay time.

### D. Preserve free M23 automatic endgame 2x

Timed expiry must **not** force 1x if the authoritative free M23 supply-exhausted auto-2x condition currently requires 2x.

You must identify the real auto-2x authority and test the overlap case:

- timed entitlement expires;
- free auto-2x is active;
- live speed remains 2x for the free auto reason;
- no SB/entitlement resurrection occurs.

Do not infer free-auto state from visual slot occupancy or UI labels.

### E. Retry / new-attempt continuity

Prove an active timed entitlement is not stranded at 1x by a legitimate retry/new-attempt reset. After the reset, if timed entitlement is still active, live speed must again be 2x under the new owner ruling.

Do not change current-level entitlement semantics unless required for correctness. Keep its successful-completion clearing rule intact.

### F. Manual switching

While timed entitlement is active:

- 2x -> 1x remains allowed and free;
- 1x -> 2x remains allowed and free;
- no recharge occurs.

Do not remove this owner-approved behavior.

### G. HUD consistency

The visible 2x control, timed countdown and actual runtime factor must agree.

Forbidden state while timed remaining > 0 at a new level launch:
- UI says timed 2x active;
- runtime factor is 1x.

Add direct assertions tying:
- `timed_seconds_remaining()`,
- runtime `is_2x()/factor()`,
- Gameplay V02 speed presentation

to the same scenario.

## Preferred implementation shape

Keep the architectural split:

- `SpeedEntitlementService` owns permission/expiry;
- `GameplaySpeedAuthority` owns live temporal factor.

Add one narrow production synchronization seam at attempt/host start and expiry refresh. Do not merge economy entitlement state into the gameplay speed value object.

Avoid:
- Engine.time_scale;
- duplicate timers when an existing 1s HUD/runtime refresh can safely own the check;
- a second persistence authority;
- re-buying timed products;
- changing product config.

## Tests

Add a focused regression suite that covers at minimum:

1. Level 2 timed purchase -> 2x active;
2. authoritative WON -> Level 3 continue;
3. Level 3 starts 2x while timer still active;
4. same expiry, no extra SB spend;
5. countdown continues, not reset to full;
6. timed expiry -> 1x when no other 2x authority applies;
7. timed expiry during free M23 auto-2x -> remains 2x for free-auto authority;
8. active timed entitlement + Retry -> new attempt 2x;
9. manual 1x/2x switching while active costs 0;
10. current-level entitlement still clears only on successful completion of its own level;
11. save/relaunch/background anti-rollback regressions remain green;
12. rapid level transitions / duplicate Continue cannot double-apply or double-charge.

Use a deterministic injected clock for focused tests.

## Regression gate

Run at minimum:

- new focused remediation suite;
- M28-C002-C003 final gate suite;
- M29 speed/input;
- M30 completion/retry;
- M39 economy/integration;
- M40 save;
- M43-C003 acquisition;
- M52 2x / supply exhausted;
- M55 timed 2x anti-rollback;
- root suite;
- `git diff --check`.

For the pre-existing `m39_v04_integration` real-clock snapshot flake:
- do not hide it;
- if untouched, report it separately;
- do not broaden this remediation into unrelated M39 cleanup unless the fix directly requires it.

## Evidence

Create:

- `coordination/sessions/M28-C002-C003-R01/CLAUDE_LOG_V01.md`
- `coordination/sessions/M28-C002-C003-R01/TIMED_2X_CROSS_LEVEL_MATRIX_V01.md`

Also create fresh evidence proving:

- Level 2 timed 2x active;
- Results/Continue;
- Level 3 timed countdown still active AND runtime visibly 2x;
- expiry returns to correct speed state.

A short real runtime video is preferred if existing Movie Maker tooling can reuse the previous capture path without new dependencies.

## Scope locks

Do not:

- edit root `TASKS.md`;
- redesign Gameplay V02;
- alter 2x prices/durations;
- alter Heart/booster rules;
- change M23 automatic 2x semantics;
- use Engine.time_scale;
- create a second economy/save authority;
- fix unrelated issues.

## Finish

Commit and push to `main`.

Return:

1. final commit SHA;
2. exact root cause;
3. production code changes;
4. focused/regression results;
5. log/matrix/evidence links;
6. whether owner must replay Level 2 -> Level 3 after audit.

Finish exactly:

`AWAITING_CHATGPT_AUDIT / M28-C002-C003-R01 TIMED 2X CROSS-LEVEL REMEDIATION`
