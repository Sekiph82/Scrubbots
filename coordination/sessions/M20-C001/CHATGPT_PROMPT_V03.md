# M20-C001 — Strict-v2 Trust-Boundary / Exact-State Correction V03

Status: **ISSUED — SAME FROZEN F-M20-STRICT-001..007 SET**

Canonical live tracker: repository-root `TASKS.md` only.

Read FIRST:
- root `TASKS.md`;
- `AGENTS.md`;
- `CLAUDE.md`;
- `coordination/AUDIT_POLICY.md`;
- `coordination/AUDIT_INDEX.md`;
- `coordination/VERSIONED_LOG_POLICY.md`;
- `coordination/sessions/M20-C001/CHATGPT_AUDIT_V02.md`;
- `coordination/sessions/M20-C001/CHATGPT_FULL_SURFACE_REAUDIT_V03.md`;
- this prompt;
- `CHATGPT_AUDIT_CRITERIA_V03.md`.

Expected evidence log:
`coordination/sessions/M20-C001/CLAUDE_LOG_V03.md`

Do not begin M21.

## 0. Root TASKS lifecycle

Expected synced starting state:
- M20-C001 V02;
- `AWAITING_AUDIT`;
- Required Actor `CHATGPT`;
- 290/719 main+ui, 290/943 overall;
- lastCompletedTaskId M19-C001-V06;
- SB-M20-001..014 all open.

`CHATGPT_AUDIT_V02.md` + this prompt authorize V03.

Before ANY V03 production/test edit:
1. sync `origin/main`, preserving owner work;
2. verify audit V02 + V03 freeze/prompt/criteria exist;
3. verify root tracker has not moved to another task;
4. update ONLY top Project Status lifecycle fields to:
   - Current Milestone: M20
   - Current Sprint: M20-C001 V03 — exact dependency / exact-state closure
   - Current Task: M20-C001-V03 — close residual trust-boundary and exact-state gaps
   - Current Task Status: IN_PROGRESS
   - Required Actor: CLAUDE
   - Next Task/Action: implement V03, validate, write CLAUDE_LOG_V03.md, hand off AWAITING_AUDIT to ChatGPT
   - progress unchanged
   - lastCompletedTaskId unchanged
5. commit + push the tracker-only transition BEFORE any local production/test edit;
6. verify remote main contains it.

If tracker moved: `TRACKER_STATE_CONFLICT`.
If push fails: `GITHUB_TRACKING_NOT_SYNCED`.

Do not mark any SB-M20 row complete.

## 1. Preserve accepted V02 architecture

Keep unchanged in semantics:
- separate CompleteClearingLoop;
- serialized activation;
- lossless distinct-arrival FIFO;
- transactional deferred reset;
- transaction order BoardState -> candidate -> reservation -> dispatcher -> renderer;
- authenticated M19 arrival bridge;
- renderer post-commit presentation;
- real 1x1 / second-B / five-slot / queue-free smoke coverage;
- M19 queue_free reset hardening;
- no win/lose/scoring/session/M21 behavior.

This is NOT a redesign.

## 2. Close the canonical dependency trust boundary

Production `CompleteClearingLoop.bind()` must require EXACT production script
identity for ALL canonical collaborators:
- BoardState;
- SlotSystem;
- ColorCandidateIndex;
- ReservationState;
- ScrubbotDispatcher;
- optional BoardRenderer.

Specifically replace subclass-open checks for candidate/reservation with the same
exact-script policy already used for the other canonical collaborators.

Required direct tests:
- exact ColorCandidateIndex accepted;
- candidate subclass rejected before callback use;
- exact ReservationState accepted;
- reservation subclass rejected before callback use;
- rejected subclass binds no arrival signal;
- failed bind remains fully unbound;
- original exact bundle still works;
- ordinary second bind preserves it.

Do NOT weaken production category merely to support tests.

## 3. Record pre-fix sensitivity BEFORE narrowing

Before V03 production change, against current V02 source, directly challenge the
subclass-open boundary.

### Candidate coherence spoof
Create/temporarily extend a test candidate subclass whose `is_bound_to(board)`:
- ensures it can return true for the requested board;
- then leaves itself rebound to a foreign same-size board before returning;
- repeats that behavior on every probe.

