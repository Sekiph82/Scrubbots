# M29 Work Package 02 — Runtime Cadence & Speed Authority
Owner rule: coordination/OWNER_GAMEPLAY_SPEED_RULE_V01.md

- Add production cadence driver for M26.step(), one step per cadence event.
- Successful M24 placement calls M26.notify_placed().
- Create explicit 1x/2x gameplay-speed authority; no global Engine.time_scale.
- Bottom-right M28 speed control becomes functional toggle.
- 2x halves scheduler cadence interval.
- 2x doubles current and future Scrubbot travel speed without changing route/target/accounting.
- After successful placement, read real M23.is_exhausted(); true => auto 2x.
- Rejected placement, visible-only exhaustion or five-slot-full state alone never trigger auto 2x.
- Reset/new level => 1x.
