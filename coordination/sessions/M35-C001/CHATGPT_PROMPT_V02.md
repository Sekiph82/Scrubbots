# M35-C001 V02 — LevelCatalog Hardening Remediation

Read V01 audit + V02 criteria.

Fix:
- shallow entry exposure in get_entries_ordered/get_entry_by_id;
- exact-integer order validation;
- robust canonical path normalization/root confinement/alias detection.

Do not recreate the catalog architecture.

M36 V02 owns the general production class=dimension migration. After M36 V02 lands, rerun M35 with direct fixtures proving 24x24 VERY_HARD and 38x38 EASY can enter the production catalog while TEST is rejected.

Create V02 logs for SB-M35-002,003,005,007,009,010,011 under task_logs_v02 and canonical CLAUDE_LOG_V02.md.

Push and hand off:
`AWAITING_AUDIT / M35-C001 V02`