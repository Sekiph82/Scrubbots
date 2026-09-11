# M20-C001 — ChatGPT Independent Audit V10

Decision: **PRODUCTION_ACCEPTED / CHANGES_REQUIRED / V11_VALIDATION_ONLY**

Audited validation commit:
`893cd41de61746562e9fa9f83ade1e913dededa6`

V10 start-transition commit:
`e3764aa35053423d55a4d1a50b25037155f11d20`

Accepted production basis:
`e189ee8bd2b9be68b876cfdb18377622ed3ce832`

Prompt:
`coordination/sessions/M20-C001/CHATGPT_PROMPT_V10.md`

Criteria:
`coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V10.md`

Claude evidence:
`coordination/sessions/M20-C001/CLAUDE_LOG_V10.md`

Canonical tracker: repository-root `TASKS.md` only.

## Evidence level / runtime limitation

Claude reports Godot `4.7.1.stable.official.a13da4feb`, full root suite **4262 / 4262 PASS**, queue-free plus V04/V05/V07/V08/V09/V10 lifecycle smokes PASS, and zero final M20 `SCRIPT ERROR` / `Parse Error`.

Those runtime results are E1/E2. ChatGPT cannot execute Godot in this audit environment. E3 consists of independent GitHub commit/diff/source/test/log/tracker inspection and direct reconciliation of the V10 tests against the frozen V10 criteria.

## Governance / production immutability

PASS:
- V10 tracker-only start commit precedes the validation commit;
- the V10 validation commit changes only `TASKS.md`, `tests/run_tests.gd`, `tests/m20_v10_lifecycle_smoke.gd`, and `coordination/sessions/M20-C001/CLAUDE_LOG_V10.md`;
- no V10 `scripts/**` change exists;
- compare from accepted V07 production commit to V10 handoff contains no `scripts/**` file;
- accepted production blobs remain the locked V07 values stated by the V10 criteria/log;
- root tracker is `M20-C001-V10 / AWAITING_AUDIT / CHATGPT`;
- progress remains `290/719` main+ui and `290/943` overall;
- `lastCompletedTaskId` remains `M19-C001-V06`;
- Claude did not close SB-M20-001..014 or start M21.

No new M20 production defect was found in V10. Production remains source-accepted and immutable.

## Strict finding set

V10 does **not** close the final evidence gate. The remaining defects are in direct observability / evidence quality, not production behavior.

### F-M20-V10-EVID-001 — arrival-drain serialization does not directly prove zero extra side effects

`_v10_g02_activation_serialization()` captures:
- `active_before2`;
- `res_before2`;
- `owner_before2`.

But after the drain-time inner `activate_slot()`:
- `res_before2` is never asserted at all;
- active-agent evidence is `get_active_count() <= active_before2` only.

That active-count inequality is not sufficient. The outer A transaction finalizes during the same drain. If a broken inner activation created one extra active assignment, the final active count could still be `1`, and `<= active_before2` (also `1`) would pass.

Therefore V10 criteria 45–47 are not all directly proven, especially “inner creates no additional active assignment/reservation.”

**Required V11 correction:** inside the drain hook, capture exact active count, exact reservation map/count, and next-owner id immediately before the inner call and immediately after it returns. Assert all are byte-for-byte/logically unchanged and inner result is `REENTRANT`. Then separately prove outer A completes and later B remains usable.

### F-M20-V10-EVID-002 — missing-reservation case does not prove dispatcher assignment remains pending

The V10 missing-reservation case asserts:
- `PREFLIGHT_REJECTED`;
- cleared_count zero;
- target remains ACTIVE;
- sentinel reservation survives.

It does **not** assert `dispatcher.has_owner(owner)` after the failed preflight.

This leaves V10 criterion 54 (“dispatcher assignment is not silently finalized”) without the direct assertion explicitly required by the frozen matrix.

### F-M20-V10-EVID-003 — candidate-null case still omits reverse reservation identity and cleared-count proof

