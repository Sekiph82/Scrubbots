# M25-C001 V03 — Exact M24 Work-Tuple Binding Remediation

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Milestone: M25 Batch Target Claim Engine
Execution mode: ONE NARROW CONTINUOUS PASS

Read:
1. `coordination/sessions/M25-C001/CHATGPT_AUDIT_V02.md`
2. `coordination/sessions/M25-C001/CHATGPT_AUDIT_CRITERIA_V03.md`
3. prior M25 V01/V02 audit criteria.

Objective: close the single remaining finding `F-M25-V02-STRICT-001`.

Critical correction:

M25 must not accept an M24 work ID merely because that ID is live and internally coherent somewhere in FiveSlotBatchEngine.

The M24 work must be proven bound to the exact M25 claim ledger tuple:
- claim/work id;
- slot index;
- batch_id.

Implement a minimal read-only M24 exact-binding seam, preferably:
`is_work_bound_to(work_id, expected_slot, expected_batch_id)`.

Use the exact check in:
- rollback_claim preflight;
- finalize_clear preflight before resolve_clear;
- reset/teardown preflight.

Required adversarial proof:

- two occupied same-color batches A and B;
- claim C originally belongs to A;
- externally rollback C from A at M24;
- externally re-commit the SAME work id C to B;
- M24's redirected work is internally coherent for B, but M25 must detect it does not match claim C's original A tuple;
- rollback_claim(C) fails closed with reservation + M25 ledger intact and B counters untouched;
- finalize_clear(C) fails closed and cannot decrement B after clear prerequisites are staged;
- reset with redirected C plus a healthy claim fails closed before mutating either tuple.

Preserve every V01/V02 accepted behavior. Do not implement M26/M27. Do not modify root TASKS.md. Zero image credits.

Run the complete V03 criteria and all required regressions.

Push implementation first, then write `coordination/sessions/M25-C001/CLAUDE_LOG_V03.md` as a separate commit.

The V03 log must explicitly state safe-sync SHA, every implementation SHA, final implementation SHA, changed files, root-suite count/failures, and direct redirected-work traces.

Return only AWAITING_AUDIT, final implementation SHA and direct GitHub log URL.
