# M20-C001 V09 — Final Exact-Evidence Whole-Sprint Validation-Only Gate

You are Claude, validation/test runner only. ChatGPT owns independent audit verdicts and task closure.

Canonical repository:
`https://github.com/Sekiph82/Scrubbots`

Canonical live tracker:
repository-root `TASKS.md` ONLY.

Read first:
- `TASKS.md`
- `CLAUDE.md`
- `AGENTS.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/sessions/M20-C001/CHATGPT_AUDIT_V08.md`
- `coordination/sessions/M20-C001/CHATGPT_FULL_SURFACE_REAUDIT_V09.md`
- `coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V09.md`
- prior V01-V08 M20 evidence as regression truth when needed.

This is a FINAL EVIDENCE-ONLY gate. Production is already source-accepted.

## 0. GitHub-first tracker start gate

Expected initial state:
- milestone M20;
- current sprint/task M20-C001 V08 / M20-C001-V08;
- status AWAITING_AUDIT;
- actor CHATGPT;
- progress 290/719 = 40.33% main+ui;
- overall 290/943 = 30.75%;
- lastCompletedTaskId M19-C001-V06;
- SB-M20-001..014 all `[ ]`.

BEFORE ANY V09 test/smoke/support edit or temporary sensitivity mutation:
1. sync `origin/main` safely; preserve owner/local work;
2. update ONLY root `TASKS.md` Project Status lifecycle fields to:
   - Current Sprint: `M20-C001 V09 — final exact-evidence validation-only gate`;
   - Current Task: `M20-C001-V09`;
   - Current Task Status: `IN_PROGRESS`;
   - Required Actor: `CLAUDE`;
   - Next Task/Action: execute complete V09 exact-evidence gate, then hand back `AWAITING_AUDIT / CHATGPT`;
   - progress/lastCompleted unchanged;
3. commit tracker-only transition;
4. push to `origin/main`;
5. verify remote transition;
6. record that NO V09 test/support/smoke edit and NO sensitivity mutation existed before the successful start push.

If safe sync is blocked by owner/local work, STOP `BLOCKED`. Never reset/restore owner work for cleanliness.

## 1. Production immutability lock

Before validation record exact blobs:
- loop `06391839523cbc27e88a4b3ef12b730012cd45fa`;
- dispatcher `eee10149e4f116af6706beec832042352bf3a6dd`.

Committed V09 changes under `scripts/**` are FORBIDDEN.

If any V09 test exposes a production defect:
- do NOT fix production;
- restore any temporary sensitivity edit;
- log exact failure;
- return `BLOCKED / V09_VALIDATION_EXPOSED_PRODUCTION_DEFECT`.

## 2. Fresh V09 test section

Add one clearly named `_run_m20_v09_exact_evidence_tests()` section to `tests/run_tests.gd` and keep every prior M19/M20 regression enabled.

It must call separate clearly named groups for:
- owner claim lifecycle;
- activation exact snapshots;
- arrival-preflight exact invariants;
- SB-M20-001..014 exact final ledger;
- rollback/reset/contention exact matrix.

Use fresh arrangements. Reuse low-level wiring helpers only where they do not substitute for the new assertions.

## 3. Owner claim exact lifecycle

Arrange a benign diagnostic `assignment_arrived` listener BEFORE the first M20 loop bind.

Directly prove:
- first loop still binds;
- diagnostic observer remains connected and independent;
- second different live loop bind fails;
- second loop remains unbound;
- second loop adds no M20 transaction callback;
- second loop cleared_count remains zero;
- second loop activation fails and its reset mutates no canonical state;
- first loop remains coherent;
- first loop one healthy arrival produces exactly one clear/count increment;
- owner-loop reset while alive preserves a detached BoardState snapshot and does NOT release the claim;
- first loop is still usable after its reset;
- a different loop is still rejected while first loop is alive.

Frame-aware smoke, using real SceneTree frames:
- retain a WeakRef to owner loop;
- drop all strong owner-loop refs;
- prove WeakRef resolves null;
- prove the old M20 transaction signal callback is no longer present;
- diagnostic listener is still independent/present until test teardown;
- fresh loop binds afterward and contributes exactly one M20 transaction callback;
- no strong cycle retains old loop.

Do not modify dispatcher production API.

## 4. Activation exact snapshot matrix

Implement a detached snapshot that stores AND later compares:
- full BoardState cell-state snapshot;
- dispatcher active count;
- dispatcher next owner id;
- exact ReservationState target->owner map;
- reservation count;
- all five slot tuples `(palette_id, available, active)`.

