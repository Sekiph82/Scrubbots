# M27-C001 V01 — MASTER IMPLEMENTATION PROMPT

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Milestone: `M27 — Solvability / Deadlock Engine`
Execution mode: **ONE CONTINUOUS FULL-MILESTONE PASS**
Tasks: `SB-M27-001..034`

Read first:
1. root `TASKS.md` M27 section;
2. `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`;
3. M23/M24/M25/M26 final audit records;
4. `coordination/sessions/M27-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`;
5. all five M27 work-package files in this directory.

## Objective

Build a deterministic proof/search layer that answers:

1. **Generation-time solvability:** given a level and a concrete M23 supply layout, does at least one legal sequence of player front-batch selections lead to full completion under the accepted M24/M25/routing semantics?
2. **Runtime classification:** is the current state COMPLETED, still PROGRESSABLE, temporarily WAITING/STALLED, provably DEADLOCKED, or UNKNOWN because configured proof bounds were exhausted?

M27 is a proof engine, not a second gameplay engine and not player UI.

## Core architectural rule

Do not invent simplified reachability, slot, claim or supply rules.

The proof transition kernel must consume/reuse the accepted gameplay-domain semantics:
- M23 FIFO/front-only supply ordering;
- exactly five M24 slots with rightmost-empty placement;
- M24 remaining/committed/WAITING lifecycle;
- M25 oldest-placement-first same-color arbitration;
- TargetSelector bottom-most then left-most policy;
- ProductionTargetAccess + ProductionRoutingSystem + RouteValidator reachability;
- Railroad V1 + M22 V07 interior-turn rules;
- ACTIVE -> CLEARED board evolution.

A solver state may be reconstructed/cloned into isolated gameplay-domain objects for search, but it must not substitute a contradictory hand-written notion of reachability or target ownership.

## Proof strategy: legal serial authenticated progress

For search/proof purposes, use a deterministic **serial clear kernel**:
- after a legal player batch placement, repeatedly perform one legal M25-style claim at a time;
- validate real production targetability/routing for the exact slot origin;
- apply one authenticated-equivalent clear transition synchronously to the isolated proof state;
- update M24 quota/work state exactly as successful M25 finalization would;
- continue until the proof state reaches quiescence.

This is a valid legal execution schedule and therefore sufficient to prove solvability: if the serial schedule under a sequence of legal player choices completes the board, the layout is solvable.

Do NOT use ScrubbotAgent animation timing as a proof requirement.
Do NOT claim all possible schedules are solvable merely because one is.

## Player-choice search

At a quiescent proof state:
- legal player actions are ONLY selectable front/top batches from configured M23 columns;
- Row 2/Row 3/hidden batches may be known internally to the generator/solver but are never legal early actions;
- placing a selected front batch uses M24's automatic rightmost-empty rule;
- if all five slots are full, that selection is not a legal state transition and the supply front must remain unchanged;
- search must branch across legal selectable columns rather than assume one greedy order.

Success requires:
- every required logical target cleared;
- every required batch quota consumed consistently;
- no live committed work;
- supply exhausted or only zero-required state according to canonical conservation rules;
- all five slots empty.

## Solver result contract

Define stable result classes/statuses, at minimum:
- `SOLVED`
- `DEADLOCK`
- `WAITING` / `STALLED`
- `COMPLETED` for already-complete runtime state if separated from SOLVED
- `UNKNOWN_BOUND` when state/time/depth policy prevents proof.

Never label `UNKNOWN_BOUND` as DEADLOCK.

Generation acceptance:
- only `SOLVED` is accepted for production generated supply;
- `DEADLOCK`, `UNKNOWN_BOUND`, malformed/error outcomes are rejected.

## DEADLOCK definition

A runtime state is DEADLOCK only when there is no legal future action sequence that can produce further authenticated progress/completion.

Never report DEADLOCK while:
- an in-flight M26 assignment/robot can still reach authenticated clear;
- a valid selectable supply front can be legally placed and lead to future progress;
- current WAITING batches can be unlocked by already-scheduled/legal future clearing;
- proof bounds were exhausted without proving impossibility.

A canonical true-deadlock fixture must include:
- five occupied WAITING batches;
- no in-flight progress;
- no selectable placement because all five slots are occupied;
- no currently claimable target;
- search/proof shows no legal unlock sequence.

## Search state / canonicalization

Create a detached deterministic canonical state key containing only gameplay truth needed for future behavior, such as:
- BoardState cell-state bitmap/logical representation;
- M23 remaining queue positions/order per column;
- M24 exact five-slot batch identities, color, remaining, committed-equivalent proof state, placement sequence/lifecycle;
- deterministic solver policy state needed for exact replay.

