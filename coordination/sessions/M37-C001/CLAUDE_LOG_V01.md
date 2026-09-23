# M37-C001 V01 — Claude Implementation Log

Prompt: `coordination/sessions/M37-C001/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/M37-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
Master batch: `coordination/sessions/M34-M40-BATCH/CHATGPT_MASTER_PROMPT_V01.md`

## Scope
Authoritative `LevelProgressionService`: owns the current progression frontier
and an idempotent first-clear set keyed by stable level number; reads M36
Difficulty V1 for cadence class / target; replay is non-advancing; versioned
snapshot/import seam for M40. No UI, no economy, no own save format.

## Files added
- `scripts/progression/level_progression_service.gd`
- `tests/m37_level_progression.gd`
- eight task logs under `coordination/sessions/M37-C001/task_logs/`.

## Task log index
- [SB-M37-001](task_logs/SB-M37-001.md) IMPLEMENTED — cadence via M36
- [SB-M37-002](task_logs/SB-M37-002.md) IMPLEMENTED — current level authority
- [SB-M37-003](task_logs/SB-M37-003.md) IMPLEMENTED — idempotent first-clear
- [SB-M37-004](task_logs/SB-M37-004.md) IMPLEMENTED — replay non-advancing
- [SB-M37-005](task_logs/SB-M37-005.md) IMPLEMENTED — target curve via M36
- [SB-M37-006](task_logs/SB-M37-006.md) OWNER_REQUIRED — debug seam only, no shipping select
- [SB-M37-007](task_logs/SB-M37-007.md) IMPLEMENTED — narrow service + snapshot seam
- [SB-M37-008](task_logs/SB-M37-008.md) TESTED — full adversarial matrix

## Tests
```
godot --headless --path . -s res://tests/m37_level_progression.gd
```
Result: **PASS** — cadence, frontier, first-clear idempotency, reentrant
duplicates, replay win/loss, stale completion, invalid input, cadence
boundaries (10->11/20->21/310->311), snapshot round-trip, malformed snapshot
fail-closed, no-content-mutation.

Regression: M36 and M35 tests still PASS; M37 composes them without modification.

## Owner gate
SB-M37-006 shipping level-select is OWNER_REQUIRED (only a non-shipping debug
seam exists).

## Handoff
`AWAITING_AUDIT / M37-C001 V01 / LEVEL_SELECT_OWNER_GATE_REMAINS`

Root `TASKS.md` was not edited. Batch continues to M38.
