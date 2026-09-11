# M20-C001 V07 — Batched Whole-Sprint Correction + Evidence Closure

You are Claude, implementer/test runner only. ChatGPT owns independent audit verdicts and task closure.

Canonical repository:
`https://github.com/Sekiph82/Scrubbots`

Canonical live tracker:
repository-root `TASKS.md` ONLY.

Read first:
- `TASKS.md`
- `CLAUDE.md`
- `AGENTS.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/sessions/M20-C001/CHATGPT_AUDIT_V06.md`
- `coordination/sessions/M20-C001/CHATGPT_FULL_SURFACE_REAUDIT_V07.md`
- `coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V07.md`
- prior M20 V01-V06 prompts/audits/logs as needed for regression truth.

This is one BATCHED correction pass over the complete frozen V07 set. Do not stop after the first fix. Do not begin M21.

## 0. GitHub-first tracker start gate

Expected initial canonical state:
- milestone M20;
- current sprint/task M20-C001 V06;
- status AWAITING_AUDIT;
- required actor CHATGPT;
- progress 290/719 = 40.33% main+ui;
- overall 290/943 = 30.75%;
- lastCompletedTaskId M19-C001-V06;
- SB-M20-001..014 all `[ ]`.

BEFORE ANY V07 production edit, test/support edit, temporary sensitivity mutation or documentation edit:
1. sync `origin/main` safely and preserve owner/local work;
2. update only root `TASKS.md` Project Status lifecycle fields to:
   - Current Sprint: `M20-C001 V07 — batched whole-sprint correction + evidence closure`;
   - Current Task: `M20-C001-V07`;
   - Current Task Status: `IN_PROGRESS`;
   - Required Actor: `CLAUDE`;
   - Next Task/Action: execute the V07 frozen set, run full validation, then hand back `AWAITING_AUDIT / CHATGPT`;
   - progress/lastCompleted unchanged;
3. commit tracker-only transition;
4. push to `origin/main`;
5. verify remote contains the transition;
6. record in `CLAUDE_LOG_V07.md` that NO V07 production/test/support/doc mutation existed before successful start push.

If owner/local changes prevent a safe sync, STOP `BLOCKED`; never reset/restore them for cleanliness.

## 1. Pre-fix sensitivity on the V06 baseline

After the successful V07 IN_PROGRESS push but BEFORE production correction, reproduce/record both root defects against current V06 production.

### S-PRE-1 — duplicate CompleteClearingLoop authority

Use one real coherent board/bundle/dispatcher with zero active assignments.
- construct two separate `CompleteClearingLoop` instances;
- attempt to bind both to the same dispatcher/bundle;
- record current V06 behavior, including bind results and M20 signal-consumer count/behavior;
- if both bind, demonstrate why this is split authority: two M20 controllers are attached to the same authenticated-arrival source and can expose different `cleared_count`/outcome/reset authority.

Do NOT permanently patch during this observation.

### S-PRE-2 — truly-freed explicit agent_parent

Use a frame-aware script because true destruction is required.
- create a real Node parent and hold its reference;
- destroy it across SceneTree frame(s);
- directly record `is_instance_valid`, equality-to-null and `typeof` if available;
- pass that same explicit reference as `agent_parent` to `ScrubbotDispatcher.bind` on an otherwise coherent real/narrow bundle;
- record whether current V06 silently treats it as omitted/default parent and binds.

If Godot's typed parameter erases the distinguishing Variant information before the body, record that exact runtime fact. The correction still must provide an API boundary that distinguishes intentional omitted/null from an invalid explicit dependency; making the parameter untyped + runtime category gate is authorized.

These are sensitivity observations, not audit verdicts.

## 2. Production correction A — one M20 transaction owner per dispatcher

Close `F-M20-STRICT-001.M`.

Implement a narrow dispatcher-owned M20 arrival-consumer claim.

Preferred shape, equivalent safe design allowed:
- dispatcher stores a private NON-OWNING/weak claim to the live M20 consumer;
- a narrow method such as `_claim_m20_arrival_consumer(consumer) -> bool` succeeds when there is no live claimed consumer and fails for a different live consumer;
- an exact release/rollback method may exist only to undo a failed bind/connect transaction;
- do not use a strong reference cycle;
- do not use global singleton/service locator state;
- do not treat arbitrary diagnostic signal observers as the claim.

