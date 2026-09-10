# M20-C001 — ChatGPT Independent Audit V01

Verdict: **CHANGES_REQUIRED / STRICT_V2_TRANSACTION_CORRECTION_REQUIRED**

Audited implementation commit:
`30711975cd9bb06bf1f398d0ab00ede7483d2410`

Tracker start transition:
`d38bffcd26d50e60997c0d5ca3f9b8c5586679f7`

Prompt:
`coordination/sessions/M20-C001/CHATGPT_PROMPT_V01.md`

Criteria:
`coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V01.md`

Claude evidence:
`coordination/sessions/M20-C001/CLAUDE_LOG_V01.md`

Frozen design basis:
`coordination/sessions/M20-C001/CHATGPT_FULL_SURFACE_REAUDIT_V01.md`

## Runtime / independence disclosure

Claude reports Godot `4.7.1.stable.official.a13da4feb` and **3386 / 3386 ALL PASS** with zero final failures. This is E1/E2 runtime evidence.

Godot is not available in the ChatGPT audit environment, so ChatGPT did not independently rerun the suite. ChatGPT independently inspected the exact implementation commit, source, changed-file scope, V01 tests/support doubles, M19 arrival bridge, renderer seam, root tracker and the frozen V01 contract. This is E3 source/diff/adversarial-test evidence.

## Tracker / governance — PASS

The root `TASKS.md` sole-live-tracker rule was followed.

Durable order is correct:
1. prompt/criteria issuance;
2. tracker-only start commit `d38bffc` -> M20-C001 V01 / IN_PROGRESS / CLAUDE;
3. implementation commit `30711975...` -> AWAITING_AUDIT / CHATGPT.

Claude did not close SB-M20-001..014 and progress remained 290/719 main+ui, 290/943 overall.

## Accepted V01 work

The following architecture is accepted and must be preserved:

- `CompleteClearingLoop` is a separate M20 orchestrator under `scripts/gameplay/clearing/`.
- M19 remains assignment/agent orchestration; M20 owns cross-module arrival resolution.
- BoardState remains physical ACTIVE/CLEARED truth.
- ColorCandidateIndex remains derived candidate truth.
- ReservationState remains ephemeral owner<->target truth.
- ProductionAccessQuery remains live BoardState access truth; no second access cache was introduced.
- Slot activation delegates target selection/routing to the M19/M15/M17 production chain.
- The M19 `assignment_arrived` bridge is emitted only after existing owner/target/color/exact-agent validation and only once.
- `is_arrival_pending` and `finalize_arrival` are narrow M20 seams; M19 still does not clear BoardState or resolve ReservationState.
- BoardRenderer received only the narrow read-only exact-board coherence seam.
- Happy-path post-arrival tuple is correct in the real production stack.
- no-target and enclosed-target no-spawn behavior is preserved.
- basic candidate-failure and reservation-failure rollback paths exist.
- M20 does not implement win/lose/scoring/session completion/auto-next/slot queue/cooldown/consumption.
- 59x59 and rectangular smoke coverage exists.

## Why V01 cannot final-close

### F-M20-STRICT-001 — OPEN: bind transaction is not re-entry/drift safe

`CompleteClearingLoop.bind()` invokes multiple subclass-overridable collaborator methods before `_bound` is committed:
- SlotSystem `is_configured()` / `get_slot_count()`;
- ColorCandidateIndex `is_bound_to()`;
- ReservationState `is_bound_to()`;
- ScrubbotDispatcher `is_bound_to()` / `get_active_count()`;
- BoardRenderer `is_bound_to()`.

There is no `_in_bind` transaction guard.

A callback can recursively call `bind()` while the outer bind is still validating. The inner bind can commit and connect an arrival signal before the outer bind resumes, after which the outer bind can also commit. This creates a possible ghost/dual signal connection and violates the initialization-only atomic-bind contract.

V01 tests exercise static wrong-bundle inputs but do not inject re-entry or drift from bind-time callbacks.

