# M19-C001 — Frozen Full-Surface Dispatcher Closure V02

Status: **ISSUED — FINDING SET FROZEN**

H!veAI tracking contract: **GitHub-first v3**.

Implement ONLY the frozen M19 strict-v2 set.

## H!veAI v3 precedence

For operational project state, the live authority is:
- GitHub `origin/main`;
- `.hiveai/PROJECT.json`;
- `.hiveai/RULES.md`;
- `.hiveai/TASKS.md`;
- `.hiveai/EVENTS.jsonl`.

The H!veAI v3 adapter at the top of `CLAUDE.md` and `.hiveai/RULES.md`
SUPERSEDE historical tracker-ownership instructions that said Claude must not
modify `.hiveai/*` or that legacy dashboard/index files are live authority.

This DOES NOT supersede independent audit separation:
- Claude implements/tests and may move the live workflow only to
  `AWAITING_AUDIT`;
- Claude MUST NOT mark independently audited work `COMPLETE` or
  `READY_FOR_NEXT_TASK`;
- ChatGPT performs the independent audit and owns acceptance/final closure.

Legacy files such as:
- `.hiveai/PROJECT_DASHBOARD.md`;
- `.hiveai/ACTIVE_CYCLES.md`;
- `.hiveai/ARTIFACT_MAP.md`;
- `.hiveai/PROGRESS_SNAPSHOT.md`;
- `coordination/SESSION_INDEX.md`

are historical evidence only and MUST NOT be maintained as competing live
trackers.

Read FIRST, before implementation:
- `.hiveai/RULES.md`;
- `.hiveai/TASKS.md`;
- `.hiveai/PROJECT.json`;
- `CLAUDE.md`.

Then read:
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/VERSIONED_LOG_POLICY.md
- coordination/STRICT_FOUNDATION_REPAIR_QUEUE_V01.md
- coordination/sessions/M19-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md
- coordination/sessions/M19-C001/CHATGPT_BLOCKER_NOTE_V01.md
- coordination/sessions/M19-C001/CHATGPT_PROMPT_V01.md
- coordination/sessions/M19-C001/CLAUDE_LOG_V01.md
- current audited M13-M18 production code/audits
- FOUNDATION-C001 final audit
- this prompt + V02 criteria

Expected log:
`coordination/sessions/M19-C001/CLAUDE_LOG_V02.md`

## First action — safe sync + H!veAI lifecycle start

1. Safely synchronize the local repository with `origin/main` while preserving
   pre-existing owner work.
2. Re-read `.hiveai/TASKS.md` FROM THE SYNCED `origin/main` state.
3. Verify the canonical live task is still:
   - `currentTaskId = M19-C001-V02`;
   - `requiredActor = CLAUDE`;
   - workflow state authorizes implementation (currently `CHANGES_REQUIRED`);
   - no blocker says another actor owns the task.
4. If the authoritative tracker has moved to another task/actor, DO NOT overwrite
   it. Fail closed and report `HIVEAI_STATE_CONFLICT`.
5. Before editing production code, transition the canonical tracker to:
   - `workflowState: IN_PROGRESS`;
   - `requiredActor: CLAUDE`;
   - `currentTaskId/currentMilestone/currentSprint` unchanged;
   - `nextAction` = execute this V02 frozen correction and validation;
   - progress unchanged at **278 / 719 = 38.66% main+UI**;
   - `updatedAt` = current UTC ISO8601;
   - `updatedBy` = `CLAUDE`.
6. Update BOTH the machine-readable comment block and human-readable Current /
   Active sections of `.hiveai/TASKS.md` so they agree.
7. Append exactly one canonical lifecycle row to `.hiveai/EVENTS.jsonl` for
   this transition. Use the v3 schema:
   ```json
   {"schema":"hiveai-event/v1","id":"<uuid>","projectKey":"scrubbots","type":"WORKFLOW_CHANGED","actor":"CLAUDE","timestamp":"<UTC ISO8601>","taskId":"M19-C001-V02","from":"CHANGES_REQUIRED","to":"IN_PROGRESS","workflowState":"IN_PROGRESS","summary":"Started M19-C001 V02 frozen strict-v2 dispatcher hardening."}
   ```
   If the synced starting state differs, record the ACTUAL from-state rather
   than fabricating `CHANGES_REQUIRED`.
