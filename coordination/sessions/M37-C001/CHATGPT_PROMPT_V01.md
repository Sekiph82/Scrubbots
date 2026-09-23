# M37-C001 V01 — Level Progression Implementation Prompt

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Tasks: `SB-M37-001..SB-M37-008`

Read:
- `CLAUDE.md`
- root `TASKS.md` read-only
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`
- `data/config/level_progression_v1.json`
- `coordination/sessions/M37-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
- M35/M36 implementation + logs already produced in this batch

## Batch continuation
Finish, test, commit and push M37; if Level Select lacks owner approval, log it OWNER_REQUIRED and continue to M38. Do not pause for owner response. Do not edit root `TASKS.md`.

## Implement
1. Create an authoritative LevelProgressionService or equivalent narrow service.
2. Implement exact repeating 10-level cadence from owner config.
3. Own current progression frontier using stable catalog level identity/number.
4. Record first-clear completion idempotently.
5. Replay must never advance frontier or first-clear rewards.
6. Implement exact TargetChallenge/micro-modifier read model through M36 Difficulty V1 logic.
7. Reject stale/duplicate completion events.
8. Provide safe snapshot/import seams for future M40 persistence without inventing a second save system.
9. Do not implement a shipping Level Select unless an explicit owner approval artifact exists. Debug/test-only selection must be clearly isolated.
10. Keep progression separate from UI/economy.

## Mandatory task logs
Create:
`coordination/sessions/M37-C001/task_logs/SB-M37-001.md`
through `SB-M37-008.md`.

Each log: requirement, production owner, changed files, direct tests, failure condition, result/status, dependency/owner gate, commit evidence.

Create:
`coordination/sessions/M37-C001/CLAUDE_LOG_V01.md`
indexing all eight task logs and recording exact test commands/results and implementation SHA(s).

## Git
Preserve owner work. No destructive reset/clean/force.
Push all M37 code + logs before M38.

Final log handoff:
`AWAITING_AUDIT / M37-C001 V01 / LEVEL_SELECT_OWNER_GATE_REMAINS`

Then continue immediately to M38 via the overnight master pipeline.