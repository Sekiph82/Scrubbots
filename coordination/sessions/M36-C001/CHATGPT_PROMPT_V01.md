# M36-C001 V01 — Difficulty V1 Migration & Runtime Prompt

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Tasks: `SB-M36-001..SB-M36-006`

Mandatory reading:
- `CLAUDE.md`
- root `TASKS.md` read-only
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`
- `docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md`
- `docs/11_LEVEL_DIFFICULTY_CALIBRATION_QA.md`
- `data/config/level_progression_v1.json`
- `data/config/difficulty_score_model_v1.json`
- `coordination/sessions/M36-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
- M35 catalog implementation/log if already produced in this batch

## Batch continuation
Implement, test, commit and push M36; log any human playtest requirement as OWNER_REQUIRED; then continue directly to M37. Do not wait for ChatGPT between milestones and do not edit root `TASKS.md`.

## Required implementation
1. Replace/retire legacy class=dimension runtime truth while preserving 20..59 rectangular board-envelope validation.
2. Introduce a versioned Difficulty V1 runtime/config reader or equivalent narrow service.
3. Implement deterministic cadence/target challenge logic from `level_progression_v1.json`.
4. Implement/version W/C/A/U/B/R/S challenge analysis using current canonical gameplay/routing/solver truth rather than inventing duplicate laws.
5. Keep Session Load and Frustration Risk separate from Challenge.
6. Integrate M35 catalog compatibility validation.
7. Add controlled fixtures proving board size alone cannot define difficulty.
8. Add structured local playtest report/harness for later owner calibration. Do not invent human results.
9. Preserve M21 compatibility only through an explicit legacy compatibility boundary if still needed.
10. No analytics SDK, hidden DDA or economy changes.

## Mandatory per-task logs
Create:
`coordination/sessions/M36-C001/task_logs/SB-M36-001.md`
through
`SB-M36-006.md`.

Each must state requirement, code paths, direct evidence, expected/failure condition, result, owner gate if applicable, and commit evidence.

Create canonical:
`coordination/sessions/M36-C001/CLAUDE_LOG_V01.md`
indexing all six task logs.

## Git
Preserve owner work. No force/reset/clean.
Implementation/tests first, evidence/log docs second. Push all M36 work before M37.

Final M36 log handoff:
`AWAITING_AUDIT / M36-C001 V01 / OWNER_PLAYTEST_GATE_REMAINS`

Then continue immediately to M37 through the overnight master pipeline.