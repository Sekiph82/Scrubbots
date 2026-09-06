# M18-C001 — Scrubbot Agent (V01)

Status: **ISSUED — first implementation cycle of milestone M18**

M17 production routing is audited complete.

## Scope

Implement exactly:
- SB-M18-001 Lightweight agent core.
- SB-M18-002 Assigned color.
- SB-M18-003 Assigned target.
- SB-M18-004 Assigned route.
- SB-M18-005 Spawn origin.
- SB-M18-006 Route movement.
- SB-M18-007 Arrival detection.
- SB-M18-008 Completion event.
- SB-M18-009 Despawn.
- SB-M18-010 No return-to-slot.
- SB-M18-011 No resource carrying.
- SB-M18-012 Reset cancellation.
- SB-M18-013 No orphan nodes.
- SB-M18-014 Performance stress test.
- SB-M18-015 Pool only if profiling justifies it.

Do NOT implement M19 Dispatcher or M20 vertical slice.

## First action

Work in:
`C:\Users\sekip\Desktop\ScrubBots`

Safely sync main with origin/main while preserving owner work.

Read:
- CLAUDE.md
- tasks.md
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- docs/01_GAMEPLAY_SPEC.md
- docs/02_TECH_ARCHITECTURE.md
- docs/05_TECH_DECISIONS.md
- M16 routing contract
- production_access_query.gd
- production_routing_system.gd
- M17 owner decision + M17-C002 audit
- this prompt
- M18 audit criteria

## Architecture

Create a lightweight ScrubbotAgent, preferably:
`scripts/gameplay/agents/scrubbot_agent.gd`

It owns only one in-flight visual movement instance.

Required assigned data:
- owner_id
- color_id
- target_index
- RouteResult / detached route points
- spawn_origin
- movement progress/state

It does NOT:
- select targets
- reserve targets
- compute routes
- clear BoardState
- own scoring
- carry resources/colors back
- return to slot
- dispatch another bot

## Movement contract

Consume an already-valid successful RouteResult.

Move along the route in board-local coordinate space.

Use deterministic route-distance progression, not per-frame point skipping.

Recommended:
- speed in board-local cell units / second
- traverse consecutive polyline segments
- support large delta safely
- exact final snap to route endpoint

Do not bake screen pixels into movement truth.

Presentation transform to screen coordinates belongs to the visual/container layer.

## Lifecycle

Suggested states:
- IDLE / UNASSIGNED
- MOVING
- ARRIVED
- CANCELLED
- COMPLETED / DESPAWN_PENDING

Exact enum names may vary.

Assignment must validate:
- valid owner_id
- valid color_id
- valid target_index
- successful RouteResult
- result target matches assigned target
- >=2 route points
- first point matches spawn origin
- last point is target endpoint

Invalid assignment fails closed.

## Arrival

Arrival means:
- route traversal reached the final route point;
- emit completion/arrival exactly once;
- do NOT mutate BoardState;
- do NOT release ReservationState;
- do NOT clear target;
- do NOT return to slot.

Later M19/M20 orchestration owns those actions.

## Completion event

Provide a narrow signal/callback carrying enough identity for orchestration, e.g.:
- owner_id
- target_index
- color_id

Signal fires exactly once.

## Despawn

Agent may queue_free itself after completion, or expose a deterministic completion/despawn seam.

If auto-despawn is used:
- completion event must fire first;
- no orphan child/timer/tween nodes may remain;
- no deferred callback may mutate after cancellation/reset.

## Reset cancellation

Provide explicit cancel/reset behavior.

After cancellation:
- movement stops;
- no arrival/completion signal fires afterward;
- agent can be safely freed;
- no orphan tween/timer/node remains.

## No return behavior

After arrival:
- agent disappears/completes;
- it never traverses a return path;
- no return route is created.

## No resource carrying

Agent visual/state must not model:
- carried cell color
- resource inventory
- return payload
- slot delivery

Assigned color is identity/presentation metadata only.

## Visual debug scene

Create a minimal debug scene if useful:
`scenes/debug/scrubbot_agent_debug.tscn`

This is not final Scrubbot art.

Use simple debug geometry/marker only.

Do not open M27 final visuals early.

## Performance

Stress lightweight agents without production Dispatcher.

At minimum:
- 1
- 5
- 10
- 25
- higher-density stress

Use precomputed valid routes.

Measure CPU/node behavior only.
No FPS/GPU claim from headless timing.

Pooling rule:
- do NOT introduce pooling by default;
- only add pool architecture if profiling/test evidence shows lifecycle allocation is materially problematic;
- otherwise explicitly record “pooling not justified yet”.

## Required tests

At minimum prove:

1. valid assignment succeeds;
2. invalid owner rejected;
3. invalid color rejected;
4. invalid target rejected;
5. failed RouteResult rejected;
6. route target mismatch rejected;
7. spawn origin mismatch rejected;
8. assigned color retained;
9. assigned target retained;
10. detached assigned route retained safely;
11. movement begins at spawn origin;
12. small delta advances correctly;
13. large delta traverses multiple segments correctly;
14. zero delta does not move;
15. route endpoint is reached exactly;
16. arrival emitted exactly once;
17. completion identity is correct;
18. BoardState not mutated;
19. ReservationState not mutated;
20. no return movement after arrival;
21. no resource-carry state/API;
22. cancel before arrival stops movement;
23. cancel prevents later completion;
24. repeated cancel is safe;
25. freeing cancelled agent leaves no orphan nodes;
26. freeing completed agent leaves no orphan nodes;
27. 5-agent concurrent movement;
28. 10-agent concurrent movement;
29. 25-agent concurrent movement;
30. stress >25 agents;
31. deterministic repeated movement for same route/delta sequence;
32. 59×59 route coordinate compatibility;
33. rectangular Very Hard route compatibility;
34. no TargetSelector call;
35. no route computation call;
36. no Dispatcher implementation;
37. full Godot 4.7.1 suite passes;
38. debug scene smoke if scene added.

## Locked production routing

Use ADR-025 current production direction:
- Organized/curved movement language
- Grid-aware deterministic backbone
- Direct debug only

M18 consumes a finished route. It must not care how the route was computed.

## Documentation

Update current-law docs only if needed.

Add ADR only if M18 introduces a durable architecture choice not already obvious from existing rules.

## Governance

Claude must NOT modify:
- tasks.md
- .hiveai/*
- coordination/SESSION_INDEX.md
- coordination/AUDIT_INDEX.md
- any CHATGPT audit file

## Validation

Run:
- godot --version
- full headless tests
- git diff --check
- debug scene smoke if added

Write:
`coordination/sessions/M18-C001/CLAUDE_LOG_V01.md`

Commit/push safely.

Return:
`AWAITING_AUDIT`

Then stop.
