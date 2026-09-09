# M19-C001 — Strict-v2 Orchestrator Closure V03

Status: **ISSUED — SAME FROZEN FINDING SET / SECOND-STAGE CLOSURE**

H!veAI tracking contract: **GitHub-first v3**.

This continues the SAME frozen M19 findings:
- F-M19-STRICT-001
- F-M19-STRICT-002
- F-M19-STRICT-003
- F-M19-STRICT-004 (regression-only; source correction already accepted)

Do not implement M20.

## H!veAI v3

Live authority:
- origin/main
- .hiveai/PROJECT.json
- .hiveai/RULES.md
- .hiveai/TASKS.md
- .hiveai/EVENTS.jsonl

Independent audit separation remains locked.

Claude may move:
`CHANGES_REQUIRED -> IN_PROGRESS -> AWAITING_AUDIT`

Claude may NOT mark:
- COMPLETE
- READY_FOR_NEXT_TASK
- root tasks.md M19 checkboxes [x]

Legacy dashboard/cycle/progress/SESSION_INDEX files are historical only. Do not
refresh them.

Read FIRST:
- .hiveai/RULES.md
- .hiveai/TASKS.md
- .hiveai/PROJECT.json
- CLAUDE.md

Then read:
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/VERSIONED_LOG_POLICY.md
- coordination/sessions/M19-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md
- coordination/sessions/M19-C001/CHATGPT_PROMPT_V02.md
- coordination/sessions/M19-C001/CHATGPT_AUDIT_CRITERIA_V02.md
- coordination/sessions/M19-C001/CLAUDE_LOG_V02.md
- coordination/sessions/M19-C001/CHATGPT_AUDIT_V02.md
- this prompt + V03 criteria

Expected log:
`coordination/sessions/M19-C001/CLAUDE_LOG_V03.md`

## First action — canonical tracker start

Safely sync origin/main and preserve owner work.

Re-read synced .hiveai/TASKS.md.

Expected canonical state:
- currentTaskId: M19-C001-V03
- workflowState: CHANGES_REQUIRED
- requiredActor: CLAUDE
- progress: 278/719 = 38.66%

If the canonical actor/task has moved, fail closed as HIVEAI_STATE_CONFLICT.

Before production edits:
- set workflowState = IN_PROGRESS;
- requiredActor = CLAUDE;
- keep progress unchanged;
- update machine + human tracker sections;
- append one truthful hiveai-event/v1 WORKFLOW_CHANGED event;
- commit + push this start transition to origin/main.

If tracking push fails:
`GITHUB_TRACKING_NOT_SYNCED`

## 1. Make select_access coherence mandatory

Dispatcher select_access API must include:
- is_targetable
- is_coherent_with

Fresh bind must reject:
- object with only is_targetable;
- missing coherence method;
- coherence returning non-bool;
- coherence returning false;
- same-shape different bundle.

ProductionTargetAccess and AccessQueryDouble must remain valid only when exact
coherence returns true.

Do not treat absence of is_coherent_with as a stateless exemption.

## 2. Narrow collaborator lifecycle categories

Canonical dispatcher collaborators are RefCounted:
- TargetSelector
- ReservationState
- RoutingSystem
- routing access
- selection access

Require RefCounted + narrow API for these injected collaborators.

Reject method-compatible Node dependencies at fresh bind.

Keep agent_parent as the only intentional Node lifecycle dependency.

Do not widen production classes.

## 3. Arm serial guard BEFORE live collaborator callbacks

After pure request validation and before _bundle_coherent():
- set _in_dispatch;
- capture reset generation.

Then call live coherence.

Directly inject recursive dispatch from:
- selector.is_bound_to;
- reservations.is_bound_to;
- routing_access.is_bound_to;
- select_access.is_coherent_with.

Every recursive call:
- REENTRANT;
- no reservation;
- no route;
- no owner id advance.

Outer call may continue only if coherence remains true and generation unchanged.

Inject reset from at least one live coherence callback:
- outer returns RESETTING;
- selection never begins;
- no reservation/route/factory;
- guard clears;
- later normal dispatch succeeds.

## 4. Check generation immediately after EVERY external boundary

Direct boundaries include:
- live bundle coherence;
- select_access.set_origin;
- selector.select_and_reserve;
- select_access.consume_route;
- routing_system.compute_route;
- route validation access callbacks if they can inject;
- agent factory;
- agent.assign;
- add_child lifecycle.

At minimum add direct reset injection for the previously missing:
- set_origin;
- consume_route.

Required:
- once reset generation changes, no NEW downstream external phase begins;
- pending reservation released when one exists;
- owned fresh agent freed/cancelled when one exists;
- no _active commit;
- _in_dispatch always clears;
- later dispatch recovers.

## 5. Re-check exact bundle coherence between phases

A dispatch that began coherent must not commit work after a sibling dependency
drifts inside an injected callback.

Directly inject drift during:
- selection/access callback;
- routing callback;
- factory callback;
- assign callback.

