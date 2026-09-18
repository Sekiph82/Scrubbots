# M27-C001 V01 — MASTER STRICT AUDIT CRITERIA

Milestone: `M27 — Solvability / Deadlock Engine`
Tasks: `SB-M27-001..034`
Verdict policy: every section is blocking unless explicitly marked sanity-only.

## A. Governance

- correct repo/branch;
- root TASKS unchanged by Claude;
- M28 UI untouched;
- zero image credits;
- implementation first, separate log commit last.

## B. No contradictory gameplay model

Proof kernel must preserve:
- M23 front-only FIFO supply;
- 3/4/5 columns;
- preview/hidden ordering without illegal early selection;
- M24 five slots + rightmost-empty;
- full-slot rejection with no supply consumption;
- M24 quota/lifecycle;
- M25 same-color oldest placement arbitration;
- TargetSelector order;
- real ProductionTargetAccess/Routing/RouteValidator semantics;
- Railroad V1/V07;
- ACTIVE->CLEARED evolution.

Audit must reject a solver that replaces production reachability with Manhattan/BFS shortcuts not equivalent to production routing.

## C. Isolated deterministic proof state

- no UI Nodes as gameplay truth;
- detached/cloned search state;
- canonical deterministic serialization/key;
- no instance IDs/time/Dictionary iteration in key;
- reset/replay same input => same state keys/outcome.

## D. Legal transition kernel

For each search transition:
- only legal supply front may be selected;
- M24 rightmost-empty placement exact;
- full slots => no pop/advance;
- deterministic serial claim/clear kernel uses real targetability;
- no duplicate target claim;
- quota decrements only on successful proof clear;
- WAITING behavior preserved;
- newly-cleared corridors can unlock later targets.

## E. Search completeness within configured bounds

- branches over all legal selectable columns/actions;
- deterministic action order;
- does not assume one greedy supply order;
- memoizes equivalent states;
- SOLVED only after full canonical completion;
- DEADLOCK only after exhaustive bounded-state proof of no future legal progress;
- bound exhaustion => UNKNOWN_BOUND, never DEADLOCK.

## F. Solution trace

SOLVED trace must:
- contain legal player front selections;
- be deterministic;
- replay against identical level/supply;
- reproduce completion;
- include enough debug state identifiers to diagnose divergence;
- not be exposed by player-facing M23 APIs.

## G. Supply-generation acceptance/retry

- candidate accepted only on SOLVED;
- deterministic base seed + attempt derivation;
- unsolvable candidate rejected and retried;
- UNKNOWN_BOUND rejected;
- attempt limit respected;
- identical inputs reproduce candidate sequence + accepted attempt;
- exact level color conservation preserved;
- no hidden batch leakage to runtime UI query surface.

Required fixture must force at least one rejected candidate before a later accepted candidate, without hardcoding acceptance around the solver.

## H. Runtime classification

Stable statuses/reasons.
Never DEADLOCK if:
- M26 has valid in-flight assignment/progress;
- immediate claimable work exists;
- an empty slot + legal supply front can lead to progress;
- existing legal in-flight clear can open waiting targets;
- search returns UNKNOWN_BOUND.

## I. Canonical deadlock fixture

Five occupied WAITING batches:
- no in-flight;
- no claimable target;
- no legal supply placement because slots full;
- no legal unlock sequence;
- solver/classifier returns DEADLOCK with deterministic reason/evidence.

## J. False-positive guards

At least:
- waiting batch revived by a newly opened same-color target;
- apparently stuck state where one legal supply choice frees future progress;
- state with in-flight robot but no current immediate new claim;
- bounded-search UNKNOWN case.

None may return DEADLOCK.

## K. Hazard Bot

Use real 20x20 Hazard Bot.
Required:
- exact real level data;
- candidate supply respects exact per-color totals;
- at least one deterministic candidate proven SOLVED;
- complete trace persisted in test/evidence artifact or deterministic generated output;
- replay completes;
- solver does not illegally select preview/hidden rows;
- report decisions, visited states, memo hits, max depth, elapsed time and trace hash/summary.

## L. Rectangular fixtures

At least one non-square solvable and one non-square deadlock/unsolvable fixture.

## M. 59x59

At least one solvable proof within bound.
At least one deliberately bounded stress fixture may return UNKNOWN_BOUND.
Report:
- visited;
- memo hits;
- frontier/stack peak;
- elapsed;
- state-key size/memory estimate or equivalent.

No unbounded search.

## N. Generation seed/replay

Persist/report:
- base generation seed;
- effective attempt seed;
- attempt index;
- solver outcome;
- visited states;
- solution trace hash/summary for accepted candidate.

Identical rerun => identical result.

## O. Performance / memory

- canonical state key compact enough for bounded search;
- no full rendered image/pixel texture snapshots in memo key;
- no UI scene duplication per state;
- no avoidable O(board * candidates * hidden queue) work on every trivial check without justification;
- explicit policy constants/config.

## P. Regression floor

Run:
- full root suite and compare known baseline environmental failures;
- all M26 V01/V02 evidence;
- M25 V01/V02/V03;
- M24 V01/V02;
- M23 V01/V02/V03;
- M22 V07/V06/connector;
- representative M20/M19/M18/M21;
- new M27 dedicated evidence;
- `git diff --check`.

No new regressions.

## Q. Closure

PASS only when every `SB-M27-001..034` has direct implementation/evidence mapping.

If PASS, M23–M27 core batch gameplay engine program is closed and project may advance to M28 production gameplay screen/layout.
