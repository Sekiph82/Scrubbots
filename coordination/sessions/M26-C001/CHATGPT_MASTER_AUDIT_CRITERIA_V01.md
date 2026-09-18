# M26-C001 V01 — MASTER STRICT AUDIT CRITERIA

Milestone: `M26 — Auto Dispatch Scheduler`
Tasks: `SB-M26-001..030`
Verdict policy: all criteria are blocking.

## A. Governance

- Correct repo/branch: `Sekiph82/Scrubbots/main`.
- Safe sync; preserve owner-local work.
- Root `TASKS.md` unchanged by Claude.
- No M27 implementation.
- No final M28 UI implementation.
- Zero image-generation credits.
- Implementation commit(s) precede separate `CLAUDE_LOG_V01.md`.

## B. Authority topology

Audit must prove one coherent production chain:
- M23 supply;
- M24 five-slot batch state/counters;
- M25 claim/reservation arbitration;
- existing TargetSelector;
- existing ProductionTargetAccess/Routing/RouteValidator;
- ScrubbotDispatcher agent ownership;
- CompleteClearingLoop authenticated clear.

No duplicate target selector/reservation/clear authority may be introduced.

## C. Preclaimed dispatcher boundary

A new M26-compatible dispatcher path must consume an existing M25 reservation rather than select/reserve again.

Direct evidence must prove:
- exact owner->target and target->owner pair required;
- exact color/target/request required;
- owner already active rejected;
- wrong/foreign reservation rejected;
- invalid/mismatched route rejected;
- generic route-like object rejected;
- RouteValidator-clean exact route accepted;
- no TargetSelector call in this path;
- no second ReservationState reserve call;
- failure spawns zero agents;
- failure does not release the M25 reservation;
- success creates exactly one active ScrubbotAgent keyed by the exact M25 owner id;
- legacy dispatcher path remains green.

## D. Hard no-ghost transaction

For every scheduler attempt:
1. successful M25 claim/reservation;
2. exact route to claimed target;
3. RouteValidator success;
4. exact preclaimed dispatcher success;
5. only then a robot exists.

Required adversarial evidence:
- no target;
- claim failure;
- missing route;
- invalid route;
- route target mismatch;
- dispatcher/factory/assign failure;
- reset injected before spawn;
- stale claim;
- wrong slot origin.

Every case must show zero new agent and exact M25 rollback where applicable.

## E. No retarget

Once M25 returns claim C/target T:
- route work is only for T;
- spawn assignment is only for T;
- route/spawn failure rolls C back;
- no second TargetSelector call or alternate target may occur in the same attempt.

## F. Exact slot origin / Railroad

Real integration evidence must use the actual owning SlotCell top-center global anchor mapped via BoardPresentation to board-local units.

Route must preserve accepted M22:
- route point 0 exact mapped slot anchor;
- visible connector to BOTTOM rail;
- canonical Railroad V1 exterior travel;
- V07 legal ingress + orthogonal interior turns;
- no diagonal/corner-cut/teleport.

## G. Pacing / capacity

- At most one new accepted assignment per scheduler step/cadence event.
- Repeated steps may create multiple in-flight agents over time.
- Never one synchronous batch-count burst.
- M24 `committed <= remaining` always.
- No assignment created when dispatch capacity is zero.
- `BLUE 15` can autonomously produce exactly 15 authenticated clears, no 16th assignment.
- remaining decrements only after authenticated clear, never at claim/route/spawn.

## H. Fairness

Deterministic round-robin across eligible colors.
- no Dictionary-order authority;
- continuously busy color cannot starve another eligible color;
- same-color ordering entirely delegated to M25;
- BLUE 8/14/12 proves oldest-first and capacity spill when oldest dispatch capacity reaches zero.

## I. WAITING / wake

No target:
- batch becomes/remains WAITING;
- zero agent;
- no reservation churn/busy-loop on repeated idle processing.

Wake must be event-driven/deterministic after:
- successful placement;
- authenticated clear that changes reachability;
- resume.

Opening one blue target while several blue batches wait must produce at most one claim on the M25-selected oldest eligible blue batch for that scheduling turn.

## J. Authenticated clear bridge

M26 quota finalization must be triggered only by a successful M20 authenticated clear commit.

A minimal post-commit M20 signal is acceptable only if:
- emitted after successful transaction;
- exact owner/target/color/agent;
- one emission per committed clear;
- not emitted on rollback/failure/reset;
- legacy M20 behavior preserved.

M26 must map it to the exact live claim and call `M25.finalize_clear` once.
Duplicate/stale/wrong notification cannot decrement M24.

## K. Completion / slot freeing

After final authenticated clear:
- remaining 0;
- committed 0;
- slot EMPTY;
- other occupied slots do not shift;
- M23 supply queues unchanged by completion;
- scheduler can later schedule newly placed work in the freed slot.

## L. Pause / resume

Pause:
- no new claim/spawn;
- existing state preserved.

Resume:
- no duplicate claim/spawn;
- deterministic scheduling restarts;
- WAITING colors reconsidered.

## M. Reset / teardown

Required with multiple in-flight slots/colors:
- serialized reset;
- M25 claims/committed work cleaned before reservation truth is destroyed;
- dispatcher/M20 agents cancelled after claim cleanup;
- zero active dispatcher assignments;
- zero M25 live claims;
- zero orphan ScrubbotAgent nodes;
- zero scheduler ledger entries;
- no remaining quota decremented for cancelled work;
- unrelated reservations survive where they are not scheduler claims;
- repeated reset idempotent;
- stale callbacks after reset cannot mutate new session state.

## N. Rapid/concurrent pressure

Evidence with rapid supply placements and scheduler steps must prove:
- no double-spawn;
- no duplicate claim id;
- no duplicate target reservation;
- no over-commit;
- exact batch identity preserved;
- same-color and different-color concurrency safe.

## O. Hazard Bot end-to-end

Use real `m21_level_001_hazard_bot.json`.

Required integration smoke:
- real BoardState;
- real five-slot batch engine;
- real M25;
- real routing/access/RouteValidator;
- real dispatcher/ScrubbotAgent;
- real CompleteClearingLoop;
- real laid-out SlotCell anchors for starts;
- candidate supply from M23 or deterministic fixture consistent with level totals.

Prove:
- no ghost robots;
- no duplicate targets;
- exact reservation ownership;
- authenticated clears decrement exact batch quota;
- WAITING/wake works on newly opened corridors;
- at least one same-color multi-batch case;
- reset leaves zero agents/claims/reservations from scheduler.

## P. 59x59 / density sanity

Run deterministic high-density scheduler simulation/evidence on 59x59:
- no O(board) scan per frame/tick where avoidable;
- bounded scheduler bookkeeping by occupied slots + in-flight assignments;
- no unbounded hidden queue;
- report timing/allocation/peak live-assignment observations;
- exact quota/invariant checks.

This is a sanity/performance gate, not a benchmark target.

## Q. Regression floor

At minimum re-run:
- full `tests/run_tests.gd`;
- all M25 V01/V02/V03 evidence;
- all M24 V01/V02 evidence;
- M23 V01/V02/V03;
- M22 V07 routing + V06 real demo + connector evidence;
- representative M20 strict lifecycle/queue/reset;
- dispatcher M19 strict tests;
- ScrubbotAgent M18;
- M21 real-art/V10;
- `git diff --check`.

## R. Closure

PASS only if every `SB-M26-001..030` maps to production implementation and direct evidence, and the no-ghost invariant is proven on both adversarial seams and real Hazard Bot integration.
