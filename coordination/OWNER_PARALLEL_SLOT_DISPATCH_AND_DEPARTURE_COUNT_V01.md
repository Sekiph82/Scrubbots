# OWNER PARALLEL SLOT DISPATCH AND DEPARTURE COUNT V01

Date: 2026-09-26
Authority: OWNER
Status: OWNER-LOCKED
Repository: Sekiph82/Scrubbots
Scope: production gameplay runtime dispatch, same-color batches, slot counters, 2x interaction

## 1. Each occupied slot is an independent dispatch lane

The five normal execution slots are independent active work lanes. A temporary sixth slot from +1 Slot follows the same rule.

A same-color batch must not be blocked merely because an older same-color batch still contains waiting robots.

This supersedes the previous same-color arbitration rule that drained the oldest placement-sequence batch to zero dispatch capacity before allowing the next same-color batch to dispatch.

## 2. Parallel dispatch wave

At each production dispatch cadence, the runtime may create at most ONE new Scrubby assignment per eligible occupied slot.

Therefore:
- baseline maximum new assignments per cadence wave = 5;
- with the temporary +1 Slot booster = 6;
- one slot can never create two new assignments in the same wave;
- different slots may create assignments in the same frame/wave.

Deterministic lane ordering must be defined and tested. Prefer ascending placement sequence, with physical slot index as stable tie-break.

"Parallel" means the player can visibly see multiple Scrubbys from multiple occupied slots travelling/cleaning at the same time. It does not authorize threads, duplicate targets or unsafe simultaneous state mutation.

## 3. Five BLUE x30 acceptance example

When five independent BLUE batches of 30 are occupying the five slots and at least five legal BLUE targets exist:

- the next dispatch wave must be able to spawn one Scrubby from EACH of those five batches;
- five live assignments/claims/agents may coexist;
- each assignment must own a unique reserved target;
- each of the five batch displays must move from 30 to 29 when its own Scrubby successfully commits/leaves the slot;
- the board does not need to wait for batch #1 to finish before batches #2..#5 begin.

This exact fixture is a required automated and owner-visible acceptance test.

## 4. Per-slot target/claim authority

TargetSelector, ReservationState, ProductionTargetAccess, routing and authenticated clearing remain authoritative.

The claim layer must support an exact slot-specific claim seam so a scheduler wave can request work for each eligible slot independently.

For same-color slots:
- each slot uses its own route origin;
- each accepted claim gets a unique target/reservation;
- one slot failing to find a target must not automatically block a sibling same-color slot that has a legal target;
- waiting state is therefore per-slot, not globally per-color.

No target => no robot.
No reservation => no robot.
No valid route => no robot.

## 5. Counter timing

Authoritative safety accounting remains:
- `remaining_to_clear` decreases only after authenticated successful clear;
- `committed` increases when a work identity is successfully claimed/committed and a real dispatch is successfully established;
- rollback restores committed capacity.

Player-facing batch count is:
`waiting_to_launch = remaining_to_clear - committed`.

The displayed number must update immediately after successful dispatch establishment, before that Scrubby clears its target pixel.

If dispatch is rolled back before a real agent exists, the player-visible count must not remain decremented.

## 6. Cadence and 2x

Normal cadence remains the current 1x base cadence unless profiling proves a separate owner-approved tuning change is needed.

At 2x:
- cadence interval is half;
- agent travel is 2x;
- multiple in-flight agents remain supported.

The 2x button must NEVER silently do nothing.

Current Economy V1 rule remains:
- if manual 2x entitlement already exists, pressing the control toggles 1x/2x;
- if no entitlement exists, pressing 2x opens the canonical 2x acquisition flow rather than silently returning;
- successful purchase activates 2x immediately;
- cancel/failure/insufficient SB changes no speed and spends nothing;
- free automatic supply-exhausted 2x remains entitlement-independent.

A functional production popup may be implemented now with live Godot UI; final visual polish/master remains under the later Player Experience program.

## 7. Performance / stutter

The Level 2 owner-observed micro-freezes are a release blocker for this remediation.

Do not guess the cause. Instrument the main-thread runtime and identify the dominant spike(s), including at minimum:
- scheduler wave;
- target selection / routing;
- agent drive/arrival;
- board/renderer refresh;
- completion/deadlock proof;
- UI snapshot sync.

Any optimization must preserve authoritative gameplay truth and solver/runtime consistency.

## 8. Solver / deadlock consistency

Because dispatch policy changes from color-serialized to slot-parallel, M27 proof/runtime equivalence must be reviewed.

The implementation must either:
1. update ProofKernel/solver semantics to model the new legal policy faithfully; or
2. prove and document a conservative serial linearization that is valid for every parallel wave and cannot admit a runtime-deadlocked level.

Do not leave stale comments/tests claiming exact runtime equivalence if that equivalence no longer holds.

All current production Levels 1–10 must be re-proven/replayed and production-runtime tested after the change.

## 9. Protected rules

Unchanged:
- M23 front-only FIFO player selection;
- rightmost-empty slot placement;
- 5 baseline / max 6 temporary slots;
- exact per-color conservation;
- immutable batch identity;
- TargetSelector target order;
- ReservationState uniqueness;
- Railroad/routing legality;
- no-ghost transaction law;
- authenticated clear authority;
- exact-once terminal/economy behavior.

## 10. Precedence

This decision supersedes only conflicting wording in older M25/M26 documents/tests regarding:
- oldest same-color batch monopolizing dispatch capacity;
- one accepted assignment globally per cadence;
- waiting tracked globally by color.

All other accepted invariants remain in force.
