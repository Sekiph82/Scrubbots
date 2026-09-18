# M26 Work Package 01 — Scheduler Core & Preclaimed Dispatch
Tasks: SB-M26-001..010

Implement the scheduler domain object and the exact M25->dispatcher bridge.

Required:
- production AutoDispatchScheduler independent of UI rendering;
- bind/coherence rules for BoardState, M24, M25, ReservationState, routing/access, dispatcher and M20;
- deterministic slot-origin provider contract;
- minimal M24 successful-placement notification if needed;
- exact preclaimed dispatcher API consuming M25 owner/target reservation;
- no selector/reserve call in the preclaimed dispatcher path;
- exact RouteRequest + RouteValidator validation;
- exact owner/color/target/agent active assignment;
- one successful transaction => exactly one agent;
- every pre-spawn failure => zero agent and scheduler invokes M25.rollback_claim;
- no retarget;
- exact real SlotCell anchor integration evidence preserving Railroad V1/V07.

Do not implement fairness/pacing policy beyond the one-step primitive yet. Do not change M25 arbitration.
