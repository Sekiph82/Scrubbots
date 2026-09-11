# M20-C001 — ChatGPT Independent Audit V04

Decision: **SOURCE_CORRECTION_ACCEPTED / VALIDATION_ONLY_V05_REQUIRED**

Audited implementation commit:
`50be126cc7bf82e62650d81287c0bf2ba4ca7064`

Tracker start-transition commit:
`ee51cdfa89e52f53c795d32e1efa85ce10636e78`

Accepted V04 production blobs:
- `scripts/gameplay/clearing/complete_clearing_loop.gd` = `f00c34021da85e596df58f08857acde8846dd8a4`
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` = `1709b8c8ebf7595596bdf8cbd059f04bf1196ea3`

Prompt:
`coordination/sessions/M20-C001/CHATGPT_PROMPT_V04.md`

Criteria:
`coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V04.md`

Claude evidence:
`coordination/sessions/M20-C001/CLAUDE_LOG_V04.md`

Prior audit:
`coordination/sessions/M20-C001/CHATGPT_AUDIT_V03.md`

## Runtime / independence

Claude reports Godot `4.7.1.stable.official.a13da4feb`, full root suite **3563 / 3563 ALL PASS**, M20 queue-free smoke PASS, M20 V04 lifecycle smoke PASS, and clean `git diff --check`.

These runtime results are E1/E2. ChatGPT cannot independently execute Godot in this audit environment.

ChatGPT independently inspected:
- root `TASKS.md` sole-live-tracker state;
- V04 prompt / criteria / log;
- start -> implementation Git order;
- exact V04 implementation commit and scope;
- current `CompleteClearingLoop` and `ScrubbotDispatcher` source;
- V04 lifecycle / post-dispatch / pair-narrow reset tests;
- V04 lifecycle smoke;
- the post-correction M20 public/stateful surface.

This is E3 source/diff/test-design evidence.

## Root TASKS lifecycle — PASS

The V04 start transition `ee51cdf` was committed and pushed before V04 production/test edits. The implementation commit is `50be126`. Root `TASKS.md` is now truthfully `M20-C001 V04 / AWAITING_AUDIT / CHATGPT`, progress remains `290/719` main+ui and `290/943` overall, lastCompletedTaskId remains `M19-C001-V06`, and no SB-M20 checkbox was closed.

## Actual V03-baseline sensitivity — PASS WITH EVIDENCE GAPS NOTED

Claude did run a throwaway baseline test against unchanged V03 production before the correction and directly reproduced the three material defects:

- **S1 dispatcher lifecycle:** queued exact dispatcher was accepted by V03 bind (`true`).
- **S2 stale-success window:** `loop.reset()` injected inside M19 dispatch still let V03 `activate_slot()` return `success=true / NONE`, while dispatcher/reservations were torn down on unwind.
- **S3 reset collateral:** after destructive ReservationState rebind to board B and reuse of the same numeric owner token, V03 reset removed the foreign board-B reservation.

This is materially stronger than V03's source-derived prose.

Two V04-criteria evidence details were not individually recorded in the baseline log:
- queued renderer was not separately shown in the verbatim pre-fix output;
- the S2 pre-fix owner-counter value was not printed.

These are validation evidence gaps, not new production defects. V05 must cover them directly.

## F-M20-STRICT-001.K — Node lifetime correction — SOURCE ACCEPTED

V04 correctly distinguishes RefCounted exact-category dependencies from Node lifecycle dependencies.

At bind:
- dispatcher and optional renderer are required to be valid live Nodes;
- `is_instance_valid()` and `not is_queued_for_deletion()` are proved before `get_script()`;
- exact script identity is checked only after liveness.

At live coherence:
- dispatcher and optional renderer liveness is checked before calling `is_bound_to()`.

At reset:
- an already-invalid dispatcher is not called;
- a queued-but-still-valid dispatcher may still receive reset cleanup, while future coherence stays false;
- M20 local queue/current bookkeeping is still cleared deterministically.

The dedicated lifecycle smoke exercises a truly destroyed dispatcher across real SceneTree frames and records no M20 SCRIPT ERROR.

No material Node-lifetime defect was found in the V04 source.

## F-M20-STRICT-002.K — post-dispatch M20 transaction barrier — SOURCE ACCEPTED

V04 no longer returns the raw `dispatcher.dispatch()` result directly.

The current order is:
1. capture dispatcher result;
2. check M20 reset request/generation;
3. if moved, return RESETTING;
4. otherwise re-check full live M20 coherence;
5. on coherence loss, request deterministic M20 reset and return COHERENCE_FAILED;
6. only otherwise return the captured dispatcher result.

The outer `activate_slot()` then clears the activation guard and drains pending reset before returning.

The dedicated reset-inside-M19 test directly observes:
- no stale success;
- RESETTING;
- no active dispatcher assignment;
- no current reservation;
- later recovery.

The renderer-lifecycle adversary observes COHERENCE_FAILED and cleanup rather than exposing raw M19 success.

No material source defect was found in this barrier.

## F-M20-STRICT-006.K — pair-narrow board-safe dispatcher reset — SOURCE ACCEPTED

The V04 reset path no longer uses owner-wide `release_for_owner(owner_id)` as active-entry cleanup authority.

For each immutable active `(owner O, target T)` it now requires:
- ReservationState `is_bound_to(_board)` returns actual bool true;
- `get_target_for_owner(O) == T`;
- `get_owner(T) == O`;
- only then exact `release(T, O)`.

Otherwise reservation mutation is skipped, while agent disconnect/cancel/queue-free and `_active` cleanup continue.

Direct cases cover:
- healthy original pair release;
- foreign board / different target preservation;
- foreign board / same numeric target preservation;
- same-board O->V replacement preservation;
- missing current pair;
- monotonic owner counter.

No material M20 vertical-slice defect was found in this reset source.

### Validation evidence remainder

The V04 tests do not make two criteria maximally direct:
- healthy reset case A does not also carry a separate unrelated reservation and prove it survives;
- missing-pair case E does not also carry a separate unrelated reservation and prove it survives.

V05 must add those arrangements.

## Accepted V03 behavior preserved

Source/diff inspection found V03 accepted laws intact:
- exact production categories for all M20 canonical collaborators;
- exact reservation owner-map snapshot/postcondition/rollback;
- current-arrival dedup;
- lossless distinct-arrival FIFO;
- serialized activation;
- deferred transactional reset;
- BoardState -> candidate -> reservation -> dispatcher -> renderer order;
- renderer post-commit only;
- authenticated M19 arrival bridge;
- no M21/win/lose/scoring/session/slot policy.

## Scope — PASS

V04 production changes are limited to:
- `scripts/gameplay/clearing/complete_clearing_loop.gd`;
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` reset hardening.

