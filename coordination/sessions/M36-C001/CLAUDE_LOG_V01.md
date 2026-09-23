# M36-C001 V01 — Claude Implementation Log

Prompt: `coordination/sessions/M36-C001/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/M36-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
Master batch: `coordination/sessions/M34-M40-BATCH/CHATGPT_MASTER_PROMPT_V01.md`

## Scope
Versioned Difficulty V1 runtime services reading the owner-locked configs:
- cadence + campaign-age target curve (`level_progression_v1.json`);
- Challenge Score model W/C/A/U/B/R/S + Session Load + Frustration Risk
  (`difficulty_score_model_v1.json`).
Player-facing class comes from the cadence config keyed on level number, NOT
from board dimensions. Legacy dimension bands retained only as the isolated M21
structural compatibility gate; they no longer decide class.

## Files added
- `scripts/difficulty/difficulty_progression_v1.gd`
- `scripts/difficulty/challenge_score_model_v1.gd`
- `scripts/difficulty/difficulty_v1_catalog_check.gd`
- `tests/m36_difficulty_v1.gd`
- `coordination/sessions/M36-C001/OWNER_PLAYTEST_TEMPLATE.md`
- six task logs under `coordination/sessions/M36-C001/task_logs/`.

## Task log index
- [SB-M36-001](task_logs/SB-M36-001.md) IMPLEMENTED — class no longer from dimensions
- [SB-M36-002](task_logs/SB-M36-002.md) IMPLEMENTED — catalog Difficulty-V1 compat check
- [SB-M36-003](task_logs/SB-M36-003.md) IMPLEMENTED — W/C/A/U/B/R/S model, clamped/versioned
- [SB-M36-004](task_logs/SB-M36-004.md) IMPLEMENTED — deterministic calibration matrix
- [SB-M36-005](task_logs/SB-M36-005.md) OWNER_REQUIRED — playtest harness + template
- [SB-M36-006](task_logs/SB-M36-006.md) IMPLEMENTED — board size cannot determine class

## Tests
```
godot --headless --path . -s res://tests/m36_difficulty_v1.gd
```
Result: **PASS**. Progression regression at levels 1,10,11,100,101,110,111,
300,310,311,1000,1001,1010 all finite/in-range; level 311 EASY target (31.03) >
level 11 EASY target (20.68); cadence classes/modifiers match the owner lock;
boss→recovery drops present (>=35 cycle boss, >=20 mini-boss, >=15 tension);
Challenge/Session Load/Frustration Risk proven as three separate axes; compact
board carries VERY_HARD score, dimension-only change bounded to the 10-point
workload cap.

Regression: M35 catalog test still PASS (composed, not modified).

## Owner gate
SB-M36-005 human calibration is OWNER_REQUIRED. No human fairness verdict
fabricated.

## Handoff
`AWAITING_AUDIT / M36-C001 V01 / OWNER_PLAYTEST_GATE_REMAINS`

Root `TASKS.md` was not edited. Batch continues to M37.
