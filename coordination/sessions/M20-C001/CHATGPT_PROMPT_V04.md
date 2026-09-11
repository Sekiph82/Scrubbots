# M20-C001 — Strict-v2 Lifecycle / Reset Correction V04

Status: **ISSUED — SAME FROZEN F-M20-STRICT-001..007 SET**

Canonical live tracker: repository-root `TASKS.md` only.

Read FIRST:
- root `TASKS.md`;
- `AGENTS.md`;
- `CLAUDE.md`;
- `coordination/AUDIT_POLICY.md`;
- `coordination/AUDIT_INDEX.md`;
- `coordination/VERSIONED_LOG_POLICY.md`;
- `coordination/sessions/M20-C001/CHATGPT_AUDIT_V03.md`;
- `coordination/sessions/M20-C001/CHATGPT_FULL_SURFACE_REAUDIT_V04.md`;
- this prompt;
- `CHATGPT_AUDIT_CRITERIA_V04.md`.

Expected evidence log:
`coordination/sessions/M20-C001/CLAUDE_LOG_V04.md`

Do not begin M21.

## 0. Root TASKS lifecycle

Expected synced starting state:
- M20-C001 V03;
- `AWAITING_AUDIT`;
- Required Actor `CHATGPT`;
- 290/719 main+ui, 290/943 overall;
- lastCompletedTaskId M19-C001-V06;
- SB-M20-001..014 all open.

`CHATGPT_AUDIT_V03.md` + this prompt authorize V04.

Before ANY V04 production/test edit:
1. sync `origin/main`, preserving owner work;
2. verify V03 audit + V04 freeze/prompt/criteria exist;
3. verify root tracker has not moved;
4. update ONLY top Project Status lifecycle fields to:
   - Current Milestone: M20
   - Current Sprint: M20-C001 V04 — lifecycle/reset closure
   - Current Task: M20-C001-V04 — close Node lifetime, post-dispatch and reset-collateral gaps
   - Current Task Status: IN_PROGRESS
   - Required Actor: CLAUDE
   - Next Task/Action: implement V04, validate, write CLAUDE_LOG_V04.md, hand off AWAITING_AUDIT to ChatGPT
   - progress unchanged
   - lastCompletedTaskId unchanged
5. commit + push tracker-only transition BEFORE any V04 production/test edit;
6. verify remote main contains it.

If tracker moved: `TRACKER_STATE_CONFLICT`.
If push fails: `GITHUB_TRACKING_NOT_SYNCED`.

Do not mark any SB-M20 row complete.

## 1. Preserve accepted V03 work

Do NOT redesign these accepted parts:
- exact production-script bind category for all M20 collaborators;
- exact detached reservation owner-map snapshot/postcondition/rollback;
- current-arrival owner+agent dedup;
- distinct-arrival FIFO;
- serialized activation;
- deferred transactional reset model;
- clear order BoardState -> candidate -> reservation -> dispatcher finalize -> renderer;
- renderer post-commit only;
- M19 authenticated arrival identity;
- no M21/win/lose/scoring/session/slot policy.

## 2. Run actual V03-baseline sensitivity BEFORE production correction

After V04 IN_PROGRESS is pushed, add/run targeted tests against the unchanged V03 production baseline and record ACTUAL observations before editing production.

### S1 — dying Node dependency

At minimum directly challenge:
- exact ScrubbotDispatcher queued for deletion before bind;
- exact BoardRenderer queued for deletion before bind;
- dispatcher queued/freed after a successful bind followed by `is_coherent()` / `activate_slot()` / `reset()` as safely executable.

Record whether V03 cleanly rejects or emits SCRIPT ERROR / stale coherence.

Use a dedicated smoke script if the root runner cannot safely contain an expected freed-object SCRIPT ERROR.

### S2 — reset inside M19 dispatch callback

Construct a real M20 exact bundle whose M19 dispatch uses an injected callback seam late enough that V03 would otherwise complete a successful dispatch.

Inside that M19 callback call ONLY `loop.reset()`.

Record V03 result returned from `activate_slot()` and post-return dispatcher/reservation state.

The intended sensitivity is the stale-success window: M20 reset generation moves, heavy dispatcher reset is deferred, M19 may still return success, and V03 does not bracket that downstream boundary.

### S3 — reservation drift before M20 reset

Using real exact ReservationState:
1. create one real active dispatch on board A;
2. destructively rebind the same ReservationState object to board B;
3. reserve a B target using the same numeric owner token;
4. call `loop.reset()`;
5. directly observe whether the B reservation survived.

