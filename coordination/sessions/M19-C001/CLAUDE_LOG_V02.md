# CLAUDE_LOG_V02 — M19-C001 Frozen Full-Surface Dispatcher Closure V02

Cycle: M19-C001
Prompt: coordination/sessions/M19-C001/CHATGPT_PROMPT_V02.md
Criteria: coordination/sessions/M19-C001/CHATGPT_AUDIT_CRITERIA_V02.md
Actor: CLAUDE (implementation + tests only; no self-audit verdict)
Handoff: AWAITING_AUDIT

## Synced starting commit

- Synced `origin/main` HEAD before implementation: `28d7f57` (start-transition
  commit, below). Prior to the start transition, main was at `143bf5a`
  ("docs: align M19 V02 criteria/prompt with H!veAI tracker v3").
- Safe fast-forward only; pre-existing owner working-tree changes
  (`project.godot`, `scenes/debug/*.tscn`) preserved untouched throughout.

## H!veAI starting state (read from synced .hiveai/TASKS.md)

- currentTaskId: `M19-C001-V02`
- currentMilestone: `M19 — Scrubbot dispatcher orchestration`
- currentSprint: `M19-C001 V02 — frozen full-surface dispatcher closure`
- workflowState: `CHANGES_REQUIRED`
- requiredActor: `CLAUDE`
- progress: `278 / 719 = 38.66%` main+UI
- Authorized implementation for actor CLAUDE; no blocker naming another actor.

## Start transition / push evidence (CHANGES_REQUIRED -> IN_PROGRESS)

- Updated `.hiveai/TASKS.md` machine block + human sections to
  `workflowState: IN_PROGRESS`, `requiredActor: CLAUDE`.
- Appended `hiveai-event/v1` WORKFLOW_CHANGED row (from CHANGES_REQUIRED to
  IN_PROGRESS), id `93073256-a5b1-40a1-800b-b16873c3ccea`.
- Committed + pushed BEFORE implementation: commit `28d7f57`, pushed to
  `origin/main` (`143bf5a..28d7f57`).

## Godot version

`4.7.1.stable.official.a13da4feb`

## Exact changed files

