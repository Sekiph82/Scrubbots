# M18-C001 — Strict Re-Audit V02

Decision: **CHANGES_REQUIRED**

Reason for re-audit:
The owner raised the audit standard. This re-audit applies the new
`coordination/AUDIT_POLICY.md` Strict Audit Standard v2 retroactively to M18.

Original audit:
`coordination/sessions/M18-C001/CHATGPT_AUDIT_V01.md`

Implementation:
`c7c11a79e46f548b5cc2d90fe9661122bb17aad4`

## Evidence discipline

Claude's 1483/1483 suite remains E2 implementer evidence.

ChatGPT independently re-inspected:
- ScrubbotAgent lifecycle source;
- M18 assignment/movement/cancel tests;
- stress/performance timer boundaries;
- ADR-026;
- task-to-test mapping.

Godot still cannot be independently rerun in the ChatGPT audit environment.

Under strict-v2, that means M18 cannot remain finally closed without an
auditor-authored adversarial validation pass.

## Adversarial classes checked

Applicable and inspected:
- repeated call / re-entry;
- lifecycle reuse after completion;
- lifecycle reuse after cancel;
- direct observability of multi-segment movement;
- performance-measurement isolation;
- rollback/cancel terminal behavior;
- mutable route aliasing;
- repeated completion.

## Findings

### F-M18-STRICT-001 — active agent can be reassigned

Severity: **material lifecycle defect**

`ScrubbotAgent.assign()` does not require `State.UNASSIGNED`.

Therefore a valid second `assign()` while the agent is already MOVING can
replace:
- owner_id;
- color_id;
- target_index;
- route;
- spawn_origin;
- movement progress.

That contradicts the M18 architecture description that one lightweight agent
owns exactly one in-flight movement and that assigned identity is read-only
after assign.

The current test suite does not attempt a valid second assignment.

Required correction:
- define ScrubbotAgent as single-use;
- `assign()` succeeds only from UNASSIGNED;
- valid or invalid re-entry while MOVING/ARRIVED/CANCELLED must fail closed and
  preserve existing terminal/active state and assignment truth;
- no second completion signal may become possible through reuse.

Affected task:
- SB-M18-001

Reusable learning:
- AL-037.

### F-M18-STRICT-002 — “large delta crosses multiple segments” is not directly proven

Severity: **evidence gap**

The current test compares:
- one `advance(0.5)`
against
- fifty `advance(0.01)`

but does not assert that the selected S2 route and 0.5-second delta actually
cross at least one route segment boundary.

The test can remain green while exercising only one long segment, so it does
not directly establish the property named by the test.

Required validation:
- use a deterministic handcrafted successful RouteResult with known segment
  lengths;
- choose a delta that provably crosses multiple segment boundaries;
- assert exact expected position/progress while still not completing;
- separately keep huge-delta exact-final-snap coverage.

Affected task:
- SB-M18-006

Reusable learning:
- AL-038.

### F-M18-STRICT-003 — agent performance timing includes route generation

Severity: **material evidence defect**

M18 prompt required stress with **precomputed valid routes** and CPU/node
behavior for the lightweight agent.

The current timed region begins before:
`ProductionRoutingSystem.compute_route(...)`

for every request.

The reported 5/10/25/40 timings therefore mix:
- route generation;
- agent allocation;
- assignment;
- movement;
- signal handling.

Those numbers cannot establish ScrubbotAgent lifecycle cost and cannot support
a pooling decision under Strict-v2 performance isolation.

Required correction/validation:
- precompute all routes before starting the timer;
- verify all precomputed routes are successful first;
- measure agent create + assign + movement + completion + free separately;
- report route-generation timing separately only if useful;
- make no FPS/GPU/mobile-performance claim;
- keep pooling deferred unless isolated agent-lifecycle evidence actually
  justifies adding it.

Affected tasks:
- SB-M18-014
- SB-M18-015

Reusable learning:
- AL-036.

## Previously accepted invariants that remain accepted

No new defect found in:
- detached route copy-out;
- exact completion identity;
- once-only completion guard;
- no BoardState mutation;
- no ReservationState mutation;
- no return-to-slot;
- no resource carrying;
- cancel-before-arrival blocking completion;
- no child/tween/timer ownership;
- 59×59 and rectangular coordinate compatibility;
- M19/M20 non-scope.

Those tasks do not need reopening.

## Strict-v2 task state

Reopen:
- SB-M18-001
- SB-M18-006
- SB-M18-014
- SB-M18-015

Keep SB-M18-002..005, 007..013 closed.

M18 state:
**CHANGES_REQUIRED / STRICT_VALIDATION_OPEN**

M19 is dependent on M18 and must be paused until M18 V02 passes.

Next:
`coordination/sessions/M18-C001/CHATGPT_PROMPT_V02.md`
