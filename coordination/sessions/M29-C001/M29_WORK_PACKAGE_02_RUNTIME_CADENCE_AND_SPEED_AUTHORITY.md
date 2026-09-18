# M29 Work Package 02 — Runtime Cadence & Speed Authority
Owner rule: coordination/OWNER_GAMEPLAY_SPEED_RULE_V01.md

- Add production cadence driver for M26.step(), one step per cadence event.
- Successful M24 placement calls M26.notify_placed().
- Create explicit 1x/2x gameplay-speed authority; no global Engine.time_scale.
- Keep a direct 1x/2x toggle seam for M29 temporal/headless verification, but do not treat it as the final free production entitlement policy.
- Production manual 2x is economy-gated by `OWNER_ECONOMY_REWARDS_V01.md`; M39 owns SB purchase/level/timed entitlement integration.
- 2x halves scheduler cadence interval.
- 2x doubles current and future Scrubbot travel speed without changing route/target/accounting.
- After successful placement, read real M23.is_exhausted(); true => auto 2x.
- Rejected placement, visible-only exhaustion or five-slot-full state alone never trigger auto 2x.
- Reset/new level => 1x.
- Automatic M23-exhausted -> 2x remains free and bypasses paid entitlement.
- Timed entitlement countdown is wall-clock/application time, never gameplay delta/time_scale.
