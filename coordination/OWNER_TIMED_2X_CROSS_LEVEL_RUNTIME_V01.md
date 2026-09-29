# OWNER TIMED 2X CROSS-LEVEL RUNTIME RULING V01

Date: 2026-09-29
Authority: OWNER
Status: OWNER-LOCKED / CANONICAL

## Observed owner-playtest defect

Owner purchased a timed 2x entitlement on Level 2. After completing Level 2 and continuing to Level 3:

- the timed countdown continued correctly;
- the live gameplay speed started/reran at 1x instead of 2x.

This is not accepted behavior.

## Canonical ruling

A timed 2x purchase is a **cross-level real-world-time 2x gameplay entitlement**, not a one-level speed activation with a decorative timer.

While timed remaining time is greater than zero:

1. entering a new progression level must initialize live gameplay at 2x;
2. the countdown continues across Results, Home, background, relaunch and level transitions according to the existing wall-clock rules;
3. a same-attempt/new-attempt reset must not silently strand an active timed entitlement at 1x;
4. manual 1x <-> 2x switching remains free while the timed entitlement is active;
5. when the timed entitlement expires, paid/manual timed 2x must no longer keep gameplay at 2x;
6. expiry handling must not disable or interfere with the separate free M23 supply-exhausted automatic 2x authority.

## Non-effects

This ruling does not change:

- current-level 2x price or scope;
- 15m / 30m / 60m prices or durations;
- timed wall-clock anti-rollback/high-water rules;
- free M23 automatic endgame 2x;
- booster/Heart/economy rules;
- Gameplay V02 visuals except live speed state correctness.

## Root-cause note

Current code keeps the timed entitlement in `SpeedEntitlementService`, but a newly built `GameplaySpeedAuthority` starts at 1x. HUD refresh displays the surviving timed countdown without reapplying the live 2x factor. That split is the defect to remediate.
