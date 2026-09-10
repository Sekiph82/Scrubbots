# M19-C001 — Transaction Boundary Closure V05

Status: **ISSUED — SAME FROZEN M19 SET / V04 REMAINDER**

H!veAI contract: **GitHub-first v3**.

This V05 continues the SAME M19 frozen set. Do not open new M19 responsibilities.

Frozen status entering V05:
- F-M19-STRICT-001 — OPEN remainder;
- F-M19-STRICT-002 — OPEN evidence/remainder;
- F-M19-STRICT-003 — OPEN remainder;
- F-M19-STRICT-004 — CLOSED, regression-only.

Canonical audit basis:
`coordination/sessions/M19-C001/CHATGPT_AUDIT_V04.md`

Expected log:
`coordination/sessions/M19-C001/CLAUDE_LOG_V05.md`

Do NOT implement M20 clearing/scoring/arrival resolution.

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
11. `coordination/sessions/M19-C001/CHATGPT_AUDIT_V04.md`
12. `coordination/sessions/M19-C001/CLAUDE_LOG_V04.md`
13. `coordination/sessions/M15-C002/CHATGPT_AUDIT_V03.md`
14. current dispatcher / TargetSelector / ReservationState / routing / ScrubbotAgent
15. this prompt + `CHATGPT_AUDIT_CRITERIA_V05.md`

# 0. H!veAI start ordering is a hard gate

The V04 process nonconformance MUST NOT repeat.

Safely sync `origin/main`; preserve pre-existing owner work; re-read the canonical tracker.

Expected live state:
- currentTaskId = `M19-C001-V05`;
- workflowState = `CHANGES_REQUIRED`;
- requiredActor = `CLAUDE`;
- progress = `278 / 719 = 38.66%`;
- lastCompletedTaskId = `M15-C002-V03`.

Before ANY V05 production OR test edit, including local uncommitted edits:
1. update `.hiveai/TASKS.md` -> `IN_PROGRESS`, actor CLAUDE;
2. append matching `hiveai-event/v1` WORKFLOW_CHANGED event;
3. commit tracker/event only;
4. push to `origin/main`;
5. verify remote main contains that start transition;
6. ONLY THEN edit production/tests.

The log must explicitly state whether any V05 production/test edit existed before the successful start push. Normal successful answer requires **NO**.

If task/actor changed: `HIVEAI_STATE_CONFLICT`.
If start tracking push fails: `GITHUB_TRACKING_NOT_SYNCED` and STOP before edits.

# 1. F-M19-STRICT-001.G / 003.H — bracket the pending-owner baseline

Before selector invocation, the dispatcher queries the pending owner in ReservationState.

Required exact sequence:
1. call `get_target_for_owner(owner_id)` into an untyped Variant;
2. immediately check reset generation;
3. require TYPE_INT;
4. call exact bundle coherence;
5. immediately check reset generation again;
6. require coherence true;
7. require value exactly `-1`;
8. only then enter `selector.select_and_reserve(...)`.

If the baseline callback:
- calls reset -> `RESETTING`;
- rebinds/drifts ReservationState/candidate/selector bundle but returns `-1` -> `COHERENCE_FAILED`;
- returns malformed -> `COHERENCE_FAILED`.

Direct counters must prove selector call count remains ZERO in all three cases.

No owner id advance, route, factory, agent, active entry or new reservation.

# 2. F-M19-STRICT-003.G — bracket the canonical selector `-1` side-effect query

After selector returns actual int `-1`, the dispatcher checks whether the selector secretly created a pending-owner reservation.

Treat `get_target_for_owner(owner_id)` as a full external callback boundary.

Required sequence:
1. call into untyped Variant;
2. check reset generation FIRST;
3. require TYPE_INT;
4. re-check exact bundle coherence;
5. check generation immediately after coherence;
6. only then interpret the returned ownership value.

Outcomes:
- reset during callback -> cleanup this pending owner where possible + `RESETTING`;
- non-reset bundle drift -> cleanup pending owner + `COHERENCE_FAILED`;
- malformed return -> cleanup pending owner + `COHERENCE_FAILED`;
- actual `-1`, coherent, no reset -> canonical `NO_REACHABLE_TARGET`;
- any non-`-1` owner target -> selector contract violation, cleanup pending owner + `COHERENCE_FAILED`.

Directly prove no routing/factory/agent starts on reset/drift/malformed paths.

# 3. F-M19-STRICT-003.I — generation must beat ownability/postcondition verdicts

V04 checks generation AFTER these helper verdicts are already interpreted. Correct the order.

## `_dispatcher_ownable(agent)`

Required:
1. store helper verdict;
2. immediately check reset generation;
3. if reset occurred: exact reservation rollback, dispose only dispatcher-owned fresh agent safely, return `RESETTING`;
4. only then interpret ownability false as `AGENT_ASSIGN_FAILED`.

Create a ScrubbotAgent subclass whose `get_state()`:
- synchronously calls `dispatcher.reset()`;
- returns a non-UNASSIGNED state so `_dispatcher_ownable()` itself returns false.

Expected result MUST be `RESETTING`, not `AGENT_ASSIGN_FAILED`.
Prove assign call count = 0, no child/active, reservation absent.

## `_agent_assigned_ok(...)`

Required:
1. store postcondition helper verdict;
2. immediately check reset generation;
3. reset -> rollback/free + `RESETTING`;
4. only then interpret false helper verdict as `AGENT_ASSIGN_FAILED`.

Create a legal subclass whose assign path reaches the postcondition check and whose `get_state()` during that postcondition probe:
- triggers `dispatcher.reset()`;
- returns a state that makes the helper false.