Also test same-board replacement if practical: owner O holds V != immutable dispatch target T before reset.

Record exact pre/post owner and target values.

These pre-fix observations are mandatory. Do not replace them with “would fail” prose.

## 3. Close Node lifetime boundary — F-M20-STRICT-001.K

Exact script identity is necessary but not sufficient for Node collaborators.

### Bind-time law

Before ANY `get_script()`/method/property call on a Node/Object dependency:
- prove non-null object;
- prove `is_instance_valid()`;
- for dispatcher/renderer production use, reject `is_queued_for_deletion()`;
- then compare exact script identity.

A freed or queued dispatcher/renderer must return false from bind without SCRIPT ERROR and without signal connection.

Do not apply `is_queued_for_deletion()` to RefCounted collaborators.

### Live coherence law

`_probe()` / `is_coherent()` must prove dispatcher and optional renderer are live before calling their coherence methods.

Required:
- healthy exact live bundle -> true;
- renderer queued/dead -> false;
- dispatcher queued/dead -> false;
- no SCRIPT ERROR.

### Activation law

Activation against a dead/dying dispatcher fails closed with a stable DispatchResult failure; it never calls a dead dispatcher.

### Reset law for invalid dispatcher

`reset()` must never call an already-invalid dispatcher.

If dispatcher is merely queued for deletion but still callable, cleanup may run while valid; future coherence must still be false.

If dispatcher is already destroyed, make M20 local reset/queue/current bookkeeping deterministic without claiming impossible recovery of a dependency already externally destroyed.

Do not mutate BoardState/candidate/reservation merely to hide a destroyed dispatcher.

### Current-law prose

Fix the stale bind comment that still says candidate/reservation subclasses are accepted. Final source must consistently state exact production categories; fault seams are test-only.

## 4. Bracket `dispatcher.dispatch()` as an M20 transaction boundary — F-M20-STRICT-002.K

Current V03 returns dispatcher result directly. Replace with explicit post-boundary ordering:

1. call dispatcher and capture result;
2. check M20 `_reset_requested` / `_generation != my_gen` BEFORE trusting result;
3. if reset moved, return `DispatchResult.FailureReason.RESETTING`;
4. otherwise re-check full LIVE M20 coherence;
5. if coherence was lost, request deterministic M20 reset/cleanup and return `COHERENCE_FAILED`;
6. only if both checks pass return the captured dispatcher result.

The outer `activate_slot()` must still clear `_in_activation`, drain any pending reset safely, then return the corrected result.

### Direct reset adversary

Inside an M19 callback after M20 preflight:
- call only `loop.reset()`;
- permit M19 to otherwise succeed;
- corrected `activate_slot()` returns RESETTING, never stale SUCCESS;
- when the call returns, dispatcher active state and current-attempt reservation are cleaned;
- no agent is left active/orphaned;
- any already-consumed owner id remains monotonically consumed, never rewound/reused;
- later ordinary activation recovers.

### Direct M20-only coherence adversary

Bind a real renderer. From an M19 callback queue-free that renderer, without otherwise invalidating M19's own bundle.

Corrected M20 must:
- detect post-dispatch renderer liveness/coherence loss;
- never expose the raw M19 SUCCESS;
- request safe cleanup/reset;
- return COHERENCE_FAILED;
- leave no live dispatcher assignment/current reservation when `activate_slot()` returns.

A new healthy loop/bundle may be used to prove later recovery because the original renderer is intentionally dying.

## 5. Make dispatcher reset pair-narrow and board-safe — F-M20-STRICT-006.K

Minimal authorized upstream hardening:
`scripts/gameplay/dispatch/scrubbot_dispatcher.gd` reset path ONLY.

Current owner-wide cleanup:
`release_for_owner(owner_id)`

is not safe after ReservationState drift/replacement.

For each active immutable dispatcher entry `(owner O, target T)`:
1. prove reservation dependency still reports bound to the dispatcher's original board with an ACTUAL bool true;
2. prove `get_target_for_owner(O)` is exactly T;
3. prove `get_owner(T)` is exactly O;
4. only then call exact `release(T, O)`;
5. otherwise skip reservation mutation;
6. regardless, continue disconnect/cancel/queue-free of the dispatcher-owned agent and clear the dispatcher's own active bookkeeping.

Do NOT use `release_for_owner(O)` as reset authority for active-entry cleanup.

Do not broaden any other M19 behavior.

### Required direct cases

A. healthy original board + exact T<->O -> reset releases T only.

