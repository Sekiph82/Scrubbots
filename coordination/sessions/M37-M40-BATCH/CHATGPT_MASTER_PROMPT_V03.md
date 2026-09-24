# M37 / M39 / M40 REMEDIATION BATCH V03 — Uninterrupted Final Repair Prompt

Repository: `Sekiph82/Scrubbots`
Branch: `main`

This batch exists after independent V02 full-surface audits.

Closed / gate-only milestones:
- M35: AUDITED_PASS
- M38: AUDITED_PASS
- M34: code pass; real-device haptics gate remains
- M36: code pass; human difficulty playtest remains

Do NOT redo closed work.

## Execution order
1. M37 V03
2. M39 V03
3. M40 V03

Proceed without waiting between these three cycles.

At each cycle:
- fetch/sync safely;
- read V02 audit + V03 criteria + V03 prompt;
- implement every frozen finding;
- run direct/adversarial tests;
- write task_logs_v03/ for affected tasks;
- write CLAUDE_LOG_V03.md;
- commit implementation/tests;
- commit evidence/logs;
- push;
- verify remote log exists;
- continue.

Do not edit root TASKS.md.
Do not self-audit.
Do not start M41+.

## M37 V03
Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M37-C001/CHATGPT_PROMPT_V03.md

Criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M37-C001/CHATGPT_AUDIT_CRITERIA_V03.md

Frozen findings:
F-M37-V02-001..002

## M39 V03
Start only after M37 V03 is pushed.

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M39-C001/CHATGPT_PROMPT_V03.md

Criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M39-C001/CHATGPT_AUDIT_CRITERIA_V03.md

Frozen findings:
F-M39-V02-001..016

SB-M39-033 real-device safe-area/touch remains OWNER/DEVICE_REQUIRED after code integration; do not stop the batch for that gate.

## M40 V03
Start only after M39 V03 is pushed.

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M40-C001/CHATGPT_PROMPT_V03.md

Criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M40-C001/CHATGPT_AUDIT_CRITERIA_V03.md

Frozen findings:
F-M40-V02-001..009

M40 must validate the POST-M39-V03 state graph.

## Context-loss recovery
After any compression/restart:
1. git fetch origin
2. inspect status/log
3. reread this master prompt from GitHub
4. inspect latest CLAUDE_LOG_V03.md + task_logs_v03/
5. resume from first missing cycle/task

Scratchpad is not authority.

## Final handoff
After M40 V03 is pushed and remote-verified, stop production work and return:
- M37 V03 implementation/log commits + CLAUDE_LOG URL
- M39 V03 implementation/log commits + CLAUDE_LOG URL
- M40 V03 implementation/log commits + CLAUDE_LOG URL
- remaining owner/device gates
- confirmation TASKS.md untouched
- confirmation no M41+ work

Final line:
`AWAITING_AUDIT / M37-M40 REMEDIATION BATCH V03 COMPLETE`
