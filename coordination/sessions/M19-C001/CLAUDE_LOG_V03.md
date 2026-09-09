# CLAUDE_LOG_V03 — M19-C001 Strict-v2 Orchestrator Closure V03 (second stage)

Cycle: M19-C001
Prompt: coordination/sessions/M19-C001/CHATGPT_PROMPT_V03.md
Criteria: coordination/sessions/M19-C001/CHATGPT_AUDIT_CRITERIA_V03.md
Basis: coordination/sessions/M19-C001/CHATGPT_AUDIT_V02.md (CHANGES_REQUIRED / STRICT_V2_SECOND_STAGE_REQUIRED)
Actor: CLAUDE (implementation + tests only; no self-audit verdict)
Handoff: AWAITING_AUDIT

## Synced starting commit

- Synced `origin/main` before implementation. Fast-forward from `358c3c6`
  ("audit: index M19 V02 second-stage findings") to the V03 start transition
  `3e0b2a4`. Pre-existing owner working-tree changes (`project.godot`,
  `scenes/debug/*.tscn`) preserved untouched throughout.

## H!veAI starting state (read from synced .hiveai/TASKS.md)

- currentTaskId `M19-C001-V03`; workflowState `CHANGES_REQUIRED`;
  requiredActor `CLAUDE`; progress `278 / 719 = 38.66%` main+UI. Authorized.

## Start transition (CHANGES_REQUIRED -> IN_PROGRESS)

- Updated `.hiveai/TASKS.md` machine block + human sections to IN_PROGRESS.
- Appended `hiveai-event/v1` WORKFLOW_CHANGED (CHANGES_REQUIRED -> IN_PROGRESS),
  id `c157095c-87ac-4dd6-8934-253c9973f942`.
- Committed + pushed BEFORE implementation: commit `3e0b2a4`
  (`358c3c6..3e0b2a4`).

## Godot version

`4.7.1.stable.official.a13da4feb`

## Exact changed files