`CompleteClearingLoop.bind()` transaction must:
1. retain all existing exact category/coherence/active-count validation;
2. acquire the M20 claim only after the bundle is otherwise valid;
3. connect its exact arrival callback;
4. if claim or connection fails, undo any claim/connection created by this bind and remain fully unbound;
5. only then commit the loop bundle as bound.

Required behavior:
- first healthy loop bind succeeds;
- a benign diagnostic listener on `assignment_arrived` does not block the M20 owner claim;
- second different loop on the same dispatcher fails bind;
- second failure creates no second M20 transaction connection;
- first loop remains coherent/usable;
- second loop cannot activate/reset canonical state because it is unbound;
- existing single-loop behavior unchanged.

Do not move BoardState/candidate/reservation/renderer mutation into dispatcher.

## 3. Production correction B — explicit agent_parent presence law

Close `F-M20-STRICT-001.N`.

Current equality-to-null checks are not configuration authority for a Node that may be truly freed.

Required bind law:
- omitted/default `agent_parent` and actual `null` intentionally select dispatcher `self`;
- any NON-NIL Variant supplied as `agent_parent` is an explicit dependency;
- explicit dependency must be a live Node, not queued for deletion;
- capture this configured-vs-default truth before any external coherence callbacks;
- revalidate the explicit parent after those callbacks using the captured truth, not `agent_parent != null`;
- truly-freed explicit parent -> bind false, no fallback to self;
- queued explicit parent -> bind false;
- wrong/scalar explicit parent -> bind false without SCRIPT ERROR;
- healthy explicit parent -> bind true and spawned agent attaches there;
- post-bind parent liveness before `add_child` remains;
- no change to explicit factory semantics.

It is authorized to remove the static `: Node` annotation from the public `agent_parent` parameter if needed so the function can preserve Variant identity and fail closed itself. `_agent_parent` storage may remain Node-typed after validation.

Do not reinterpret actual `null` as an error.

## 4. Renderer whole-lifecycle evidence closure

Do NOT redesign the accepted V06 `_renderer_expected` production model unless a test exposes a real defect.

Add fresh direct coverage for all of the following in the same V07 suite/smoke state:

### bind/category
- omitted renderer -> healthy headless;
- explicit null -> healthy headless;
- int;
- float;
- String;
- Vector2;
- Array or Dictionary;
- arbitrary RefCounted;
- wrong Node;
- queued exact BoardRenderer;
- truly-freed exact BoardRenderer;
- healthy exact BoardRenderer.

All explicit invalid variants fail cleanly, remain unbound and create no M20 signal connection/claim.

### failed-bind metadata recovery
Using the SAME loop instance:
- fail bind with an invalid explicit renderer;
- then bind a clean headless or healthy-renderer bundle;
- prove no stale `_renderer_expected`/claim metadata survived the failed attempt.

### second-bind preservation
- bind healthy configured renderer;
- second bind attempt with null/different bundle fails;
- prove original configured renderer remains required by making that original renderer queued/dead or foreign-board and observing coherence false.

### post-bind drift/death
- reconfigure the configured renderer to a same-size different BoardState -> `is_coherent()` false and activation fails before new dispatcher work;
- dispatch a real assignment, then queue the configured renderer BEFORE arrival -> authenticated arrival preflight must clear nothing/finalize nothing; reservation+dispatcher pending state stay held until explicit reset;
- frame-aware variant: truly destroy configured renderer after dispatch but before arrival and prove the same no-clear law;
- reset afterward is safe and cleans only the original assignment/reservation as allowed.

### healthy presentation
- successful renderer clear yields target alpha 0 after dispatcher finalization;
- choose at least one unrelated cell/pixel and assert it is unchanged by the one-cell repaint.

## 5. Arrival-preflight desynchronization matrix

Use real M20 + current production dependencies unless a controlled direct seam is required. Do not rely only on M19 read-only query checks.

Create a real pending arrived assignment. When useful, temporarily disconnect the loop's arrival callback, drive the agent to the authenticated M19 arrived state, then inject the exact tuple variants through the M20 arrival boundary and reconnect/cleanup safely.

Independently cover:
- wrong owner;
- wrong target;
- wrong color;
- wrong source agent;
- unknown owner;
- missing reservation;
- same-board reservation replaced with a different owner;
- ReservationState rebound to a foreign board with a foreign replacement reservation;
- ColorCandidateIndex rebound to a foreign board;
- ColorCandidateIndex neutralized/unbound before arrival where safely controllable;
- target already CLEARED;
- renderer foreign-board/queued/dead before arrival;
- stale replay after reset;
- duplicate correct completion/current-arrival dedup.