For EACH ordinary invalid/no-work case use a fresh arrangement or prove restored exact prestate, take the snapshot immediately before the call, then compare EVERY field afterward:
- slot -1;
- slot 5;
- non-int slot;
- unavailable slot;
- origin NaN x;
- origin NaN y;
- origin +INF;
- origin -INF;
- speed NaN;
- speed +INF;
- speed -INF;
- speed 0;
- speed negative;
- absent color/no target;
- fully enclosed matching target.

Also directly cover:
- nested activation -> REENTRANT, no second reservation/owner;
- activation while an arrival transaction is actively draining -> REENTRANT;
- reset during activation preflight -> RESETTING;
- reset inside M19 dispatch -> RESETTING, never raw SUCCESS;
- post-dispatch M20 coherence loss -> COHERENCE_FAILED with deterministic cleanup.

For reset/coherence cases that legitimately consume an owner token before abort, assert monotonic/no-reuse explicitly and do not pretend owner counter stayed unchanged.

## 5. Arrival-preflight exact invariant matrix

Use a helper that creates a REAL ARRIVED-but-unconsumed M19 assignment by disconnecting only the M20 arrival callback and driving the agent to authenticated arrival.

For EACH of these use a fresh arrangement unless exact restoration is independently proven:
- wrong owner;
- wrong target;
- wrong color;
- wrong source agent;
- unknown owner.

For EACH identity case directly assert after failed M20 preflight:
- PREFLIGHT_REJECTED;
- BoardState exact snapshot unchanged;
- cleared_count unchanged;
- exact real reservation remains BOTH `target->owner` and `owner->target`;
- real dispatcher assignment remains pending;
- raw target candidate remains present;
- unrelated sentinel cell/candidate/reservation remains unchanged where arranged.

Add independent fresh cases for:
- missing reservation;
- same-board `(T,O)` replaced by `T->O2`;
- ReservationState rebind(foreign) + foreign replacement reservation;
- ColorCandidateIndex rebind(foreign);
- ColorCandidateIndex `rebind(null)`;
- target already externally CLEARED;
- configured renderer rebound to foreign BoardState AFTER real assignment but BEFORE arrival;
- configured renderer queued before arrival;
- frame-aware configured renderer truly freed before arrival;
- stale replay after reset;
- duplicate current owner+agent;
- duplicate already-queued owner+agent as its own test;
- distinct nested arrival FIFO/lossless.

For `T->O2` and foreign replacement cases prove the replacement pair immediately survives the failed preflight BEFORE reset and still survives the later pair-narrow reset.

For candidate drift/unbound cases prove exact reservation + dispatcher assignment remain held and cleared_count remains zero before cleanup.

After authorized cleanup prove no orphan agent remains where a frame is required.

## 6. Exact final SB-M20 ledger

Create a V09 ledger where each row is directly observable.

### SB-M20-001
One healthy real-production sequence proves all:
- target CLEARED;
- target absent raw candidate bucket;
- ProductionAccessQuery OPEN;
- reservation `target->owner` absent;
- reservation `owner->target` absent;
- dispatcher owner absent;
- agent queued for deletion;
- renderer target alpha 0.

### SB-M20-002
For no-target and enclosed-target independently assert:
- NO_REACHABLE_TARGET;
- active count unchanged/zero;
- reservation count/map unchanged/zero;
- BoardState unchanged.

### SB-M20-003
Run `tests/m20_queue_free_smoke.gd` separately in final validation. It must prove actual frame destruction + no orphan/no return.

### SB-M20-004
True 1x1, one clear, then exhausted.

### SB-M20-005
One-color repeated clear until exact exhaustion.

### SB-M20-006
Multi-color corresponding-slot clears. Snapshot unrelated other-color raw candidate buckets and prove they remain correct after the relevant clear.

### SB-M20-007
Five successful in-flight assignments:
- 5 unique owner IDs;
- 5 distinct targets;
- every pair exact in BOTH directions;
- first arrival removes only its pair and preserves other four exact pairs BOTH directions;
- all five eventually clear/finalize;
- final dispatcher active count 0;
- final reservation count 0.

### SB-M20-008..013
Fresh Easy / Medium / Hard / Very Hard / 59x59 / rectangular successful paths.
59x59: prove exactly intended target changes state through the normal M20 single-cell path; do not make GPU/FPS claims.

### SB-M20-014 and AL-028
- use the V09 desync matrix;
- explicitly prove B is NOT reachable/dispatchable while ACTIVE A blocks it;
- first REAL activation clears A;
- second REAL `activate_slot()` selects/routes B;
- before B arrival prove exact B reservation BOTH directions;
- B arrival clears/finalizes;
- rapid >=25 sequential clear cycles;
- reset with multiple in-flight assignments cleans active/reservations while preserving BoardState and raw candidate truth;
- snapshot all five slot tuples before/after representative ordinary success and ordinary failure; exact equality required.