The candidate `rebind(null)` case asserts only:
- rejection;
- `target -> owner` reservation;
- dispatcher assignment pending.

It does not directly assert:
- `owner -> target` reverse reservation identity;
- cleared_count remains zero.

Thus V10 criteria 65 and 67 remain incompletely observed.

### F-M20-V10-EVID-004 — externally-CLEARED case still omits reservation and dispatcher preservation

The externally-CLEARED case asserts only:
- rejection;
- cleared_count remains zero.

It does not directly assert:
- reservation remains exact in both directions;
- dispatcher assignment remains pending.

Thus V10 criteria 71–72 remain open.

### F-M20-V10-EVID-005 — reservation rollback does not compare the unrelated owner->target reverse identity

The V10 reservation mutate-before-false case snapshots:
- the full target->owner map/count;
- `get_target_for_owner(r2.owner_id)` for the current owner;
- `get_owner(u2)` for the unrelated target.

The unrelated check is another target->owner check. It is **not** the required reverse identity for the unrelated owner (`get_target_for_owner(6060) == u2`). The full target->owner map already covers the forward direction.

Therefore V10 criteria 136 and 141 are not fully proven for every arranged owner.

**Required V11 correction:** snapshot and compare `owner -> target` for both the current owner and unrelated owner(s), not a redundant second target->owner query.

## Traceability defect in CLAUDE_LOG_V10

Because the assertions above are absent/incomplete, the G-V09 evidence table overstates the direct proof:
- G-V09-02 says no extra agent/reservation/token;
- G-V09-03 says the exact matrix preserves all required pair/assignment truth;
- G-V09-05 says reverse identities are restored for all arranged owners.

The corresponding test source does not fully establish those claims. Therefore G-V09-06 traceability is also not clean enough for final closure. V11 must make the table match exact executable assertions, not intended semantics.

## Accepted V10 evidence that does not need reinvention

The following V10 evidence is accepted and should remain enabled:
- G-V09-01 actual post-reset usability: same owning loop performs a second real activation/arrival and clears B while another loop remains rejected;
- reset preserves BoardState and exact reservation map/count in the no-active-work claim scenario;
- nested activation during activation preflight returns `REENTRANT`, outer succeeds, active/reservation count is one, and owner counter advances exactly once;
- renderer-foreign and renderer-queued failed-preflight preservation assertions;
- truly-freed renderer frame smoke;
- failed-preflight -> authorized reset -> frames -> agent destroyed / no orphan / exact pair gone / unrelated sentinel intact;
- five-slot first-pair removal in both directions and remaining four pairs;
- direct expected-target CLEARED + exact +1 delta for scale rows;
- candidate rollback detached BoardState/candidate buckets/reservation map/dispatcher compare;
- production immutability and all previously accepted V09/V08 evidence.

Do not rewrite or broaden these areas in V11 unless required to keep tests compiling.

## Frozen V11 scope

V11 is a **narrow validation-only reconciliation**. Production is immutable.

V11 must close only:
1. drain-time inner activation exact side-effect snapshots;
2. missing-reservation dispatcher-pending assertion;
3. candidate-null reverse reservation + cleared-count assertions;
4. externally-CLEARED reservation-both-directions + dispatcher-pending assertions;
5. unrelated owner->target reverse identity in reservation rollback;
6. truthful G-V10 evidence table mapped to those exact assertions.

No `scripts/**` change is authorized. If any new test exposes a production defect, Claude must stop and return BLOCKED without fixing production.

## Task disposition

- SB-M20-001..014 remain open.
- Progress remains `290/719` main+ui and `290/943` overall.
- `lastCompletedTaskId` remains `M19-C001-V06`.
- M21 must not start.

## Verdict

**PRODUCTION_ACCEPTED / CHANGES_REQUIRED / V11_VALIDATION_ONLY**

V10 is not final closure because five direct-assertion gaps remain and the V10 log overclaims those proofs. One narrow V11 validation pass is required. Production remains accepted and must not be modified.