For every failed preflight directly assert the relevant invariant:
- no new M20 clear;
- `cleared_count` unchanged;
- current dispatcher assignment is not silently finalized by the failed M20 preflight;
- M20 does not release/erase a foreign or replacement reservation;
- unrelated candidate/reservation/cell truth is preserved;
- explicit subsequent `loop.reset()` cleans only what the pair-narrow law authorizes.

## 6. Activation public-boundary matrix

Add direct M20 coverage for:
- slot -1;
- slot 5;
- non-int slot Variant;
- unavailable slot;
- valid finite origin/speed;
- start_position.x/y with NaN, +INF and -INF (representative independent cases);
- speed NaN, +INF, -INF, 0 and negative;
- absent color/no candidate;
- fully enclosed matching candidate;
- nested activation -> REENTRANT;
- activation while arrival drain active -> REENTRANT;
- reset during activation preflight -> RESETTING;
- reset during M19 dispatch -> RESETTING, never stale SUCCESS.

Every rejected activation:
- zero new agent;
- zero new current-attempt reservation;
- zero BoardState mutation;
- no slot palette/availability/activity mutation;
- no second selection/routing implementation in M20.

## 7. Fresh whole-sprint SB-M20-001..014 ledger run

Create a clearly named V07 whole-sprint section in `tests/run_tests.gd`. Existing tests remain enabled, but this section must make final task evidence easy to audit.

Directly demonstrate in the final V07 tree:

### SB-M20-001
One full healthy sequence through real production dependencies with exact post-arrival tuple:
- target CLEARED;
- target absent from raw candidate bucket;
- ProductionAccessQuery reports OPEN;
- reservation owner/target absent;
- dispatcher owner absent;
- agent queued for deletion;
- renderer alpha 0 when renderer bound.

### SB-M20-002
No target and enclosed matching target both produce no bot/no reservation/no clear.

### SB-M20-003
Frame-aware `queue_free` proof: finalized agent actually disappears after real frame(s), no orphan, no return.

### SB-M20-004
True 1x1 dimensions/count, clear once, exhausted afterward.

### SB-M20-005
One-color board repeatedly clears to exhaustion.

### SB-M20-006
Multi-color board clears through corresponding slots without cross-color corruption.

### SB-M20-007
Five configured slots produce five successful in-flight assignments where targets permit:
- five unique owner IDs;
- five distinct targets;
- five exact owner<->target reservation pairs;
- all five eventually arrive/resolve;
- resolving one preserves the other four until their own arrivals.

### SB-M20-008..011
Fresh real production spine at representative Easy, Medium, Hard, Very Hard dimensions.

### SB-M20-012
59x59 max board successful single-cell path; no M20 O(board) scan added.

### SB-M20-013
Rectangular production board successful clear.

### SB-M20-014
Use the V07 state-desync matrix plus:
- exact rollback/adversary regression;
- reset with multiple in-flight assignments;
- duplicate current arrival;
- distinct nested arrival FIFO;
- second-loop ownership rejection.

Also preserve:
- AL-028 gate A initially blocks B; clear A; SECOND REAL `activate_slot()` selects/routes B; B arrival clears;
- rapid >=25 sequential activate/arrival/clear cycles.

## 8. Rollback/reset regression lock

Freshly execute or add directly named regression arrangements for:
- candidate mutate-before-false -> verified rollback;
- reservation mutate-before-false -> verified rollback;
- candidate unrelated same-color loss sensitivity -> unrelated candidate restored or fatal rollback detected, never silently lost;
- unrelated reservation identity swap -> exact owner-map proof catches it;
- reset during candidate phase;
- reset during reservation phase;
- duplicate current arrival dropped;
- distinct second arrival FIFO/lossless;
- pair-narrow reset healthy pair + unrelated reservation;
- foreign-board replacement reservation survives;
- same-board wrong-owner replacement survives;
- post-dispatch generation barrier remains load-bearing.

Do not widen exact production category gates to make fault injection easier. Continue using test-only harnesses for adversarial candidate/reservation subclasses.

## 9. Documentation reconciliation

Update current non-historical truth only.

