# Level Factory Coordination

GitHub is the communication bus between ChatGPT and Claude for Factory work.

## Cycle layout

\`\`\`text
level_factory/coordination/sessions/LFxx-Cyyy/
├── CHATGPT_PROMPT_V01.md
├── CHATGPT_AUDIT_CRITERIA_V01.md
├── CLAUDE_IMPLEMENTATION_LOG.md
├── CHATGPT_AUDIT_V01.md
├── CHATGPT_PROMPT_V02.md            # only if correction is required
└── CHATGPT_AUDIT_CRITERIA_V02.md
\`\`\`

Historical prompt/audit versions are immutable evidence.

## Actor contract

- ChatGPT: prompt, criteria, independent audit, correction prompt.
- Claude: implementation, tests, append-only implementation log, task/session/
  dashboard synchronization, safe commit/push.
- Only ChatGPT assigns \`AUDITED_PASS\`/\`AUDITED_FAIL\`.
- Root \`tasks.md\` is the only canonical task ledger.
- Root \`.hiveai/PROJECT_DASHBOARD.md\` is the H!veAI-facing materialized
  status surface.
