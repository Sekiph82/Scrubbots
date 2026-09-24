# M37-C001 V02 — Strict-v2 Progression Validation Pass

Read V01 audit + V02 criteria.

Do not rewrite LevelProgressionService preemptively.
Add an auditor-driven adversarial test suite covering every V02 criterion.
Record PRE-FIX results first.
If a test exposes a concrete defect, implement the smallest production correction, record before/after evidence, rerun full M35-M37 regressions.

Create task_logs_v02 for affected SB-M37 IDs and CLAUDE_LOG_V02.md.

Owner decision is now locked in `coordination/OWNER_M37_LEVEL_SELECT_DECISION_V01.md`: do not implement shipping Level Select. Keep the existing non-shipping debug seam only and add a regression proving no player-facing level-select flow is introduced.

Handoff:
`AWAITING_AUDIT / M37-C001 V02 / STRICT_V2_VALIDATION_COMPLETE`