No BoardState, SlotSystem, ColorCandidateIndex, ReservationState, TargetSelector, routing, ScrubbotAgent or BoardRenderer production change was introduced.

## Post-V04 attack-surface sweep

No new material M20 production defect was found after the V04 correction.

Checked classes include:
- bind and live Node lifetime;
- activation preflight and post-dispatch return trust;
- reset during M19 callback work;
- renderer-only M20 coherence loss;
- reservation drift/rebind before reset;
- same-board owner replacement;
- missing reservation;
- reset with queued/destroyed dispatcher;
- duplicate/current/distinct arrival behavior;
- exact reservation/candidate rollback laws;
- downstream direct integrations and scale boundaries.

## Strict-v2 stage decision

M20 is a critical/stateful vertical-slice orchestrator. V04 changed production code. ChatGPT can provide E3 source/diff/test-design evidence but cannot independently run Godot.

Under `coordination/AUDIT_POLICY.md`, V04 source correction therefore cannot directly final-close M20.

Next stage is **M20-C001 V05 validation-only**.

V05 must:
- commit zero production changes;
- lock the accepted V04 production blobs;
- add auditor-authored fresh adversarial validation tests;
- directly close the small V04 evidence gaps noted above;
- execute load-bearing temporary mutations for Node-liveness, post-dispatch generation barrier and pair-narrow reset, restoring exact production blobs before final run;
- rerun full root suite and lifecycle smokes on Godot 4.7.1;
- stop at AWAITING_AUDIT.

If V05 passes independent audit, ChatGPT may final-close M20's 14 tasks and advance to the next authorized frontier.

## Frozen finding status after V04

- F-M20-STRICT-001 — **SOURCE_CORRECTION_ACCEPTED / pending V05 validation**
- F-M20-STRICT-002 — **SOURCE_CORRECTION_ACCEPTED / pending V05 validation**
- F-M20-STRICT-003 — **SOURCE_CORRECTION_ACCEPTED / pending V05 validation**
- F-M20-STRICT-004 — **SOURCE_CORRECTION_ACCEPTED / pending V05 validation**
- F-M20-STRICT-005 — **SOURCE_CORRECTION_ACCEPTED / pending V05 validation**
- F-M20-STRICT-006 — **SOURCE_CORRECTION_ACCEPTED / pending V05 validation**
- F-M20-STRICT-007 — **SOURCE_CORRECTION_ACCEPTED / pending V05 validation**

No new top-level finding ID is opened.

## Verdict

**SOURCE_CORRECTION_ACCEPTED / VALIDATION_ONLY_V05_REQUIRED**

Do not close SB-M20 tasks yet. Do not begin M21.