# M20-C001 — Auditor-Authored Validation-Only Gate V05

Status: **ISSUED — VALIDATION ONLY / PRODUCTION IMMUTABLE**

Canonical live tracker: repository-root `TASKS.md` only.

Read FIRST:
- root `TASKS.md`;
- `AGENTS.md`;
- `CLAUDE.md`;
- `coordination/AUDIT_POLICY.md`;
- `coordination/AUDIT_INDEX.md`;
- `coordination/VERSIONED_LOG_POLICY.md`;
- `coordination/sessions/M20-C001/CHATGPT_AUDIT_V04.md`;
- this prompt;
- `CHATGPT_AUDIT_CRITERIA_V05.md`.

Expected evidence log:
`coordination/sessions/M20-C001/CLAUDE_LOG_V05.md`

Do not begin M21.

## 0. Root TASKS lifecycle

Expected synced starting state:
- M20-C001 V04;
- `AWAITING_AUDIT`;
- Required Actor `CHATGPT`;
- 290/719 main+ui, 290/943 overall;
- lastCompletedTaskId M19-C001-V06;
- SB-M20-001..014 all open.

`CHATGPT_AUDIT_V04.md` + this prompt authorize V05.

Before ANY V05 test/support edit or temporary production sensitivity mutation:
1. sync `origin/main`, preserving owner work;
2. verify V04 audit + this V05 prompt/criteria exist;
3. verify root tracker has not moved;
4. update ONLY top Project Status lifecycle fields to:
   - Current Milestone: M20
   - Current Sprint: M20-C001 V05 — auditor-authored validation-only gate
   - Current Task: M20-C001-V05 — adversarially validate accepted V04 production without committed production edits
   - Current Task Status: IN_PROGRESS
   - Required Actor: CLAUDE
   - Next Task/Action: execute V05 validation-only matrix, restore any temporary production mutations byte-for-byte, write CLAUDE_LOG_V05.md, hand off AWAITING_AUDIT to ChatGPT
   - progress unchanged
   - lastCompletedTaskId unchanged
5. commit + push tracker-only transition BEFORE any V05 validation edit/mutation;
6. verify remote main contains it.

If tracker moved: `TRACKER_STATE_CONFLICT`.
If push fails: `GITHUB_TRACKING_NOT_SYNCED`.

Do not mark any SB-M20 row complete.

## 1. Production immutability lock

Accepted V04 implementation commit:
`50be126cc7bf82e62650d81287c0bf2ba4ca7064`