B. ReservationState rebound to foreign board B, owner O on a different B target -> reset preserves B reservation.

C. foreign board B uses same numeric target index T and owner O -> reset STILL preserves it because board identity is foreign.

D. same original board but O now owns V != T -> reset preserves V.

E. current reservation missing -> reset does not invent/mutate another reservation.

In B-E the dispatcher must still cancel/clear its own active agent/bookkeeping.

M19 owner counter remains monotonic.

## 6. Preserve reset / arrival semantics

Keep green:
- reset during candidate-phase test harness;
- reset during reservation-phase harness;
- queued distinct arrival cleared on reset;
- no BoardState rewind of already committed clears;
- current arrival identity cleared;
- no stale replay clear;
- later healthy activation works where the dependency bundle itself is healthy.

## 7. Preserve exact reservation and candidate truth

Keep V03 owner-map exactness tests green.

Keep direct unrelated truth:
- T clear removes T only;
- same-color U survives;
- other-color bucket survives;
- rollback restores target and unrelated candidate truth;
- identity-swap harness cannot report ordinary rollback success.

Do not add normal-path full-board rebuild/snapshot.

## 8. Preserve direct-observability matrix

Re-run:
- true 1x1 clear + exhaustion;
- full AL-028 A -> second real B activation -> B arrival/clear;
- five simultaneous unique owners/targets/reservation pairs;
- first-of-five preserves other four;
- failed-preflight reset recovery;
- nested DISTINCT arrival FIFO;
- current duplicate arrival dedup;
- renderer rollback opaque;
- queue_free frame smoke;
- one-color exhaustion;
- multi-color;
- Easy/Medium/Hard/Very Hard;
- 59x59;
- rectangular;
- rapid 25+ cycles.

## 9. Upstream regression lock

Run full root suite and preserve:
- BoardState;
- BoardRenderer;
- M11 session;
- M12 slots;
- M13 candidate;
- M14 reservation;
- M15-C002 selector;
- M16 routing;
- M17 production routing;
- M18 agent;
- ALL M19 V01-V06 tests;
- M20 V01-V03 accepted tests.

Add focused M19 reset tests for the pair-narrow cleanup but do not alter unrelated M19 semantics.

## 10. Scope

Authorized production:
- `scripts/gameplay/clearing/complete_clearing_loop.gd`;
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` RESET hardening only.

No other production change is authorized unless a direct V04 test proves a blocker. If so STOP `BLOCKED` and document it.

Allowed tests:
- `tests/run_tests.gd`;
- narrow `tests/support/m20_*` and existing M19 support reuse;
- narrow lifecycle smoke if required.

Allowed docs:
- M20 architecture clarification;
- `CLAUDE_LOG_V04.md`;
- root TASKS lifecycle fields.

Claude MUST NOT edit any `CHATGPT_*` artifact, audit verdict, AUDIT_INDEX, or SB-M20 completion checkbox.

## 11. Validation / evidence

Record individually:
- `godot --version`;
- ACTUAL V03-baseline S1/S2/S3 observations before production correction;
- targeted post-fix lifecycle tests;
- targeted post-dispatch reset/coherence tests;
- targeted pair-narrow dispatcher reset tests;
- full root headless suite;
- dedicated queue-free smoke;
- any new lifecycle smoke;
- zero final SCRIPT ERROR / Parse Error;
- `git diff --check`;
- exact changed files;
- source proof no M21/win/scoring/session behavior;
- root TASKS lifecycle before/start/final;
- all failed attempts/fixes.

Write:
`coordination/sessions/M20-C001/CLAUDE_LOG_V04.md`

## 12. Final handoff

On successful correction/testing:
- root TASKS current sprint/task -> M20-C001 V04 / M20-C001-V04;
- status -> AWAITING_AUDIT;
- Required Actor -> CHATGPT;
- progress remains 290/719 main+ui and 290/943 overall;
- lastCompletedTaskId remains M19-C001-V06;
- no SB-M20 checkbox `[x]`;
- push implementation + tests + log + tracker handoff;
- verify remote main.

Do NOT mark COMPLETE or READY_FOR_NEXT_TASK.

A clean V04 is still not final M20 closure because production changed. ChatGPT will issue an auditor-authored V05 validation-only gate after a clean V04 source audit.

Return exactly:
`AWAITING_AUDIT`

Tracking push failure:
`GITHUB_TRACKING_NOT_SYNCED`

Frozen-scope blocker:
`BLOCKED`

Then stop.
