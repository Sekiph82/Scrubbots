# M19-C001 — Frozen Dispatcher Transaction Remainder V04

Status: **ISSUED — UPSTREAM M15 GATE CLOSED / SAME FROZEN M19 REMAINDER**

H!veAI contract: **GitHub-first v3**.

M15-C002 is independently final-closed by:
`coordination/sessions/M15-C002/CHATGPT_AUDIT_V03.md`.

This V04 may now repair ONLY the remaining M19-owned parts already frozen in:
`coordination/sessions/M19-C001/CHATGPT_AUDIT_V03.md`.

Frozen status entering V04:
- F-M19-STRICT-001 — OPEN remainder;
- F-M19-STRICT-002 — OPEN remainder;
- F-M19-STRICT-003 — OPEN remainder;
- F-M19-STRICT-004 — CLOSED, regression-only.

Do NOT implement M20 clearing/scoring/arrival resolution.

Expected log:
`coordination/sessions/M19-C001/CLAUDE_LOG_V04.md`

## Read first

1. `.hiveai/RULES.md`
2. `.hiveai/TASKS.md`
3. `.hiveai/PROJECT.json`
4. `CLAUDE.md`
5. `coordination/AUDIT_POLICY.md`
6. `coordination/AUDIT_INDEX.md`
7. `coordination/VERSIONED_LOG_POLICY.md`
8. `coordination/sessions/M19-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md`
9. `coordination/sessions/M19-C001/CHATGPT_AUDIT_V02.md`
10. `coordination/sessions/M19-C001/CHATGPT_AUDIT_V03.md`
11. `coordination/sessions/M19-C001/CHATGPT_PROMPT_V03.md`
12. `coordination/sessions/M19-C001/CLAUDE_LOG_V03.md`
13. `coordination/sessions/M15-C002/CHATGPT_AUDIT_V03.md`
14. current TargetSelector / ReservationState / routing / ScrubbotAgent contracts
15. this prompt + `CHATGPT_AUDIT_CRITERIA_V04.md`

## H!veAI start ordering is mandatory

Safely sync `origin/main` and preserve pre-existing owner work.

Re-read canonical `.hiveai/TASKS.md` after sync.

Expected live state:
- `currentTaskId = M19-C001-V04`;
- `workflowState = CHANGES_REQUIRED`;
- `requiredActor = CLAUDE`;
- progress = `278 / 719 = 38.66%`;
- `lastCompletedTaskId = M15-C002-V03`.

Before ANY V04 production/test edit:
1. tracker -> `IN_PROGRESS` / actor CLAUDE;
2. append matching `hiveai-event/v1` WORKFLOW_CHANGED row;
3. commit;
4. push to `origin/main`;
5. only then edit code/tests.

If canonical state moved: `HIVEAI_STATE_CONFLICT`.
If tracker push fails: `GITHUB_TRACKING_NOT_SYNCED`.

# 1. F-M19-STRICT-001.D — make fresh bind a guarded transaction

Current fresh `bind()` is UNBOUND-only but can re-enter while its coherence callbacks are running.

Add an explicit bind-in-progress transaction guard.

Required:
- second/nested `bind()` while `_in_bind` is true returns false before collaborator callbacks;
- outer bind validates/commits at most once;
- ordinary bind while already `_bound` remains false/preserve;
- guard clears on every validation failure;
- later clean bind recovers.

Bind-time external callbacks are:
- selector `is_bound_to(board,reservations)`;
- reservations `is_bound_to(board)`;
- routing_access `is_bound_to(board)`;
- select_access `is_coherent_with(board,routing_system,routing_access)`.

Directly inject nested `dispatcher.bind(other_bundle...)` from EACH callback.

For each:
- nested bind false;
- no nested bundle committed;
- outer valid bundle commits once;
- dispatcher ends coherent with outer bundle;
- no active assignment/reservation is created by bind.

## reset during bind

Bind must also capture the dispatcher reset generation before the first external coherence callback.

Inject `dispatcher.reset()` from EACH bind-time coherence seam at least once across the matrix.

If generation changes during outer bind:
- outer bind false;
- dispatcher remains UNBOUND;
- no collaborator refs are committed as a live bundle;
- `_in_bind` clears;
- later clean bind succeeds.

Before final commit, revalidate:
- reset generation unchanged;
- explicit factory still valid if one was configured;
- agent_parent still a live/not-queued Node.

Do not add destructive dispatcher rebind.

# 2. F-M19-STRICT-001.E / 002.D — validate selector Variant + exact reservation ownership

The dispatcher accepts a narrow RefCounted selector, therefore `select_and_reserve()` return is an external Variant contract.

Do NOT assign the raw return directly to typed `int` before validation.

Required sequence around selection:

1. establish that this pending owner id is not already owned in dispatcher ReservationState before calling selector;
2. call `selector.select_and_reserve(...)` into an untyped Variant;
3. immediately check reset generation;
4. validate return TYPE_INT;
5. re-check exact bundle coherence + generation;
6. distinguish canonical no-target `-1` from a selected target;
7. before routing/owner-id commit, prove exact reservation truth in the SAME dispatcher ReservationState:
   - `get_target_for_owner(owner_id)` returns TYPE_INT and equals selected target;
   - `get_owner(selected_target)` returns TYPE_INT and equals owner_id;
8. re-check generation/coherence after each ownership proof callback before next consequential side effect;
9. only after exact proof may `_next_owner_id` advance and routing begin.

## selector malformed/lying matrix

Use narrow selector doubles, not TargetSelector edits.

Direct cases:
- null Variant return if constructible through untyped double;
- float;
- String;
- Vector2;
- RefCounted;
- bool;
- Array/Dictionary;
- negative int other than canonical `-1`;
- `-1` with NO reservation -> canonical NO_REACHABLE_TARGET;
- `-1` but selector secretly creates owner reservation -> dependency/coherence failure + cleanup;
- positive target but stores nothing;
- positive target but owner->different target;
- positive target but selected target->different owner;
- positive target with exact owner<->target mapping -> accepted.

For malformed/lying cases:
- no route;
- no factory;
- no agent;
- no `_active` commit;
- owner id counter does not advance unless the exact reservation proof succeeded;
- any reservation demonstrably created by THIS pending selection attempt is removed with the narrowest safe exact cleanup;
- unrelated reservations remain untouched.

Use an existing stable failure reason. Prefer `COHERENCE_FAILED` for malformed selector/ownership contract violations; preserve `NO_REACHABLE_TARGET` only for canonical actual-int `-1` with no pending ownership side effect.

Do not move target-selection policy into dispatcher.

# 3. F-M19-STRICT-003.D — generation must win immediately after every external boundary

V03 armed the guard early but still misses reset-generation checks after later callback-bearing helpers.

Required law:
**after every external/overridable callback boundary, test generation before starting the next external phase. RESETTING wins over ordinary failure/coherence when reset occurred during that boundary.**

At minimum cover every `_bundle_coherent(...)` call:
- initial live coherence;
- post-selection coherence;
- post-routing coherence;
- post-factory coherence;
- post-assign coherence;
- new post-add-child coherence.

For each:
1. store coherence result;
2. check `_reset_since(my_gen)` immediately;
3. if reset: rollback pending resources as appropriate and return RESETTING;
4. only then interpret coherence result.

Also cover every `_route_ok(...)` call because `RouteValidator` invokes routing-access callbacks:
- cached route validation;
- fresh route validation.

After `_route_ok`:
- generation check immediately;
- reset -> RESETTING + exact pending rollback;
- do not proceed to factory.

Also cover overridable agent helpers:
- `_dispatcher_ownable(agent)` if it executes subclass `get_state()`;
- `agent.assign(...)`;
- `_agent_assigned_ok(...)` if it executes subclass-visible state access.

Do not begin a later phase after reset was injected in the previous callback-bearing phase.

## direct reset injection

Add sensitivity-safe hooks/doubles and inject reset from at least:
- post-selection `_bundle_coherent` callback;
- cached-route RouteValidator routing-access callback;
- fresh-route RouteValidator routing-access callback;
- post-routing `_bundle_coherent` callback;
- post-factory `_bundle_coherent` callback;
- `_dispatcher_ownable` / agent-state probe where reproducible;
- post-assign `_bundle_coherent` callback;
- `_agent_assigned_ok` state probe where reproducible.

For each applicable phase prove forbidden NEXT phase call count stays zero.

# 4. F-M19-STRICT-003.E — make reset re-entry safe

Current `reset()` sets `_resetting=true` but does not reject a nested reset already in progress.

Required:
- first line/lifecycle gate: if already `_resetting`, return stable no-op;
- one outer reset increments generation once;
- nested reset does not increment generation again;
- one outer reset visits each committed assignment once.

Create an accepted ScrubbotAgent subclass whose `cancel()` synchronously calls `dispatcher.reset()`.

Directly prove:
- no recursive reset storm;
- cancel count for that agent = 1;
- generation advances once for the outer reset;
- reservation released once/effectively absent;
- active map empty;
- no orphan child;
- later dispatch succeeds;
- owner ids remain monotonic.

## agent validity after cancel

A subclass may free/cancel itself inside `cancel()`.

After `agent.cancel()` revalidate `is_instance_valid(agent)` before:
- `get_parent()`;
- `remove_child()`;
- `free()`.

Directly test a cancel implementation that frees itself if reproducible. Reset must not fault/double-free.

# 5. F-M19-STRICT-002.E — assign return must be actual bool

Do not trust truthiness from the external/subclass assign call.

Use:
- untyped captured return;
- `typeof(result) == TYPE_BOOL`;
- only actual `true` proceeds to postcondition validation.

Direct runtime evidence must establish the Godot subclass behavior:
- if a legal ScrubbotAgent override can return non-bool, test null/int/String/Object-like classes and prove they fail closed;
- if Godot's override/typed-return rules make a non-bool return impossible, record that direct runtime/parse evidence and still keep an explicit dispatcher TYPE_BOOL gate where possible.

