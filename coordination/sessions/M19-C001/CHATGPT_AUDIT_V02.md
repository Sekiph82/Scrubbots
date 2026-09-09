# M19-C001 — ChatGPT Independent Audit V02

Decision: **CHANGES_REQUIRED / STRICT_V2_SECOND_STAGE_REQUIRED**

Audited implementation commit:
`fe4e2e88754a9b9472536967937e042a7b581462`

H!veAI start-transition commit:
`28d7f5713e5e0015aebd1e8acd27d91b87f1a792`

Prompt:
`coordination/sessions/M19-C001/CHATGPT_PROMPT_V02.md`

Criteria:
`coordination/sessions/M19-C001/CHATGPT_AUDIT_CRITERIA_V02.md`

Claude evidence:
`coordination/sessions/M19-C001/CLAUDE_LOG_V02.md`

Frozen basis:
`coordination/sessions/M19-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md`

## Independence / runtime disclosure

Claude reports Godot 4.7.1 and **2780 / 2780 ALL PASS**. This is E1/E2 runtime
evidence.

Godot is unavailable in the ChatGPT audit environment, so the root suite was not
independently rerun.

ChatGPT independently inspected:
- the exact start-transition and implementation commits;
- production ScrubbotDispatcher;
- ProductionTargetAccess;
- DispatchResult;
- TargetSelector coherence addition;
- M19 test/support doubles;
- the full M19 V02 strict test block;
- current M13-M18 dependencies;
- canonical H!veAI v3 TASKS/EVENTS state.

This is E3 source/diff/adversarial-test evidence.

## H!veAI GitHub-first v3 audit — PASS

The lifecycle contract was followed correctly.

### Start
Canonical synced state was:
- task M19-C001-V02;
- workflow CHANGES_REQUIRED;
- actor CLAUDE;
- progress 278/719 = 38.66%.

Claude then:
- updated the canonical tracker to IN_PROGRESS;
- appended one WORKFLOW_CHANGED event;
- pushed the start transition separately before implementation.

Event:
`93073256-a5b1-40a1-800b-b16873c3ccea`

Commit:
`28d7f5713e5e0015aebd1e8acd27d91b87f1a792`

### Final handoff
Canonical tracker at implementation commit is:
- workflowState = AWAITING_AUDIT;
- requiredActor = CHATGPT;
- currentTaskId = M19-C001-V02;
- blockers = [];
- progress unchanged 278/719 = 38.66%;
- lastCompletedTaskId still FOUNDATION-C001-V01.

Final event:
`24a14b34-3a86-4e77-8fbc-6e81053a7e46`

Claude did not claim COMPLETE or READY_FOR_NEXT_TASK.

Legacy H!veAI dashboard/cycle/progress files were not used as the live handoff.

## Accepted V02 corrections

### F-M19-STRICT-004 — CLOSED

Request validation now rejects before side effects:
- negative color;
- non-finite start;
- speed NaN;
- speed +INF;
- speed -INF;
- zero;
- negative speed.

Finite positive speed remains valid.

### F-M19-STRICT-001 — materially improved, remains OPEN

Accepted:
- ordinary dispatcher bind is initialization-only;
- repeated bind preserves live assignments;
- selector/reservation/routing-access identity checks exist;
- TargetSelector exposes read-only exact board+reservation coherence;
- ProductionTargetAccess exposes read-only exact board+routing/access coherence;
- live drift for the directly tested collaborators is rejected before selection.

However the bundle boundary is not yet fully fail-closed.

### F-M19-STRICT-002 — materially improved, remains OPEN

Accepted:
- ProductionTargetAccess validates route results through RouteValidator;
- memo success is one-shot;
- route geometry/target validation exists;
- malformed factory products are rejected;
- foreign parented/reused agents are not freed;
- parent lifecycle is rechecked before attach.

Remaining external-result trust gaps are listed below.

### F-M19-STRICT-003 — materially improved, remains OPEN

Accepted:
- recursive dispatch guard exists;
- reset generation exists;
- reset injection during selector/routing/factory/assign is directly exercised;
- completion identity includes owner/target/color/agent;
- stale/wrong completion is ignored.

Remaining re-entry/generation gaps are listed below.

# Remaining strict-v2 defects / evidence gaps

## F-M19-STRICT-001.A — select_access coherence is optional, not mandatory

The V02 prompt requires the selection-access dependency to provide the complete
selection seam PLUS bundle coherence.

Production currently requires only:

```gdscript
const _SELECT_ACCESS_API := ["is_targetable"]
```

and _bundle_coherent() does:

```gdscript
if select_access.has_method("is_coherent_with"):
    ...
return true
```

Therefore an arbitrary stateful RefCounted exposing only is_targetable() can be
accepted without proving that it belongs to the same board/routing/access
bundle.

This is fail-open relative to criteria 15/18 and the frozen F-M19-STRICT-001
contract.

The V02 mixed-bundle test uses ProductionTargetAccess, which DOES expose
is_coherent_with, so it does not sensitivity-test the missing-method case.

Required:
- is_coherent_with becomes mandatory for dispatcher select_access;
- missing coherence method fails fresh bind;
- wrong-type coherence verdict fails;
- false verdict fails;
- exact production/fake coherent dependencies remain accepted.

## F-M19-STRICT-001.B — canonical collaborator lifecycle category is still broader than production truth

Canonical:
- TargetSelector is RefCounted;
- ReservationState is RefCounted;
- RoutingSystem is RefCounted;
- ProductionAccessQuery is RefCounted;
- ProductionTargetAccess is RefCounted.

Dispatcher still accepts routing_system/routing_access/select_access as any
TYPE_OBJECT with method names.

A method-compatible externally-freeable Node can therefore enter the bundle,
then be freed after bind.