Required V02 closure:
- guard bind before the first external callback;
- nested bind fails without commit/signal connection;
- failed/re-entered bind leaves no ghost dispatcher connection;
- final committed bundle must still be exact-coherent after validation;
- second ordinary bind while already bound remains false/preserve.

### F-M20-STRICT-002 — OPEN: activation is not a serial transaction

`activate_slot()` has no activation guard/generation token. It calls live coherence and slot/dependency methods before delegating to dispatcher.

If an accepted collaborator callback recursively activates another slot, or requests reset during activation preflight, the outer activation can continue and dispatch after the nested operation/reset. One player activation can therefore indirectly produce an extra dispatch or dispatch after reset intent.

Required V02 closure:
- one activation transaction at a time;
- nested activation returns a stable failure with zero new reservation/agent;
- reset requested during activation prevents the outer activation from starting a new dispatch;
- no slot state mutation and no owner-id advance from rejected nested activation.

### F-M20-STRICT-003 — substantially accepted; recovery observability remains required

The M19 arrival bridge itself is correctly authenticated and one-shot.

However V02 must prove that an abnormal preflight rejection, which intentionally leaves the arrived assignment held, has an explicit safe recovery path through `CompleteClearingLoop.reset()` so the one-shot signal cannot strand ownership forever without a defined recovery operation.

No change is required to the authenticated signal law unless V02 testing proves one.

### F-M20-STRICT-004 — OPEN: return-value trust and best-effort rollback are insufficient

V01 states that the cross-module clear is atomic, but the implementation trusts collaborator return values without proving their postconditions.

Examples:
- `BoardState.set_cell_state(...CLEARED) == true` is not followed by a direct state postcondition before the next phase;
- `ColorCandidateIndex.sync_cell() == true` is not followed by proof that the target actually left the raw bucket;
- `ReservationState.resolve_arrival() == true` is not followed by proof that owner->target and target->owner were both removed;
- `ScrubbotDispatcher.finalize_arrival() == true` is not followed by proof that the exact active owner disappeared.

The forced-failure doubles are also too friendly:
- `M20FailingCandidate` returns false **without mutating candidate state**;
- `M20FailingReservation` returns false **without resolving/removing the reservation**.

Therefore the suite does not exercise the critical mutation-before-failure class.

Concrete defects:

1. If candidate sync removes/neutralizes/rebinds state and then reports failure, `_restore_candidate()` is only best-effort. It does not return/verify restoration and may rebuild the wrong/neutralized bundle.
2. If reservation resolve removes the exact pair and then returns false, current rollback restores BoardState/candidate but does not restore the reservation.
3. If finalization fails after BoardState/candidate/reservation commit, current code reports `FINALIZE_FAILED` but leaves a partial tuple: the cell is CLEARED and reservation is gone while the dispatcher may still retain the arrived owner. `_cleared_count` also remains unincremented despite physical clear truth.

V02 must use explicit postconditions and mutation-before-failure tests.

### V02 ordering correction — renderer is presentation, not transaction authority

V01 placed renderer update before dispatcher finalization. Audit shows this unnecessarily inserts a Node/presentation callback between gameplay-state commit and ownership finalization.

V02 supersedes that V01 ordering detail.

Correct gameplay commit order for V02:
1. preflight;
2. BoardState ACTIVE -> CLEARED;
3. candidate sync + postcondition;
4. reservation resolve + postcondition;
5. dispatcher finalization + postcondition;
6. only then update optional renderer from committed BoardState.

Renderer failure/staleness after step 5 must never roll gameplay truth backward. Presentation can be refreshed later; it is not gameplay authority.

Before step 5, any failure must restore the exact pre-arrival gameplay tuple or enter an explicit fatal/fail-closed recovery path that leaves no contradictory BoardState/candidate/reservation/dispatcher tuple.

### F-M20-STRICT-006 — OPEN: no serial arrival guard / no controlled reset-during-arrival implementation