On non-bool/false:
- exact pending reservation released;
- dispatcher-owned fresh agent freed safely;
- no child;
- no active entry.

# 6. F-M19-STRICT-001.F / 003.F — final add_child transaction check

`add_child()` is an external lifecycle boundary because `_ready`/tree callbacks can synchronously run game code.

After `_agent_parent.add_child(agent)`:
1. check reset generation;
2. if reset, detach/free safely + release pending reservation + RESETTING;
3. re-check exact bundle coherence;
4. immediately check generation again after that coherence callback set;
5. incoherence without reset -> detach/free + release + COHERENCE_FAILED;
6. revalidate agent instance/parent identity before signal connect;
7. only then connect completion and commit `_active`.

Direct `_ready`/tree callback adversaries:
- drift selector/reservation/routing/select-access coherence without reset;
- call reset during `_ready`;
- free or reparent the just-added agent if reproducible.

Required:
- no `_active` commit after drift/reset;
- no orphan child;
- pending reservation removed;
- prior committed assignments remain intact;
- later dispatch recovers.

# 7. Current M15-C002 integration regression

Use the REAL final TargetSelector from M15-C002 V03.

At minimum prove inside M19 integration:
- targetability callback attempts to rebind TargetSelector / its bundle during selection;
- real TargetSelector rejects/contains the operation according to its final transaction law;
- dispatcher does not leak a foreign reservation;
- subsequent coherent dispatch remains usable.

Do NOT modify TargetSelector production in M19 V04.

# 8. Preserve accepted M19 V02/V03 hardening

Keep green:
- mandatory select-access coherence;
- RefCounted collaborator categories;
- initialization-only ordinary bind;
- repeated bound bind preservation;
- invalid cached route => ROUTE_FAILED + zero fresh compute;
- null cache permits fresh compute;
- explicit factory invalidation fails closed;
- factory product ownership protection;
- assign MOVING/owner/color/target postconditions;
- initial re-entry guard ordering;
- set_origin/consume_route reset checks;
- completion identity validation;
- finite request validation including NaN/INF;
- route/assign ordinary rollback;
- no retarget;
- reset after committed dispatch;
- 5-slot burst;
- 25+ rapid sequential stress;
- production routing success/enclosed no-work;
- 59x59;
- rectangular Very Hard;
- M13-M18 current regressions.

F-M19-STRICT-004 remains closed.

# 9. M20 boundary remains locked

M19 V04 MUST NOT:
- set BoardState CLEARED on arrival;
- sync ColorCandidateIndex on arrival;
- resolve/release a successful arrived reservation;
- score;
- progress slots;
- auto-dispatch follow-up bot.

Successful arrived assignment remains held for M20.

# 10. Production scope

Allowed production:
- `scripts/gameplay/dispatch/*` only.

TargetSelector is now upstream-final and READ-ONLY for this cycle.

Do NOT modify production:
- BoardState;
- ColorCandidateIndex;
- ReservationState;
- TargetSelector;
- routing algorithms/access contracts;
- ScrubbotAgent core.

Test-only subclasses/doubles are allowed.

If frozen M19 closure genuinely requires an upstream production change, STOP as `BLOCKED`; do not widen scope silently.

# 11. Governance

Claude MUST NOT modify:
- root `tasks.md` completion truth;
- `coordination/AUDIT_INDEX.md`;
- strict controllers;
- any `CHATGPT_*` artifact;
- legacy H!veAI trackers;
- `.hiveai/PROJECT.json`;
- `.hiveai/RULES.md`.

Claude MUST update lifecycle only in:
- `.hiveai/TASKS.md`;
- `.hiveai/EVENTS.jsonl`.

# 12. Validation and log

Run and record separately:
- `godot --version`;
- full root headless suite;
- zero SCRIPT/Parse errors;
- `git diff --check`;
- exact changed files;
- each V04 direct adversarial observation/counter;
- H!veAI start/final commits/events;
- any failed attempts and corrections.

Write:
`coordination/sessions/M19-C001/CLAUDE_LOG_V04.md`

# Final successful handoff

Before success:
- currentTaskId = `M19-C001-V04`;
- workflowState = `AWAITING_AUDIT`;
- requiredActor = `CHATGPT`;
- blockers = [];
- progress remains `278/719 = 38.66%`;
- lastCompletedTaskId remains `M15-C002-V03`;
- nextAction = independent ChatGPT audit of V04 against V04 criteria;
- append matching `IN_PROGRESS -> AWAITING_AUDIT` event;
- push implementation/tests/log/tracker/event to `origin/main`.

Do NOT mark COMPLETE or READY_FOR_NEXT_TASK.
Do NOT self-audit.

Success: `AWAITING_AUDIT`
Tracking failure: `GITHUB_TRACKING_NOT_SYNCED`
Genuine blocker: `BLOCKED`

Then STOP.
