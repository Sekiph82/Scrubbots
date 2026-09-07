# M19-C001 — Full Attack-Surface Strict Re-Audit V02

Decision: **CHANGES_REQUIRED / FINDING_SET_FROZEN**

This is the canonical Strict Audit Standard v2 basis for current M19.

The original V01 implementation is preserved. It was audit-blocked while M18
and the M10-M14 foundation chain were repaired. Those upstream repairs and
FOUNDATION-STRICT-001 are now final-closed.

ChatGPT therefore re-audited the CURRENT M19 source against CURRENT upstream
contracts before allowing M19 final closure.

## Current production surface

- scripts/gameplay/dispatch/scrubbot_dispatcher.gd
- scripts/gameplay/dispatch/dispatch_result.gd
- scripts/gameplay/dispatch/production_target_access.gd

Immediate dependencies:
- BoardState
- TargetSelector
- ReservationState
- RoutingSystem / ProductionRoutingSystem
- ProductionAccessQuery
- ScrubbotAgent
- RouteRequest / RouteResult / RouteValidator

## Sweep scope

Public/externally-reachable M19 behavior reviewed:
- dispatcher bind();
- dispatch();
- reset();
- completion callback lifecycle;
- active-assignment queries;
- ProductionTargetAccess construction/origin/targetability/memo consumption;
- DispatchResult success/failure data surface.

Attack classes considered:
- null/scalar/non-object/partial dependencies;
- exact-board coherence across selector/reservation/routing/access;
- post-bind dependency rebind/drift;
- repeated bind with live assignments;
- malformed route result;
- target-mismatched route;
- invalid route geometry;
- malformed agent factory product;
- parented/reused/freed agent;
- freed/invalid agent_parent;
- speed NaN/+INF/-INF;
- recursive dispatch;
- reset during selector/routing/factory/assign/add-child stages;
- delayed/mismatched completion payload;
- rollback failure;
- duplicate ownership;
- rapid sequential dispatch;
- 5-slot and 59x59 behavior;
- no M20 cell mutation/reservation resolution.

Godot is unavailable in the ChatGPT audit environment. Current runtime green
counts are implementer evidence; findings below are E3 current-source/contract
evidence.

## Frozen findings

### F-M19-STRICT-001 — dispatcher dependency/coherence boundary and bind lifecycle are not fail-closed

Current bind() rejects null only.

It does not validate the narrow methods/types it later calls on:
- selector;
- reservations;
- routing_system;
- routing_access;
- select_access.

It also does not prove that every collaborator belongs to the SAME BoardState
and the same reservation/routing bundle.

A critical integration example is a valid TargetSelector bound to board B while
the dispatcher is given board A and ReservationState A. The selector can reserve
through its own B-side ReservationState while the dispatcher later builds the
route/release path against A-side dependencies. That can create split-brain
assignment truth.

Current bind() also allows a second valid bind while live assignments exist. It
overwrites _reservations/_selector/_routing refs but preserves _active. A later
reset can therefore try to release old owner ids through the NEW ReservationState,
leaving old assignment ownership orphaned.

A failed null bind after a prior valid bind sets _bound=false but leaves stale
refs and _active present.

Required:

#### Narrow dependency categories
At initial bind validate before commit:
- board is canonical BoardState;
- selector is a TargetSelector-compatible RefCounted exposing the required
  dispatch seam;
- reservations is ReservationState-compatible and exact-bound to board;
- routing_system is RoutingSystem-compatible;
- routing_access exposes the complete production routing access seam and is
  exact-bound to board;
- select_access exposes the complete M19 selection-access seam;
- agent_parent, when supplied, is a valid Node not queued for deletion;
- agent_factory is either invalid/empty meaning default factory, or a valid
  Callable.

No scalar Variant may reach has_method/direct method calls.

#### Bundle coherence
Dispatcher must prove:
- selector is bound to the same board;
- selector uses the same ReservationState instance supplied to dispatcher;
- reservations is bound to the same board;
- routing_access is bound to the same board;
- selection access is coherent with the same board/routing_system/routing_access
  bundle.

A minimal read-only coherence method may be added to TargetSelector if needed.
It must not change M15 selection behavior.

ProductionTargetAccess should expose a read-only exact-identity coherence query.

#### Re-check coherence on every dispatch
A sibling can be rebound after dispatcher bind. Before selection:
- reservation board coherence;
- selector coherence;
- routing-access coherence;
- select-access bundle coherence

must still be true.

Drift fails closed before any new reservation.

#### Ordinary bind lifecycle
bind() is initialization-only / UNBOUND-only.

After a successful bind, EVERY second bind attempt must return false and preserve:
- original collaborator bundle;
- _bound;
- _active assignments;
- exact owners/targets/agents;
- active reservations.

This includes same bundle, different valid bundle, null, scalar and malformed
dependencies.

No destructive rebind API is required for M19. Create a new dispatcher if the
whole orchestration bundle must change.

### F-M19-STRICT-002 — external route/access/agent-factory results are trusted before validation

Current dispatcher directly dereferences:
- select_access.has_method/set_origin/consume_route;
- selector.select_and_reserve return;
- routing_system.compute_route return;
- route.success / route.target_index;
- agent.assign;
- agent_parent.add_child.

Current ProductionTargetAccess directly calls routing_system.compute_route and
trusts any non-null object with success=true as reachable.

