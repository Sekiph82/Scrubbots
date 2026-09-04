# Content Pipeline Coordination

GitHub is the communication bus between ChatGPT and Claude.

## Cycle layout

\`\`\`text
content_pipeline/coordination/sessions/CPxx-Cyyy/
├── CHATGPT_PROMPT_V01.md
├── CHATGPT_AUDIT_CRITERIA_V01.md
├── CLAUDE_IMPLEMENTATION_LOG.md
└── CHATGPT_AUDIT_V01.md
\`\`\`

Correction work stays in the same cycle with V02/V03 prompt/criteria/audit
versions. Root \`tasks.md\` stays the only canonical task ledger. Root
\`.hiveai/PROJECT_DASHBOARD.md\` is the materialized H!veAI status surface.