Record whether V02's double `_probe()` can be made to accept/commit this foreign
post-callback state. If exact Godot override semantics block the chosen attack,
record the actual observed behavior and source sensitivity; do not fake a pass.

### Reservation identity-swap mutate-false
Against V02, build prestate with:
- current T->owner;
- unrelated U->ownerU;
- another valid target V.

Fault callback:
1. performs the real current arrival resolution;
2. removes unrelated U->ownerU;
3. re-reserves ownerU on V;
4. leaves reservation count compatible with V02 target/count checks;
5. returns false.

Observe whether V02 reports an ordinary reservation rollback while U/V identity
is wrong. Record exact U/V owners after rollback.

### Candidate unrelated-loss mutate-false
Against V02, prestate contains target T and unrelated same-color U.
Fault callback removes T and U from candidate truth, then returns false.
Observe target rollback AND U after rollback. Record whether V02's target-only
verification notices the loss.

All pre-fix sensitivity instrumentation must be restored before final V03 state.

## 4. Move rollback sensitivity out of production dependency polymorphism

Final production bind must reject the V02 `M20CandidateSeam` /
`M20ReservationSeam` subclasses.

Do NOT delete useful historical test evidence, but final tests must not claim
those subclasses are valid production M20 collaborators.

For exceptional rollback sensitivity after exact-category narrowing, use one of:
- temporary, uncommitted mutations to the exact upstream `sync_cell()` /
  `resolve_arrival()` behavior, run targeted sensitivity, then restore byte-for-byte;
- or a clearly test-only M20 transaction harness that does not widen production
  bind categories.

No final change to M13/M14 production is authorized.

If temporary upstream source mutation is used:
- record pre-mutation blob/hash;
- run the targeted failing/rollback scenario;
- restore exact original source;
- verify final blob/hash equals the pre-mutation blob;
- run full upstream regressions afterward.

## 5. Make reservation snapshot/postcondition exact

Current V02 captures `reserved` but ignores it. Fix that.

At pre-arrival snapshot capture detached:
- sorted reserved target indices;
- exact owner for every reserved target;
- reservation count;
- current owner<->target pair.

Do not retain mutable ReservationState internals by reference.

After successful `resolve_arrival(target, owner)` prove:
- target owner == -1;
- owner target == -1;
- reserved index set equals exactly `pre_reserved - target`;
- every unrelated preexisting reserved target has the exact same owner;
- no new reserved target appeared;
- count matches the exact set.

Count equality alone is forbidden.

## 6. Make reservation rollback exact

For every pre-finalize rollback prove:
- reserved index set equals the exact pre-snapshot set;
- every reserved target has the exact pre-snapshot owner;
- current owner<->target pair restored;
- no foreign replacement reservation exists;
- dispatcher exact arrived assignment remains pending;
- target BoardState/candidate truth restored;
- renderer has not false-cleared.

Canonical exact ReservationState should mean only the current pair can have been
changed by `resolve_arrival`; if exact verification nevertheless fails, surface
`ROLLBACK_FAILED` rather than reporting ordinary rollback success.

Do not reset/rebuild all reservations on the healthy path.

## 7. Preserve candidate single-cell performance while proving unrelated truth

Because final M20 accepts only the exact audited ColorCandidateIndex, do NOT add
an O(board) candidate snapshot to every normal clear.

Permanent integration tests MUST still directly prove:
- at least two same-color ACTIVE candidates exist before one clear;
- clearing T removes T but leaves same-color U;
- another-color candidate bucket remains unchanged;
- rollback of T leaves U unchanged;
- 59x59 normal clear remains single-cell sync / no M20 board scan.

Use source/category composition plus direct representative tests rather than
keeping arbitrary candidate subclasses in the production trust boundary.

## 8. Deduplicate the currently-processing arrival

Retain lossless FIFO for distinct arrivals, but add private current-arrival
identity while `_run_transaction()` executes.

Required:
- duplicate of current owner+agent is not appended;
- duplicate already queued is not appended;
- distinct owner/agent arriving during current transaction is queued FIFO;
- current identity is cleared after every transaction outcome;
- reset clears stale queued/current bookkeeping safely;
- no public mutable queue/current identity.

M19 bridge remains exactly-once; this is defense-in-depth required by the frozen
M20 serial-arrival contract, not a change to M19 authentication.

