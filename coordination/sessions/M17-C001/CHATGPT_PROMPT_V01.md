# M17-C001 — Routing Prototype Lab (V01)

Status: **ISSUED — prototype/comparison cycle; owner movement-language design gate follows**

## Milestone transition

M16 RoutingSystem Interface is audited complete.

This prompt intentionally opens:

**M17 — Routing Prototype Lab**

This is one of the most important SCRUBBOTS design milestones.

Do NOT lock the first working route.
Do NOT promote any prototype to production merely because it passes tests.

The goal is to build several deterministic routing prototypes behind the M16
contract, measure them, visualize them on the same scenarios, and hand the owner
a clean comparison so the owner can choose the final movement language.

The owner should use a **new Claude chat** for this milestone.

## Scope from tasks.md

Work toward:

- SB-M17-001 Direct route baseline.
- SB-M17-002 Grid-aware route prototype.
- SB-M17-003 Organized polyline/curved prototype.
- SB-M17-004 Compare visual clarity.
- SB-M17-005 Compare path crossings.
- SB-M17-006 Compare congestion.
- SB-M17-007 Compare CPU cost.
- SB-M17-008 Compare route distance.
- SB-M17-009 Compare determinism.
- SB-M17-010 Compare against original SCRUBBOTS visual direction.
- SB-M17-011 Test 5 bots.
- SB-M17-012 Test 10 bots.
- SB-M17-013 Test 25 bots.
- SB-M17-014 Stress-test higher density.
- SB-M17-015 Test 59×59.
- SB-M17-016 Test rectangular Very Hard board.

Required semantic regressions:
- blocked interior target -> no route, never retarget;
- newly-opened-after-clear -> previously blocked assigned target becomes routable
  after the relevant BoardState cells become CLEARED.

### Owner design gate

The final movement language is an **OWNER decision**.

Claude must NOT:
- declare a winning production algorithm;
- update production routing to one prototype;
- close the owner design gate;
- infer owner preference from metrics alone.

The implementation handoff must make owner comparison easy.

## First action

Work in:

`C:\Users\sekip\Desktop\ScrubBots`

Safely sync local `main` with `origin/main` while preserving all owner work.

Never use:
- `reset --hard`
- `clean -fd`
- destructive restore/checkout
- force push

Then read, in order:

- `CLAUDE.md`
- `tasks.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `.hiveai/PROJECT_DASHBOARD.md`
- `coordination/README.md`
- `coordination/SESSION_INDEX.md`
- `docs/01_GAMEPLAY_SPEC.md`
- `docs/02_TECH_ARCHITECTURE.md`
- `docs/05_TECH_DECISIONS.md`
- M15 TargetSelector implementation/audit
- all M16 route contract/validator/debug files and M16 audit
- current real-art/debug fixture data where useful
- any authoritative owner/reference material already present in the repo/local
  project that actually documents the original SCRUBBOTS movement direction
- this prompt
- `coordination/sessions/M17-C001/CHATGPT_AUDIT_CRITERIA_V01.md`

Apply relevant audit learnings, especially:
- AL-001 explicit preload
- AL-003 performance claim discipline
- AL-004 rectangular/max-size coverage
- AL-005 direct evidence before task completion
- AL-009 aggregate green totals are insufficient
- AL-011 negative-test specificity
- AL-018 direct observability
- AL-020 no mutable-state leakage
- AL-026 preserve owner/local work
- AL-027 ACTIVE/CLEARED
- AL-028 candidate != reachable target / no silent retarget
- AL-033 current C01..C16 palette v2

## Locked M16 contract

Do not weaken or bypass M16.

Every prototype must be swappable behind the same M16 contract:

```text
compute_route(request, board, access_query) -> RouteResult
```

Every successful route must still:
- use board-local cell coordinates;
- start at request.start_position;
- end at request.target_position;
- retain request.target_index;
- pass RouteValidator;
- never retarget;
- never mutate BoardState;
- never mutate ReservationState.

Every failure:
- keeps original target_index;
- returns explicit failure;
- has empty route points;
- never asks TargetSelector for another target.

## Prototype containment

Put all M17 route experiments under an explicitly experimental/debug namespace,
for example:

```text
scripts/gameplay/routing/prototypes/
scripts/debug/routing_lab/
scenes/debug/
```

Do not replace the M16 base RoutingSystem with a selected implementation.

Do not wire any prototype into production gameplay/session flow.

Tests may instantiate prototypes directly.

## Prototype A — Direct route baseline

Implement a minimal deterministic baseline:

```text
[start_position, target_position]
```

It succeeds only when the single segment is accepted by authoritative access
truth and the result passes RouteValidator.

If the segment is blocked:
- return NO_ROUTE or equivalent explicit failure;
- do not bend around the blocker;
- do not retarget.

Purpose:
- minimum route distance baseline;
- minimum point count;
- easiest crossing/congestion reference;
- not a presumed production winner.

## Prototype B — Grid-aware route

Implement a deterministic **experimental** grid-aware route.

AStarGrid2D, deterministic A*, or deterministic BFS is acceptable for this
prototype only.

Prototype topology must be explicitly documented as experimental, not canonical.

Preferred experimental topology:
- orthogonal 4-neighbor movement;
- board-local cell-center lattice;
- non-target ACTIVE cells blocked;
- CLEARED cells open;
- assigned ACTIVE target allowed as final endpoint;
- outside-board/background space available only through a small explicit
  experimental perimeter/exterior representation;
- deterministic neighbor/tie ordering.

The implementation must support caller slot origins outside the board.

Do not hide the outside-board bridge. Document/test how the outside slot origin
enters the experimental lattice.

If a different topology is chosen for the lab, document exactly why and keep it
clearly experimental.

Required:
- blocked interior target -> NO_ROUTE;
- after selected surrounding cells become CLEARED, same target/request can
  produce a route;
- route ends at the original target only.

## Prototype C — Organized polyline / curved candidate

Implement a visually organized deterministic prototype, preferably as a
post-process of a valid grid-aware path so it does not invent target truth.

Recommended sequence:

```text
valid grid-aware path
-> remove redundant collinear points
-> attempt deterministic simplification / corner organization
-> optionally generate rounded-corner / curve-sampled points
-> validate every resulting segment through RouteValidator/access truth
-> if a simplification/corner-cut is invalid, keep/fall back to the last valid
   unsimplified section rather than crossing blockers
