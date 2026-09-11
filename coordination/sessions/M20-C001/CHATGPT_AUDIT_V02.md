# M20-C001 — ChatGPT Independent Audit V02

Decision: **CHANGES_REQUIRED / SAME_FROZEN_SET / V03_REQUIRED**

Audited implementation commit:
`949798faccc61e6de7bf8150be4b51538a2cac44`

Tracker start transition:
`72fd0ddd7de3d85eb3b73189ed0a847774971159`

Prompt:
`coordination/sessions/M20-C001/CHATGPT_PROMPT_V02.md`

Criteria:
`coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V02.md`

Claude evidence:
`coordination/sessions/M20-C001/CLAUDE_LOG_V02.md`

## Runtime / independence disclosure

Claude reports Godot `4.7.1.stable.official.a13da4feb`, full root suite
**3501 / 3501 PASS**, and the dedicated `m20_queue_free_smoke.gd` PASS.
This is E1/E2 runtime evidence.

Godot is unavailable in the ChatGPT audit environment, so these commands were
not independently rerun. ChatGPT independently inspected the exact commit,
production source, V02 doubles, permanent tests, tracker state and the frozen V02
contract. This is E3 source/diff/adversarial-test evidence.

## Root TASKS / governance — PASS

The owner-locked root `TASKS.md` remained the sole live tracker.

Accepted lifecycle:
- V02 tracker-only start commit preceded production/test edits;
- implementation handed off `AWAITING_AUDIT / CHATGPT`;
- progress stayed `290 / 719 = 40.33%` main+ui and `290 / 943 = 30.75%` overall;
- `lastCompletedTaskId` stayed `M19-C001-V06`;
- no SB-M20 checkbox was closed;
- no competing `.hiveai` tracker was recreated.

## V02 corrections accepted

The following V02 work is materially correct and MUST be preserved.

### Serialized M20 lifecycle
- bind has a transaction guard before collaborator callbacks;
- activation is serialized against activation/arrival/reset;
- arrivals use a lossless FIFO drain for distinct assignments;
- reset intent advances a generation and heavy dispatcher reset is deferred until
  the cross-module transaction has unwound.

### Correct transaction ordering
Healthy commit order is now:

`BoardState -> ColorCandidateIndex -> ReservationState -> ScrubbotDispatcher -> renderer`

Renderer is presentation-only and no longer sits between ownership resolution
and dispatcher finalization.

### Postcondition discipline
V02 no longer trusts only a callback return value. It directly checks target
BoardState, target candidate membership, exact owner pair, dispatcher owner
removal and renderer result.

### Direct-observability gaps from V01
V02 added useful direct evidence for:
- a real 1x1 BoardState;
- a second real `activate_slot()` dispatch to B after clearing gate A;
- five unique simultaneous owners / distinct targets / exact reservation pairs;
- reset during arrival;
- nested distinct arrival serialization;
- failed-preflight recovery through reset;
- actual deferred destruction after a SceneTree frame.

### M19 reset seam
The narrow M19 change from synchronous `free()` to `queue_free()` after cancel is
accepted. It avoids freeing a signal emitter inside an arrival/completion stack
while preserving synchronous active/reservation cleanup. Existing M19 strict
regressions remain in the reported green root suite.

# Remaining strict-v2 gaps

No new top-level F-M20 IDs are created. These remain inside the already-frozen
F-M20-STRICT-001..007 set.

## F-M20-STRICT-001 — OPEN: production coherence is still spoofable because M20 accepts stateful subclasses

V02 narrowed BoardState, SlotSystem, ScrubbotDispatcher and BoardRenderer to exact
production scripts, but deliberately still accepts arbitrary subclasses of:
- `ColorCandidateIndex`;
- `ReservationState`.

Those subclasses can override every method M20 trusts, including
`is_bound_to()`, `get_candidates()`, `sync_cell()`, `get_owner()`,
`get_target_for_owner()` and `resolve_arrival()`.

The current `_probe()` therefore does not prove immutable bundle truth. Calling it
twice does not solve this class. A subclass can, on each `is_bound_to(board)`
call:
1. temporarily bind/rebind itself to the supplied board;
2. obtain/return `true`;
3. rebind itself to a foreign same-shape board before returning to M20.

Both probes can report `true` while the dependency is foreign after each probe.
The same issue applies to live `is_coherent()` / activation / arrival preflight.

This is the same strict-v2 principle already captured by AL-064/AL-065: a
callback that itself owns mutable state cannot be treated as an immutable proof
merely because it returned bool true.