8. Commit and push this start-state tracker transition to `origin/main` before
   substantial implementation work, so GitHub remains the live authority.
9. If that push fails, do not claim H!veAI is synchronized. Report
   `GITHUB_TRACKING_NOT_SYNCED`.

Fix ONLY:
- F-M19-STRICT-001
- F-M19-STRICT-002
- F-M19-STRICT-003
- F-M19-STRICT-004

Do not implement M20 clearing/scoring/arrival resolution.

## 1. Make dispatcher bind initialization-only and fail-closed

Fresh bind must validate all collaborators BEFORE storing them.

Canonical:
- board: real BoardState;
- selector: real/current TargetSelector-compatible dependency;
- reservations: real/current ReservationState-compatible dependency;
- routing_system: RoutingSystem-compatible;
- routing_access: complete routing-access seam + exact board coherence;
- select_access: complete M19 selection-access seam + bundle coherence;
- optional agent_parent: valid Node, not queued for deletion;
- optional agent_factory: valid Callable or empty default.

Unsupported scalars / junk / partial dependencies must return false with:
- dispatcher unbound;
- no refs committed;
- no active assignments;
- no runtime fault.

### Selector coherence

Add a minimal READ-ONLY TargetSelector coherence API if necessary, for example:
`is_bound_to(board, reservation_state)`.

It must prove:
- exact selector board identity;
- exact ReservationState identity.

Do not change target selection semantics.

### ProductionTargetAccess coherence

Expose a read-only exact-identity query that proves:
- board;
- routing_system;
- routing_access

are the exact bundle expected by dispatcher.

### Ordinary repeated bind

After one successful bind and at least one live assignment, test attempts with:
- exact same bundle;
- different valid board/bundle;
- null;
- int/String/Vector2;
- partial selector/reservation/routing/access dependencies;
- invalid/freed/queued agent_parent where applicable.

Every second bind:
- false;
- original bound state preserved;
- original collaborator bundle preserved;
- active assignment count unchanged;
- reservation owner/target unchanged;
- active agent unchanged.

Do not add destructive rebind behavior to M19.

### Live coherence drift

After valid dispatcher bind, deliberately rebind/mutate sibling dependencies:
- ReservationState to another board;
- TargetSelector to another coherent board bundle;
- routing_access to another board if supported;
- select_access bundle mismatch.

A subsequent dispatch must fail before creating a new reservation or route.

## 2. Harden ProductionTargetAccess

ProductionTargetAccess must fail closed for malformed construction/dependencies.

Required public behavior:
- invalid/malformed routing system -> is_targetable false, no fault;
- invalid/malformed routing access -> false;
- invalid/non-BoardState board -> false;
- non-finite origin -> rejected/fail-closed and memo cleared;
- invalid index -> false;
- malformed route Variant -> false;
- RouteResult success for wrong target -> false;
- RouteResult with invalid geometry -> false;
- valid RouteResult for exact target -> true.

Use RouteValidator on the exact request/board/access before memoizing success.

Memo rules:
- failed probe clears stale memo;
- set_origin clears memo;
- consume_route(index) returns a route only for the exact last successful probe;
- consume is ONE-SHOT and clears memo after return;
- second consume without new successful probe -> null.

## 3. Harden dispatcher route seam

Both cached route and freshly computed route must pass ONE shared validation path.

Require:
- RouteResult instance;
- success;
- exact reserved target;
- RouteValidator clean for exact request/board/routing_access.

Malformed / mismatched / invalid route:
- release current reservation;
- no agent creation/attach;
- ROUTE_FAILED;
- no retarget.

Directly test route doubles returning:
- null;
- int/String/Vector2/RefCounted;
- failure RouteResult;
- success RouteResult wrong target;
- success RouteResult wrong start;
- wrong end;
- non-finite intermediate point;
- too few points if constructible;
- valid exact route.

## 4. Harden agent factory and parent lifecycle

Factory tests:
- empty factory -> real fresh ScrubbotAgent;
- null return;
- int/String/RefCounted;
- arbitrary Node2D;
- already-parented ScrubbotAgent;
- MOVING ScrubbotAgent;
- ARRIVED ScrubbotAgent;
- CANCELLED ScrubbotAgent;
- valid fresh unparented ScrubbotAgent.

