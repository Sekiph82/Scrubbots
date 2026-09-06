# M15-C001 — TargetSelector (V01)

Status: **ISSUED — first implementation cycle of milestone M15**

## Milestone transition

M14 Reservation State is audited complete under the repository's strict audit policy.

This prompt intentionally opens the next main-game milestone:

**M15 — TargetSelector**

The owner should start M15 in a **new Claude chat** to reduce prior-context/token load.

## Scope

Implement exactly the M15 task set from `tasks.md`:

- SB-M15-001 Create TargetSelector.
- SB-M15-002 Keep BoardState access narrow.
- SB-M15-003 Baseline deterministic strategy.
- SB-M15-004 Match Scrubbot color.
- SB-M15-005 Never target CLEARED.
- SB-M15-006 Never target invalid or blocked/unreachable ACTIVE cells.
- SB-M15-007 Respect reservations.
- SB-M15-008 Return no-target cleanly.
- SB-M15-009 No route generation inside selector.
- SB-M15-010 Determinism tests.
- SB-M15-011 Simultaneous assignment tests.
- SB-M15-012 3,481-cell benchmark.

Do NOT implement M16 RoutingSystem, M17 routing prototypes, M18 ScrubbotAgent,
M19 Dispatcher, or M20 vertical slice.

## First action

Work in:

`C:\Users\sekip\Desktop\ScrubBots`

Safely synchronize local `main` with `origin/main` while preserving all owner work.

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
- `scripts/gameplay/board/board_state.gd`
- `scripts/gameplay/targeting/color_candidate_index.gd`
- `scripts/gameplay/targeting/reservation_state.gd`
- relevant M13/M14 tests and audit artifacts
- this prompt
- `coordination/sessions/M15-C001/CHATGPT_AUDIT_CRITERIA_V01.md`

Apply all relevant AUDIT_INDEX learnings, especially:
- AL-001 explicit preload
- AL-003 performance-claim discipline
- AL-004 variable/rectangular/max-size coverage
- AL-005 task completion needs real validation
- AL-009 aggregate green count is not enough
- AL-011 negative-test specificity
- AL-018 direct observability
- AL-020 no mutable-state leakage
- AL-026 owner-work preservation
- AL-027 ACTIVE/CLEARED
- AL-028 raw color candidate != reachable final target
- AL-033 current canonical C01..C16 palette v2

## Locked M15 responsibility

TargetSelector decides **WHAT target** a Scrubbot assignment gets.

It must NOT decide **HOW to travel** there.

Canonical separation remains:

```text
ColorCandidateIndex
    -> raw ACTIVE matching-color candidates
ReservationState
    -> current assignment exclusions + atomic ownership
Reachability/access truth
    -> says whether a candidate is currently targetable
TargetSelector
    -> chooses WHAT target and atomically reserves it
RoutingSystem (M16+)
    -> later decides HOW to travel to that already-assigned target
```

## Critical architecture direction

Create:

`scripts/gameplay/targeting/target_selector.gd`

Use explicit preload conventions.

### Dependencies

TargetSelector should bind to / receive only the narrow dependencies it needs:

1. `BoardState`
2. `ColorCandidateIndex`
3. `ReservationState`
4. a narrow **reachability/access truth** supplied by the caller

Do NOT implement routing or pathfinding in M15.

### Reachability/access seam

M16/M17 routing topology is still TO BE DESIGNED.

Therefore M15 must consume reachability as an injected narrow query contract.

Use one of these simple forms:

```text
access_query.is_targetable(target_index) -> bool
```

or an equivalently narrow Callable contract.

Prefer a tiny duck-typed RefCounted/test-double-friendly interface rather than
creating a routing subsystem early.

The selector must **fail closed** when no valid access query is supplied.

Do not silently assume every raw color candidate is reachable.

Do not compute route geometry.

Do not run AStar.

Do not inspect route points.

Do not invent neighborhood topology.

### What “blocked/unreachable” means in M15

M15 does not decide why a target is blocked.

It consumes authoritative access truth from the injected query.

Required regression:

