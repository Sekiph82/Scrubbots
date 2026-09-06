# M14-C001 — Reservation State (V01)

Status: **ISSUED — first implementation cycle of milestone M14**

## Milestone transition

M10 owner manual QA is complete. M11, M12 and M13 are already audited complete.
This prompt intentionally opens the next main-game milestone:

**M14 — Reservation State**

The owner should start this work in a **new Claude chat** to reduce unnecessary prior-context/token load.

## Scope

Implement exactly the M14 reservation layer required by `tasks.md`:

- SB-M14-001 Define reservation ownership.
- SB-M14-002 Decide whether RESERVED belongs in `BoardState.CellState` or separate data.
- SB-M14-003 Record decision (ADR).
- SB-M14-004 Reserve target atomically.
- SB-M14-005 Prevent double reservation.
- SB-M14-006 Release on dispatch failure.
- SB-M14-007 Release on reset.
- SB-M14-008 Resolve arrival.
- SB-M14-009 Concurrency tests.

Also formally resolve the old deferred gate:
- SB-M02-017 Add RESERVED only when reservation architecture is designed.

Do NOT implement M15 TargetSelector, M16 routing, M17 routing prototype, M18 agent, M19 dispatcher, or M20 vertical slice.

## First action

Work in:

`C:\Users\sekip\Desktop\ScrubBots`

Safely sync local `main` with `origin/main` while preserving all owner changes.

Never use:
- `reset --hard`
- `clean -fd`
- destructive restore/checkout
- force push

Read, in order:
- `CLAUDE.md`
- `tasks.md`
- `.hiveai/PROJECT_DASHBOARD.md`
- `coordination/README.md`
- `coordination/SESSION_INDEX.md`
- `coordination/AUDIT_INDEX.md`
- `docs/01_GAMEPLAY_SPEC.md`
- `docs/02_TECH_ARCHITECTURE.md`
- `docs/05_TECH_DECISIONS.md`
- `scripts/gameplay/board/board_state.gd`
- `scripts/gameplay/targeting/color_candidate_index.gd`
- relevant M11/M12/M13 implementation and tests
- this prompt
- `coordination/sessions/M14-C001/CHATGPT_AUDIT_CRITERIA_V01.md`

## Owner-approved architecture direction for M14

Use a **separate reservation data layer**.

Do NOT add `RESERVED` to `BoardState.CellState`.

BoardState must remain the canonical physical/artwork lifecycle only:

```text
ACTIVE  = artwork cell still present
CLEARED = artwork cell removed / transparent / open
```

Reservation is not a physical cell lifecycle state. It is temporary assignment metadata.

### Required module

Create a focused reservation module under targeting, preferably:

`scripts/gameplay/targeting/reservation_state.gd`

or an equally clear name if repository conventions strongly justify another one.

The reservation layer owns ephemeral assignment truth only.

## Reservation ownership contract

A reservation belongs to a unique future dispatch/agent assignment token.

Use a simple deterministic integer owner token:

```text
owner_id >= 0
```

The owner token is NOT:
- a color ID;
- a slot ID;
- a cell ID;
- a permanent gameplay entity identity requirement.

It represents one future in-flight target assignment.

The reservation layer must enforce:

1. one target index can have at most one owner;
2. one owner_id can hold at most one target at a time;
3. reserve is check-and-set in one synchronous method;
4. no `await`, deferred mutation or multi-step caller dance between checking and storing.

Godot gameplay is currently main-thread/synchronous. “Atomic” here means the reserve API performs validation + conflict check + insertion within one uninterrupted call.

## Required state relationship

The ReservationState should bind to a BoardState (or otherwise receive BoardState truth narrowly) so it can reject:

- invalid cell indices;
- CLEARED cells;
- null/unbound use;
- invalid owner IDs.

A reservation is legal only for a currently ACTIVE valid cell.

Do not duplicate cell color/state storage inside ReservationState.

## Required API behavior

