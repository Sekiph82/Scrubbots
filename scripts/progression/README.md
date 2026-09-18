# Progression Runtime Module

Economy V1 robot progression contract:

- Scrubby starts unlocked.
- `Bot Parts` are robot-unlock-only progression.
- Every post-Scrubby robot costs 250 Bot Parts.
- Overflow is preserved after unlock.
- Target cadence is roughly one robot every 150 progression levels for an average engaged player; this is a tuning target, not a level gate.
- Bot Parts may not be bought with Scrub Bucks or real money in V1.
- Robot passive perks may affect meta/economy convenience only and may never change BoardState legality, TargetSelector ordering, route legality, reservation uniqueness, batch conservation or solver truth.

Planned M39 module:

- `robot_unlock_service.gd`

Canonical source: `coordination/OWNER_ECONOMY_REWARDS_V01.md`.
