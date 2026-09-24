# M39 / M40 REMEDIATION BATCH V04 — Uninterrupted Final Integration Prompt

Repository: `Sekiph82/Scrubbots`
Branch: `main`

Independent V03 audit state:
- M37: AUDITED_PASS / CLOSED
- M39: CHANGES_REQUIRED / F-M39-V03-001..005
- M40: CHANGES_REQUIRED / F-M40-V03-001..004
- M34: code pass; real-device haptics gate remains
- M36: code pass; human difficulty playtest remains

Do not redo closed work.

## Execution order
1. M39 V04
2. M40 V04

Proceed without waiting between the two cycles.

## M39 V04
Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M39-C001/CHATGPT_PROMPT_V04.md

Criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M39-C001/CHATGPT_AUDIT_CRITERIA_V04.md

Frozen findings:
F-M39-V03-001..005

Focus:
- owner-required selected-color Tornado in-flight cancellation;
- real production local-calendar provider;
- exact +1 Slot rollback;
- atomic progression+first-clear transaction;
- canonical production action facade.

SB-M39-033 remains DEVICE/OWNER_REQUIRED after code audit. Do not stop for that device gate.

After implementation:
- create task_logs_v04/
- create CLAUDE_LOG_V04.md
- commit implementation/tests
- commit logs
- push
- verify remote
- continue immediately to M40 V04.

## M40 V04
Start after M39 V04 is pushed.

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M40-C001/CHATGPT_PROMPT_V04.md

Criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M40-C001/CHATGPT_AUDIT_CRITERIA_V04.md

Frozen findings:
F-M40-V03-001..004

Focus:
- actual project main bootstrap owns AppState;
- frontier resolves canonical LevelCatalog content;
- committed durable actions automatically bind to canonical persistence;
- background/quit lifecycle flush;
- end-to-end local Daily save/relaunch semantics.

Do not implement M41+ UI.

## Continuous-execution rules
Do not edit root TASKS.md.
Do not create ChatGPT audit verdicts.
Do not self-assign AUDITED_PASS.
Do not stop between M39 and M40 for intermediate ChatGPT review.

If context is lost:
1. git fetch origin
2. inspect git status/log
3. reread this master prompt from GitHub
4. inspect latest task_logs_v04/ and CLAUDE_LOG_V04.md
5. resume from first missing step

## Final handoff
Return:
- M39 V04 implementation/log SHAs + CLAUDE_LOG URL
- M40 V04 implementation/log SHAs + CLAUDE_LOG URL
- remaining OWNER/DEVICE gates
- confirmation TASKS.md untouched
- confirmation no M41+ work

Final line:
`AWAITING_AUDIT / M39-M40 REMEDIATION BATCH V04 COMPLETE`