Exact method names may vary, but the behavior must be cleanly available and tested.

At minimum support equivalents of:

```text
bind(board)
rebind(board)                  # clears stale reservations from prior board
reserve(target_index, owner_id) -> bool
is_reserved(target_index) -> bool
get_owner(target_index) -> int # -1 when unreserved/invalid
get_target_for_owner(owner_id) -> int # -1 when none
release(target_index, owner_id) -> bool
release_for_owner(owner_id) -> bool   # optional but strongly preferred
reset()                        # clear all reservations, keep current board binding
resolve_arrival(target_index, owner_id) -> bool
get_reserved_indices() -> Array/PackedInt32Array
get_reservation_count() -> int
```

### reserve()

Must return false without mutation when:

- unbound;
- target index invalid;
- target is not ACTIVE;
- owner_id invalid;
- target already reserved by any owner;
- owner already holds a different target.

A repeated reserve of the exact same target by the same owner should also return false. Do not silently treat duplicate reserve as success.

### release()

Must be ownership-safe.

Only the current owner of that target may release it.

Wrong-owner release returns false and changes nothing.

### release on dispatch failure

M14 does not implement the dispatcher.

Provide the reservation API needed for a future dispatcher to release a failed assignment, and test the exact lifecycle:

```text
reserve -> simulated dispatch failure -> release -> target becomes reservable again
```

Do not create M19 merely to test M14.

### reset()

Reset must release every active reservation deterministically.

Rebinding to a new BoardState must also clear all old-board reservations.

### resolve_arrival()

M14 owns reservation bookkeeping only.

`resolve_arrival(target, owner)` must validate ownership and remove the reservation exactly once.

It must NOT:
- clear the BoardState cell itself;
- animate a robot;
- dispatch a robot;
- choose another target;
- generate a route.

Board mutation on successful cleaning remains a later orchestration responsibility.

Wrong owner / non-reserved target / second resolution must return false without side effects.

## ColorCandidateIndex integration seam

Do NOT make ColorCandidateIndex own reservations.

Its M13 contract remains:

```text
raw ACTIVE matching-color candidates
minus caller-supplied excluded/reserved indices
```

ReservationState should expose its reserved indices in a detached deterministic collection that can be passed directly to:

```gdscript
ColorCandidateIndex.get_candidates(color_id, reserved_indices)
ColorCandidateIndex.has_candidates(color_id, reserved_indices)
```

Add focused integration tests proving a reserved ACTIVE matching-color cell is excluded only because ReservationState supplies it as caller exclusion.

Do not modify M13 into an M14 owner.

## Ordering / determinism

- Reserved-index output must be deterministic, preferably ascending cell index.
- No mutable internal dictionary/array references may leak to callers.
- Query results must be detached copies/scalars.
- Invalid calls must fail cleanly, not throw.

## Performance

Reservation lookup/reserve/release must be O(1) average using maps/dictionaries or equivalent.

Do not scan the full board on every reservation query.

A one-time BoardState validation of one target index/state is fine.

Include a 59×59 / 3481-cell sanity test with a meaningful number of reservations and verify no full-board scan is part of normal reserve/is_reserved/release calls.

## ADR

Record the M14 architecture decision as the next available ADR, currently expected to be **ADR-022** after inspecting the file.

The ADR must explicitly state:

- ReservationState is separate from BoardState.
- `BoardState.CellState` remains ACTIVE/CLEARED only.
- reservation is temporary assignment metadata, not artwork/access state.
- target-level and owner-level uniqueness.
- future TargetSelector consumes reservation exclusions but does not own them.
- future dispatcher/agent is the caller supplying unique owner tokens.
- reservation resolution does not itself clear BoardState.

If another ADR number is already present on current main, use the next actually available number.

## Documentation updates

Update only current architecture/gameplay documentation needed to reflect the accepted M14 reservation contract.

