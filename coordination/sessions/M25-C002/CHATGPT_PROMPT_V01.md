# M25-C002 — 59x59 TARGET-SELECTION PERFORMANCE INVESTIGATION — PROMPT V01

Date: 2026-09-29
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Task: `SB-M25-033`
Status: READY FOR CLAUDE / INVESTIGATION ONLY

Blocking audit:
`coordination/sessions/M29-C002/CHATGPT_AUDIT_V01.md`

Evidence source:
`coordination/sessions/M29-C002/evidence/tempo_report.txt`

## Scope lock

This is an INVESTIGATION / PROPOSAL task only.

Do NOT change production gameplay code.

Do NOT edit:
- `TargetSelector`;
- `ProductionTargetAccess`;
- routing;
- claims/reservations;
- scheduler/runtime;
- economy;
- level data;
- root `TASKS.md`.

Instrumentation/test-only changes are allowed if they are clearly non-shipping and required to measure the hotspot.

Do not silently "fix" the issue.

## Finding to reproduce

On the dense 59x59 six-colour wide-stripe TEST fixture used by M29-C002, a single production dispatch lane can synchronously block the main thread for roughly 0.9–3.4 seconds.

RuntimePerfProbe attributes the stall primarily to:

`ProductionRuntimeController -> AutoDispatchScheduler.step_lane -> M25 claim -> TargetSelector -> access_query.is_targetable -> ProductionRoutingSystem.compute_route`

A lane may issue 100+ route/access probes while scanning matching-color candidates before finding the first canonical targetable candidate.

The same pathological scan exists at the historical tempo, although the new faster cadence attempts lanes more often.

## Reproduction

Start from the actual M29-C002 fixture/harness.

Reproduce the 59x59 path using the equivalent of:

`_run_fixture(59, 6, true, 60, 6.0, false)`

and at least these comparison cases:

- 59x59, 6 slots, new 1x, 60 FPS;
- 59x59, 6 slots, new 2x, 60 FPS;
- 59x59, 6 slots, historical tempo, 60 FPS;
- one 30 FPS case;
- one 32x32 control case.

Do not rely on wall-clock totals alone.

## Required instrumentation

Measure PER LANE, not only aggregate per run.

For representative expensive lanes capture:

1. board revision;
2. slot / batch identity / color;
3. candidate count returned by ColorCandidateIndex;
4. candidate order position of the eventual selected target;
5. number skipped because invalid/CLEARED/wrong-color/reserved;
6. number rejected by any cheap prefilter;
7. number of `access_query.is_targetable` calls;
8. number of `compute_route` calls;
9. number of successful vs failed route probes;
10. target-selection total time;
11. route-probe total/mean/max time;
12. winning target index/coordinate;
13. whether the same failed candidate+origin+board-revision combination is probed repeatedly across nearby waves/lanes.

Instrument without changing selection results.

## Existing prefilter analysis

ProductionTargetAccess already has the M52 reachability mask / `_could_reach()` prefilter.

Explicitly explain:

- what cases that mask removes;
- why the 59x59 wide-stripe case still reaches 100+ expensive route probes;
- whether perimeter ACTIVE candidates, frontier shape, board revision churn, slot-origin differences, or repeated candidate scans are the main reason;
- what work is duplicated within one lane and across lanes/waves.

Do not propose "add a reachability prefilter" generically without accounting for the existing one.

## Canonical truth that MUST remain exact

Any future mitigation must preserve:

### TargetSelector WHAT policy
- matching ACTIVE color;
- unreserved;
- currently production-targetable;
- **bottom-most first, then left-most** among targetable candidates;
- deterministic index tie-break;
- exact same winning target as current production for the same state.

### Transaction truth
- one target per owner;
- reservation uniqueness;
- same-color FIFO batch arbitration;
- no pre-claim;
- no ghost;
- exact rollback;
- fail-closed strict collaborator/coherence rules.

### Architecture
- TargetSelector decides WHAT;
- RoutingSystem decides HOW;
- no route geometry duplicated inside TargetSelector;
- no approximate "nearest" substitution;
- no changed target priority for speed.

## Proposal requirements

Evaluate at least THREE concrete mitigation families.

At minimum discuss:

### Option A — stronger exact-safe frontier/necessary-condition filter

A cheap necessary-condition structure may reject candidates that provably cannot be targetable before routing.

Explain where it should live so TargetSelector does not absorb routing topology.

Must prove:
- zero false negatives;
- exact same first canonical target;
- invalidation on BoardState revision/reset/restore.

### Option B — exact memo/cache of targetability results

Evaluate caching failed/successful targetability probes keyed by all truth inputs necessary for correctness, such as:
- exact BoardState identity;
- revision;
- origin;
- target index;
- routing authority/version if needed.

Discuss likely hit rate given board revision changes after clears and different slot origins.

Must never reuse a route/verdict across a changed board state or wrong origin.

### Option C — bounded incremental scan / deterministic continuation

Evaluate splitting one candidate scan across frames while preserving exact canonical order and atomic reservation semantics.

Must address:
- selection transaction currently synchronous;
- re-entrancy/coherence guards;
- board revision changing between frames;
- reservation races;
- restart/revalidation semantics;
- scheduler lane pending state;
- how to avoid selecting a later candidate before an earlier canonical candidate has been conclusively tested.

This option may be architecturally heavier; say so if it is.

You may add other exact-safe options.

## Recommendation

Choose ONE recommended mitigation or staged combination.

The recommendation must include:

- expected asymptotic and practical bound;
- expected number of expensive route probes per lane on the reproduced 59x59 case;
- main-thread frame budget target;
- implementation files likely to change;
- new state/cache ownership;
- invalidation rules;
- strict correctness proof obligations;
- migration/regression risks;
- rollback strategy.

Do not implement it.

## Acceptance target for the future implementation

Propose a measurable performance target suitable for a subsequent implementation prompt.

The target must be realistic on Godot 4.7.2 and should include both:

1. a hard/bounded algorithmic work metric, such as max expensive route probes per frame/lane or deterministic continuation budget;
2. an observed frame-time target on the reproduced fixture, while acknowledging machine noise.

Avoid making correctness depend on a machine-specific millisecond threshold alone.

## Required outputs

Create:

- `coordination/sessions/M25-C002/M25_59X59_TARGET_SELECTION_FINDINGS_V01.md`
- `coordination/sessions/M25-C002/evidence/` with measurement report(s) if needed;
- `coordination/sessions/M25-C002/CLAUDE_LOG_V01.md`.

Do not create an implementation/remediation commit.

Do not edit root `TASKS.md`.

Commit/push only investigation instrumentation/evidence/docs that obey this prompt.

Return:
1. final SHA;
2. exact measured hotspot;
3. probes-per-lane distribution;
4. why existing M52 prefilter is insufficient;
5. options compared;
6. recommended exact-safe mitigation;
7. proposed future acceptance bound.

Finish exactly:

`AWAITING_CHATGPT_AUDIT / M25-C002 59X59 TARGET-SELECTION INVESTIGATION V01`
