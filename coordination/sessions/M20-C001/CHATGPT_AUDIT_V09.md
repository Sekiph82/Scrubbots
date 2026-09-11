# M20-C001 — ChatGPT Independent Whole-Sprint Audit V09

Decision: **PRODUCTION_ACCEPTED / EXACT_EVIDENCE_RECONCILIATION_REQUIRED / V10_FINAL_CLOSURE_ONLY**

Audited validation commit:
`a7ac79dbbf943c7ac6def528b08c5b3e99811526`

V09 start-transition commit:
`df9e9adf8b0de71eb9bdca5b12fb184e3f1e9cd9`

Accepted production basis:
`e189ee8bd2b9be68b876cfdb18377622ed3ce832`

Prompt:
`coordination/sessions/M20-C001/CHATGPT_PROMPT_V09.md`

Criteria:
`coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V09.md`

Claude evidence:
`coordination/sessions/M20-C001/CLAUDE_LOG_V09.md`

Canonical tracker: repository-root `TASKS.md` only.

## Evidence level / runtime limitation

Claude reports Godot `4.7.1.stable.official.a13da4feb`, full suite **4192 / 4192 ALL PASS**, queue-free plus V04/V05/V07/V08/V09 lifecycle smokes PASS, and all S1-S6 sensitivity mutations failing their named protection before exact restoration.

Those runtime results are E1/E2. ChatGPT cannot execute Godot here. E3 consists of independent GitHub commit/diff/source/test/log/tracker inspection and criteria-to-evidence reconciliation.

## Governance / immutability

PASS:
- tracker-only V09 start commit precedes the validation/handoff commit;
- root tracker is `M20-C001-V09 / AWAITING_AUDIT / CHATGPT`;
- no SB-M20 row was closed by Claude;
- progress remains `290/719` main+ui and `290/943` overall;
- `lastCompletedTaskId` remains M19-C001-V06;
- compare from accepted V07 implementation to V09 handoff contains no `scripts/**` change;
- accepted production blobs remain exactly:
  - CompleteClearingLoop `06391839523cbc27e88a4b3ef12b730012cd45fa`;
  - ScrubbotDispatcher `eee10149e4f116af6706beec832042352bf3a6dd`.

No new M20 production defect was found in V09.

## Mandatory Pass A — whole-sprint implementation/state sweep

Re-read/reconciled the full M20 transaction surface rather than only the V09 test diff:
- exact production dependency categories;
- single M20 consumer claim;
- explicit `agent_parent` lifecycle;
- optional renderer configured-vs-dead law;
- activation serialization and post-dispatch reset/coherence bracket;
- authenticated arrival preflight;
- BoardState -> candidate -> reservation -> dispatcher-finalize -> renderer ordering;
- exact reservation owner-map rollback;
- duplicate-current and distinct FIFO arrival handling;
- transactional reset and pair-narrow cleanup;
- AL-028 live BoardState access;
- 1x1 / difficulty ranges / rectangular / 59x59;
- no scoring/win/lose/session/M21/slot-queue leakage.

Result: **no new material source defect found**. V07 accepted production remains source-accepted.

### Sibling and interaction sweep

Rechecked sibling classes previously responsible for repeated M20 defects:
- freed Object/null alias: renderer + agent_parent;
- claim lifecycle + reset + GC;
- reset + callback;
- reset + dependency drift;
- rollback + unrelated candidate/reservation truth;
- duplicate/re-entry + current/queued identity;
- stale completion + owner/target identity;
- presentation loss + canonical gameplay state;
- exact set/map proof versus count-only proof.

No additional production correction is frozen.

## Mandatory Pass B — all 279 criteria reconciled to actual evidence

V09 closed most V08 gaps materially. In particular:
- ordinary invalid/no-work activation now uses detached BoardState + active-count + next-owner + exact reservation map/count + all-five-slot-tuples comparison;
- forged identity arrivals use fresh arrangements and preserve target reservation in both directions plus raw candidate and sentinel truth;
- diagnostic listener is present before first M20 bind;
- GC smoke proves old M20 callback disappears without a strong cycle;
- five in-flight assignments prove both reservation directions;
- AL-028 directly proves B not targetable before A clears;
- reset-with-multiple directly preserves BoardState and raw-candidate truth;
- six sensitivity mutations remain load-bearing.

However, strict one-to-one reconciliation found the following **complete known residual evidence set**. These are validation-evidence gaps, not proven production defects.

### G-V09-01 — claim/reset usability is still partly proxy-observed

V09 says the owning loop is usable after `reset()`, but the fresh V09 assertion is only `l1.is_coherent()`. The prompt required actual usability. V10 must perform a second real activation/dispatch/arrival after owner reset on the same still-owning loop and prove exactly one additional clear. It must also snapshot reservation truth around claim/reset-only operations, not BoardState alone.

