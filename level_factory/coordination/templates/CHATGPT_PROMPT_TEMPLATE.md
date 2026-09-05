---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-prompt
cycleId: REPLACE
version: 1
actor: CHATGPT
status: ISSUED
taskRefs: []
---

# Implementation Prompt

## FIRST ACTION — synchronize before all other work

Before reading implementation sources or changing files, safely synchronize
the local repository with `origin/main` while preserving all owner work.

Do not use destructive Git operations. Inspect and preserve local owner
changes before integrating remote changes.

Do not create or update Desktop phase logs or any other local handoff log.
All durable evidence must be written only to the matching GitHub
`CLAUDE_LOG_VNN.md`.


Claude must safely sync origin/main, read the relevant governance, canonical
root tasks.md, active audit criteria, prior ChatGPT audits and audit learnings,
then implement/test/log only.

All mandatory validation steps must be recorded individually in the cycle's
single CLAUDE_LOG_VNN.md.

Claude must not create an audit/self-audit file or assign audit verdicts.
When implementation evidence is ready, update canonical task truth, the
relevant sidecar SESSION_INDEX and root H!veAI dashboard, push safely, set
AWAITING_AUDIT, and stop.


## Coordination v4 prompt requirement

Every new prompt must declare the exact expected Claude evidence filename:

`expectedClaudeLog: CLAUDE_LOG_VNN.md`

where VNN matches the prompt version. Claude must not use
CLAUDE_LOG_VNN.md for new work.