- a matching-color ACTIVE cell exists in ColorCandidateIndex;
- access truth reports it blocked/unreachable;
- TargetSelector must NOT select/reserve it;
- if it is the only matching candidate, result is cleanly “no target.”

Use the owner-locked AL-028 enclosed-cell semantic as the test scenario, but
do not implement the path algorithm yet.

## Canonical selection API

Prefer a primary API equivalent to:

```text
bind(board, candidate_index, reservation_state) -> bool

select_and_reserve(
    color_id,
    owner_id,
    access_query
) -> int
```

Return:
- selected/reserved target index on success;
- `-1` on no valid target / invalid call / failed assignment.

Exact naming may vary only if repository conventions strongly justify it.

## Why selection and reservation must be one operation

M14 already established atomic reservation ownership.

To satisfy M15 simultaneous assignment safely, TargetSelector must not expose a
race-prone caller sequence like:

```text
target = choose()
... gap ...
reserve(target)
```

The primary assignment path must choose candidates and attempt
`ReservationState.reserve(candidate, owner_id)` inside the same synchronous
selector call.

This is not multithread thread-safety. Current Godot gameplay is
main-thread/synchronous.

## Deterministic baseline strategy

Use the simplest deterministic strategy:

**first targetable candidate in ascending row-major candidate index order**.

ColorCandidateIndex already returns deterministic ascending raw candidates.

For each candidate:

1. final-validate the candidate narrowly against BoardState;
2. require valid index;
3. require `ACTIVE`;
4. require the requested `color_id`;
5. require not already reserved;
6. require access query says targetable;
7. attempt atomic ReservationState.reserve();
8. if reservation succeeds, return that target;
9. if reservation loses to another synchronous assignment, continue to the next candidate if the owner still has no reservation.

No random selection in M15.

No distance scoring.

No route-length scoring.

No “best-looking” heuristic.

No hidden fallback route logic.

## Narrow BoardState access

TargetSelector may use BoardState only for final truth checks such as:

- `is_valid_index(index)`
- `get_cell_state(index)`
- `get_color_id(index)`

Do not:
- scan the entire board;
- duplicate board arrays;
- mutate BoardState;
- re-derive coordinate/index math;
- own ACTIVE/CLEARED lifecycle.

This final validation exists so stale/corrupt upstream candidate data cannot
make TargetSelector return an invalid, CLEARED or wrong-color target.

## Reservation behavior

TargetSelector must consume the M14 ReservationState.

Before candidate selection:
- if `owner_id < 0`, return -1;
- if owner already holds a reservation, return -1;
- retrieve current reserved indices and pass them as exclusions to
  ColorCandidateIndex.

During selection:
- still rely on `ReservationState.reserve()` as the final atomic ownership
  gate.

TargetSelector must NOT:
- directly mutate ReservationState dictionaries;
- invent a second reservation store;
- auto-release someone else's reservation;
- resolve arrivals;
- clear cells.

## No-target behavior

Return `-1` cleanly for at least:

- unbound selector;
- null/missing dependencies;
- invalid color id;
- invalid owner id;
- owner already assigned;
- no raw candidates;
- all candidates reserved;
- all matching candidates CLEARED/invalid/stale;
- all matching ACTIVE candidates blocked/unreachable;
- all reservation attempts lose to competing assignments.

No exception, no dispatch, no route request.

## Required tests

Add direct tests with observability strong enough for strict audit.

At minimum prove:

1. create/bind success;
2. bind rejects null/missing dependencies;
3. unbound select returns -1;
4. invalid color returns -1;
5. invalid owner returns -1;
6. deterministic first ascending target selected;
7. matching color required;
8. wrong-color candidate never selected even if injected/stale;
9. CLEARED candidate never selected even if candidate index is stale;
10. invalid candidate never selected;
11. reserved candidate skipped;
12. reservation is actually created on successful selection;
13. owner already holding target returns -1;
14. all reserved candidates returns -1;
15. no candidates returns -1;
16. access_query required / missing query fails closed;
17. access-query false candidate skipped;
18. first blocked candidate skipped and later reachable candidate selected;
19. all blocked candidates returns -1;
20. explicit fully-enclosed matching-color ACTIVE regression returns no target
    when access truth reports it blocked;