Locked production blobs:
- `scripts/gameplay/clearing/complete_clearing_loop.gd` = `f00c34021da85e596df58f08857acde8846dd8a4`
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` = `1709b8c8ebf7595596bdf8cbd059f04bf1196ea3`

V05 is validation-only.

Final committed V05 state MUST NOT change any `scripts/**` production file.

Temporary production mutations are permitted ONLY for the three sensitivity checks in §8, one at a time, after the V05 start push. Each must be restored exactly before the next mutation and before the final suite.

If final accepted source needs any production correction, STOP:
`V05_VALIDATION_EXPOSED_PRODUCTION_DEFECT`

Do not silently fix it in V05.

## 2. Add a fresh auditor-authored V05 validation block

Add a new dedicated block to `tests/run_tests.gd`, for example:
`_run_m20_v05_auditor_validation_tests()`.

Do not merely call one aggregate old helper and count green totals. Construct fresh arrangements for the high-risk V04 seams below.

Existing V01-V04 tests remain enabled.

A narrow new test/support file is allowed if needed. Production is not.

## 3. Fresh Node-lifecycle validation

Directly validate the accepted V04 liveness law with exact production Nodes.

Required fresh arrangements:

### A. queued dispatcher before bind
- exact ScrubbotDispatcher;
- queue it for deletion before M20 bind;
- bind false;
- loop unbound;
- zero arrival connection;
- no SCRIPT ERROR.

### B. queued renderer before bind
- exact BoardRenderer;
- queue it before bind;
- bind false;
- loop unbound;
- zero arrival connection;
- no SCRIPT ERROR.

### C. dispatcher queued after healthy bind
- healthy loop first;
- queue dispatcher;
- `is_coherent()` false;
- `activate_slot()` does not call it / no success;
- `reset()` safely unwinds while instance still callable;
- no SCRIPT ERROR.

### D. renderer queued after healthy bind with a live assignment
- first create one real active M19 assignment through M20;
- then queue the renderer before arrival;
- M20 coherence becomes false;
- `loop.reset()` removes the dispatcher-owned active assignment and its exact original reservation;
- BoardState remains ACTIVE;
- no false clear/count increment.

### E. truly-freed dispatcher and renderer
Use a real SceneTree smoke if needed. Cover BOTH:
- dispatcher destroyed before bind / after healthy bind;
- renderer destroyed before bind / after healthy bind;
- no freed-object SCRIPT ERROR;
- activation/reset fail closed as specified.

This closes V04 baseline evidence gap for renderer and independently revalidates the final law.

## 4. Fresh post-dispatch transaction-barrier validation

Use a real exact M20 bundle whose M19 dispatch executes an injected callback after M20 preflight.

### Reset inside M19 dispatch
Inside the callback call ONLY `loop.reset()`.

Directly prove:
- M19 path advances far enough that exactly one owner token is consumed (`peek_next_owner_id() == before + 1`) in this arrangement;
- corrected M20 return is `success=false` / RESETTING;
- no raw M19 SUCCESS escapes;
- dispatcher active_count is zero when `activate_slot()` returns;
- current-attempt reservation absent;
- BoardState target remains ACTIVE;
- cleared_count stays zero;
- consumed owner id is not rewound;
- later ordinary activation uses a strictly later owner and succeeds.

### Renderer lifecycle loss inside M19 dispatch
With a bound renderer, callback only queues/frees renderer as safely executable.

Prove:
- M19 path otherwise consumes exactly one owner token;
- M20 returns COHERENCE_FAILED, not raw SUCCESS;
- active assignment gone on return;
- exact current reservation gone on return;
- target BoardState ACTIVE;
- cleared_count zero;
- no renderer false-clear;
- fresh healthy bundle later operates.

## 5. Fresh pair-narrow reset validation

Use real production ReservationState and real dispatcher unless the arrangement explicitly requires the test harness.

### A. healthy pair + unrelated reservation
- create one real active dispatcher entry `(O,T)`;
- add a separate valid unrelated reservation `(OU,U)` that is NOT a dispatcher active entry;
- reset;
- T<->O removed;
- U<->OU preserved exactly;
- dispatcher active cleared.

### B. foreign board, different target
- active entry remains A/T/O in dispatcher;
- same ReservationState rebinds to board B;
- B/V/O reserved;
- reset;
- V<->O survives exactly;
- dispatcher active cleared.

### C. foreign board, same numeric target
- B uses target index numerically equal to original T;
- reserve B/T/O;
- reset;
- B/T/O survives because board identity is foreign.

### D. same original board owner replacement + unrelated reservation
- remove original T<->O;
- reserve V<->O on same board;
- separately reserve U<->OU;
- reset;
- V<->O survives;
- U<->OU survives;
- dispatcher active cleared.

### E. missing current pair + unrelated reservation
- remove current T<->O entirely;
- add unrelated U<->OU;
- reset;
- U<->OU survives exactly;
- no new reservation fabricated;
- dispatcher active cleared.

### F. M20 loop reset route
Repeat at least the foreign-board case through `loop.reset()` rather than direct dispatcher reset, proving M20 does not reintroduce collateral cleanup.

## 6. Fresh arrival/transaction integration adversaries

Construct fresh direct validation for:
- duplicate current arrival cannot clear twice;
- distinct second arrival during current transaction remains FIFO/lossless;
- reset during candidate phase restores target and does not clear;
- reset during reservation phase restores target and does not clear;
- identity-swap reservation corruption still yields ROLLBACK_FAILED rather than ordinary rollback success;
- unrelated same-color candidate survives target clear/rollback;
- failed arrival preflight then reset removes stranded assignment without BoardState clear;
- stale replay after reset cannot clear.

Use test-only harness only for fault seams that production exact categories intentionally reject. Do not weaken production bind.

## 7. Fresh direct gameplay integration

At minimum directly rerun fresh arrangements for:
- true 1x1 clear then exhaustion;
- AL-028 gate A clear followed by SECOND REAL `activate_slot()` selecting/clearing B;
- five configured slots producing five unique owners, five distinct targets and five exact reservation pairs before arrivals;
- first of five arrivals preserves the other four exact pairs;
- 59x59 maximum;
- rectangular production board;
- rapid 25+ sequential clear cycles;
- queue-free destruction after a real SceneTree frame.

No M21 behavior is added.

## 8. Load-bearing sensitivity mutations

Execute ALL THREE temporary mutations, one at a time, only after the V05 IN_PROGRESS push.

Record exact pre-mutation blob, mutation, targeted test failure, restore, and post-restore blob.

### S1 — Node-liveness guard mutation
Temporarily weaken M20 Node liveness so queued Node is treated as healthy, e.g. remove the `not is_queued_for_deletion()` component from `_is_live_node`.

Expected targeted failure:
- queued dispatcher and/or queued renderer validation must fail for the intended reason.

Restore exact clearing-loop blob:
`f00c34021da85e596df58f08857acde8846dd8a4`

### S2 — post-dispatch generation barrier mutation
Temporarily remove/bypass the post-`dispatcher.dispatch()` M20 reset/generation check.

Expected targeted failure:
- reset-inside-M19 validation returns/exposes stale success or otherwise fails the RESETTING expectation.

Restore exact clearing-loop blob.

### S3 — pair-narrow reset mutation
Temporarily weaken dispatcher reset cleanup, preferably restore owner-wide `release_for_owner(owner_id)` or remove the original-board/pair proof.

Expected targeted failure:
- foreign-board and/or same-board replacement/unrelated reservation preservation test fails.

Restore exact dispatcher blob:
`1709b8c8ebf7595596bdf8cbd059f04bf1196ea3`

After all three restores, verify BOTH production blobs exactly match the accepted V04 values before final validation.

Do not commit any temporary production mutation.

## 9. Preserve all upstream and scope laws

Run the full root suite and keep all prior tests enabled, including:
- BoardState / renderer;
- M11 session;
- M12 slots;
- M13 candidate;
- M14 reservation;
- M15-C002 selector;
- M16 routing;
- M17 production routing;
- M18 agent;
- all M19 V01-V06;
- all M20 V01-V04.

Re-run:
- `tests/m20_queue_free_smoke.gd`;
- `tests/m20_v04_lifecycle_smoke.gd`;
- any V05 lifecycle smoke added.

No final production change under `scripts/**`.
No win/lose/scoring/economy/session-complete/automatic-next-bot/slot-policy implementation.

## 10. Validation / evidence

Record individually in `CLAUDE_LOG_V05.md`:
- Godot version;
- V05 tracker start commit + remote verification;
- accepted V04 implementation commit;
- pre-validation production blob SHAs;
- every fresh V05 adversarial section result;
- S1 mutation + exact failing test(s) + restore hash;
- S2 mutation + exact failing test(s) + restore hash;
- S3 mutation + exact failing test(s) + restore hash;
- final production blob SHAs;
- final diff proving no committed production change;
- full root suite exact total/pass/failure;
- queue-free smoke result;
- V04 lifecycle smoke result;
- any V05 smoke result;
- zero final M20 SCRIPT ERROR / Parse Error;
- `git diff --check`;
- exact changed-file list;
- root TASKS lifecycle start/final;
- failures/fixes encountered during validation.

## 11. Final handoff

On clean validation:
- root TASKS current sprint/task -> M20-C001 V05 / M20-C001-V05;
- status -> AWAITING_AUDIT;
- Required Actor -> CHATGPT;
- progress remains 290/719 main+ui and 290/943 overall;
- lastCompletedTaskId remains M19-C001-V06;
- no SB-M20 checkbox `[x]`;
- commit only validation tests/support/log/docs-if-needed/tracker handoff;
- verify remote main;
- final production blobs remain exact V04 locked values.

Do NOT mark COMPLETE or READY_FOR_NEXT_TASK.
Do NOT start M21.

Return exactly:
`AWAITING_AUDIT`

Production defect exposed:
`V05_VALIDATION_EXPOSED_PRODUCTION_DEFECT`

Tracking push failure:
`GITHUB_TRACKING_NOT_SYNCED`

Then stop.