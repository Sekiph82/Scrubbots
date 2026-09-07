# M19-C001 — Scrubbot Dispatcher (V01)

Status: **ISSUED — first implementation cycle of milestone M19**

M18 ScrubbotAgent is audited complete.

## Scope

Implement exactly:
- SB-M19-001 Receive slot request.
- SB-M19-002 Check work before spawn — "work" means a reachable/targetable target exists, not merely a raw color candidate.
- SB-M19-003 Ask TargetSelector.
- SB-M19-004 Refuse spawn without a reachable target.
- SB-M19-005 Reserve target.
- SB-M19-006 Spawn exactly one bot per dispatch.
- SB-M19-007 Enforce one-by-one flow.
- SB-M19-008 Prevent duplicate assignments.
- SB-M19-009 Handle dispatch failure.
- SB-M19-010 Handle rapid input.
- SB-M19-011 Concurrent slot tests.
- SB-M19-012 Reset during dispatch.

Do NOT implement M20 cell-clearing vertical slice yet.

## First action

Work in:
`C:\Users\sekip\Desktop\ScrubBots`

Safely sync main with origin/main and preserve owner work.

Read:
- CLAUDE.md
- tasks.md
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- M14 ReservationState
- M15 TargetSelector
- M16/M17 production routing
- M18 ScrubbotAgent + M18 audit
- current gameplay/architecture ADRs
- this prompt + M19 audit criteria

## Architecture

Create:
`scripts/gameplay/dispatch/scrubbot_dispatcher.gd`

Dispatcher owns orchestration only.

Canonical dispatch flow:

```text
slot/color request
-> validate work using TargetSelector access truth
-> select_and_reserve()
-> build RouteRequest
-> ProductionRoutingSystem.compute_route()
-> if route fails: release reservation, spawn nothing
-> if route succeeds: instantiate exactly one ScrubbotAgent
-> assign() agent with owner/color/target/request/route
-> if assign fails: release reservation, free agent, spawn nothing
-> if assign succeeds: hand out/attach exactly one agent
```

Do NOT:
- clear BoardState
- resolve arrival
- release successful reservation on arrival
- score
- retarget after route failure
- spawn a second fallback bot

M20 will wire arrival -> clear -> candidate sync -> reservation resolution.

## Work validation

A raw matching-color candidate is NOT sufficient.

Dispatcher must rely on TargetSelector's reachability/access truth.

No target:
- no reservation
- no route
- no agent
- clean failure result

## Owner IDs

Dispatcher must generate unique monotonically increasing owner/assignment IDs for successful dispatch attempts.

Never use:
- color_id
- slot index
- target index

as the reservation owner token.

Reset may restart the counter only if no stale assignment collision can exist; otherwise keep monotonic for dispatcher lifetime.

## One-by-one flow

One slot request produces at most one ScrubbotAgent.

No batch spawn from one request.

Rapid input may produce multiple independent dispatch attempts, but each call:
- is synchronous through selection/reservation/route/assignment
- either succeeds with one unique assignment
- or cleanly fails with zero spawn

## Failure rollback

If failure occurs after reservation:
- route failure -> release reservation
- agent creation/assignment failure -> release reservation
- no orphan agent
- target becomes immediately eligible for a later dispatch if still ACTIVE

Never clear the target during rollback.

## Return value

Prefer a detached result object/value equivalent to:

```text
DispatchResult
- success: bool
- owner_id: int
- target_index: int
- agent: ScrubbotAgent or null
- failure_reason: stable StringName
```

Stable failure reasons should cover at least:
- INVALID_REQUEST
- NO_REACHABLE_TARGET
- ROUTE_FAILED
- AGENT_ASSIGN_FAILED
- RESETTING/CANCELLED if needed

## Reset

Explicit reset/cancel-all behavior:

- cancel all active agents
- free/remove active agents safely
- release all reservations owned by dispatcher assignments
- clear dispatcher active-assignment bookkeeping
- no delayed completion callback may mutate dispatcher afterward
- no orphan nodes
- dispatcher becomes ready for new dispatches

Do NOT clear BoardState during reset.

## Completion signal handling

M18 agent completion signal may be observed only to track active-agent lifecycle.

For M19:
- do NOT clear BoardState
- do NOT resolve/release successful reservation on completion
- do NOT score

That remains M20.

If an arrived agent is removed in M19 for lifecycle cleanliness, preserve enough assignment bookkeeping/reservation identity for M20 integration, or defer removal until M20. Do not lose the owner/target mapping.

## Required tests

At minimum prove:

1. valid slot/color request succeeds;
2. invalid color/request fails;
3. no raw candidates -> no spawn;
4. raw candidate but unreachable -> no spawn;
5. reachable target -> selected/reserved;
6. exactly one agent spawned per successful dispatch;
7. agent identity matches owner/color/target;
8. route target matches reservation target;
9. duplicate target cannot be assigned concurrently;
10. two independent reachable targets can yield two unique agents;
11. owner IDs are unique;
12. route failure releases reservation;
13. route failure spawns zero agents;
14. agent assign failure releases reservation;
15. agent assign failure leaves no orphan node;
16. released-after-failure target can dispatch later;
17. rapid repeated requests do not duplicate target ownership;
18. rapid input success count equals unique reachable work;
19. one-by-one flow preserved;
20. no silent retarget after route failure;
21. BoardState not mutated by dispatcher;
22. successful reservation remains held after dispatch;
23. agent completion does not clear BoardState in M19;
24. agent completion does not release reservation in M19;
25. reset cancels active agents;
26. reset releases dispatcher-owned reservations;
27. reset leaves no orphan agents;
28. reset does not clear BoardState;
29. new dispatch works after reset;
30. 5-slot concurrent request test;
31. rapid 25-request stress;
32. 59×59 board coverage;
33. rectangular Very Hard coverage;
34. no M20 clearing implementation;
35. full Godot 4.7.1 suite passes.

## Performance

Measure CPU/node behavior for rapid dispatch bursts.

No FPS/GPU claim from headless timing.

Do not add pooling unless profiling proves it necessary.

## Debug scene

Optional minimal dispatcher debug scene is allowed if useful.

Not production UI.
Not final Scrubbot art.

## Documentation

Update current-law docs and add an ADR only if a durable Dispatcher ownership/lifecycle decision needs one.

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
- full headless suite
- git diff --check
- debug smoke if scene added

Write:
`coordination/sessions/M19-C001/CLAUDE_LOG_V01.md`

Commit/push safely.

Return:
`AWAITING_AUDIT`

Then stop.
