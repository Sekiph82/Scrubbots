# M37-C001 V02 — Claude Strict-v2 Validation Log

V01 audit: `coordination/sessions/M37-C001/CHATGPT_AUDIT_V01.md`
(`CHANGES_REQUIRED / STRICT_V2_VALIDATION_ONLY`)
V02 prompt: `coordination/sessions/M37-C001/CHATGPT_PROMPT_V02.md`
V02 criteria: `coordination/sessions/M37-C001/CHATGPT_AUDIT_CRITERIA_V02.md`

## Approach
Validation-first per the prompt. Added `tests/m37_v02_strict.gd` covering every
V02 criterion and recorded PRE-FIX results before any source change.

## Concrete defect found + minimally fixed
PRE-FIX the strict suite failed 6 assertions in `LevelProgressionService.import_snapshot`:
- fractional `current_level` (3.5) was silently truncated instead of failing closed;
- fractional `completed` entries (2.5) were silently truncated;
- duplicate `completed` ids collapsed silently;
- a malformed import therefore did not leave the exact pre-import state.

Minimal production fix in `scripts/progression/level_progression_service.gd`:
- new `_as_exact_int(v)` accepts int or integral float, rejects fractional / NaN
  / INF / non-numeric;
- duplicate `completed` ids now fail closed (a loaded snapshot never legitimately
  contains duplicates — `snapshot()` emits a sorted unique list);
- all-or-nothing apply preserved (validation completes before any live mutation),
  so a failed import leaves the exact pre-import snapshot.

POST-FIX: strict suite PASS (0 failures).

## Regression
`m37_level_progression`, `m38_win_streak`, `m40_save_system` PASS after the fix
(M40 imports integer progression snapshots, unaffected by the stricter float
rule). Root suite 5336/0.

## Task logs
`coordination/sessions/M37-C001/task_logs_v02/SB-M37-001..008`.

## Gate
SB-M37-006 shipping Level Select remains OWNER_REQUIRED.

## Handoff
`AWAITING_AUDIT / M37-C001 V02 / STRICT_V2_VALIDATION_COMPLETE`

Root `TASKS.md` not edited. Continuing to M38 V02.
