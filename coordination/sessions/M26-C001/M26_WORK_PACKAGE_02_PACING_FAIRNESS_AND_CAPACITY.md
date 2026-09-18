# M26 Work Package 02 — Pacing, Fairness & Capacity
Tasks: SB-M26-011..017, SB-M26-020..021

Implement deterministic scheduling cadence and capacity policy.

Required:
- one accepted new assignment maximum per scheduler step/cadence event;
- cadence configurable and deterministic; no frame-rate authority;
- multiple in-flight agents may accumulate across steps;
- safe concurrency across different slots;
- deterministic round-robin across eligible colors;
- color ordering derived from live placement sequence, never Dictionary iteration;
- M25 alone decides same-color oldest batch;
- BLUE 8/14/12 direct evidence;
- capacity spill when oldest batch has zero dispatch capacity because committed work consumes its remaining capacity;
- BLUE 15 can autonomously reach exactly 15 authenticated clears;
- M24 committed never exceeds remaining;
- remaining never decremented on claim/route/spawn.
