---
coordinationSchema: scrubbots-coordination/v4
artifactType: claude-log
cycleId: M19-C001
version: 01
actor: CLAUDE
status: AWAITING_AUDIT
promptUrl: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M19-C001/CHATGPT_PROMPT_V01.md
criteriaUrl: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M19-C001/CHATGPT_AUDIT_CRITERIA_V01.md
startingCommit: cd827223eedf4965542c39318cca65f2944d37d1
currentCommit: uncommitted-at-write-time
---

# SCRUBBOTS — Claude Log V01

Evidence for exactly CHATGPT_PROMPT_V01.md (M19-C001). Claude does not audit
itself. Scope: SB-M19-001..012 — the ScrubbotDispatcher orchestration layer. No
M20 cell-clearing / arrival-resolution / scoring vertical slice.

## Inputs read

- CLAUDE.md (all owner overrides; §3 locked params, §4 module boundary, the
  GitHub-only-logging and coordination-ownership overrides).
- coordination/sessions/M19-C001/CHATGPT_PROMPT_V01.md, CHATGPT_AUDIT_CRITERIA_V01.md.
- coordination/sessions/M18-C001/CHATGPT_AUDIT_V01.md (M18 ScrubbotAgent audited complete).
- scripts/gameplay/targeting/target_selector.gd (M15, select_and_reserve + is_targetable seam).
- scripts/gameplay/targeting/reservation_state.gd (M14, atomic ownership, release/release_for_owner).
- scripts/gameplay/routing/production_routing_system.gd, production_access_query.gd (M16/M17 production HOW).
- scripts/gameplay/routing/route_request.gd, route_result.gd (the consumed contracts).
- scripts/gameplay/agents/scrubbot_agent.gd (M18, assign()/advance()/cancel()/agent_completed).
- scripts/gameplay/targeting/color_candidate_index.gd, slots/slot_system.gd, board/board_state.gd.
- scripts/gameplay/routing/prototypes/routing_lab_scenarios.gd, scripts/debug/board_debug_fixtures.gd.
- tests/run_tests.gd, tests/support/access_query_double.gd (harness + selector double conventions).
- docs/05_TECH_DECISIONS.md (ADR-022/023/024/025/026).

## Repository start state

- Branch `main`, synced to `origin/main` via `git fetch` + `git merge --ff-only`
  (0 ahead / 18 behind → fast-forwarded to `cd82722`). No destructive ops.
- Owner-modified tracked files present at start and PRESERVED untouched:
  `project.godot`, `scenes/debug/routing_prototype_lab.tscn`. Verified the 18
  incoming commits do not touch either before fast-forwarding
  (`git diff --name-only HEAD origin/main -- <those two>` → empty).
- Numerous untracked owner/generated artifacts (`*.uid`, `_owner_inbox/*.import`,
  `docs/logs/`, a stray scratchpad file) left untouched and NOT staged. No
  `*.uid` file is tracked anywhere in the repo (`git ls-files "*.uid"` empty), so
  the new scripts' generated `.uid` files are likewise left untracked.

## What was implemented

New production module `scripts/gameplay/dispatch/` (ADR-027, added to
docs/05_TECH_DECISIONS.md):

- `scrubbot_dispatcher.gd` (`Node`) — orchestration only. `dispatch(color_id,
  start_position, speed)` runs the canonical flow synchronously:
  `select_and_reserve` (using the injected reachability truth) → build
  `RouteRequest.for_target` → `compute_route` → on route failure
  `reservations.release()` + spawn nothing (no retarget) → on success
  instantiate exactly one `ScrubbotAgent`, `assign()` it → on assign failure
  release + `agent.free()` + spawn nothing → on success `add_child` + connect
  completion + record bookkeeping. Returns a detached `DispatchResult`.
  - SB-M19-001 receive slot/color request; SB-M19-002 work check via selector
    access truth (a raw candidate is not enough); SB-M19-003 ask TargetSelector;
    SB-M19-004 refuse spawn without a reachable target; SB-M19-005 reserve;
    SB-M19-006 spawn exactly one; SB-M19-007 one-by-one; SB-M19-008 no duplicate
    assignment (ReservationState gate); SB-M19-009 dispatch failure handling;
    SB-M19-010 rapid input; SB-M19-011 concurrent slots; SB-M19-012 reset during
    dispatch.
  - Owner ids: dedicated monotonic counter, never a color/slot/target id, never
    restarted (not even on reset) so a stale completion cannot collide.
  - Completion observed for lifecycle bookkeeping only: NO board clear, NO
    release of a successful reservation, NO score (all remain M20). The arrived
    agent and its held reservation are preserved (owner/target mapping intact).
  - `reset()` cancels + removes + frees every active agent, releases
    dispatcher-owned reservations, clears bookkeeping, mutates no BoardState,
    does not restart the id counter, and guards against re-entrant completion.
- `dispatch_result.gd` — detached result: `success`, `owner_id`, `target_index`,
  `agent`, stable `failure_reason` (INVALID_REQUEST, NO_REACHABLE_TARGET,
  ROUTE_FAILED, AGENT_ASSIGN_FAILED, RESETTING).
