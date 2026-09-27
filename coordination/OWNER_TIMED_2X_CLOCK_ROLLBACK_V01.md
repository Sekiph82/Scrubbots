# OWNER TIMED 2X CLOCK-ROLLBACK RULING V01

Date: 2026-09-28
Authority: OWNER
Status: OWNER-LOCKED / CANONICAL

## Ruling

**Option A is canonical: timed 2x must fail closed on backward device-clock movement.**

A timed 2x entitlement must **never regain remaining time, revive after expiry, or become newly valid merely because the device/system wall clock moved backwards**.

## Required invariant

For an existing timed 2x entitlement, absent a new paid purchase:

- remaining time is monotonically non-increasing;
- once expired, it stays expired;
- a backwards wall-clock jump cannot increase remaining seconds;
- a backwards wall-clock jump cannot make `is_manual_2x_entitled()` become true again after expiry;
- save/relaunch/background/foreground must preserve this anti-rollback state.

A new explicit timed-2x purchase may extend entitlement exactly according to the canonical product rules. That intentional purchase is the only authorized way for timed remaining time to increase.

## Implementation direction

Use a persisted anti-rollback / high-water wall-clock authority or an equivalent fail-closed mechanism.

The implementation must:
- preserve the canonical 15m/300 SB, 30m/500 SB, 60m/750 SB products;
- preserve current-level 2x behavior;
- preserve free automatic M23 supply-exhausted 2x behavior;
- preserve wall-clock/background/offline expiry semantics when the clock moves normally;
- avoid invalidating legitimate legacy active timed entitlements merely because older saves do not yet contain the new anti-rollback field;
- make the new anti-rollback state backward-compatible on import and persistent on future saves.

## Migration boundary

For a legacy save that predates the anti-rollback field, preserve the entitlement state that can be represented by the existing `timed_expiry` and initialize the new guard at the first upgraded load/import. From that point forward, backwards wall-clock movement must never increase the effective remaining time.

Do not retroactively guess unobservable clock history from before the upgrade.

## Non-effects

This ruling does not change:
- Heart regen: 900 s / 15 min;
- Heart prices;
- current-level 2x = 200 SB;
- timed 2x product prices/durations;
- free automatic endgame 2x;
- First 10 content;
- difficulty/solution automation.

## Governance consequence

M55-C001 technical rows SB-M55-001..017 remain accepted.

Open **M55-C002 — Timed 2x Anti-Rollback Remediation** to implement and regress this owner-locked policy.

M55 core closes only after independent ChatGPT audit of C002.