Only a fresh unparented ScrubbotAgent/subclass can be dispatcher-owned.

Invalid factory product:
- AGENT_ASSIGN_FAILED;
- reservation released;
- no dispatcher child/orphan;
- foreign parented/reused object is NOT freed or mutated.

Agent parent tests:
- default self works;
- explicit valid Node works;
- parent freed after bind before dispatch -> clean rollback;
- parent queued for deletion before attach -> clean rollback if reproducible.

No runtime fault.

## 5. Validate request numeric boundaries before side effects

Before selector call:
- color < 0 -> INVALID_REQUEST;
- start x/y NaN/+INF/-INF -> INVALID_REQUEST;
- speed NaN/+INF/-INF -> INVALID_REQUEST;
- speed == 0 -> INVALID_REQUEST;
- speed < 0 -> INVALID_REQUEST.

For every invalid request prove:
- selector not called;
- reservation count unchanged;
- routing not called;
- no agent factory call;
- owner id counter unchanged.

Finite positive speed preserves success.

## 6. Serial re-entry + reset-during-dispatch

Add a dispatch-in-progress guard.

Recursive dispatch from any injected callback:
- clean stable failure;
- no extra reservation;
- no extra agent;
- no duplicate owner id.

Add reset generation/epoch or equivalent.

Direct adversarial reset injection at minimum from:
1. select_access.is_targetable callback;
2. routing_system.compute_route callback;
3. agent_factory callback;
4. agent.assign callback using a controlled ScrubbotAgent subclass if needed;
5. add_child/_ready lifecycle if safely reproducible.

For each phase:
- reset committed active agents normally;
- current pending reservation is eventually released;
- pending fresh agent cancelled/freed if dispatcher owns it;
- outer dispatch returns RESETTING/CANCELLED;
- no _active entry committed for pending owner;
- no orphan child;
- BoardState unchanged;
- later normal dispatch succeeds;
- owner ids never rewind/collide.

Sequential rapid input remains unchanged.

## 7. Completion identity hardening

Connect completion with enough source identity to validate the emitting agent.

Store immutable assignment identity in _active:
- owner;
- target;
- color;
- agent.

Direct tests:
- correct completion -> arrived true;
- repeated correct completion -> idempotent;
- same owner + wrong target -> ignored;
- same owner + wrong color -> ignored;
- wrong owner -> ignored;
- stale/different agent trying to spoof same owner -> ignored;
- callback after reset cannot recreate active/arrived state.

M19 still does NOT clear BoardState or release successful reservation on arrival.

## 8. Preserve ordinary rollback semantics

Keep:
- no candidate -> no reservation/agent;
- unreachable -> no reservation/agent;
- route failure -> reservation release;
- route failure -> no retarget;
- assign failure -> reservation release/no orphan;
- failure-released target dispatchable later;
- duplicate target prevented;
- independent targets independent.

When rollback calls release/release_for_owner, directly assert the reservation
really is gone.

## 9. Preserve production integration

Re-run:
- real ProductionTargetAccess + ProductionRoutingSystem;
- reachable target success;
- enclosed candidate no work;
- 59x59;
- rectangular Very Hard;
- 5-slot burst;
- 25+ rapid sequential stress;
- current M15/M16/M17/M18 strict regressions.

## 10. M20 boundary

Do NOT:
- set BoardState CLEARED on completion;
- sync ColorCandidateIndex on completion;
- resolve successful reservation on completion;
- score;
- trigger slot progression;
- spawn follow-up bot automatically.

Successful arrived assignment remains held for M20 integration.

## Governance and H!veAI v3 handoff

### Claude MUST NOT modify

Independent-audit / canonical-law surfaces:
- root `tasks.md` audit checkboxes or completion truth;
- `coordination/AUDIT_INDEX.md`;
- strict queue/sequence controllers;
- any `CHATGPT_*` artifact;
- any ChatGPT audit verdict.