Expected result MUST be `RESETTING`.
Prove add_child not reached, no active entry, reservation absent.

Do not change ScrubbotAgent production.

# 4. Directly close malformed ownership-proof evidence

V04 source validates positive ownership proof return types, but V05 must directly observe the malformed callback classes.

Use a narrow ReservationState-compatible test double or wrapper, without changing ReservationState production.

Direct positive-target cases:
- `get_target_for_owner(owner_id)` returns float/String/null/Object-like after selector created exact reservation;
- `get_owner(target)` returns float/String/null/Object-like after selector created exact reservation.

For each:
- stable `COHERENCE_FAILED` unless reset was injected;
- no route/factory/agent;
- owner id not advanced;
- pending reservation attributable to this attempt is absent after failure;
- unrelated reservation remains.

Also directly cover malformed pre-selector pending-owner baseline return.

# 5. Real M15-C002 V03 integration adversary

M15 production is READ-ONLY.

Create a real M19 dispatch bundle using:
- current real TargetSelector;
- real ReservationState;
- real/current ColorCandidateIndex;
- deterministic routing/access.

Inside `access_query.is_targetable()` attempt at least:
1. `TargetSelector.bind(...)` to a different coherent bundle while selection is in progress;
2. ReservationState/candidate dependency drift/rebind where the final M15 transaction law is applicable.

Directly prove:
- real TargetSelector returns/fails according to M15-C002 V03 law;
- no foreign ReservationState reservation is orphaned;
- dispatcher performs no split-brain route/agent commit;
- original/prior committed assignment, if present, is preserved;
- after restoring a coherent bundle or using a fresh coherent bundle, dispatch succeeds.

Do NOT modify TargetSelector production.

# 6. Preserve V04 bind/reset/route/factory/add-child source hardening

Keep all V04 accepted behavior green:
- `_in_bind` transaction guard;
- nested bind rejected from all four bind coherence seams;
- reset-during-bind leaves unbound and later bind recovers;
- parent/factory revalidated before bind commit;
- selector raw Variant matrix;
- positive exact owner<->target proof before owner-id advance;
- route validation generation checks;
- post-selection/routing/factory/assign/add coherence generation checks;
- reset re-entry no-op while `_resetting`;
- post-cancel instance revalidation;
- assign actual-bool gate;
- add_child post-generation/coherence/instance/parent source guards;
- invalid cached route does not fresh-route;
- explicit invalidated factory does not fall back;
- no retarget.

# 7. Validation-only source sensitivity for the two corrected orderings

Add direct tests that would fail if either ordering regresses:
- move generation check below `_dispatcher_ownable` verdict interpretation -> ownability-reset test must fail;
- move generation check below `_agent_assigned_ok` verdict interpretation -> postcondition-reset test must fail;
- remove coherence after pre-owner baseline -> baseline-drift test must fail;
- remove generation/coherence after canonical `-1` owner query -> reset/drift test must fail.

Record at least one temporary mutation/sensitivity proof in `CLAUDE_LOG_V05.md`; restore production before final run.

# 8. Full regression

Run the full root suite and preserve:
- M13-M18 strict regressions;
- M15-C002 V01/V02/V03 regressions;
- M19 V01-V04 regressions;
- 5-slot burst;
- rapid 25+ sequential dispatch;
- production reachable success;
- enclosed candidate no-work;
- real 59x59;
- rectangular Very Hard;
- completion identity;
- finite request NaN/INF boundaries.

# 9. M20 boundary remains locked

Do NOT:
- mutate BoardState ACTIVE->CLEARED on arrival;
- sync candidate index on arrival;
- resolve/release successful arrived reservation;
- score;
- progress slots;
- auto-dispatch follow-up.

# 10. Production scope

Allowed production change:
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` ONLY.

Test-only support changes are allowed.

READ-ONLY production:
- BoardState;
- ColorCandidateIndex;
- ReservationState;
- TargetSelector;
- routing/access algorithms;
- ScrubbotAgent.

If a frozen M19 fix genuinely requires upstream production modification, set H!veAI `BLOCKED`, push truthful event/state, and STOP.

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

# 12. Final validation and log

Record separately:
- `godot --version`;
- full root headless suite;
- zero final SCRIPT/Parse errors;
- `git diff --check`;
- exact production/test changed files;
- direct result/counter for every new V05 adversary;
- temporary sensitivity mutation and restoration;
- H!veAI start/final commits/events;
- explicit statement: **no V05 production/test edit existed before the successful IN_PROGRESS push**.

Write:
`coordination/sessions/M19-C001/CLAUDE_LOG_V05.md`

# Final H!veAI handoff

On successful implementation/validation:
- currentTaskId = `M19-C001-V05`;
- workflowState = `AWAITING_AUDIT`;
- requiredActor = `CHATGPT`;
- blockers = [];
- progress remains `278/719 = 38.66%`;
- lastCompletedTaskId remains `M15-C002-V03`;
- nextAction = independent ChatGPT V05 audit;
- append matching IN_PROGRESS -> AWAITING_AUDIT event;
- commit/push production + tests + `CLAUDE_LOG_V05.md` + canonical tracker/event to `origin/main`.

Do NOT mark COMPLETE / READY_FOR_NEXT_TASK.
Do NOT self-audit.

Success: `AWAITING_AUDIT`
Tracking failure: `GITHUB_TRACKING_NOT_SYNCED`
Genuine blocker: `BLOCKED`

Then STOP.

Because V05 changes production, even a clean V05 will normally be followed by a narrow auditor-authored **validation-only V06** before final M19 task closure, since ChatGPT cannot independently run Godot.