```

This is an experimental movement-language candidate.

Do not use physics animation or ScrubbotAgent yet.

Do not choose the final curvature amount as production law.

Expose the prototype parameters used in the lab so the owner can understand
what they are seeing.

## Experimental access implementation

M17 now needs an actual prototype access truth for routing experiments.

Create an explicitly experimental implementation that translates BoardState
ACTIVE/CLEARED semantics into the chosen prototype topology.

Requirements:
- non-target ACTIVE blocks;
- CLEARED is open;
- outside-board/background free space is represented as open according to the
  documented prototype model;
- assigned ACTIVE target may be entered only as the final destination;
- no target selection;
- no reservation ownership;
- no board mutation.

Keep this implementation inside M17 experimental/prototype scope.
It must not silently become canonical production access semantics before owner
selection.

## Determinism

All three prototypes must be deterministic for identical:

```text
BoardState
RouteRequest
prototype configuration
```

Run repeated-route tests and compare exact point sequences where practical.

No random jitter in canonical prototype outputs.

If debug-only visual jitter is useful, keep it opt-in and off for metrics/tests.

## Multi-route comparison harness

Create a reusable **Routing Prototype Lab** debug tool/scene.

Recommended scene:

`scenes/debug/routing_prototype_lab.tscn`

It must allow the owner to inspect the same board/scenario with:
- Direct
- Grid-aware
- Organized/curved

At minimum expose:
- strategy selector;
- scenario/fixture selector;
- bot count selector: 1 / 5 / 10 / 25 / stress;
- route visibility toggle;
- metric panel;
- reset/rebuild action;
- current strategy name + experimental parameters;
- success/no-route counts.

Prefer a layout that works within the existing project viewport and does not
change production UI.

Do not make the owner edit source code just to switch prototypes.

## Comparison metrics

Build deterministic, algorithm-agnostic comparison utilities.

### Route distance
For each successful route:

```text
sum(distance(points[i], points[i+1]))
```

Report:
- total;
- mean;
- median where useful;
- successful-route count.

### Path crossings

Count geometric intersections between routes.

Define and document:
- whether shared start points count;
- whether shared target endpoints count;
- how collinear overlap is counted.

Recommended:
- shared start/end endpoints do NOT count as crossings;
- proper interior segment intersections do;
- collinear overlap is tracked separately as overlap/congestion, not multiplied
  into arbitrary crossing counts.

### Congestion

Use a stable proxy, not subjective language.

Recommended metrics:
- number of occupied route buckets/segments;
- max simultaneous usage of the same quantized segment/cell corridor;
- total repeated corridor use;
- overlap length where practical.

Document the exact metric definition.

### CPU cost

Measure route-computation CPU time only.

Use meaningful repeated samples.

Report:
- total calls;
- success/failure;
- total CPU time;
- mean per call;
- board size / bot count / strategy.

Do NOT claim FPS or GPU performance.

### Determinism

Run repeated identical scenarios and compare:
- success/failure;
- target identity;
- exact route points;
- metrics.

### Visual clarity

This is partly subjective.

Claude may produce objective visual proxies and a side-by-side/debug comparison,
but must NOT claim “best visual clarity” as owner truth.

Record observations neutrally:
- point count;
- turns;
- route crossings;
- overlap/congestion;
- path length;
- visual density.

The owner will decide final visual preference.

## Original SCRUBBOTS visual direction comparison

SB-M17-010 must be evidence-based.

Before making claims:
- locate the actual authoritative original SCRUBBOTS visual reference available
  in the repo/local project;
- record its path/name/source in CLAUDE_LOG_V01.

If no authoritative movement reference exists:
- do NOT invent one;
- explicitly mark this comparison as **BLOCKED_BY_MISSING_OWNER_REFERENCE** in
  the log;
- still build the lab so the owner can compare against the prototypes manually.

Do not substitute a generic “Colony Flow-like” assumption for actual evidence.

If a valid original reference exists, compare only properties visible/supportable
from that source.

## Required scenarios

At minimum create deterministic scenarios for:

### S1 — Open/simple
Useful for direct-route baseline.

### S2 — Single blocker / detour
Direct should fail if its straight segment is blocked while a grid-aware route
may succeed.

### S3 — Fully enclosed assigned target
Matching/assigned ACTIVE target surrounded by blockers:
- no prototype may silently retarget;
- route is failure until access opens.

### S4 — Newly opened after clear
Start from blocked S3-like state.
Clear the specific prerequisite cells through BoardState.
Then rerun the same target:
- a valid routing prototype should become able to route if the experimental
  topology now permits access;
- target identity remains unchanged.

### S5 — Multi-route crossing pressure
At least 5, 10, 25 routes.

### S6 — High density stress
Use a higher route count than 25, for example 50 or 100, bounded so the headless
test remains practical.

### S7 — 59×59
Production maximum.

### S8 — rectangular Very Hard
Use a legal rectangular Very Hard size such as 53×59 or another legal 50..59
pair.

Where useful, include the current real-art debug fixtures, but do not alter their
source data.

## Multi-bot semantics

M17 is a route lab, not Dispatcher/ScrubbotAgent.

For 5/10/25/stress tests:
- create deterministic RouteRequests for already-assigned unique targets;
- do not spawn Scrubbot nodes;
- do not implement reservation/dispatch orchestration;
- compute route sets and metrics only.

Keep test target assignment deterministic and outside RoutingSystem.

## Route set validity

Every successful prototype route used in comparison must pass the shared M16
RouteValidator.

Do not compare invalid routes as if they were legitimate successes.

Record validation failures separately.

## Debug artifact / owner handoff

The debug lab should make owner review practical.

At the end, CLAUDE_LOG_V01 must tell the owner exactly:
- which scene to open in Godot;
- which controls switch between Direct / Grid / Organized;
- which scenarios to inspect;
- which bot counts to compare;
- where metrics are shown;
- what remains an experimental parameter.

If useful, create:
`coordination/sessions/M17-C001/ROUTING_COMPARISON_V01.md`

This comparison artifact may contain:
- metric tables;
- neutral observations;
- known limitations;
- owner review checklist.

It must NOT declare the final winner.

## Required tests

Add direct tests at minimum for:

1. all three prototypes satisfy M16 compute_route signature;
2. all three keep original target identity;
3. all three preserve BoardState;
4. all three preserve ReservationState / do not own reservation;
5. direct baseline succeeds on open segment;
6. direct baseline fails cleanly on blocked segment;
7. grid-aware succeeds on a deterministic detour case;
8. grid-aware fails on fully enclosed target;
9. newly-opened-after-clear makes same target routable;
10. grid-aware deterministic repeated points;
11. organized prototype produces valid route from valid source path;
12. organized prototype deterministic repeated points;
13. organized simplification never crosses a blocked segment;
14. invalid simplification falls back safely or fails, never accepts invalid;
15. every success passes shared RouteValidator;
16. no prototype calls TargetSelector;
17. no prototype retargets;
18. no prototype mutates BoardState;
19. no prototype clears cells;
20. route distance metric correctness;
21. crossing metric correctness;
22. shared-endpoint crossing policy correctness;
23. overlap/congestion metric correctness;
24. CPU benchmark harness executes without FPS/GPU claims;
25. determinism metric catches a deliberately changed route;
26. 5-route comparison;
27. 10-route comparison;
28. 25-route comparison;
29. stress route set >25;
30. 59×59 scenario;
31. rectangular Very Hard scenario;
32. blocked-interior regression;
33. newly-opened-after-clear regression;
34. debug lab can switch all three strategies;
35. debug lab exposes metrics/state without computing target selection;
36. debug lab does not modify production gameplay;
37. full Godot 4.7.1 regression suite passes;
38. headless/runtime smoke for routing_prototype_lab scene if a .tscn is added.

## Performance / reporting discipline

Do not optimize prematurely.

Measure first.

Do not claim:
- final mobile FPS;
- production routing winner;
- final visual quality;
- production congestion behavior

from lab/headless numbers.

M17 is comparative evidence, not final product proof.

## No M18+ leakage

Do NOT implement:
- ScrubbotAgent;
- movement/animation playback;
- arrival detection;
- Dispatcher;
- spawning;
- slot request handling;
- vertical slice;
- cell clearing as route completion;
- production route selection.

## Documentation / ADR

Update current-law docs only as needed to describe M17 as an experimental lab.

Do NOT change ADR-024 into a final algorithm decision.

If a durable lab architecture decision needs an ADR, add one only when genuinely
necessary. Do not create an ADR that selects the winning route.

Final algorithm/movement-language ADR waits for owner selection after the design
gate.

## Governance

Claude must NOT modify:
- `tasks.md`
- `.hiveai/ACTIVE_CYCLES.md`
- `.hiveai/ARTIFACT_MAP.md`
- `.hiveai/PROGRESS_SNAPSHOT.md`
- `.hiveai/PROJECT_DASHBOARD.md`
- `coordination/SESSION_INDEX.md`
- `coordination/AUDIT_INDEX.md`
- any `CHATGPT_AUDIT_*.md`

ChatGPT owns audit/task/tracker truth.

## Validation

Run at minimum:

```text
godot --version
godot --headless --path . -s res://tests/run_tests.gd
git diff --check
```

If `routing_prototype_lab.tscn` exists:
- run an explicit headless scene smoke.

Inspect actual git diff before commit.

Record each material validation individually; aggregate green total alone is
insufficient under AL-009.

## Coordination output

Write:

`coordination/sessions/M17-C001/CLAUDE_LOG_V01.md`

Optionally also write:

`coordination/sessions/M17-C001/ROUTING_COMPARISON_V01.md`

The log must contain:
- starting origin/main SHA;
- exact changed files;
- prototype architecture;
- exact experimental topology;
- access-truth implementation;
- direct/grid/organized behavior;
- blocked-interior evidence;
- newly-opened-after-clear evidence;
- 5/10/25/stress results;
- 59×59 + rectangular results;
- route distance/crossing/congestion/CPU/determinism metrics;
- visual comparison instructions;
- original-reference evidence path OR explicit missing-reference block;
- task-by-task SB-M17-001..016 evidence;
- full regression result;
- debug scene smoke;
- confirmation no prototype was promoted to production;
- M18+ non-scope confirmation;
- owner/local-work preservation evidence;
- governance files untouched confirmation;
- safe commit/push evidence.

Commit and push safely.

Hand back:

`AWAITING_AUDIT`

Then stop.

Do not self-audit.

After ChatGPT audit, the owner still chooses the final movement language.