Drift examples:
- ReservationState.rebind(other board);
- TargetSelector.bind/rebind equivalent to other bundle;
- routing_access bind to other board;
- select_access coherent=false / bundle mismatch.

Before the next consequential side effect:
- detect incoherence;
- abort;
- rollback current pending reservation if still owned;
- no agent/_active commit;
- prior committed assignments remain intact;
- later fresh coherent dispatcher remains usable.

Do not erase prior active assignments merely because the pending dispatch drifted.

## 6. Distinguish missing cached route from invalid cached route

Semantics:

### consume_route returns null
No memo exists:
- fresh routing compute is allowed.

### consume_route returns NON-NULL invalid/malformed route
- do NOT call routing_system.compute_route;
- release current reservation;
- ROUTE_FAILED;
- no agent;
- no retarget.

Direct cached-route cases:
- scalar/junk;
- failure RouteResult;
- wrong target;
- wrong start;
- wrong end;
- non-finite geometry.

Use routing call_count to prove zero fresh compute after a non-null invalid cache.

Valid cached route still skips redundant compute.

## 7. Fail closed on explicit factory Callable drift

Record whether bind selected:
- default factory intentionally, or
- explicit factory.

Default factory:
- continues to produce ScrubbotAgent.new().

Explicit factory:
- must still be valid at dispatch call;
- if its target was freed / Callable invalidated:
  - AGENT_ASSIGN_FAILED;
  - release reservation;
  - no default fallback;
  - no child;
  - no _active commit.

Direct sensitivity test:
1. bind with explicit Callable to an object method;
2. free callable target;
3. dispatch;
4. prove no default agent appeared.

## 8. Validate agent assign postconditions

After agent.assign(...) returns true, BEFORE add_child:
- instance still valid;
- still unparented;
- state == ScrubbotAgent.State.MOVING;
- agent.owner_id == pending owner;
- agent.color_id == request color;
- agent.target_index == reserved target;
- agent spawn/target identity remains coherent with the request where practical.

Create a test subclass that lies:
- assign() returns true;
- remains UNASSIGNED or records wrong identity.

Required:
- AGENT_ASSIGN_FAILED;
- reservation released;
- dispatcher-owned fresh liar freed;
- no child;
- no active assignment.

Preserve valid subclass acceptance.

## 9. Preserve V02 hardening

Keep all V02 regressions green:
- initialization-only bind;
- exact selector/reservation/routing coherence;
- ProductionTargetAccess RouteValidator memo discipline;
- route validation;
- foreign factory product protection;
- finite request validation;
- reset generation;
- completion identity;
- ordinary rollback;
- 5-slot burst;
- rapid sequential stress;
- real production routing;
- 59x59;
- rectangular Very Hard;
- M15-M18 strict regressions;
- no M20 behavior.

F-M19-STRICT-004 remains closed.

## 10. Full M19 closure evidence

Run FULL root suite.

Do not report aggregate green only. CLAUDE_LOG_V03 must map the new V03
adversarial cases to the relevant criteria and record exact direct observations.

## Production scope

Allowed:
- scripts/gameplay/dispatch/*
- minimal test-only/support changes
- minimal read-only TargetSelector coherence support only if required
- M19 documentation contract clarification

Do not change:
- BoardState
- ReservationState
- routing algorithms
- ScrubbotAgent core
- M20 behavior

If a V03 test proves an upstream production change is unavoidable, STOP as
BLOCKED rather than silently widening scope.

## Governance

Claude MUST NOT edit:
- root tasks.md completion checkboxes;
- coordination/AUDIT_INDEX.md;
- strict controllers;
- any CHATGPT_* artifact;
- legacy H!veAI dashboard/cycle/progress files;
- coordination/SESSION_INDEX.md.

Claude MUST update lifecycle state in:
- .hiveai/TASKS.md
- .hiveai/EVENTS.jsonl

Do not edit:
- .hiveai/PROJECT.json
- .hiveai/RULES.md

## Validation

Record:
- godot --version
- full root headless suite
- git diff --check
- exact changed files
- failed attempts
- H!veAI start/final transition evidence

Write:
`coordination/sessions/M19-C001/CLAUDE_LOG_V03.md`

## Final successful H!veAI handoff

Before reporting success:
- workflowState = AWAITING_AUDIT;
- requiredActor = CHATGPT;
- currentTaskId = M19-C001-V03;
- milestone/sprint remain M19/V03;
- nextAction = independent ChatGPT V03 audit;
- blockers = [];
- progress remains 278/719 = 38.66%;
- lastCompletedTaskId remains FOUNDATION-C001-V01;
- updatedBy = CLAUDE;
- append IN_PROGRESS -> AWAITING_AUDIT event;
- commit and push implementation + tests + CLAUDE_LOG_V03 + canonical tracker
  files to origin/main.

Do NOT mark COMPLETE or READY_FOR_NEXT_TASK.

Successful return:
`AWAITING_AUDIT`

Tracker push failure:
`GITHUB_TRACKING_NOT_SYNCED`

Genuine blocker:
`BLOCKED`

Then STOP.