Production:
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` — all V03 corrections
  (the other dispatch/targeting files were already accepted at V02 and are
  unchanged this cycle).

Tests / support (new doubles + V03 matrix):
- `tests/run_tests.gd` — `_run_m19_strict_v3_tests()` + helpers
  (`_m19_collab_dispatcher`, `_m19_wire_cache`) + new preloads.
- `tests/support/m19_collab_double.gd` — NEW: flexible coherent collaborator with
  coherence hooks/counters.
- `tests/support/m19_node_collab_double.gd` — NEW: method-compatible Node (category rejection).
- `tests/support/m19_select_access_variants.gd` — NEW: configurable coherence verdict.
- `tests/support/m19_no_coherence_select.gd` — NEW: select_access lacking is_coherent_with.
- `tests/support/m19_cache_select_access.gd` — NEW: set_origin/consume_route seam + hooks.
- `tests/support/lying_agent_double.gd` — NEW: assign() returns true while lying.
- `tests/support/agent_factory_holder.gd` — NEW: explicit-factory Callable target.

No BoardState / ReservationState / routing-algorithm / ScrubbotAgent core change;
no M20 behavior.

## Finding-by-finding second-stage closure (mapped to V03 criteria)

### F-M19-STRICT-001.A — mandatory select_access coherence (crit 7-13)
- `_SELECT_ACCESS_API` now requires `is_targetable` AND `is_coherent_with`;
  `_bundle_coherent` always queries `is_coherent_with` (no has_method exemption).
- Direct tests: missing is_targetable rejected; missing is_coherent_with
  rejected; non-bool verdict rejected; false verdict rejected; exact coherent
  ProductionTargetAccess and AccessQueryDouble accepted; same-shape
  different-board ProductionTargetAccess rejected.

### F-M19-STRICT-001.B — RefCounted collaborator lifecycle (crit 14-20)
- selector/reservations/routing_system/routing_access/select_access are now all
  validated via `_is_ref_with` (RefCounted + narrow API). `_is_object_with` was
  removed. Only `agent_parent` remains a Node.
- Direct tests: a method-compatible Node in each collaborator slot is rejected;
  canonical RefCounted dependencies still bind; a valid Node agent_parent still binds.

### F-M19-STRICT-003.A — guard armed before live coherence (crit 21-31)
- `_in_dispatch = true` and `my_gen = _generation` are set BEFORE the first live
  `_bundle_coherent` call.
- Direct tests: recursive dispatch injected from each coherence seam
  (selector/reservation/routing-access/select-access) returns REENTRANT and
  advances no owner id; reset injected from a coherence seam returns RESETTING,
  selection never begins, the guard clears, and a later dispatch recovers.

### F-M19-STRICT-003.B — generation check after every boundary (crit 32-41)
- Added generation checks immediately after `set_origin` and after
  `consume_route` (the previously missing boundaries), plus the existing ones.
- Direct tests: reset during set_origin -> RESETTING, no selector call, no
  reservation; reset during consume_route -> RESETTING, ZERO fresh routing
  compute, pending reservation released; later dispatch recovers; owner ids stay
  monotonic.

### F-M19-STRICT-001.C / 003.C — mid-dispatch bundle drift (crit 42-52)
- Exact bundle coherence is re-checked after the selection, routing, factory and
  assign boundaries; drift -> release pending reservation + COHERENCE_FAILED,
  never committing `_active`, never freeing prior committed assignments.
- Direct tests: select-access drift during selection, routing-access drift during
  routing, coherence drift during factory and during assign each abort with
  COHERENCE_FAILED, no orphan agent, pending reservation released, the prior
  committed assignment survives, and a later coherent dispatch recovers.

### F-M19-STRICT-002.A — missing vs invalid cached route (crit 53-64)
- `consume_route` null -> fresh compute permitted; a NON-NULL cached route that
  fails shared validation is a route-seam failure (release + ROUTE_FAILED, NO
  fresh compute).
- Direct tests (routing `call_count` observed): null cache computes once; scalar,
  junk, failure, wrong-target, wrong-start, wrong-end and non-finite cached
  routes each yield ROUTE_FAILED with ZERO fresh compute, released reservation
  and zero agent; a valid cached route succeeds and skips compute.

### F-M19-STRICT-002.B — explicit factory Callable drift (crit 65-71)
- `_explicit_factory` records whether a valid Callable was supplied at bind;
  `_make_agent` returns null (fail closed, no default substitution) if an explicit
  factory later becomes invalid.
- Direct test: bind an explicit `Callable(holder, "make_agent")`, first dispatch
  succeeds, free the holder, next dispatch -> AGENT_ASSIGN_FAILED with no default
  agent and its pending reservation released.

### F-M19-STRICT-002.C — assign postconditions (crit 72-81)
- After `assign()==true`, `_agent_assigned_ok` requires the exact agent to be
  valid, unparented, MOVING, and to record this dispatch's owner/color/target.
- Direct tests: a lying subclass that stays UNASSIGNED, or records a wrong
  owner/color/target, or parents itself during assign, each fail with
  AGENT_ASSIGN_FAILED, released reservation, freed dispatcher-owned agent, no
  child/_active; a truthful subclass is still accepted MOVING.

### Preserved (crit 82-145)
- All V02 hardening and M15-M18 strict regressions remain green in the same run:
  initialization-only bind, exact selector/reservation/routing coherence,
  ProductionTargetAccess RouteValidator memo discipline, fresh-route validation,
  foreign factory-product protection, finite request validation, reset
  generation, completion identity, ordinary rollback, 5-slot burst, 25+ rapid
  sequential stress, real ProductionTargetAccess + ProductionRoutingSystem
  success, enclosed no-work, 59x59, rectangular Very Hard, and no M20 behavior.
  F-M19-STRICT-004 remains closed.

## Full-suite result

- Command: `godot --headless --path . --script res://tests/run_tests.gd`
- Result: **Total checks: 2892 — Failures: 0 — RESULT: ALL PASS**
- Zero `SCRIPT ERROR` / `Parse Error` lines in the run.

## `git diff --check`

Clean (exit 0). Only informational LF->CRLF warnings; no whitespace errors.

## Failed attempts and fixes

1. `M19NodeCollabDouble` (extends Node) originally declared `get_owner(int)`,
   which collides with `Node.get_owner()` and, under warnings-as-errors, failed
   to compile (masking its bind-rejection tests). Removed `get_owner` from the
   Node double (it is rejected on the RefCounted-category check before any method
   is consulted). Suite then ran the full matrix cleanly (2892/2892).

## Final H!veAI handoff state

- `.hiveai/TASKS.md`: `workflowState: AWAITING_AUDIT`, `requiredActor: CHATGPT`,
  currentTaskId/milestone/sprint remain M19-C001-V03 / M19 / M19-C001 V03,
  blockers `[]`, progress unchanged `278 / 719 = 38.66%`, `lastCompletedTaskId`
  unchanged (`FOUNDATION-C001-V01`).
- `.hiveai/EVENTS.jsonl`: appended WORKFLOW_CHANGED (IN_PROGRESS -> AWAITING_AUDIT).
- No self-audit verdict. Independent ChatGPT V03 audit of this log + the pushed
  implementation against `CHATGPT_AUDIT_CRITERIA_V03.md` is the next step.