Production (`scripts/gameplay/dispatch/*` + one read-only selector coherence method):
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` — rewritten hardening.
- `scripts/gameplay/dispatch/production_target_access.gd` — fail-closed probe.
- `scripts/gameplay/dispatch/dispatch_result.gd` — +COHERENCE_FAILED, +REENTRANT.
- `scripts/gameplay/targeting/target_selector.gd` — +read-only `is_bound_to(board, reservation_state)` (no selection-semantics change).

Tests / support:
- `tests/run_tests.gd` — `_run_m19_strict_v2_tests()` (full V02 matrix) + updated
  `_m19_wire_fake` (permissive routing_access) + reworked assign-failure test.
- `tests/support/dispatch_routing_double.gd` — route-fault modes + `on_compute` reset hook.
- `tests/support/dispatch_agent_double.gd` — NEW: ScrubbotAgent subclass (assign-fail / reset-inject).
- `tests/support/access_query_double.gd` — +`is_coherent_with` (default true) + reset hook doc.
- `tests/support/route_access_query_double.gd` — +`bind_board`/`is_bound_to` (usable as dispatcher routing_access).

No BoardState / ReservationState / routing-algorithm / ScrubbotAgent core
behavior was modified. No M20 clearing/scoring/arrival resolution added.

## Frozen finding-by-finding implementation

### F-M19-STRICT-001 — bind fail-closed + bundle coherence + live drift
- `bind()` is initialization-only (second bind returns false, preserves the
  bound bundle / `_active` / reservations / active agent).
- Fresh bind validates BEFORE committing any ref: board `is BoardState`;
  selector/reservations are RefCounted with the narrow API; routing_system /
  routing_access / select_access are objects with their required seam; optional
  `agent_parent` is a live Node not queued for deletion; `agent_factory` is empty
  or a valid Callable. Scalars/junk/partial deps fail closed, no refs, no fault.
- Bundle coherence proven at bind AND re-checked live before every dispatch:
  `selector.is_bound_to(board, reservations)`, `reservations.is_bound_to(board)`,
  `routing_access.is_bound_to(board)`, and (when present)
  `select_access.is_coherent_with(board, routing_system, routing_access)`.
  Drift after bind -> `COHERENCE_FAILED` before any new reservation.
- Added read-only `TargetSelector.is_bound_to(board, reservation_state)` and
  `ProductionTargetAccess.is_coherent_with(board, routing_system, routing_access)`
  (exact reference identity; no behavior change).

### F-M19-STRICT-002 — validate external route/access/agent-factory results
- `ProductionTargetAccess`: fail-closed for non-BoardState board, malformed
  routing system/access, non-finite origin (memo cleared), invalid index,
  malformed/mismatched/invalid-geometry route. Success memoized ONLY after
  `RouteValidator.validate_route` is clean; failed probe clears stale memo;
  `set_origin` clears memo; `consume_route` is ONE-SHOT.
- Dispatcher route seam: cached (`consume_route`) and freshly computed routes go
  through ONE shared `_route_ok` = real RouteResult + exact reserved target +
  RouteValidator-clean. Malformed/mismatched/invalid -> release reservation, no
  agent, `ROUTE_FAILED`, no retarget.
- Agent factory/parent: only a fresh, valid, UNASSIGNED, unparented
  ScrubbotAgent/subclass is dispatcher-ownable. Invalid/foreign product ->
  `AGENT_ASSIGN_FAILED`, reservation released, no dispatcher child, and the
  foreign object is neither freed nor mutated. Parent re-validated (live, not
  queued-for-delete) before `add_child`.

### F-M19-STRICT-003 — serial re-entry + reset generation + completion identity
- Dispatch-in-progress guard: recursive dispatch from an injected callback ->
  `REENTRANT`, no reservation/agent/owner-id.
- Reset generation token: `reset()` increments `_generation`; dispatch captures
  it and, after every external-callback boundary (selection, routing/consume,
  factory, assign, add_child), aborts if it moved — releasing the pending
  reservation and freeing any dispatcher-owned fresh agent — returning
  `RESETTING`. Committed active agents are cancelled/freed and their reservations
  released by `reset()`; BoardState untouched; owner ids stay monotonic.
- Completion identity: `_active` stores immutable owner/target/color/agent; the
  completion callback is bound to its agent, and completion is accepted only on
  exact owner+target+color+agent match. Mismatched/stale ignored; repeated
  correct completion idempotent; post-reset completion cannot recreate state.

### F-M19-STRICT-004 — non-finite / non-positive speed
- Request boundary before any side effect: reject `color < 0`, non-finite
  origin, and `not is_finite(speed) or speed <= 0.0` (NaN/+INF/-INF/0/negative).
  Proven: no selector/reservation/routing/factory call and no owner-counter
  advance on any invalid request; finite positive speed preserves success.

## Full-suite result

- Command: `godot --headless --path . --script res://tests/run_tests.gd`
- Result: **Total checks: 2780 — Failures: 0 — RESULT: ALL PASS**
- Includes the full V02 adversarial matrix (`_run_m19_strict_v2_tests`) plus the
  preserved M15/M16/M17/M18 strict regressions and the real
  ProductionTargetAccess + ProductionRoutingSystem integration (reachable
  success, enclosed no-work, 59x59, rectangular Very Hard, 5-slot burst, 25+
  rapid sequential stress).

## `git diff --check`

Clean (exit 0). Only informational LF->CRLF working-copy warnings; no whitespace
errors.

## Failed attempts and fixes

1. Enforcing `RouteValidator` in the deterministic-fake dispatcher tests made the
   fake straight-through-blocker routes invalid against `ProductionAccessQuery`.
   Fix: `_m19_wire_fake` now injects a permissive, board-bound
   `RouteAccessQueryDouble` as routing_access (production wiring keeps the real
   access truth), so the shared validator is exercised without spurious blocks.
2. `mismatch` (wrong-start) routing now correctly fails at `ROUTE_FAILED`
   (validated pre-agent), not `AGENT_ASSIGN_FAILED`. The assign-failure
   regression was re-expressed with a fresh, ownable `DispatchAgentDouble`
   whose `assign()` returns false.
3. A nested single-line lambda (`func(): ... a.on_assign = func(): drs.reset(); return a`)
   was mis-parsed so the factory returned null; rewritten as a multi-line lambda.
4. The add-child-phase reset proved not synchronously reproducible: the engine
   delivered `child_entered_tree` deferred, so the reset lands after dispatch
   returns. The generation guard after `add_child` still covers the boundary in
   production code; the test now asserts the clean-rollback invariants only when
   the reset lands synchronously (criteria 86: "where reproducible") and records
   the deferred case otherwise.

## Final H!veAI handoff state

- `.hiveai/TASKS.md`: `workflowState: AWAITING_AUDIT`, `requiredActor: CHATGPT`,
  currentTaskId/milestone/sprint remain M19-C001-V02 / M19 / M19-C001 V02,
  blockers `[]`, progress unchanged `278 / 719 = 38.66%` main+UI,
  `lastCompletedTaskId` unchanged (`FOUNDATION-C001-V01`).
- `.hiveai/EVENTS.jsonl`: appended WORKFLOW_CHANGED (IN_PROGRESS -> AWAITING_AUDIT).
- No self-audit verdict. Independent ChatGPT audit of this log + the pushed
  implementation against `CHATGPT_AUDIT_CRITERIA_V02.md` is the next step.
