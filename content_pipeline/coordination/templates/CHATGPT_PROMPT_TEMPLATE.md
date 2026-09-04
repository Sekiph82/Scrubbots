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

Claude must safely sync origin/main, read the relevant governance, canonical
root tasks.md, active audit criteria, prior ChatGPT audits and audit learnings,
then implement/test/log only.

All mandatory validation steps must be recorded individually in the cycle's
single CLAUDE_IMPLEMENTATION_LOG.md.

Claude must not create an audit/self-audit file or assign audit verdicts.
When implementation evidence is ready, update canonical task truth, the
relevant sidecar SESSION_INDEX and root H!veAI dashboard, push safely, set
AWAITING_AUDIT, and stop.


## Coordination v4 prompt requirement

Every new prompt must declare the exact expected Claude evidence filename:

`expectedClaudeLog: CLAUDE_LOG_VNN.md`

where VNN matches the prompt version. Claude must not use
CLAUDE_IMPLEMENTATION_LOG.md for new work.
