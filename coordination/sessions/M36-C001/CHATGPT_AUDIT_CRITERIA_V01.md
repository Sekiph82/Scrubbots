# M36-C001 V01 — ChatGPT Audit Criteria

Milestone: `M36 — Difficulty System`
Tasks: `SB-M36-001..SB-M36-006`

Authority:
- `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`
- `docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md`
- `docs/11_LEVEL_DIFFICULTY_CALIBRATION_QA.md`
- `data/config/level_progression_v1.json`
- `data/config/difficulty_score_model_v1.json`
- root `TASKS.md`, `CLAUDE.md`, `coordination/AUDIT_POLICY.md`

## Governance
Claude must not edit root `TASKS.md`.
Each task must have its own durable GitHub log under
`coordination/sessions/M36-C001/task_logs/<TASK_ID>.md`
plus `CLAUDE_LOG_V01.md`.

## SB-M36-001 Legacy migration
The old runtime rule mapping EASY=20..29, MEDIUM=30..39, HARD=40..49, VERY_HARD=50..59 must no longer define player-facing difficulty.
Production board envelope remains 20..59 per dimension, rectangular allowed.
Legacy M21 compatibility may remain only through a clearly isolated compatibility seam if still required.

## SB-M36-002 Catalog validation
M35 production catalog must validate against Difficulty V1 compatibility:
- known class token
- production dimensions within engine envelope
- class not derived from dimensions
- required score/model provenance fields when present
- TEST fixtures rejected

## SB-M36-003 Challenge components
Implement/version Challenge V1 components W/C/A/U/B/R/S and owner-approved factors exactly from the locked config/docs.
All submetrics finite and clamped 0..1.
Final Challenge finite and clamped 0..100.
Do not silently change coefficients under version 1.

## SB-M36-004 Calibration fixtures
Create deterministic calibration fixtures/matrix covering:
- same dimensions, different structural challenge
- compact HARD/VERY_HARD vs larger EASY
- same challenge, different Session Load
- different dominant challenge vectors
- early/mid/late campaign target examples
- boss→recovery relationships

## SB-M36-005 Playtest difficulty
Human difficulty/fairness calibration is OWNER/PLAYTEST-GATED. Claude may provide a local structured playtest harness/report template and machine proxies, but cannot self-claim human calibration PASS. Record `OWNER_REQUIRED` if no human playtest is available. This must not halt the overnight batch.

## SB-M36-006 Board size cannot determine class
Direct sensitivity tests must prove at least:
- a production-legal compact board can carry VERY_HARD
- a larger production board can carry EASY
- changing only dimensions does not automatically rewrite class
- changing class does not automatically rewrite dimensions

## Required progression regression
Verify deterministic targets/cadence for representative levels:
1, 10, 11, 100, 101, 110, 111, 300, 310, 311, 1000, 1001, 1010.
Prove level 311 EASY target > level 11 EASY target.
Prove recovery drops remain present.

## Separation
Challenge, Session Load and Frustration Risk remain separate values.
No dynamic per-player difficulty, analytics SDK, monetization logic, or hidden adaptive difficulty.

## Regression floor
Focused M36 tests, M35 catalog tests, LevelData/validator tests, root suite, representative gameplay load smoke, `git diff --check`.

## Expected handoff
`AWAITING_AUDIT / M36-C001 V01 / OWNER_PLAYTEST_GATE_REMAINS`