## 9. Exact-category coherence regression

After narrowing candidate/reservation:
- bind coherent exact bundle succeeds;
- `is_coherent()` true on healthy exact bundle;
- real activation succeeds;
- real arrival clears;
- same-size different-board exact candidate/reservation cannot be committed;
- reset/recovery still works;
- no support subclass can spoof `_probe()` because it is rejected at bind.

Do not add repeated-probe folklore as a substitute for category safety.

## 10. Preserve V02 rollback/postcondition outcomes

Keep stable outcomes:
- BOARD_WRITE_FAILED;
- BOARD_POSTCONDITION_FAILED;
- CANDIDATE_ROLLBACK;
- RESERVATION_ROLLBACK;
- FINALIZE_FAILED;
- RESET_ABORTED;
- ROLLBACK_FAILED;
- CLEARED / PREFLIGHT_REJECTED.

Do not report ordinary rollback outcome unless exact verification succeeds.

## 11. Preserve direct-observability suite

Keep and re-run:
- real 1x1 clear + exhaustion;
- full AL-028 A -> second real B activation -> B arrival/clear;
- five simultaneous unique owner IDs / distinct targets / exact reservation pairs;
- first of five arrival preserves other four;
- failed-preflight reset recovery;
- reset during candidate/reservation transaction;
- nested DISTINCT arrival FIFO;
- renderer rollback remains opaque;
- dedicated frame-after-queue_free smoke;
- one-color exhaustion;
- multi-color;
- Easy/Medium/Hard/Very Hard;
- 59x59;
- rectangular;
- rapid 25+ cycles.

## 12. Upstream regression lock

Run full root suite and preserve:
- BoardState strict canonical tests;
- renderer ACTIVE/CLEARED;
- M11 session;
- M12 slots;
- M13 candidate strict suite;
- M14 reservation strict suite;
- M15-C002 selector final suite;
- M16 routing;
- M17 production routing;
- M18 agent;
- all M19 V01-V06;
- all accepted M20 V01/V02 happy-path/integration tests, adjusted only where V02
  support subclasses are no longer valid production collaborators.

## 13. Scope

Allowed production:
- `scripts/gameplay/clearing/complete_clearing_loop.gd` only, unless a test proves
  a genuine blocker.

Expected no production change to:
- BoardState;
- ColorCandidateIndex;
- ReservationState;
- TargetSelector;
- routing;
- ScrubbotAgent;
- ScrubbotDispatcher;
- BoardRenderer.

Allowed tests:
- `tests/run_tests.gd`;
- narrow `tests/support/m20_*` updates;
- existing M20 queue-free smoke.

Allowed docs:
- M20 architecture clarification;
- `CLAUDE_LOG_V03.md`;
- root TASKS lifecycle fields.

If broader upstream production change is genuinely required, STOP `BLOCKED` and
hand back to ChatGPT. Do not silently widen scope.

## 14. Validation / evidence

Record individually:
- `godot --version`;
- pre-fix sensitivity results from §3;
- exact-category bind tests;
- exact reservation-set/owner-map tests;
- duplicate-current-arrival test;
- temporary mutation/hash restoration evidence if used;
- full root headless suite;
- dedicated queue-free smoke;
- `git diff --check`;
- exact changed files;
- source proof no M21/win/scoring/session behavior;
- root TASKS lifecycle before/start/final;
- failed attempts/fixes.

Write:
`coordination/sessions/M20-C001/CLAUDE_LOG_V03.md`

## 15. Final handoff

On successful V03 implementation/testing:
- root TASKS current sprint/task -> M20-C001 V03 / M20-C001-V03;
- status -> AWAITING_AUDIT;
- Required Actor -> CHATGPT;
- progress remains 290/719 main+ui and 290/943 overall;
- lastCompletedTaskId remains M19-C001-V06;
- no SB-M20 checkbox `[x]`;
- push implementation + tests + log + tracker handoff;
- verify remote main.

Do NOT mark COMPLETE or READY_FOR_NEXT_TASK.

Return exactly:
`AWAITING_AUDIT`

Tracking push failure:
`GITHUB_TRACKING_NOT_SYNCED`

Frozen-scope blocker:
`BLOCKED`

Then stop.
