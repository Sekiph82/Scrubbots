# M37-C001 V03 — Forward-Only Progression Remediation

Read:
- CHATGPT_AUDIT_V02.md
- CHATGPT_AUDIT_CRITERIA_V03.md
- OWNER_M37_LEVEL_SELECT_DECISION_V01.md

Fix only frozen F-M37-V02-001..002.

Required:
- record_win accepts a NEW shipping first-clear only for the current frontier;
- stale/future/replay/duplicate attempts make zero mutation;
- import_snapshot enforces canonical contiguous completed history 1..current_level-1;
- debug_set_current_level remains debug/test-only and must not become a player-facing level selector.

Add a new V03 adversarial test file. Record pre-fix evidence where practical, then fix, then rerun.

Create:
- coordination/sessions/M37-C001/task_logs_v03/ for SB-M37-003,007,008
- coordination/sessions/M37-C001/CLAUDE_LOG_V03.md

Do not edit TASKS.md.
Push implementation/tests then logs.

Handoff:
`AWAITING_AUDIT / M37-C001 V03 / FORWARD_ONLY_REMEDIATION_COMPLETE`