### tests/run_tests.gd comment
Fix M20 overview/comment text to the accepted transaction order:
`BoardState -> candidate -> reservation -> dispatcher finalize -> renderer`.

### docs/02_TECH_ARCHITECTURE.md
Remove/qualify the stale claim that simultaneous active Scrubbots are hard-bounded by slot count. Current M20 law is:
- one bot per activation;
- M20 does not mutate slot availability/activity to create a busy flag;
- per-slot/global concurrent-bot caps, queues, cooldowns or consumption remain later/design-gated unless separately implemented.

Do not alter owner-locked five-visible-slot law.

Do not rewrite historical prompts/audits.

## 10. Sensitivity after correction

After production correction, run TEMPORARY, UNCOMMITTED mutations one at a time and restore exactly before final validation.

### S1 — M20 consumer claim
Temporarily bypass/disable the new single-consumer claim. The named V07 second-loop ownership test must fail for the intended reason.

### S2 — agent_parent presence
Temporarily revert explicit parent configuration to equality/null-style logic (`agent_parent != null` / silent self fallback). The frame-aware truly-freed explicit-parent test must fail for the intended reason.

### S3 — renderer presence regression
Temporarily revert the V06 renderer-presence decision to equality/null-style logic. The frame-aware truly-freed renderer test must fail for the intended reason.

Record exact failing test names/messages/results. Restore each mutation before the next. Final production blobs must match the intended corrected files exactly.

## 11. Scope

Allowed production changes ONLY:
- `scripts/gameplay/clearing/complete_clearing_loop.gd` for M20 consumer-claim integration;
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` for the narrow M20 claim seam + explicit agent_parent presence correction.

Allowed nonproduction:
- `tests/run_tests.gd`;
- `tests/m20_*` / narrow M19/M20 support smoke files required by this prompt;
- `docs/02_TECH_ARCHITECTURE.md`;
- `coordination/sessions/M20-C001/CLAUDE_LOG_V07.md`;
- root `TASKS.md` lifecycle fields.

READ-ONLY production:
- BoardState;
- BoardRenderer;
- SlotSystem;
- ColorCandidateIndex;
- ReservationState;
- TargetSelector;
- ProductionAccessQuery;
- ProductionTargetAccess;
- ProductionRoutingSystem;
- ScrubbotAgent;
- GameplaySession;
- LevelData/level validation.

If these read-only production files require a real fix, STOP `BLOCKED`, record exact evidence, push truthful tracker/log state and do not widen scope.

## 12. Final validation

Run and individually record:
- `godot --version`;
- full root suite `godot --headless --path . -s res://tests/run_tests.gd`;
- existing `tests/m20_queue_free_smoke.gd`;
- existing V04/V05 lifecycle smokes;
- new V07 frame-aware optional-node/renderer lifecycle smoke;
- any additional prompt-created smoke;
- `git diff --check`;
- exact changed-file list;
- final blob hashes for both allowed production files;
- grep/source proof: no win/lose/scoring/session-complete/M21/slot queue/cooldown/consumption behavior introduced;
- all V01-V06 M20 tests remain enabled;
- all M19 V01-V06 tests remain enabled;
- zero final SCRIPT ERROR / Parse Error lines.

Runtime aggregate green is not enough. Map V07 log sections to the criteria groups and name direct test/smoke evidence.

## 13. Final handoff

On a clean V07:
- do NOT mark any SB-M20 task complete;
- do NOT mark COMPLETE or READY_FOR_NEXT_TASK;
- keep progress `290/719 = 40.33%` main+ui and `290/943 = 30.75%` overall;
- keep `lastCompletedTaskId = M19-C001-V06`;
- set root tracker:
  - Current Sprint: `M20-C001 V07 — batched whole-sprint correction + evidence closure`;
  - Current Task: `M20-C001-V07`;
  - Current Task Status: `AWAITING_AUDIT`;
  - Required Actor: `CHATGPT`;
  - Next Task/Action: independent V07 whole-sprint audit; if source correction is accepted, ChatGPT issues V08 validation-only final gate;
- write `coordination/sessions/M20-C001/CLAUDE_LOG_V07.md`;
- commit + push all authorized V07 changes;
- verify remote main;
- return exactly `AWAITING_AUDIT` and stop.

If a new production defect outside the frozen writable scope is exposed, STOP `BLOCKED`; do not self-expand the implementation.