Do not key on UI Nodes, object instance IDs, timestamps or Dictionary iteration order.

Memoize equivalent states.
Use deterministic action ordering.

## Bounds

Define explicit policy:
- maximum visited states;
- maximum search depth/player decisions;
- optional wall-clock budget for tooling use;
- deterministic state-count bound for tests/replays.

For deterministic tests, state-count/depth bounds are authoritative; wall-clock should not alter classification when deterministic mode is requested.

When a bound is hit before proof:
- return `UNKNOWN_BOUND`;
- include reason code + visited-state count;
- generation candidate is rejected, not accepted and not mislabeled DEADLOCK.

## Solution trace

For SOLVED:
- emit a detached deterministic QA trace of legal player selections + important proof transitions;
- trace must be replayable against the same level/supply/seed;
- keep it debug/tooling only, never automatically expose hidden future batches to production player UI.

## Generation-time acceptance/retry

Add an orchestration layer around M23 candidate generation:
- generate deterministic candidate from base seed + deterministic attempt index/derived seed;
- solve it;
- accept first SOLVED candidate;
- reject DEADLOCK/UNKNOWN/malformed candidates;
- retry deterministically up to a configured attempt bound;
- persist/report base seed, attempt number, effective seed, solver result, visited states and accepted trace hash/summary;
- identical inputs reproduce identical accepted/rejected sequence.

Do not mutate M23's core authority semantics merely to make candidates easier to solve.

## Runtime deadlock classification

Provide a read-only classifier over current gameplay-domain state.

It may consume:
- current BoardState;
- M23 supply snapshot;
- M24 five-slot state;
- M25 live claims;
- M26 live assignment count / pending progress.

Rules:
- if M26 has any valid live assignment/in-flight progress, return non-deadlock WAITING/PROGRESSABLE;
- if immediate legal authenticated progress exists, non-deadlock;
- if legal future supply choice sequence exists, non-deadlock;
- DEADLOCK only after proof of no legal future progress;
- UNKNOWN_BOUND remains separate.

Do not couple this API to lose-screen presentation.

## Hazard Bot

Required:
- use real `m21_level_001_hazard_bot.json`;
- generate or load a deterministic M23 candidate supply consistent with exact per-color totals;
- prove at least one complete legal solution under the five-slot rules;
- persist deterministic trace/evidence;
- replay the trace and reproduce completion;
- prove hidden future batches remain inaccessible through player-facing M23 query APIs despite solver knowing full candidate queues internally.

## 59x59

Run a bounded sanity/performance fixture appropriate to the search design:
- deterministic;
- report visited states, memo hits, peak frontier/stack, elapsed time, approximate memory/serialized key observations;
- no accidental unbounded search;
- UNKNOWN_BOUND accepted as a valid proof outcome only for an intentionally bounded stress fixture, never as production acceptance;
- include at least one 59x59 fixture whose solvability can be proven within bound.

## Continuous execution

Execute all work packages without waiting:
1. `M27_WORK_PACKAGE_01_PROOF_STATE_AND_TRANSITION_KERNEL.md`
2. `M27_WORK_PACKAGE_02_SEARCH_MEMOIZATION_AND_TRACE.md`
3. `M27_WORK_PACKAGE_03_GENERATION_ACCEPTANCE_AND_RETRY.md`
4. `M27_WORK_PACKAGE_04_RUNTIME_DEADLOCK_CLASSIFIER.md`
5. `M27_WORK_PACKAGE_05_HAZARD_BOT_SCALE_AND_CLOSURE.md`

Fix failures and continue automatically until all `SB-M27-001..034` are implemented and evidence is complete.

## Scope prohibitions

- Do not modify root `TASKS.md`.
- Do not implement M28 gameplay screen/layout.
- Do not implement lose-screen UI.
- Do not generate images or spend image credits.
- Do not weaken M23/M24/M25/M26 authorities.
- Do not expose solution trace or hidden supply queues to normal player-facing UI.

## Final handoff

After all tasks and regressions:
1. push implementation commit(s);
2. create `coordination/sessions/M27-C001/CLAUDE_LOG_V01.md` as a separate final commit;
3. map every `SB-M27-001..034` to code + direct evidence;
4. report exact start SHA, implementation SHA(s), final implementation SHA, changed files, literal commands, root-suite baseline/new failure comparison, Hazard Bot solution stats/trace hash, 59x59 stats, generator retry evidence;
5. confirm root TASKS modified = NO, M28 UI = NO, image credits = 0;
6. return only `AWAITING_AUDIT`, final implementation SHA and direct log URL.