### G-V09-02 — activation serialization has two direct-proof gaps

1. V09 nested activation asserts one active assignment and one reservation but declares `owner_before` without checking the owner counter. Therefore it does not directly prove the rejected nested activation consumed no second owner token.
2. V09 prompt/criterion 104 explicitly required `activate_slot()` during an **actively draining arrival transaction** to return `REENTRANT`. The new V09 block contains nested activation during activation preflight, but no direct activation-from-arrival-drain arrangement.

Production source explicitly guards `_in_activation or _draining`; the gap is direct evidence.

### G-V09-03 — failed-arrival preflight preservation is incomplete outside the forged-identity five

The forged identity five are strong. Several sibling preflight cases still assert only a subset of the exact invariants required by V09:
- missing reservation: rejection + target ACTIVE are checked, but cleared_count and pending dispatcher assignment/no-finalize are not directly checked;
- candidate `rebind(foreign)`: only target->owner + dispatcher + cleared_count are checked; owner->target is not;
- candidate `rebind(null)`: rejection is checked, but exact reservation both directions + dispatcher pending + cleared_count zero are not directly checked;
- externally-CLEARED target: rejection + cleared_count zero are checked, but reservation and dispatcher assignment preservation are not;
- renderer foreign after assignment: target ACTIVE + target->owner + dispatcher are checked, but raw candidate and owner->target are not;
- renderer queued after assignment: target ACTIVE + cleared_count zero are checked, but raw candidate, both reservation directions, and dispatcher pending are not;
- frame-freed renderer smoke proves target ACTIVE, target->owner and dispatcher pending, but not raw candidate and owner->target.

V10 must cover these as one table-driven exact preflight-preservation matrix. Where cleanup is authorized, a frame-aware case must prove the agent is actually gone/no orphan after reset.

### G-V09-04 — exact pair-removal / exact target-change ledger has two proxy assertions

- SB-M20-007 after first arrival checks first target `get_owner == -1`, then proves the other four pairs both ways. It does not directly assert first owner `get_target_for_owner(first_owner) == -1` at that exact point.
- SB-M20-008..013 count CLEARED cells before/after and prove `+1`; for the 59x59 row criterion 184 explicitly says the intended target changed. V10 must directly assert `get_cell_state(expected_target) == CLEARED` in each scale row in addition to count delta.

### G-V09-05 — rollback “exact prestate” labels are stronger than their fresh assertions

Fresh V09 candidate mutate-before-false calls its result “exact tuple restored” but directly checks only the focal target/candidate/reservation/dispatcher ownership. Fresh reservation mutate-before-false calls its result “exact map restored” but directly checks only the focal pair. Prior V03/V08 adversaries provide adjacent coverage, but V09 criteria 199/201 explicitly asked detached exact prestate/map proof.

V10 must take detached prestate snapshots and compare:
- candidate case: BoardState states, relevant candidate buckets including unrelated same/different-color truth, exact reservation map, dispatcher active/owner state;
- reservation case: exact full reservation target->owner map/count plus owner->target identities for all arranged pairs, BoardState and dispatcher state.

### G-V09-06 — cleanup/no-orphan and traceability need explicit final rows

V09 prompt required failed-preflight authorized cleanup to prove no orphan agent where a frame is required. Healthy queue-free smoke is not the same failure path. V10 must add one frame-aware failed-preflight -> reset case and prove the held agent is truly destroyed and leaves no orphan child.

The final evidence table must map G-V09-01..06 to exact test/assertion names and runtime results. Aggregate `4192/4192` is not a substitute.

## Criteria classified as already sufficient

The following are accepted and do not need reinvention in V10:
- V09 tracker/governance ordering;
- production immutability;
- agent_parent lifecycle regressions;
- renderer bind/presence category regressions;
- full ordinary invalid/no-work snapshot matrix;
- forged-identity five exact preservation matrix;
- same-board T->O2 and foreign ReservationState replacement survival;
- SB-M20-001..006 core behavior;
- five-in-flight initial both-direction pairs and preservation of the remaining four;
- AL-028 initial non-targetability + second real dispatch;
- rapid >=25;
- multi-in-flight reset BoardState/candidate preservation;
- identity-swap owner-map sensitivity;
- pair-narrow reset sensitivity;
- S1-S6 mutation/restoration evidence;
- current architecture documentation.

## Task disposition

SB-M20-001..014 remain open only because final critical-sprint evidence closure has not yet met every explicitly requested direct-observability condition. No task is reopened for a new production defect.

## Verdict

**PRODUCTION_ACCEPTED / EXACT_EVIDENCE_RECONCILIATION_REQUIRED / V10_FINAL_CLOSURE_ONLY**

V10 must be validation-only. No `scripts/**` change is authorized. It exists solely to close G-V09-01..06 in one batched pass and rerun final regression evidence. If V10 exposes a production defect, Claude must stop without fixing it.