Legacy live-tracker replacements:
- `.hiveai/PROJECT_DASHBOARD.md`;
- `.hiveai/ACTIVE_CYCLES.md`;
- `.hiveai/ARTIFACT_MAP.md`;
- `.hiveai/PROGRESS_SNAPSHOT.md`;
- `coordination/SESSION_INDEX.md`.

Those files are historical evidence only under H!veAI v3 and must not be
refreshed as current state.

### Claude MUST update

Canonical live tracking when lifecycle state changes:
- `.hiveai/TASKS.md`;
- `.hiveai/EVENTS.jsonl`.

Read-only H!veAI contract files:
- `.hiveai/PROJECT.json`;
- `.hiveai/RULES.md`.

Do not edit those unless this prompt explicitly says the tracking contract
itself is being migrated. It is not.

### Allowed production scope

- `scripts/gameplay/dispatch/*`;
- a minimal read-only coherence method in TargetSelector if necessary;
- test support;
- docs only for durable M19 contract clarification.

Do not modify BoardState, ReservationState, routing algorithms or ScrubbotAgent
core behavior unless a direct V02 test proves an unavoidable frozen-scope defect.
If such an upstream change is required, STOP and record the blocker instead of
silently widening scope.

## Validation

Run and record separately:
- `godot --version`;
- full root headless suite;
- `git diff --check`.

Write:
`coordination/sessions/M19-C001/CLAUDE_LOG_V02.md`

The log must include:
- synced starting commit;
- H!veAI starting state read from `.hiveai/TASKS.md`;
- start transition/push evidence for `IN_PROGRESS`;
- exact changed production/test files;
- frozen finding-by-finding implementation summary;
- exact Godot version;
- exact full-suite total/pass/fail result;
- exact `git diff --check` result;
- any failed attempts and fixes;
- final H!veAI handoff state;
- no self-audit verdict.

## Final successful handoff — REQUIRED H!veAI transition

After implementation/tests are complete but BEFORE reporting success:

1. Update `.hiveai/TASKS.md` to:
   - `workflowState: AWAITING_AUDIT`;
   - `requiredActor: CHATGPT`;
   - `currentTaskId: M19-C001-V02`;
   - current milestone/sprint remain M19/M19-C001 V02;
   - `nextAction` = independently audit
     `coordination/sessions/M19-C001/CLAUDE_LOG_V02.md` and the exact pushed
     implementation against `CHATGPT_AUDIT_CRITERIA_V02.md`;
   - blockers = [];
   - progress remains **278 / 719 = 38.66% main+UI** because Claude cannot
     independently close SB-M19-001..012;
   - `lastCompletedTaskId` remains the last independently accepted task
     (currently `FOUNDATION-C001-V01`);
   - `updatedAt` current UTC ISO8601;
   - `updatedBy: CLAUDE`.
2. Update the human-readable Current / Active / Planned sections to agree:
   implementation is finished, **awaiting independent ChatGPT audit**, not
   complete.
3. Append one lifecycle event:
   ```json
   {"schema":"hiveai-event/v1","id":"<uuid>","projectKey":"scrubbots","type":"WORKFLOW_CHANGED","actor":"CLAUDE","timestamp":"<UTC ISO8601>","taskId":"M19-C001-V02","from":"IN_PROGRESS","to":"AWAITING_AUDIT","workflowState":"AWAITING_AUDIT","summary":"M19-C001 V02 implementation and validation pushed; awaiting independent ChatGPT audit."}
   ```
4. Commit intended implementation, tests, `CLAUDE_LOG_V02.md`,
   `.hiveai/TASKS.md`, and `.hiveai/EVENTS.jsonl`.
5. Push to `origin/main`.
6. Verify the remote main head contains the intended implementation + log +
   canonical tracker handoff.
7. Do NOT edit the Git-tracked log merely to insert the SHA of the commit that
   contains that same log.
8. Do NOT set H!veAI to `COMPLETE` or `READY_FOR_NEXT_TASK`.

On the normal successful path, return exactly:
`AWAITING_AUDIT`

If final tracker push fails, return:
`GITHUB_TRACKING_NOT_SYNCED`

If a genuine frozen-scope blocker prevents implementation, set H!veAI to
`BLOCKED` with a truthful blocker + lifecycle event, push it, and return:
`BLOCKED`

Then STOP.