## 7. Exact rollback/reset/contention matrix

Fresh/direct V09 cases:
- candidate mutate-before-false: detached exact board/candidate/reservation/dispatcher tuple restored or explicit ROLLBACK_FAILED;
- reservation mutate-before-false: exact reservation map restored or explicit ROLLBACK_FAILED;
- candidate true-without-postcondition;
- reservation true-without-postcondition;
- unrelated same-color candidate loss: exact membership restored or explicit fatal rollback, never silent loss;
- healthy clear preserves unrelated different-color candidate bucket;
- reservation identity swap cannot pass exact owner-map proof;
- missing-current-pair reset does not fabricate/delete unrelated reservation;
- healthy pair-narrow reset preserves unrelated reservation;
- foreign-board replacement survives reset;
- same-board owner replacement survives reset;
- reset during candidate phase;
- reset during reservation phase;
- duplicate current arrival;
- duplicate queued arrival;
- distinct nested arrival FIFO;
- post-dispatch generation barrier;
- reset re-entry safe;
- owner ids monotonic/no reuse.

Do NOT widen production category gates. Test-only harness seams only.

## 8. Six load-bearing sensitivity mutations

After the start push and after final V09 tests exist, run each mutation alone. Do not commit any mutation. Restore exact blob before next.

S1 — bypass consumer claim. Named V09 second-loop test must fail.
S2 — regress `agent_parent` presence to equality/null. Truly-freed explicit-parent smoke must fail.
S3 — regress renderer presence to equality/null. Truly-freed renderer smoke must fail.
S4 — weaken/remove post-dispatch generation/reset barrier. V09 reset-inside-dispatch test must fail.
S5 — weaken exact owner-map proof to count-only/bypass. V09 identity-swap test must fail.
S6 — weaken pair-narrow reset to owner-wide. V09 foreign/same-board replacement preservation test must fail.

For each log:
- exact temporary mutation;
- exact named failing assertion(s);
- why failure is the intended protection;
- restored loop/dispatcher blob before proceeding.

## 9. Documentation / scope

V08 current architecture documentation is accepted. Do not edit current docs in V09 unless a new concrete documentation defect is discovered and ChatGPT explicitly authorizes it. Historical evidence is read-only.

Allowed committed files:
- root `TASKS.md` lifecycle fields only;
- `tests/run_tests.gd`;
- narrow V09 frame smoke if needed;
- narrow `tests/support/**` only where required for validation;
- `coordination/sessions/M20-C001/CLAUDE_LOG_V09.md`.

NO committed `scripts/**` change.

## 10. Final validation

Only after all S1-S6 are restored:
1. verify exact production blobs again;
2. run `godot --version`;
3. run full root suite and record total/pass/fail;
4. run separately:
   - `tests/m20_queue_free_smoke.gd`
   - `tests/m20_v04_lifecycle_smoke.gd`
   - `tests/m20_v05_lifecycle_smoke.gd`
   - `tests/m20_v07_lifecycle_smoke.gd`
   - `tests/m20_v08_lifecycle_smoke.gd`
   - any V09 lifecycle smoke;
5. for each final command explicitly inspect/record whether literal `SCRIPT ERROR` or `Parse Error` appears;
6. run `git diff --check`;
7. record exact changed files;
8. prove committed `scripts/**` diff vs `e189ee8` is EMPTY;
9. verify remote push.

## 11. Required V09 evidence table

`CLAUDE_LOG_V09.md` must include a table with rows:
- G-V08-01 owner claim;
- G-V08-02 activation snapshots;
- G-V08-03 arrival preflight;
- G-V08-04 task ledger;
- G-V08-05 rollback/reset;
- G-V08-06 traceability;

Columns:
- named test function / smoke;
- direct assertions;
- actual runtime result;
- sensitivity mapping if applicable.

Do not substitute aggregate test count for this mapping.

## 12. Handoff

On clean validation:
- keep ALL SB-M20-001..014 open;
- progress unchanged;
- lastCompletedTaskId unchanged;
- set root Project Status to `M20-C001-V09 / AWAITING_AUDIT / CHATGPT`;
- commit allowed validation/log/tracker files;
- push to origin/main;
- verify remote;
- return exactly `AWAITING_AUDIT` and stop.

If any production defect is exposed:
- do not fix it;
- restore temporary mutations;
- set truthful BLOCKED state;
- return `BLOCKED / V09_VALIDATION_EXPOSED_PRODUCTION_DEFECT` and stop.

Do not start M21.
