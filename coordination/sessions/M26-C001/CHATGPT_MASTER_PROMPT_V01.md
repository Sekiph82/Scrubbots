# M26-C001 V01 — MASTER IMPLEMENTATION PROMPT

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Milestone: `M26 — Auto Dispatch Scheduler`
Execution mode: **ONE CONTINUOUS FULL-MILESTONE PASS**
Tasks: `SB-M26-001..030`

Read first:
1. root `TASKS.md` M26 section;
2. `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`;
3. `coordination/sessions/M25-C001/CHATGPT_AUDIT_V03.md`;
4. `coordination/sessions/M26-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`;
5. all five M26 work-package files in this directory.

## Objective

Implement the complete production Auto Dispatch Scheduler on top of the already-accepted M23/M24/M25 systems.

The production chain is:

`front supply selection -> M24 placement -> M26 scheduler -> M25 claim/reserve -> exact route -> RouteValidator -> exact preclaimed dispatcher assignment -> ScrubbotAgent -> M20 authenticated clear -> M25 finalize_clear -> M24 quota/lifecycle update -> scheduler continues`

The scheduler does not replace any accepted authority.

## Non-negotiable authority boundaries

- M23 owns supply/FIFO/preview/transactional column consumption.
- M24 owns five batch slots, placement sequence, remaining/committed counters and EMPTY/ACTIVE/WAITING.
- M25 owns same-color arbitration, target claim ledger and ReservationState claim ownership.
- TargetSelector remains WHAT authority inside M25.
- ProductionTargetAccess + ProductionRoutingSystem + RouteValidator remain route/reachability truth.
- ScrubbotDispatcher remains the one ScrubbotAgent spawn/assignment authority.
- CompleteClearingLoop remains the only authenticated BoardState clear authority.
- M26 owns orchestration, pacing, fairness, wake/retry policy, and the exact mapping from an M25 claim to a dispatcher assignment.
- M27 remains untouched.

## HARD NO-GHOST invariant

Production order must be:

`M25 claim+reservation -> exact target route -> RouteValidator-clean -> exact preclaimed dispatcher assignment -> one agent`

Therefore:
- no target => no robot;
- no successful M25 claim/reservation => no robot;
- no exact valid route => no robot;
- route/spawn failure => M25 claim rollback, zero robot;
- never retarget a failed claim;
- never spawn an unclaimed or unreserved robot;
- one successful assignment transaction creates exactly one ScrubbotAgent.

## Critical M25 -> Dispatcher integration

Do **not** call the existing legacy `ScrubbotDispatcher.dispatch(color,start)` after M25 has already claimed a target. That method performs its own TargetSelector/reservation transaction and would create a second target authority.

Add a narrow production dispatcher entry for an **already claimed exact reservation**, e.g. `dispatch_preclaimed(...)` or equivalent.

It must:
- accept the exact M25 reservation owner_id, target, color, start origin and exact route/request;
- prove ReservationState owner<->target in both directions;
- prove target/color/board validity;
- RouteValidator-validate the exact supplied route/request against the dispatcher's bound board/routing access;
- never call TargetSelector;
- never create another reservation;
- never retarget;
- never release the M25 reservation on pre-spawn failure; M26 rolls the whole claim back through M25;
- create/register exactly one fresh ScrubbotAgent on success;
- use the SAME owner_id as the M25 ReservationState claim so M20 authenticated arrival sees one coherent owner/target tuple;
- reject owner ids already active in the dispatcher;
- preserve every legacy M19 dispatcher behavior/test;
- keep legacy dispatcher owner allocation collision-safe if the old path is ever used after preclaimed assignments.

Refactor shared spawn/assign internals if useful, but do not duplicate the full dispatcher pipeline.

## Exact slot origin

M26 is gameplay-domain logic and must not guess screen coordinates.

Inject a read-only slot-origin provider or equivalent seam:
`slot_index -> board-local Vector2`.

For the real Hazard Bot integration evidence, derive each origin from the actual laid-out SlotCell top-center anchor through the accepted `BoardPresentation.global_to_board_local()` transform, preserving:
- exact slot anchor;
- visible connector to canonical BOTTOM rail;
- Railroad V1;
- legal interior-turn routing from M22 V07.

No hardcoded fallback may pass closure evidence.

## Route transaction

For the slot returned by M25:
1. use that slot's coherent ProductionTargetAccess/origin;
2. consume the M25 selection's memoized exact winning route if present;
3. otherwise recompute a route only for the SAME claimed target;
4. RouteValidator-clean it;
5. dispatch only that exact claim/route;
6. on any pre-spawn failure call `M25.rollback_claim(claim_id)`;
7. no target reselection.

## Authenticated clear -> quota finalization

M24 remaining quota may decrement only after a successful M20 authenticated clear transaction.

