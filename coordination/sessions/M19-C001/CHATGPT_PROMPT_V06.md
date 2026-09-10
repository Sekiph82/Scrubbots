# M19-C001 — Auditor-Authored Strict-v2 Validation-Only V06

Status: **ISSUED — VALIDATION ONLY / FINAL M19 CLOSURE GATE**

H!veAI contract: **GitHub-first v3**.

V05 production correction is source-accepted by ChatGPT in:
`coordination/sessions/M19-C001/CHATGPT_AUDIT_V05.md`

V06 exists because M19 is critical/stateful, V05 changed production, and ChatGPT cannot independently execute Godot in the audit environment.

**V06 MUST NOT commit any production change.**

Expected log:
`coordination/sessions/M19-C001/CLAUDE_LOG_V06.md`

Do NOT implement M20.

## Read first

1. `.hiveai/RULES.md`
2. `.hiveai/TASKS.md`
3. `.hiveai/PROJECT.json`
4. `CLAUDE.md`
5. `coordination/AUDIT_POLICY.md`
6. `coordination/AUDIT_INDEX.md`
7. `coordination/sessions/M19-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md`
8. `coordination/sessions/M19-C001/CHATGPT_AUDIT_V02.md`
9. `coordination/sessions/M19-C001/CHATGPT_AUDIT_V03.md`
10. `coordination/sessions/M19-C001/CHATGPT_AUDIT_V04.md`
11. `coordination/sessions/M19-C001/CHATGPT_AUDIT_V05.md`
12. `coordination/sessions/M19-C001/CLAUDE_LOG_V05.md`
13. current M13-M18 + M15-C002 audited production
14. this prompt + `CHATGPT_AUDIT_CRITERIA_V06.md`

# 0. H!veAI start ordering is a hard gate

Safely sync `origin/main`; preserve all pre-existing owner work.

Expected canonical state:
- currentTaskId = `M19-C001-V06`;
- workflowState = `CHANGES_REQUIRED`;
- requiredActor = `CLAUDE`;
- progress = `278 / 719 = 38.66%`;
- lastCompletedTaskId = `M15-C002-V03`.

Before ANY V06 test/support edit or temporary sensitivity mutation:
1. update `.hiveai/TASKS.md` to `IN_PROGRESS`, actor CLAUDE;
2. append matching `hiveai-event/v1` event;
3. commit tracker/event only;
4. push to `origin/main`;
5. verify remote main contains the transition;
6. ONLY THEN edit validation files or perform temporary sensitivity mutations.

Normal successful log must explicitly state that no V06 test/support/production edit existed before the successful start push.

# 1. Production immutability lock

V05 implementation commit:
`9cf1e7d75009ba50d02db35802aa5cf345f9752a`

V05 dispatcher blob:
`0d1a6b1f6e9a6f1788ceb2078473c87bec8986e3`

Before validation, record:
- `git rev-parse 9cf1e7d75009ba50d02db35802aa5cf345f9752a:scripts/gameplay/dispatch/scrubbot_dispatcher.gd`
- current `git hash-object scripts/gameplay/dispatch/scrubbot_dispatcher.gd`

They must represent the same production blob before test work.

Committed V06 changes may include ONLY:
- `tests/run_tests.gd`;
- new/updated `tests/support/*` used exclusively for V06;
- `coordination/sessions/M19-C001/CLAUDE_LOG_V06.md`;
- `.hiveai/TASKS.md`;
- `.hiveai/EVENTS.jsonl`.

No committed change is allowed in:
- `scripts/gameplay/dispatch/*`;
- `scripts/gameplay/targeting/*`;
- `scripts/gameplay/routing/*`;
- `scripts/gameplay/agents/*`;
- BoardState / SlotSystem / GameplaySession production.

Temporary local production mutations are permitted ONLY for sensitivity testing after the H!veAI start push, but MUST be restored before the final suite, diff review, commit and push.

If a V06 adversarial test exposes a real production defect:
- do NOT fix production in V06;
- preserve the failing test/evidence where safe;
- set H!veAI `BLOCKED` with blocker `V06_VALIDATION_EXPOSED_PRODUCTION_DEFECT`;
- append event, push truthful tracker/log/evidence;
- return `BLOCKED`.

# 2. Independent transaction adversaries

