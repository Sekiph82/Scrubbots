# M25-C001 V02 — ChatGPT Strict Audit

Date: 2026-09-18
Repository: `Sekiph82/Scrubbots`
Milestone: `M25 — Batch Target Claim Engine`
Cycle: `M25-C001 V02`
Auditor: ChatGPT
Implementation SHA: `66b6359fb55837daf605cae5f832e74d4bd961e8`
Claude log commit: `a56f3b303cddcb9a9a45f813721d887cb364fcf0`
Prior audit: `coordination/sessions/M25-C001/CHATGPT_AUDIT_V01.md`
Criteria: `coordination/sessions/M25-C001/CHATGPT_AUDIT_CRITERIA_V02.md`

## Verdict

**CHANGES_REQUIRED / ALL V01 FINDINGS CLOSED / ONE EXACT M24 WORK-TUPLE BINDING DEFECT REMAINS**

V02 successfully closes the five findings raised by the V01 audit. The remediation is narrow and the two compatibility seams are read-only and policy-neutral.

However, strict inspection found one new cross-engine integrity defect: M25 verifies that its `claim_id` still names some coherent live M24 work entry, but it does not verify that the M24 entry is still bound to the exact M25 ledger slot + batch identity. This can redirect accounting to a different occupied batch while M25 still believes the claim belongs to the original batch.

M25 remains open for one narrow V03 correction.

## 1. Governance / diff integrity

The Claude implementation commit is isolated as:

- parent: `fc4aa94aba070a4891c8ef25cd8ed3c95facb7c3`
- implementation: `66b6359fb55837daf605cae5f832e74d4bd961e8`

The implementation commit changes exactly:

- `scripts/gameplay/dispatch/production_target_access.gd`
- `scripts/gameplay/slots/five_slot_batch_engine.gd`
- `scripts/gameplay/targeting/batch_target_claim_engine.gd`
- `tests/m25_v02_strict_remediation_evidence.gd`
- `tests/run_tests.gd`
- `tests/support/m25_reentrant_access.gd`

The unrelated UI commit `fc4aa94...` landed before Claude's implementation and is not part of Claude's implementation diff.

Implementation -> log is one separate commit and changes only:

- `coordination/sessions/M25-C001/CLAUDE_LOG_V02.md`

Root `TASKS.md` is absent from the Claude implementation commit. M26/M27 code is absent.

Claude reports root suite `5139 / 0`.

## 2. V01 findings status

### F-M25-V01-STRICT-001 — CLOSED

- claim and reservation-owner counters are monotonic across reset;
- stale pre-reset claim IDs do not alias post-reset claims;
- owner allocation skips unrelated live ReservationState owners, including owner 0;
- unrelated ownership is not stolen or released.

### F-M25-V01-STRICT-002 — CLOSED

- selected slot lifecycle prestate is captured;
- WAITING -> ACTIVE confirmation is rolled back to WAITING if M24 commit fails;
- reservation is released;
- counters and ledger remain unchanged.

### F-M25-V01-STRICT-003 — CLOSED for absent/stale work and reservation drift

- rollback preflights ReservationState exact target/owner pair;
- rollback preflights live M24 work coherence before mutation;
- reset preflights all live tuples before cleanup;
- incoherent tuples abort cleanup rather than silently erasing the ledger.

### F-M25-V01-STRICT-004 — CLOSED

- production claims require `ProductionTargetAccess`;
- exact BoardState identity is checked through a read-only seam;
- generic all-true RefCounted and foreign-board ProductionTargetAccess are rejected;
- category-correct re-entry test retains production trust-boundary coverage.

### F-M25-V01-STRICT-005 — CLOSED

- bind is initialization-only;
- second same-bundle or foreign-bundle bind fails closed;
- live claims remain attached to the original authority bundle.

## 3. F-M25-V02-STRICT-001 — M24 work coherence is not exact to the M25 claim tuple

V02 adds:

`FiveSlotBatchEngine.is_work_coherent(work_id)`

It proves only that:

1. `work_id` is currently live in M24;
2. the M24 record's own recorded slot still contains the M24 record's own recorded batch.

It does **not** prove that the work record is still bound to the slot and batch recorded by the M25 claim ledger.

An adversarial but legal public-API sequence can therefore redirect the same work ID:

1. M25 creates claim `C` for slot 4 / batch A / target T.
2. M24 contains work `C -> slot4/A`.
3. An external caller executes `M24.rollback_work(C)`.
4. The same caller executes `M24.commit_work(slot3, C)` while slot 3 contains batch B.
5. M25 ledger still says `C -> slot4/A/targetT`.
6. `M24.is_work_coherent(C)` returns true, because the redirected M24 record `slot3/B` is internally coherent.
7. M25 `rollback_claim(C)`, `finalize_clear(C)`, or `reset()` may now mutate batch B's accounting while releasing/erasing a claim that M25 still attributes to batch A.

This violates the core M25 invariant:

`one M25 claim <-> exact M24 slot/batch work identity <-> exact ReservationState pair`

and the master criteria requiring exact slot/batch/target/owner identity on rollback/finalization.

The defect is especially dangerous before M26 because M26 will hold claim IDs and drive rollback/finalization paths.

## 4. Required V03 correction

Add one narrow read-only exact M24 binding check.

Preferred shape:

`is_work_bound_to(work_id, expected_slot, expected_batch_id) -> bool`

or an equivalent detached/read-only query.

It must return true only when:

- work_id is live;
- its engine-owned M24 record slot == expected_slot;
- its engine-owned M24 record batch_id == expected_batch_id;
- that exact slot still contains that exact batch.

M25 must use the exact M25 ledger `slot` + `batch_id` in:

- `rollback_claim`;
- `finalize_clear` before `resolve_clear`;
- reset/teardown preflight.

Do not infer exactness only from work-id existence.

## 5. Required adversarial proof

Use two occupied same-color batches A and B so color equality cannot hide the error.

Required sequence:

1. create claim C for oldest batch A;
2. externally `rollback_work(C)` from A;
3. externally `commit_work(B_slot, C)` using the same claim ID;
4. prove M25 detects the redirected M24 work as incoherent with its claim ledger.

Then directly prove:

- `rollback_claim(C)` fails closed;
- B committed count is unchanged by the failed M25 rollback;
- ReservationState pair for C is not released by failed rollback;
- M25 ledger entry remains;
- reset fails closed without mutating unrelated/healthy tuples;
- after authoritative clear prerequisites are staged, `finalize_clear(C)` also fails closed and does not decrement B's remaining/committed counters.

Also re-run healthy rollback/finalize/reset proofs.

## 6. Preserve all V02 accepted behavior

Do not rewrite M25.

Preserve:

- monotonic IDs across reset;
- owner collision skipping;
- exact lifecycle rollback on failed M24 commit;
- strict ProductionTargetAccess category + board coherence;
- session-stable bind;
- BLUE 8/14/12 FIFO;
- capacity spill;
- opening-time claim;
- TargetSelector order;
- one target / one reservation / one claim;
- M24 remaining unchanged on claim;
- rectangular + 59x59 evidence;
- no M26/M27 implementation.

## 7. Closure decision

Do not close `SB-M25-001..032` yet.

Open `M25-C001 V03` as a single exact-work-tuple remediation. If V03 closes this finding and preserves all regressions, M25 may close in full and the canonical tracker may advance to M26.