Add only the minimal M20 notification seam needed by M26, preferably a post-commit signal emitted **after** the M20 transaction reaches CLEARED success, carrying immutable owner/target/color/agent identity.

Do not create a second clearing pipeline.

M26 maps that authenticated identity back to the exact live claim and calls `M25.finalize_clear(claim_id)` exactly once.

Duplicate/stale/wrong clear notifications must not double-decrement quota.

If needed, add an arrival-only M20 bind path for the new batch scheduler so production M26 does not require a fake historical direct-color `SlotSystem` merely to consume authenticated arrivals. Preserve the legacy M20 bind/activate API and all tests.

## Scheduler pacing

V1 deterministic pacing policy:
- scheduler may have multiple in-flight robots from one batch over time, but it may create at most **one new assignment per scheduler step/cadence event**;
- never burst an entire batch in one synchronous loop/frame;
- different slots may have concurrent in-flight assignments;
- per-batch committed capacity remains bounded by M24 `remaining - committed`;
- one scheduling step performs at most one accepted claim/spawn transaction.

Make cadence configurable/deterministic for tests. Do not make frame rate a gameplay authority.

## Fairness

Use deterministic round-robin across currently eligible **colors**, with candidate-color ordering derived from live occupied batch placement sequence rather than arbitrary Dictionary iteration.

For each chosen color:
- M25 alone chooses the oldest capacity-bearing same-color batch;
- M26 never overrides M25's same-color ordering;
- after a color receives/attempts a scheduling turn, advance the fairness cursor deterministically;
- a continuously busy color cannot starve another eligible color.

The BLUE 8 / BLUE 14 / BLUE 12 fixture must prove:
- distinct identities remain;
- oldest blue receives claims while it has dispatch capacity;
- when its capacity becomes zero due committed in-flight units, additional blue claims spill to the next batch;
- no duplicate target ownership.

## WAITING and wake

If M25 returns no claimable target:
- no spawn;
- no repeated busy-loop claim churn;
- relevant batch/color stays WAITING.

Wake/reconsider on authoritative events such as:
- successful transactional batch placement;
- authenticated BoardState clear completion that may open corridors;
- resume.

A minimal M24 post-placement notification signal is allowed if it emits only after successful placement commit and changes no authority.

## Pause / resume

Pause:
- blocks new scheduler dispatches;
- does not fabricate rollback or quota changes;
- preserves valid live claims/agents according to session pause rules.

Resume:
- resumes deterministic scheduling;
- never duplicates a live claim/spawn;
- wakes WAITING colors safely.

## Reset / teardown

Reset must be serialized and leave:
- zero M26 assignment records;
- zero live M25 claims created by the production scheduler;
- zero scheduler-owned reservations;
- zero dispatcher active assignments;
- zero ScrubbotAgent children/orphans;
- M24 committed counters returned consistently without decrementing remaining quota for cancelled work.

Required cleanup order must preserve accepted authorities. A safe default is:
1. stop new scheduling / enter reset guard;
2. preflight scheduler claim<->assignment coherence;
3. clean M25 live claims/committed work while their ReservationState pairs still exist;
4. then reset/cancel M20/dispatcher agents;
5. clear scheduler bookkeeping;
6. never recycle stale scheduler identities.

Do not call dispatcher reset first if doing so would destroy ReservationState truth M25 needs for rollback.

## Continuous execution

Execute all five work packages in order without asking for approval:
1. `M26_WORK_PACKAGE_01_CORE_AND_PRECLAIMED_DISPATCH.md`
2. `M26_WORK_PACKAGE_02_PACING_FAIRNESS_AND_CAPACITY.md`
3. `M26_WORK_PACKAGE_03_WAITING_CLEAR_AND_COMPLETION.md`
4. `M26_WORK_PACKAGE_04_PAUSE_RESET_AND_CONCURRENCY.md`
5. `M26_WORK_PACKAGE_05_SCALE_HAZARD_BOT_AND_CLOSURE.md`

Fix failures and continue. Do not stop between packages.

## Scope prohibitions

- Do not modify root `TASKS.md`.
- Do not implement M27 solvability/deadlock.
- Do not implement final M28 gameplay UI.
- Do not generate images or spend image credits.
- Do not revive direct player slot-click gameplay as production input.
- Do not create a second ReservationState, TargetSelector, routing or clearing authority.

## Final handoff

After all `SB-M26-001..030` and all required regressions pass:
1. push implementation commit(s);
2. create `coordination/sessions/M26-C001/CLAUDE_LOG_V01.md` as a separate final commit;
3. map every SB-M26 task to production code + direct evidence;
4. include start SHA, every implementation SHA, final implementation SHA, changed files, literal test commands, check/failure totals, Hazard Bot traces, 59x59 timing/allocation evidence;
5. confirm root TASKS modified = NO, M27 implemented = NO, image credits = 0;
6. return only `AWAITING_AUDIT`, final implementation SHA, direct log URL.