Add a new narrow test section such as `_run_m19_v06_auditor_validation_tests()`.

Do not merely assert that V05 tests still exist. Exercise the same laws with fresh adversarial arrangements and direct counters/post-state.

## 2A. Bind transaction

Directly validate:
- nested bind from at least TWO different coherence collaborators cannot win;
- reset from a DIFFERENT bind-time coherence seam leaves dispatcher unbound;
- after failed/reset bind, a clean bind succeeds;
- after successful bind + one live assignment, a second bind to a different valid bundle returns false and preserves original active assignment + original reservation.

## 2B. Pre-selector pending-owner boundary

Use an independent ReservationState-compatible validation double.

Challenge baseline `get_target_for_owner(next_owner)` with:
- callback reset + returns `-1`;
- callback bundle drift + returns `-1`;
- malformed Dictionary/Vector2 return;
- valid non-`-1` return.

For every failure prove:
- selector call count = 0;
- route call count = 0;
- factory call count = 0;
- active count unchanged;
- owner counter unchanged;
- no current-attempt reservation appears.

Expected priority:
- reset -> `RESETTING`;
- drift/malformed/non-`-1` -> `COHERENCE_FAILED`.

## 2C. Selector result + canonical `-1`

Challenge:
- non-int selector return after secretly reserving current owner;
- exact `-1` with no reservation -> `NO_REACHABLE_TARGET`;
- `-1` with secret current-owner reservation -> cleanup + `COHERENCE_FAILED`;
- reset during the post-`-1` owner query -> `RESETTING`;
- drift during the post-`-1` owner query -> `COHERENCE_FAILED`.

Prove no route/factory/agent on all non-success paths and unrelated reservation remains intact.

## 2D. Positive ownership proof

Start with selector creating the exact current owner/target reservation.

Independently inject:
- malformed owner->target proof;
- malformed target->owner proof;
- owner->different-target;
- target->different-owner;
- reset during either ownership proof callback;
- bundle drift during either ownership proof callback.

Require:
- exact pair only succeeds;
- reset wins as `RESETTING`;
- otherwise `COHERENCE_FAILED`;
- no routing before proof passes;
- current pending reservation cleaned on failure;
- unrelated reservation preserved;
- owner counter advances only after exact proof.

# 3. Routing seam validation

Use call counters.

Directly validate:
- null/no cached route permits fresh compute;
- NON-NULL invalid cached route does NOT fresh-compute;
- wrong-target cached route -> `ROUTE_FAILED` + release;
- invalid-geometry cached route -> `ROUTE_FAILED` + release;
- reset inside cached RouteValidator access -> `RESETTING`, factory count 0;
- reset inside fresh RouteValidator access -> `RESETTING`, factory count 0;
- fresh route failure performs no retarget;
- a later valid dispatch can reuse a target released by route failure.

# 4. Factory / agent callback precedence

## 4A. Factory ownership

Directly validate:
- explicit Callable invalidated after bind never falls back to default agent;
- parented foreign ScrubbotAgent is rejected without being freed or cancelled;
- reused MOVING/ARRIVED/CANCELLED agent is rejected;
- default fresh factory path still succeeds.

## 4B. `_dispatcher_ownable` reset priority

Use a subclass whose `get_state()`:
- resets dispatcher;
- returns a value that makes ownability false.

Require:
- result `RESETTING`, never `AGENT_ASSIGN_FAILED`;
- assign not entered;
- no child/active;
- reservation removed;
- later clean dispatch succeeds.

## 4C. `_agent_assigned_ok` reset priority

Use a subclass that truthfully reaches assign success, then during postcondition `get_state()`:
- resets dispatcher;
- returns a state that makes postcondition false.

Require:
- `RESETTING` wins;
- add_child not entered;
- no active/orphan;
- reservation removed;
- later dispatch succeeds.

# 5. Reset / completion lifecycle

Directly validate:
- recursive dispatch from a routing or coherence callback -> `REENTRANT` with no second reservation/owner;
- reset from agent `cancel()` does not recurse/double-cancel;
- reset clears committed active assignments and reservations but does not rewind owner ids;
- stale completion after reset cannot recreate state;
- wrong source agent cannot mark another assignment arrived;
- wrong owner/target/color completion ignored;
- correct completion exactly once marks arrived;
- arrival in M19 still does NOT clear BoardState or resolve reservation.