The frozen contract explicitly requires:
- one arrival transaction at a time;
- duplicate/nested arrival cannot double-resolve;
- controlled reset during arrival must occur before mutation or produce a documented fail-closed rollback.

Current `CompleteClearingLoop` has no `_in_arrival`, queue, generation token or reset-defer mechanism.

`reset()` immediately calls `dispatcher.reset()` even if an arrival transaction is between BoardState mutation, candidate sync and reservation/finalization.

A controlled callback can therefore interleave reset with the cross-module transaction. For example, reset during candidate sync can erase dispatcher/reservation ownership after BoardState has already become CLEARED. The outer transaction then cannot restore the exact pre-arrival tuple.

Criterion 215 was not directly tested in V01.

Nested legitimate arrivals are also not serialized. A second arrival or activation can observe temporary partially-mutated truth from the first transaction.

Required V02 closure:
- serial arrival processing;
- nested distinct arrivals are queued/drained, not lost;
- duplicate same assignment is idempotent;
- activation cannot interleave with an arrival commit;
- reset during arrival is deferred/marked so the current transaction either has not mutated yet or rolls back before dispatcher reset is applied;
- after reset processing there is no half-cleared tuple or orphan owner/agent.

### F-M20-STRICT-005 — implementation semantics accepted, direct integration proof incomplete

V01 proves that clearing gate A makes target B `ProductionTargetAccess.is_targetable(B) == true`.

But the frozen criterion also requires a **later slot activation** to actually select and route to B through the real TargetSelector + ProductionRoutingSystem chain.

The current test stops after a fresh probe. It does not execute the second activation/arrival for B.

V02 must perform the second real activation and prove B is the selected reserved target and can clear successfully.

### F-M20-STRICT-007 — OPEN: several direct-observability holes

1. The claimed “one-cell synthetic board” is actually a 20x20 board with exactly one ACTIVE cell. That is useful but it is not a true 1x1 generic board boundary.
2. The five-slot scenario counts five successful in-flight assignments but does not directly assert five unique owner IDs, five distinct target IDs and five exact reservations before arrival.
3. Candidate/reservation rollback tests run without a renderer, so criterion 269 (rollback does not falsely render target cleared) is not directly observed.
4. M20 does not directly prove the queued agent is actually gone after a SceneTree frame/queued-free processing; current teardown can hide this by freeing the dispatcher parent.
5. Reset during the M20 arrival transaction is not present despite criterion 215.

V02 must close these observability gaps.

## V01 test sensitivity assessment

The V01 suite is useful and not discarded. It directly proves many happy-path and ordinary failure properties. However 3386/3386 cannot establish behaviors that are absent from the matrix.

In particular, a negative double that returns false before mutating anything cannot prove rollback correctness against mutation-before-failure. This is the same reusable class as AL-067: callback return validation does not prove the callback left state untouched.

## Frozen finding status after V01

- F-M20-STRICT-001 — OPEN
- F-M20-STRICT-002 — OPEN
- F-M20-STRICT-003 — bridge accepted; recovery proof pending
- F-M20-STRICT-004 — OPEN
- F-M20-STRICT-005 — semantics accepted; second-dispatch proof pending
- F-M20-STRICT-006 — OPEN
- F-M20-STRICT-007 — OPEN

No new top-level M20 finding IDs are required for V02; all correction work stays inside the already-frozen F-M20-STRICT-001..007 surface.

## Task/progress disposition

Keep SB-M20-001..014 open.

Progress remains:
- main+ui 290 / 719 = 40.33%
- overall 290 / 943 = 30.75%
- lastCompletedTaskId remains M19-C001-V06.

## Verdict

**CHANGES_REQUIRED / STRICT_V2_TRANSACTION_CORRECTION_REQUIRED**

Next implementation contract:
`coordination/sessions/M20-C001/CHATGPT_PROMPT_V02.md`