Current recomputed dispatcher route checks success but does not re-check
route.target_index == reserved target before agent creation.

A malformed/mismatched RoutingSystem can therefore:
- fault the dispatcher;
- classify the wrong target as reachable;
- produce a target-mismatch that is only noticed later as AGENT_ASSIGN_FAILED;
- return malformed route geometry to the agent seam.

The optional agent factory can return:
- null;
- scalar;
- RefCounted;
- arbitrary Node;
- already-parented ScrubbotAgent;
- already-assigned ScrubbotAgent;

and current code can fault, free foreign objects or fail at add_child.

Required:

#### ProductionTargetAccess
Harden it so:
- malformed dependencies fail closed;
- set_origin rejects non-finite origin and clears memo;
- is_targetable validates exact request/route target;
- a route is targetable only if it is a real RouteResult and
  RouteValidator-clean for the request/board/routing access;
- malformed/mismatched/invalid route => false;
- failed probe cannot leave a stale successful memo;
- consume_route is one-shot: returning the memo clears it;
- coherence query proves exact board/routing_system/routing_access identities.

#### Dispatcher route result
Before agent creation, any cached or freshly computed route must:
- be a real RouteResult;
- success == true;
- target_index == reserved target;
- pass RouteValidator for the exact RouteRequest/board/routing access.

Otherwise:
- release the reservation;
- spawn zero agents;
- return ROUTE_FAILED;
- no retarget.

#### Agent factory / parent
Factory product accepted by dispatcher must be:
- a real ScrubbotAgent or subclass;
- valid instance;
- fresh UNASSIGNED;
- unparented.

Invalid product:
- produces AGENT_ASSIGN_FAILED;
- releases reservation;
- creates no dispatcher child;
- does not free/mutate a foreign parented/reused object.

Before add_child, agent_parent must still be valid and not queued for deletion.
Parent lifecycle failure rolls back the reservation/agent safely.

### F-M19-STRICT-003 — reset/reentrant dispatch can miss a pending reserved assignment

M19 is stateful orchestration and reset-during-dispatch is an explicit task.

Current reset() knows only entries already committed to _active.

But dispatch() invokes external collaborators after reservation:
- routing;
- factory;
- agent.assign;
- Node add/ready lifecycle.

A collaborator can synchronously call dispatcher.reset() while the current
dispatch has a RESERVED target but has not yet inserted the assignment into
_active.

reset() then releases only old _active owners. The pending reservation is
invisible to reset, and the outer dispatch can continue afterward.

Similarly, recursive dispatch from an injected callback can interleave against
the same next-owner-id before the outer attempt commits.

Required:

#### Serial re-entry guard
- one dispatcher may execute at most one dispatch() body at a time;
- recursive dispatch while one is in progress returns a stable failure and
  creates no reservation/agent;
- ordinary rapid SEQUENTIAL calls remain supported.

#### Reset generation/cancellation
Use a generation/epoch or equivalent deterministic token:
- dispatch captures generation at start;
- reset increments/invalidate generation;
- after EVERY external callback boundary, dispatch checks whether reset occurred.

External boundaries include at least:
- selector.select_and_reserve;
- consume_route / routing compute;
- agent factory;
- agent.assign;
- add_child lifecycle.

If reset occurred after current reservation:
- release current pending owner/target;
- cancel/free any current dispatcher-owned fresh agent;
- do not add/retain _active entry;
- return RESETTING/CANCELLED;
- no orphan reservation or node.

Reset still:
- cancels/frees committed active agents;
- releases their reservations;
- preserves BoardState;
- keeps owner id monotonic.

Direct adversarial callbacks must trigger reset from multiple phases, not only
after a completed dispatch.

#### Completion identity
A completion callback may mark arrived only when payload/source matches the
active assignment:
- expected owner;
- expected target;
- expected color;
- expected agent instance.

Mismatched/stale completion is ignored.
Repeated correct completion remains idempotent.
Reset-disconnected callbacks cannot recreate state.

### F-M19-STRICT-004 — non-finite positive speed bypasses INVALID_REQUEST validation

Current request check is:
`speed <= 0.0`.

For NaN this comparison is false. +INF is also > 0.

Therefore NaN/+INF can cross selection/reservation/routing into agent assignment
instead of being rejected as INVALID_REQUEST.

Required:
- finite speed only;
- speed > 0;
- NaN, +INF, -INF, zero and negative all fail before selector/reservation calls;
- valid finite positive speed preserves current behavior.

## Accepted / not reopened

The current V01 implementation already has good evidence for:
- raw candidate != reachable work;
- exactly one agent per ordinary successful dispatch;
- reservation rollback on ordinary route/assign failure;
- no silent fallback target;
- unique monotonic owner ids in sequential calls;
- successful reservation held after dispatch;
- M19 completion does not clear/release;
- reset after committed dispatches;
- rapid sequential uniqueness;
- 5-slot burst;
- 59x59 and rectangular production pipeline;
- no M20 clearing/scoring.

These must remain green but are not separate findings.

## Frozen M19 finding set

Frozen to:
- F-M19-STRICT-001
- F-M19-STRICT-002
- F-M19-STRICT-003
- F-M19-STRICT-004

Affected tasks remain open:
- SB-M19-001..012

Next:
`coordination/sessions/M19-C001/CHATGPT_PROMPT_V02.md`