# 6. Real production integration

Use real current:
- TargetSelector (M15-C002 V03);
- ReservationState;
- ColorCandidateIndex;
- ProductionTargetAccess / ProductionRoutingSystem where applicable;
- ScrubbotAgent.

Directly validate:
- one reachable target -> one exact assignment;
- enclosed matching ACTIVE candidate -> no work/spawn;
- duplicate target prevented across sequential slot requests;
- at least five successful independent dispatches where five reachable targets exist;
- 25+ sequential stress remains deterministic/no duplicate owner ids;
- 59x59 production maximum;
- rectangular Very Hard board.

Repeat the M15 integration adversary in a variant different from V05: targetability attempts dependency mutation/rebind during selection and no foreign reservation/split-brain route may appear.

# 7. Add-child boundary disclosure

The known headless locked-object limitation remains acceptable ONLY if represented truthfully.

V06 must source-verify that after `add_child(agent)` the dispatcher still performs BEFORE signal connect / `_active` commit:
- generation check;
- exact bundle coherence;
- generation recheck;
- instance validity;
- exact expected parent identity.

Do not claim a synchronous `_ready` self-free/reset runtime case passed if the engine harness cannot reproduce it without locked-object errors.

# 8. Auditor-authored sensitivity checks

After H!veAI start push, temporarily mutate production one case at a time, run ONLY the relevant V06 validation subset, and restore before the next mutation.

At least TWO of these THREE must be demonstrated:

### Mutation S1
Remove/bypass the post-baseline bundle-coherence gate.
Expected: pre-selector drift validation fails.

### Mutation S2
Interpret `_dispatcher_ownable` false before checking reset generation.
Expected: reset-priority validation fails with wrong failure reason.

### Mutation S3
Allow a present-but-invalid cached route to fall back to fresh routing.
Expected: invalid-cache zero-fresh-compute validation fails.

Record exact failing validation names/results in `CLAUDE_LOG_V06.md`.

Restore the exact V05 production blob before the final full run.

# 9. Final immutable-production proof

Before final commit:
- `git hash-object scripts/gameplay/dispatch/scrubbot_dispatcher.gd` must again equal `0d1a6b1f6e9a6f1788ceb2078473c87bec8986e3`;
- `git diff --exit-code 9cf1e7d75009ba50d02db35802aa5cf345f9752a -- scripts/gameplay/dispatch scripts/gameplay/targeting scripts/gameplay/routing scripts/gameplay/agents` must show no production change attributable after the V05 implementation baseline;
- `git diff --check` clean.

If any temporary production mutation remains, STOP. Do not commit.

# 10. Full validation

Run and record separately:
- `godot --version`;
- full root suite;
- total/pass/failure count;
- zero final SCRIPT ERROR / Parse Error;
- `git diff --check`;
- production-immutability checks above.

The new validation must remain additive. Do not delete/disable V01-V05 M19 tests to make V06 green.

# 11. Governance

Claude MUST NOT modify:
- root `tasks.md` completion truth;
- `coordination/AUDIT_INDEX.md`;
- any `CHATGPT_*` artifact;
- strict controllers;
- `.hiveai/PROJECT.json`;
- `.hiveai/RULES.md`;
- deprecated legacy trackers.

Claude MUST update lifecycle only in:
- `.hiveai/TASKS.md`;
- `.hiveai/EVENTS.jsonl`.

# 12. Final successful H!veAI handoff

On clean validation:
- currentTaskId = `M19-C001-V06`;
- workflowState = `AWAITING_AUDIT`;
- requiredActor = `CHATGPT`;
- blockers = [];
- progress remains `278 / 719 = 38.66%`;
- lastCompletedTaskId remains `M15-C002-V03`;
- nextAction = ChatGPT final M19 V06 audit and, if PASS, close SB-M19-001..012;
- append matching `IN_PROGRESS -> AWAITING_AUDIT` event;
- commit/push tests/support + `CLAUDE_LOG_V06.md` + tracker/events.

Do NOT mark M19 COMPLETE yourself.
Do NOT change root M19 checkboxes.
Do NOT self-audit.

Success: `AWAITING_AUDIT`
Tracking failure: `GITHUB_TRACKING_NOT_SYNCED`
Validation exposes production defect: `BLOCKED`

Then STOP.