Required:
- narrow these injectable collaborators to the production lifecycle category
  actually used: RefCounted + required narrow API, unless a stronger reason
  requires Node support;
- reject method-compatible Nodes;
- prove externally-freeable dependency cannot become a stale callable bundle.

## F-M19-STRICT-003.A — re-entry guard is armed AFTER live coherence callbacks

dispatch() currently calls:

```gdscript
if not _bundle_coherent(...):
    return COHERENCE_FAILED

_in_dispatch = true
```

But _bundle_coherent() calls injected collaborator methods:
- selector.is_bound_to();
- reservations.is_bound_to();
- routing_access.is_bound_to();
- select_access.is_coherent_with().

A collaborator callback can therefore recursively call dispatcher.dispatch()
BEFORE _in_dispatch is true.

This means the serial re-entry protection does not cover the first external
callback boundary in dispatch.

Required:
- arm the serial guard before any injected live-coherence callback;
- capture reset generation before external coherence calls;
- recursive dispatch from every coherence seam returns REENTRANT;
- reset injected during coherence aborts the outer attempt before selection.

## F-M19-STRICT-003.B — reset generation is not checked after every external callback boundary

The V02 prompt explicitly requires checking after every external callback
boundary.

Current gaps include:

### set_origin
Dispatcher may call injected:
`select_access.set_origin(start_position)`

There is no generation check immediately afterward.

If set_origin synchronously calls reset(), dispatcher continues into
select_and_reserve before discovering the reset later.

### consume_route
Dispatcher may call:
`select_access.consume_route(target)`

There is no generation check immediately afterward.

If consume_route resets or mutates lifecycle state, dispatcher can continue into
route validation / fresh compute before observing the generation change.

Required:
- generation check immediately after each optional/injected callback;
- reset means no further selector/routing/factory/agent side effect may begin;
- pending reservation rollback remains exact.

## F-M19-STRICT-001.C / F-M19-STRICT-003.C — collaborator coherence is checked only at dispatch start

A bundle can be coherent at dispatch entry and drift synchronously inside an
injected callback.

Example:
1. selection reserves target on board A;
2. routing callback rebinds ReservationState or another bundle member;
3. dispatcher does not re-check bundle after routing;
4. agent may be committed while successful reservation truth no longer belongs
   to the original bundle.

Required:
- after external phases capable of arbitrary injected code, re-check exact
  bundle coherence before committing the next side effect;
- if coherence drifts after reservation, abort current dispatch and rollback any
  still-owned pending reservation;
- never commit _active when collaborator bundle no longer matches the original
  board/reservation/routing identities.

At minimum challenge drift during:
- selection access callback;
- routing callback;
- factory callback;
- assign callback.

## F-M19-STRICT-002.A — invalid NON-NULL cached route silently falls back to fresh routing

Current code:

```gdscript
route = select_access.consume_route(target)
if not _route_ok(route, request, target):
    route = routing_system.compute_route(...)
```

This treats:
- no cached route (null), and
- a present but malformed/mismatched cached route

as the same condition.

The frozen V02 contract states that a malformed/mismatched/invalid route result
must release and return ROUTE_FAILED, not silently recover by obtaining another
route.

Required:
- null/no memo may legitimately trigger fresh compute;
- a NON-NULL cached route that fails shared validation is a route seam failure:
  release reservation, ROUTE_FAILED, no fresh compute, no agent;
- direct sensitivity test must prove malformed cached route does not invoke
  routing_system.

## F-M19-STRICT-002.B — explicit agent_factory can silently degrade into default factory after Callable drift

Current _make_agent():

```gdscript
if _agent_factory.is_valid():
    return _agent_factory.call()
return ScrubbotAgent.new()
```

This cannot distinguish:
- user intentionally configured no factory, from
- user configured an explicit valid Callable at bind and that Callable later
  became invalid because its target was freed.

In the latter case, dependency drift silently creates a default production agent.

Required:
- remember whether default factory was intentionally selected;
- explicit factory that becomes invalid after bind fails closed;
- release pending reservation;
- spawn no default substitute;
- no owner/agent active commit;
- later normal dispatcher with a valid bundle remains usable.

## F-M19-STRICT-002.C — assign()==true is trusted without postcondition validation

Dispatcher validates a factory product BEFORE assign(), then trusts a true return.

Because subclasses are intentionally accepted, an injected subclass can override
assign() and return true without becoming a canonical MOVING agent or without
recording the requested owner/color/target.

Required after assign()==true:
- agent still valid;
- agent still unparented before attach;
- agent state is MOVING;
- owner_id matches;
- color_id matches;
- target_index matches;
- assigned route/request identity remains coherent where exposed.

A lying subclass returning true while remaining UNASSIGNED must fail:
- AGENT_ASSIGN_FAILED;
- reservation released;
- dispatcher-owned fresh agent freed;
- no child/_active entry.

## Direct-observability note

The V02 suite is large and green, but the missing cases above are NOT exercised.
A 2780/2780 aggregate cannot prove behavior absent from the matrix.

This is exactly why Strict Audit Standard v2 requires an auditor-authored
second-stage pass for critical orchestration.

## Frozen finding status

No new M19 finding IDs are created.

- F-M19-STRICT-001 — OPEN
- F-M19-STRICT-002 — OPEN
- F-M19-STRICT-003 — OPEN
- F-M19-STRICT-004 — CLOSED / preserve regression

## Task / progress disposition

Keep open:
- SB-M19-001..012

Progress remains:
- Main + UI: **278 / 719 = 38.66%**
- Overall: **278 / 943 = 29.48%**

## Verdict

**CHANGES_REQUIRED / STRICT_V2_SECOND_STAGE_REQUIRED**

Next:
`coordination/sessions/M19-C001/CHATGPT_PROMPT_V03.md`
