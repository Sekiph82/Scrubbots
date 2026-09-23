# M39-C001 V02 — Economy Full Integration & Atomicity Remediation

Read:
- CHATGPT_AUDIT_V01.md
- CHATGPT_AUDIT_CRITERIA_V02.md
- original V01 prompt/criteria/log
- M23-M30 production engines
- M37/M38 V02 results

Do not patch only SB-M39-031/032. Close the entire frozen finding set F-M39-001..010.

## Phase A — live capacity + solver
Wire SlotCapacityAuthority into the real FiveSlotBatchEngine/runtime placement queries.
Extend real M27 proof/canonical state for capacity 5/6.
Preserve capacity=5 regressions.
Add exact tests proving state distinction and no 7+ state.

## Phase B — concrete production booster adapter
Create one narrow adapter over actual BoardState/supply/slots/claims/scheduler/solver.
Wire BoosterService to it through the real runtime composition.
Implement Random/Selector/Tornado end-to-end.
Use real-state snapshot/rollback and fault injection at every Tornado stage.

## Phase C — shipping speed/economy event wiring
Gate the actual manual 2x request path through SpeedEntitlementService while preserving free automatic M23-exhausted 2x.
Wire first-clear/streak/heart/restart/completion semantics through authoritative existing events.
No direct UI mutation.

## Phase D — state hardening
Make EconomyServices.import_snapshot independently atomic.
Reject fractional/non-finite values for integer state.
Make Cards Exchange truly all-or-nothing.
Persist Daily current-day task state.
Reject noncanonical collection snapshot IDs/state.

## Phase E — full strict validation
Run real production integration tests for 5/6 slots, solver, all four boosters, speed gate, first-clear/replay, restart/loss, import rollback and cross-engine conservation.
Capture exact before/after snapshots for every forced failure.

## Evidence
Create `task_logs_v02/` for every affected M39 task, at minimum:
031,032,033,034,035,036,037,038,039,040,020,027,028,043,045,048,050,052 and any additional IDs touched.
Do not overwrite V01 logs.

Create `CLAUDE_LOG_V02.md` with:
- finding-by-finding closure table F-M39-001..010;
- implementation commit SHAs;
- exact real integration paths;
- tests/results;
- remaining DEVICE_REQUIRED truth for 033.

Commit by coherent phases, push all, no TASKS edit, no self-audit.

Handoff:
`AWAITING_AUDIT / M39-C001 V02 / DEVICE_GATE_REMAINS / STRICT_V2_REAUDIT_REQUIRED`