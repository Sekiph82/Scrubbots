# M38-C001 V02 — Claude Strict-v2 Validation Log

V01 audit: `coordination/sessions/M38-C001/CHATGPT_AUDIT_V01.md`
(`CHANGES_REQUIRED / STRICT_V2_VALIDATION_ONLY`)
V02 prompt: `coordination/sessions/M38-C001/CHATGPT_PROMPT_V02.md`
V02 criteria: `coordination/sessions/M38-C001/CHATGPT_AUDIT_CRITERIA_V02.md`

## Approach
Independent adversarial suite `tests/m38_v02_strict.gd` (separate from the V01
happy-path suite), using exact economy-state fingerprints (streak / SB / bot
parts / gift total / gift cycle) before and after every rejected operation.
PRE-FIX results captured first.

## Concrete defect found + minimally fixed
PRE-FIX 4 failures in `WinStreakService.import_snapshot`:
- fractional `streak` (3.5) silently truncated;
- fractional `processed` entries (2.5) silently truncated;
- duplicate `processed` ids collapsed silently;
- a malformed import therefore did not leave the exact pre-import state.

Minimal fix in `scripts/economy/win_streak_service.gd`: `_as_exact_int` accepts
int or integral float and rejects fractional / NaN / INF; duplicate processed
ids fail closed; all-or-nothing apply preserved. POST-FIX 0 failures.

## Scenarios validated (all PASS)
duplicate/reentrant first-clear; stale prior-level; replay win/loss isolation;
loss/reset/restart-after-action/pre-action-exit matrix; exact wallet/Bot-Part/
gift state at 4->5, 5->6, 9->10; reward-grant-failure leaves streak/wallet/gift
untouched (via injected failing reward) and the level stays winnable; gift feed
idempotent by tx id; snapshot/import then stale-tx replay; malformed/fractional/
duplicate snapshot fail-closed with exact pre-import state; large valid streak
(100000) imports and still maps to 100 SB.

## Regression
`m37_v02_strict`, `m38_win_streak`, `m39a_economy_core`, `m39e_full_matrix`,
`m40_save_system` PASS; root suite 5336/0. No M39 service duplicated.

## Task logs
`coordination/sessions/M38-C001/task_logs_v02/SB-M38-001..016`.

## Handoff
`AWAITING_AUDIT / M38-C001 V02 / STRICT_V2_VALIDATION_COMPLETE`

Root `TASKS.md` not edited. Continuing to M39 V02.