### Required V03 direction
Production M20 has no requirement to accept custom candidate/reservation
implementations. Require exact production script identity for both
`ColorCandidateIndex` and `ReservationState`, matching the other canonical M20
collaborators.

Do NOT keep a production trust hole solely to make tests injectable.

Rollback sensitivity must move out of production dependency polymorphism. Use
one of these narrow approaches:
- temporary, uncommitted sensitivity mutations to the exact upstream scripts,
  restored before final commit; and/or
- a test-only M20 transaction harness that exercises M20 rollback logic without
  making canonical dependency binding accept arbitrary production subclasses.

Do not modify the final upstream M13/M14 production behavior.

## F-M20-STRICT-004 — OPEN: exact reservation/candidate preservation is not actually proven

V02 `_snapshot()` captures:
- `res_count`;
- detached `reserved` indices;
- target owner pair;
- target candidate membership.

But `_verify_pre_arrival()` never compares `snap["reserved"]` at all. It verifies
only reservation count plus the current assignment pair.

Likewise the healthy reservation postcondition verifies only:
- target owner == -1;
- owner target == -1;
- count == pre-count - 1.

Therefore a callback can change unrelated reservation identity while preserving
the same count, and M20 can report successful commit/rollback without noticing.
For example, remove target T plus unrelated U, add foreign V: the expected count
can still match even though reservation truth changed.

Candidate rollback has the analogous weakness under the currently accepted
subclass model. `_verify_pre_arrival()` proves only the target's raw membership,
not unrelated candidate truth. A subclass can mutate another candidate and let
target restoration succeed.

The current V02 support doubles do not sensitivity-test these cases. They mutate
only the target under test:
- `M20CandidateSeam.mutate_false` performs the normal target sync then false;
- `M20ReservationSeam.mutate_false` resolves only the exact target/owner then
  false.

### Required V03 direction
After exact production-category narrowing:
- use the already-detached reserved-index snapshot instead of ignoring it;
- capture enough detached reservation ownership proof to verify every preexisting
  unrelated reservation is unchanged;
- after successful resolve prove the exact reserved set is `pre - target` and
  all unrelated owner mappings are unchanged;
- after rollback prove the exact pre-reserved set and unrelated owner mappings are
  restored;
- retain direct representative assertions that unrelated same-color candidates
  remain unchanged, and rely on exact audited `ColorCandidateIndex.sync_cell()`
  source scope rather than accepting an arbitrary subclass that may mutate any
  bucket.

Do NOT add a full BoardState scan to the normal clear path.

## F-M20-STRICT-006 — OPEN: duplicate of the currently-processing arrival is not deduped

`_enqueue_arrival()` scans only `_arrival_queue`.

`_drain_arrivals()` pops the current tuple BEFORE `_run_transaction()`.
Therefore, while that tuple is being processed, the same owner+agent is absent
from the queue. A synchronous duplicate invocation of the M20 arrival entry can
be appended and later processed a second time.

M19's canonical bridge emits once, so this is not observed in the normal happy
path. But the frozen M20 contract explicitly requires that a duplicate same
assignment is not queued/resolved twice, including under re-entry/adversarial
validation.

Required:
- track the current in-flight arrival identity while `_run_transaction()` runs;
- `_enqueue_arrival()` rejects a tuple matching either the currently-processing
  assignment OR an already-queued assignment;
- a distinct second assignment must still queue and process losslessly;
- no mutable current/queue identity is exposed publicly.

## Accepted/final-pending finding status

- F-M20-STRICT-001 — **OPEN** (canonical dependency trust boundary)
- F-M20-STRICT-002 — source correction accepted; preserve activation behavior
- F-M20-STRICT-003 — source correction accepted; preserve authenticated bridge
- F-M20-STRICT-004 — **OPEN** (exact transactional state proof)
- F-M20-STRICT-005 — source correction accepted; preserve second real B dispatch
- F-M20-STRICT-006 — **OPEN** (current-arrival duplicate serialization)
- F-M20-STRICT-007 — source/test correction accepted; preserve scale/observability

All accepted findings remain final-pending until the critical M20 cycle closes.

## Task / progress disposition

Keep open:
`SB-M20-001..SB-M20-014`

Progress remains:
- Main + UI: **290 / 719 = 40.33%**
- Overall: **290 / 943 = 30.75%**

## Verdict

**CHANGES_REQUIRED / SAME_FROZEN_SET / V03_REQUIRED**

V03 must be a narrow trust-boundary/exact-state correction, not a redesign of the
clearing architecture and not M21 work.
