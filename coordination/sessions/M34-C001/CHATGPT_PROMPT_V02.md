# M34-C001 V02 — Production Haptics Wiring Remediation

Read V01 audit + V02 criteria first.

Fix only F-M34-001:
- instantiate/own one live HapticsController in the production gameplay host/composition;
- wire committed clear, WON terminal and successful Retry/new-attempt authoritative seams exactly once;
- bind the live haptics setting to that controller;
- prevent duplicate connections on reinit/reset;
- preserve fail-open unsupported-platform behavior.

Add production-stack tests that emit the real authoritative signals and assert injected platform-sink calls. Do not rely only on direct request_* calls.

Do not fake SB-M34-006 device evidence.

Create V02 task logs for SB-M34-002, 003, 004, 005, 006 under:
`coordination/sessions/M34-C001/task_logs_v02/`

Create `CLAUDE_LOG_V02.md`, commit implementation/tests then logs, push, hand off:
`AWAITING_AUDIT / M34-C001 V02 / DEVICE_OWNER_GATE_REMAINS`