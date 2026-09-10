# CLAUDE_LOG_V01 — M20-C001 Complete Clearing Vertical Slice

- Cycle: M20-C001
- Prompt: `coordination/sessions/M20-C001/CHATGPT_PROMPT_V01.md`
- Audit criteria: `coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
- Actor: CLAUDE (implement + test only)
- Handoff state: AWAITING_AUDIT
- Engine: Godot `4.7.1.stable.official.a13da4feb`
- Starting `origin/main`: `f4b0d98` (M20 prompt + audit criteria issued)
- Tracker start transition commit (IN_PROGRESS): `d38bffc`
- Result: full headless suite **3386 / 3386 PASS**, exit 0 (up from the
  M19-C001 V06 baseline of 3273; **+113 M20 checks**, independently
  re-verified pre/post to confirm the leak-at-exit warnings are pre-existing,
  not an M20 regression).

Claude did NOT modify any `CHATGPT_*` artifact, any audit verdict, any SB-M20
checkbox, any `.hiveai/*` file, `coordination/SESSION_INDEX.md`, or any
unrelated production system. Pre-existing owner working-tree changes
(`project.godot`, `scenes/debug/*.tscn`, untracked `.uid`/`.import`/`docs/logs`)
were preserved and left unstaged.

## 0. Tracking / start-order law (§0)

1. Synced `origin/main` fast-forward (`77d5359..f4b0d98`), owner working-tree
   modifications preserved (no restore/reset/clean).
2. Verified root `TASKS.md` still referenced M20 prep (READY_FOR_NEXT_TASK,
   Required Actor CHATGPT) — no shift to another actor/task.
3. Updated the Project Status block to M20 / M20-C001 V01 / IN_PROGRESS /
   Required Actor CLAUDE.
4. Committed + pushed the start transition (`d38bffc`) BEFORE any production or
   test edit.
5. Verified remote `origin/main` carried the IN_PROGRESS transition
   (`git show origin/main:TASKS.md` → `Current Task Status: IN_PROGRESS`).

## Files changed (excluding auto-generated `.uid`)

- `scripts/gameplay/clearing/complete_clearing_loop.gd` — NEW. M20 orchestrator.
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` — narrow M19 arrival bridge.
- `scripts/gameplay/board/board_renderer.gd` — minimal read-only `is_bound_to`.
- `tests/run_tests.gd` — M20 scenario matrix (7 sections) + preloads + init hooks.
- `tests/support/m20_failing_candidate.gd` — NEW rollback double (real subclass).
- `tests/support/m20_failing_reservation.gd` — NEW rollback double (real subclass).
- `docs/02_TECH_ARCHITECTURE.md` — records the M20 clearing-loop seam (§14).
- `TASKS.md` — Project Status lifecycle only (IN_PROGRESS → AWAITING_AUDIT).
- `coordination/sessions/M20-C001/CLAUDE_LOG_V01.md` — this log.

## Evidence mapped to prompt criteria

### §1 Separate M20 orchestrator
`CompleteClearingLoop` extends `RefCounted`, lives in `scripts/gameplay/clearing/`,
uses explicit `preload()` (AL-001). Owns exactly: slot-activation → one dispatch;
authenticated arrival → the synchronized clear transaction; reset of in-flight
dispatch state. Class doc explicitly disclaims target-selection, routing,
reservation storage, BoardState storage, candidate buckets, agent movement,
win/lose/scoring/session, and slot cooldown/queue/consumption.

### §2 Bind contract
`bind(board, slot_system, candidate_index, reservation_state, dispatcher, renderer=null)`
requires: real `BoardState`; real configured `SlotSystem` with exactly 5 slots;
real `ColorCandidateIndex` exact-bound to board; real `ReservationState`
exact-bound; real `ScrubbotDispatcher` exact-bound to same board + reservation
(`dispatcher.is_bound_to(board, reservation_state)`); dispatcher
`get_active_count() == 0` at bind; optional renderer live + exact-bound. Exposes
`is_bound()` and `is_coherent()`. Second bind returns false and preserves the
bundle. Tests: `_run_m20_bind_contract_tests` (scalar board, unconfigured slots,
foreign-board candidate/reservation, wrong-board renderer, dispatcher-active!=0,
second-bind-refused).

### §3 Narrow M19 arrival bridge
Added `signal assignment_arrived(owner_id, target_index, color_id, agent)`,
emitted EXACTLY once inside `_on_agent_completed` after the existing immutable
owner/target/color/exact-agent identity checks (duplicate correct completion
stays idempotently arrived, no re-emit). Added read-only `is_bound_to`,
`is_arrival_pending`, and `finalize_arrival` (removes the `_active` entry exactly
once, disconnects the completion signal, `queue_free()`s the agent — safe from
inside the completion-signal stack, no return path, leaves BoardState/reservation
to M20). Wrong/stale/mismatched finalize returns false and changes nothing. All
M19 V01–V06 tests preserved and still pass (3273 baseline included).

### §4 Slot activation API
`activate_slot(slot_id, start_position, speed=6.0) -> DispatchResult`. Preflight:
loop bound+coherent, integer slot id in 0..4, slots configured, slot available,
palette id ≥ 0, finite origin, finite positive speed. Delegates the no-work /
reachability decision entirely to the dispatcher path. Slot fields unchanged by
success or failure; one activation → at most one Scrubbot. Tests:
`_run_m20_activation_tests`.

### §5 Arrival preflight
`_arrival_preflight_ok` re-checks: loop bound+coherent; dispatcher exact-bound to
board+reservation and reporting exactly this arrived owner/target/color/agent
(`is_arrival_pending`); target valid index; board state exactly ACTIVE; board
color == assignment color; reservation owner→target and target→owner exact;
candidate index still bound; renderer (if any) still live+bound. On any failure:
no clear, no release, no removal, no unrelated mutation. The loop listens ONLY to
`assignment_arrived`, never to a raw agent signal.

### §6 Authoritative clear transaction
Exact locked order: `set_cell_state(target, CLEARED)` → `sync_cell(target)` →
`resolve_arrival(target, owner)` → (renderer) `update_cells([target])` →
`finalize_arrival`. Step-1 failure ⇒ nothing after runs (BOARD_WRITE_FAILED).
Candidate-sync failure ⇒ rollback BoardState→ACTIVE + restore candidate truth,
reservation + dispatcher assignment held, no finalize (CANDIDATE_ROLLBACK).
Reservation-resolve failure ⇒ rollback BoardState→ACTIVE + candidate resync,
reservation left as-was, dispatcher held, no finalize (RESERVATION_ROLLBACK).
`ProductionAccessQuery` receives no explicit mutation — it reads BoardState live.
`renderer == null` is a valid headless config. Tests: `_run_m20_clear_transaction_tests`
(both rollbacks driven by real subclass doubles `M20FailingCandidate` /
`M20FailingReservation`).

### §7 Exactly-once / spoof / stale
`_run_m20_desync_adversary_tests`: unknown/spoofed owner → PREFLIGHT_REJECTED, no
mutation; bridge `is_arrival_pending` false for wrong owner/target/color/agent;
`finalize_arrival` wrong-owner → false, assignment still held; duplicate correct
completion does not clear twice (bridge emits once); target externally CLEARED
before arrival → preflight rejected; reservation removed before arrival →
preflight rejected. One assignment clears exactly one cell exactly once.

### §8 Clear opens future reachability (AL-028 regression)
`_run_m20_reachability_open_tests`: real bundle (BoardState, ColorCandidateIndex,
ReservationState, TargetSelector, ProductionAccessQuery, ProductionTargetAccess,
ProductionRoutingSystem, ScrubbotDispatcher, CompleteClearingLoop). Inner cell B
enclosed by ACTIVE walls with door A the only opening: B initially not targetable,
A targetable; activation clears A; a fresh `ProductionTargetAccess` probe (no
explicit cache refresh) now reads B as targetable from live BoardState.

### §9 Reset / lifecycle
`reset()` delegates to `dispatcher.reset()` (cancels in-flight, releases their
reservations, frees agents), preserves already-CLEARED cells and unchanged
candidate truth, does not rewind owner ids, and is re-entry-safe (dispatcher
guard). A stale completion after reset cannot clear (no longer arrival-pending →
preflight rejects). Tests: `_run_m20_reset_lifecycle_tests`.

### §10 Synchronized post-arrival tuple
`_run_m20_clear_transaction_tests` asserts, after a successful arrival: target
CLEARED; absent from its color candidate bucket; ProductionAccessQuery treats the
cell as OPEN; reservation owner == -1 and owner target == -1; dispatcher no longer
has the owner and active_count 0; renderer pixel alpha == 0 via RGBA8-tolerant
`_colors_close` (AL-002).

### §11 Scenario matrix
`_run_m20_scenario_matrix_tests`: one-cell board; one-color repeated-until-
exhausted; multi-color board; five configured slots; five distinct simultaneous
in-flight assignments; no-target; fully-enclosed no-spawn; newly-opened-after-
clear (§8 section); Easy 24×24 / Medium 34×34 / Hard 44×44 / Very Hard 54×54;
59×59 maximum; rectangular 53×59; rapid 40-iteration (28 targets, ≥25 cycles)
sequential activate/arrival; reset with multiple in-flight agents; desync
adversaries (§§5–9). The scale/reachability/clearing spine uses real production
dependencies, not a single toy stack; doubles are used only for the two forced
rollback paths.

### §12 Performance / architecture
A successful clear performs one BoardState cell mutation, one single-cell
`sync_cell`, one O(1) `resolve_arrival`, and (with a renderer) one single-cell
`update_cells` — no full board scan in M20 code, no second access cache, no
one-node-per-cell.

### §13 M21+ boundary
No artwork load/generation, no real-art slice, no slot UI, no scoring/win/lose/
session completion, no progression/save/economy, no auto-next-dispatch, no slot
queue/cooldown/consumption, no palette/ACTIVE-CLEARED change. Grep of
`complete_clearing_loop.gd` shows the forbidden terms only in exclusion comments.

### §14 Documentation
`docs/02_TECH_ARCHITECTURE.md` records the M20 clearing-loop seam: it owns the
cross-module arrival transaction; M19 remains assignment/agent orchestration;
access truth updates by reading BoardState live; no win/session policy introduced.
Historical audit evidence untouched.

### §15 Validation (run individually)
- `godot --version` → `4.7.1.stable.official.a13da4feb`.
- `godot --headless --path . -s res://tests/run_tests.gd` → `Total checks: 3386 /
  Failures: 0 / RESULT: ALL PASS`, exit 0.
- `git diff --check` → clean (only a benign LF→CRLF advisory on the pre-existing
  owner-modified `project.godot`, not staged by this cycle).
- Changed-file list: see "Files changed" above.
- Scope grep: no win/scoring/session-complete/queue/cooldown behavior added.
- TASKS lifecycle before: READY_FOR_NEXT_TASK / CHATGPT (M20 prep). Start:
  IN_PROGRESS / CLAUDE (`d38bffc`). After: AWAITING_AUDIT / CHATGPT.
- Leak-at-exit warnings (60 ObjectDB / 1 CanvasItem RID / 9 resources) confirmed
  identical on the pre-M20 baseline run (3273 checks) — pre-existing, not an M20
  regression. No fatal Godot errors, no script/parse errors.

### §16 Governance / handoff
Modified only the authorized surfaces. Did NOT mark COMPLETE/READY_FOR_NEXT_TASK
or any SB-M20 checkbox. Progress unchanged (290/719 = 40.33% main+ui; 290/943 =
30.75% overall; lastCompletedTaskId M19-C001-V06). Tracker set to AWAITING_AUDIT /
Required Actor CHATGPT. Implementation + tests + doc + log + tracker handoff
committed and pushed; remote `origin/main` verified to carry the handoff.

Return: `AWAITING_AUDIT`.