At minimum inspect/update:
- `docs/01_GAMEPLAY_SPEC.md`
- `docs/02_TECH_ARCHITECTURE.md`
- `docs/05_TECH_DECISIONS.md`
- relevant current-law comments in `CLAUDE.md` if needed

Also clean stale current-law wording that still says M10 owner QA is open if encountered in active governance documentation.

Do not rewrite historical audit/prompt evidence.

## Tests required

Add comprehensive tests for at least:

1. create/bind success;
2. null/unbound rejection;
3. valid ACTIVE reserve succeeds;
4. invalid index reserve fails;
5. CLEARED target reserve fails;
6. invalid owner ID fails;
7. target double reservation by different owner fails;
8. same owner duplicate reserve fails;
9. same owner cannot reserve two targets;
10. independent owners can reserve different targets;
11. `is_reserved` truth;
12. `get_owner` truth;
13. owner->target lookup truth;
14. wrong-owner release fails;
15. correct release succeeds;
16. released target can be reserved again;
17. simulated dispatch-failure lifecycle releases correctly;
18. reset clears all reservations;
19. rebind clears old reservations;
20. arrival resolution succeeds once;
21. wrong-owner arrival resolution fails;
22. second arrival resolution fails;
23. resolve_arrival does NOT mutate BoardState cell state;
24. detached reserved-index output cannot mutate internal state;
25. reserved indices deterministic/ascending;
26. ColorCandidateIndex integration excludes reserved candidate via caller exclusion;
27. releasing reservation makes candidate visible again;
28. raw candidate index itself still owns no reservation state;
29. no `BoardState.CellState.RESERVED` exists;
30. BoardRenderer ACTIVE/CLEARED behavior remains unchanged;
31. 3,481-cell reservation sanity/performance coverage;
32. full existing Godot 4.7.1 regression suite passes.

Concurrency/simultaneous-assignment tests must simulate competing synchronous calls for the same target and prove exactly one succeeds.

## Important scope locks

Preserve all owner-locked rules:

- production boards: Easy 20–29, Medium 30–39, Hard 40–49, Very Hard 50–59
- max = 59×59 = 3481
- palette = C01..C16
- C16 Pure Black = #000000
- BG01 = #202533 outside the logical palette
- ACTIVE/CLEARED only
- raw color candidate != reachable final target
- target selection separate from routing
- 5 slots
- no one-Node-per-cell architecture

Do NOT:
- implement reachability;
- invent route topology;
- implement TargetSelector;
- implement ScrubbotAgent;
- implement Dispatcher;
- alter slot mechanics;
- alter renderer visuals;
- change production board limits;
- change palette values;
- start M15+.

## Task ledger ownership

Claude must NOT update `tasks.md`.

ChatGPT will update `tasks.md` only after independent audit verifies which M14 tasks genuinely passed.

Claude must also NOT update:
- `.hiveai/ACTIVE_CYCLES.md`
- `.hiveai/ARTIFACT_MAP.md`
- `.hiveai/PROGRESS_SNAPSHOT.md`
- `.hiveai/PROJECT_DASHBOARD.md`
- `coordination/SESSION_INDEX.md`

## Validation

Run at minimum:

```text
godot --version
godot --headless --path . -s res://tests/run_tests.gd
git diff --check
```

Also inspect actual `git diff` before commit.

No SCRIPT ERROR / parse error / unexpected runtime error may remain.

Preserve unrelated owner/local changes.

## Coordination output

Write:

`coordination/sessions/M14-C001/CLAUDE_LOG_V01.md`

The log must contain:
- starting origin/main SHA;
- implementation commit SHA;
- exact changed files;
- ADR decision summary;
- test commands/results;
- M14 task-by-task evidence;
- SB-M02-017 evidence;
- performance evidence;
- confirmation that M15+ was not implemented;
- confirmation that `tasks.md`, H!veAI files and SESSION_INDEX were untouched;
- push result.

Commit and push safely.

Hand back:

`AWAITING_AUDIT`

Then stop.

Do not self-audit.
