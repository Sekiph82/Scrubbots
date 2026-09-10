# M15-C002 — ChatGPT Independent Audit V02

Decision: **CHANGES_REQUIRED / SAME_FROZEN_SET / V03_REQUIRED**

Audited production commit:
`5ff0b1e47f641ca626c69b22a7142eba38d72ce0`

H!veAI start transition:
`58d67775fbc4d926114c1d368a5aa1631458010e`

H!veAI final handoff:
`6c92bc6451b2b122c75e4d82cd1d60ec125cb7db`

Prompt:
`coordination/sessions/M15-C002/CHATGPT_PROMPT_V02.md`

Criteria:
`coordination/sessions/M15-C002/CHATGPT_AUDIT_CRITERIA_V02.md`

Claude evidence:
`coordination/sessions/M15-C002/CLAUDE_LOG_V02.md`

Frozen basis remains exactly:
- F-M15-STRICT-004
- F-M15-STRICT-005

M19-C001 remains blocked by this upstream gate.

## Independence / runtime

Claude reports Godot `4.7.1.stable.official.a13da4feb`, full root suite **2984 / 2984 ALL PASS**, zero SCRIPT/Parse errors and clean `git diff --check`.

These runtime results are E1/E2. Godot is unavailable in the ChatGPT audit environment, so ChatGPT did not independently rerun Godot.

ChatGPT independently inspected the exact production commit/diff, current TargetSelector source, the V02 test block/doubles, ReservationState contract, prompt/criteria, H!veAI tracker/event chain and immediate M19 consumer assumptions. This is E3 source/diff/adversarial-test evidence.

## H!veAI v3

Durable GitHub ordering is correct:
`CHANGES_REQUIRED -> IN_PROGRESS` was pushed before the implementation commit, and the final handoff is `AWAITING_AUDIT / CHATGPT` with progress unchanged at 278/719.

However Claude explicitly disclosed that local production/test edits were written before the IN_PROGRESS start-transition was pushed. This violates the V02 prompt/criterion requiring the lifecycle guard to be armed before production edits. Record as **HIVEAI_PROCESS_NONCONFORMANCE**. It is not promoted to a gameplay finding, but V03 must follow the ordering literally.

## V02 corrections accepted

The following V01 gaps are materially corrected and must be preserved:

- `_in_selection` is armed before the first selection coherence callback;
- recursive `select_and_reserve()` during an active selection returns -1;
- `_in_bind` blocks nested bind during bind-time coherence callbacks;
- coherence is rechecked after `is_reserved()` for true and false branches;
- malformed non-bool `reserve()` after mutation triggers exact-pair rollback;
- rollback uses exact `release(idx, owner_id)` and is no longer gated by `get_owner()`;
- same-owner assignment after targetability stops before later candidates;
- V01 Variant/category/type hardening remains present.

The auditor-authored pre-fix sensitivity evidence is strong: all seven V01 gaps were reproduced against commit `5a2ed276...` before correction.

## Remaining frozen-set gaps

No new top-level M15 finding ID is opened. The following remain inside F-M15-STRICT-004/005.

### F-M15-STRICT-005.H — selection can run during a bind transaction

V02 introduces `_in_bind`, but `select_and_reserve()` checks only `_in_selection`.

This is unsafe when the selector is already bound to bundle A and an outer `bind(B)` begins. During B's candidate/reservation `is_bound_to()` callback, a nested `select_and_reserve()` can still execute against the old A binding because `_in_bind == true` but `_in_selection == false`.

That nested selection can create a reservation in A immediately before the outer bind commits B, leaving an orphaned old-bundle reservation.

Required:
- `select_and_reserve()` must fail closed while `_in_bind` is true;
- rejection must occur before any selection collaborator callback;
- direct candidate-coherence and reservation-coherence bind-time tests must begin from an already-bound A selector, attempt bind B, inject nested selection, and prove A/B reservation counts do not gain an orphan;
- outer valid bind B may then commit normally and later selection on B must recover.

### F-M15-STRICT-005.I — post-targetability owner query is itself an unchecked callback boundary

V02 correctly adds:
`owned_after = rs.get_target_for_owner(owner_id)`

after targetability, but does not perform `_op_coherent(...)` after this external callback.

If that owner-query callback rebinds candidate/reservation state and returns valid int `-1`, the selector may continue to `reserve()` or the next candidate under a drifted operation.

Required sequence:
1. targetability callback;
2. coherence check;
3. owner query;
4. validate TYPE_INT;
5. **coherence check again**;
6. only then branch on owner assignment/verdict and consider reserve/continue.

Direct sensitivity must inject candidate and ReservationState drift from the post-targetability owner query while returning `-1`, for bool-true and at least one false/non-bool verdict path. No reserve or later targetability call may occur after drift.

### F-M15-STRICT-005.J — post-reserve ownership proof callbacks are not transactionally bracketed

After a successful reserve, current code calls:
- `get_owner(idx)`;
- `get_target_for_owner(owner_id)`;

then validates both together and can return success without a coherence check after either proof callback.

Two problems follow:

1. A proof callback can drift a sibling dependency while returning the expected integer, allowing success under a drifted operation.
2. If `get_owner()` is already malformed, the second proof callback is still invoked even though failure is already known, violating direct fail-closed ordering and allowing an unnecessary side effect after a known invalid result.

Required strict sequence:
- after reserve true, coherence check;
- call `get_owner(idx)`;
- validate TYPE_INT immediately;
- on malformed: exact-pair rollback and return -1, with **zero target-proof callback after the known failure**;
- after valid owner proof: coherence check; on drift rollback;
- call `get_target_for_owner(owner_id)`;
- validate TYPE_INT immediately;
- after valid target proof: coherence check; on drift rollback;
- only then compare exact owner/target identity and return success.

Direct tests:
- get_owner callback drifts candidate while returning correct owner -> -1 + exact rollback + target-proof not called;
- get_owner callback drifts ReservationState while returning correct owner -> -1 + no success;
- target-proof callback drifts candidate while returning correct target -> -1 + exact rollback;
- target-proof callback drifts ReservationState while returning correct target -> -1 + no success;
- malformed get_owner proves target-proof callback count remains unchanged;
- unrelated reservation survives every rollback case.

## Coherence-seam contract note

Production `ColorCandidateIndex.is_bound_to()` and `ReservationState.is_bound_to()` are read-only identity queries. V03 is not required to defend against a deliberately Byzantine coherence method that lies about its own internal state after every probe. The required adversarial model remains synchronous side effects at ordinary collaborator boundaries plus selector re-entry, with the read-only coherence seam itself treated as truthful about the state it returns.

## Frozen set status

- F-M15-STRICT-004 — materially improved; remains OPEN only for transactionally safe malformed-result cleanup regressions.
- F-M15-STRICT-005 — OPEN for H/I/J above.

No additional M15 finding IDs.

## Task/progress disposition

Do not advance root task completion or project progress.

- Main + UI: **278 / 719 = 38.66%**
- Overall: **278 / 943 = 29.48%**

## Verdict

**CHANGES_REQUIRED / SAME_FROZEN_SET / V03_REQUIRED**

Next:
`coordination/sessions/M15-C002/CHATGPT_PROMPT_V03.md`