21. no target causes no new reservation;
22. selector does not mutate BoardState;
23. selector does not mutate ColorCandidateIndex internal truth;
24. selector does not implement or call route-generation APIs;
25. repeated identical state produces identical selected index;
26. after releasing the selected reservation, the same deterministic target is
    selected again for a new owner;
27. simultaneous/competing owners against one target: exactly one succeeds;
28. simultaneous/competing owners with multiple candidates: assignments remain
    unique and deterministic under call order;
29. if first reservation attempt loses because another synchronous assignment
    took it, selector may continue to the next valid candidate for the still-
    unassigned owner;
30. rectangular-board test;
31. 59×59 / 3481-cell benchmark;
32. no per-call full-board scan in steady-state selection beyond candidate
    iteration;
33. full existing Godot 4.7.1 regression suite passes.

### Test-double requirements

Create a tiny test access-query double able to:

- mark specific target indices targetable/unreachable;
- count which target indices were queried.

This lets the audit directly observe that TargetSelector consults access truth.

Do not use a proxy assertion like “reservation count changed” as the only proof
that access filtering ran.

## Performance

TargetSelector may iterate the candidate bucket for the requested color.

It must not scan all 3481 cells merely to make a selection.

Benchmark on a 59×59 board and report:
- candidate count for the tested color;
- selection iterations/access-query calls;
- total CPU time for a meaningful repeated sample.

Do not claim FPS/GPU performance from headless CPU timings.

## Documentation

Update only current-law documentation needed for M15.

At minimum inspect/update:

- `docs/01_GAMEPLAY_SPEC.md`
- `docs/02_TECH_ARCHITECTURE.md`
- `docs/05_TECH_DECISIONS.md`

Record a new ADR only if M15 introduces a durable architecture choice not
already fully covered by existing ADRs. Do not create ceremonial ADR noise.

Do not rewrite historical prompt/audit evidence.

## Scope locks

Preserve:

- production board bands and 59×59 maximum;
- C01..C16 palette v2;
- C16 Pure Black #000000;
- BG01 #202533 outside logical palette;
- ACTIVE/CLEARED only;
- five slots;
- ReservationState architecture from ADR-022;
- raw color candidate != reachable target;
- TargetSelector != RoutingSystem;
- no one-Node-per-cell architecture.

Do NOT implement:

- route generation;
- AStar/pathfinding;
- collision radius;
- path topology;
- Scrubbot movement;
- dispatch queue;
- actual robot spawning;
- cell clearing on arrival;
- M16+.

## Task/governance ownership

Claude must NOT update:

- `tasks.md`
- `.hiveai/ACTIVE_CYCLES.md`
- `.hiveai/ARTIFACT_MAP.md`
- `.hiveai/PROGRESS_SNAPSHOT.md`
- `.hiveai/PROJECT_DASHBOARD.md`
- `coordination/SESSION_INDEX.md`
- `coordination/AUDIT_INDEX.md`
- any ChatGPT audit file

ChatGPT will independently audit and update canonical task/tracker truth.

## Validation

Run at minimum:

```text
godot --version
godot --headless --path . -s res://tests/run_tests.gd
git diff --check
```

Inspect actual `git diff` before commit.

Record every prompt-mandated material check individually in the matching Claude
log; aggregate green totals alone are insufficient under AL-009.

## Coordination output

Write:

`coordination/sessions/M15-C001/CLAUDE_LOG_V01.md`

The log must contain:
- starting origin/main SHA;
- implementation commit/push evidence;
- exact changed files;
- dependency/API design;
- access-query seam;
- deterministic strategy;
- task-by-task evidence for SB-M15-001..012;
- negative-test evidence;
- AL-018 direct-observability evidence;
- simultaneous assignment evidence;
- 59×59 performance evidence;
- explicit M16+ non-scope confirmation;
- confirmation that tasks/H!veAI/SESSION_INDEX/AUDIT_INDEX were untouched.

Commit and push safely.

Hand back:

`AWAITING_AUDIT`

Then stop.

Do not self-audit.