- `production_target_access.gd` — the PRODUCTION `is_targetable()` reachability
  truth for TargetSelector, backed by the SAME `ProductionRoutingSystem` that
  moves the bot (no second reachability BFS). Memoizes the winning target's route
  so the dispatcher reuses it — one routing computation per successful dispatch.

Test-only: `tests/support/dispatch_routing_double.gd` (configurable fake routing:
`ok` / `fail` / `mismatch`) for deterministic route-failure and
agent-assign-failure injection.

Boundaries preserved: dispatcher selects nothing, computes no route geometry,
stores no reservation, owns no cell lifecycle. TargetSelector/RoutingSystem stay
separate (CLAUDE.md hard rule 14). No M20 clearing implemented.

## Tests added (tests/run_tests.gd)

Registered `_run_m19_dispatcher_tests`, `_run_m19_dispatcher_production_tests`,
`_run_m19_dispatcher_stress_tests`. Coverage maps to the prompt's 35 required
proofs and the 40 audit criteria, including:

- valid request succeeds; invalid color/origin → INVALID_REQUEST; no raw
  candidates → NO_REACHABLE_TARGET; raw-but-unreachable candidate → no spawn
  (AccessQueryDouble default-false while `has_candidates` true); reachable target
  selected + atomically reserved; exactly one agent per dispatch; agent identity
  (owner/color/target); route endpoint == reserved target centre.
- duplicate target not assigned twice; two independent targets → two unique
  agents; owner ids unique + monotonic across reset (no restart).
- route failure releases reservation + zero spawn + result carries no target
  (no silent retarget); failure-released target dispatchable again; agent-assign
  failure (mismatched route rejected by the real ScrubbotAgent) releases
  reservation + leaves no orphan child node.
- rapid 12 requests over 5 reachable candidates → exactly 5 successes, unique
  owners/targets (one-by-one); BoardState unmutated by dispatch.
- successful reservation still held after dispatch; agent completion (driven to
  arrival) does NOT clear BoardState (target still ACTIVE) and does NOT release
  the reservation in M19.
- reset cancels active agents, leaves zero child nodes, releases reservations,
  mutates no BoardState, then new dispatch works.
- REAL production pipeline (ColorCandidateIndex + TargetSelector +
  ProductionRoutingSystem + ProductionAccessQuery + ProductionTargetAccess):
  single reachable target dispatches with a real route; enclosed sole candidate
  → NO_REACHABLE_TARGET (real routing reachability); 59×59 coverage (three
  reachable targets, three unique owners, no board mutation); rectangular Very
  Hard 53×59 coverage.
- 5-slot concurrent burst (five unique agents); 25-request rapid stress (30
  requests, 25 unique reachable → 25 successes, unique owners/targets).

## Validation evidence

- `godot --version` → `4.7.1.stable.official.a13da4feb`.
- `godot --headless --path . -s res://tests/run_tests.gd`:

  ```
  ==== SCRUBBOTS test summary ====
  Total checks: 1564
  Failures: 0
  RESULT: ALL PASS
  ```

  (Prior baseline before M19 additions was 1462 checks; the M19 blocks add the
  new checks with zero failures. Full suite — dimensions, validation, renderer,
  routing M16/M17/M17-C002, M18 agent, M19 dispatcher — all pass.)
- `git diff --check` → no whitespace errors (only benign LF→CRLF advisory
  warnings on files Git will normalize; no content change forced).

## Performance evidence (headless CPU/node only — NO FPS/GPU claim)

- M19 rapid-input stress: 30 rapid dispatches (25 reachable) completed in
  ~0.8 ms of CPU (`Time.get_ticks_usec`), each dispatch synchronous through
  selection/reservation/route/assignment.
- Pooling: NOT justified. Agents are childless Node2Ds with no per-frame
  allocation; 30 rapid create/assign/attach dispatches cost a fraction of a ms.
  Deferred per prompt ("no pooling unless profiling proves it necessary").

## Governance / boundaries honored

- Did NOT modify: tasks.md, `.hiveai/*`, coordination/SESSION_INDEX.md,
  coordination/AUDIT_INDEX.md, any CHATGPT_AUDIT file (coordination-ownership +
  GitHub-only-logging owner overrides).
- No self-audit, no audit verdict assigned.
- Owner-modified `project.godot` / routing_prototype_lab.tscn preserved,
  unstaged.
- No destructive git ops. No secrets. Docs updated (ADR-027) per hard rule 19.

## Files changed in this cycle

- A `scripts/gameplay/dispatch/scrubbot_dispatcher.gd`
- A `scripts/gameplay/dispatch/dispatch_result.gd`
- A `scripts/gameplay/dispatch/production_target_access.gd`
- A `tests/support/dispatch_routing_double.gd`
- M `tests/run_tests.gd` (M19 test blocks + preloads + registration)
- M `docs/05_TECH_DECISIONS.md` (ADR-027)

## Handoff

State: **AWAITING_AUDIT**. ChatGPT owns the independent audit and all
SESSION_INDEX / H!veAI / dashboard updates.
