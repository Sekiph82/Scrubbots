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


## Coordination v4 — version-matched artifact bundles [LOCKED]

This section supersedes the earlier one-log-per-cycle model.

Each implementation version is a matched bundle:

```text
CHATGPT_PROMPT_VNN.md
CHATGPT_AUDIT_CRITERIA_VNN.md
CLAUDE_LOG_VNN.md
CHATGPT_AUDIT_VNN.md
```

Claude owns only `CLAUDE_LOG_VNN.md`. ChatGPT owns the CHATGPT_* artifacts.
The version number must match. Multiple local Claude sessions under one prompt
append to that prompt's one versioned log. Historical
`CLAUDE_IMPLEMENTATION_LOG.md` files remain preserved legacy evidence.

ChatGPT must not audit a prompt version until the expected matching Claude log
is visible on GitHub.

### Owner-facing progress reporting

Every ChatGPT audit/new-prompt handoff to the owner must recalculate from
canonical `tasks.md` and report total, completed, remaining, overall
percentage, main-game percentage, Level Factory percentage, and Content
Pipeline percentage.

### H!veAI derived tracking

Maintain:

- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/ACTIVE_CYCLES.md
- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/ARTIFACT_MAP.md
- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROGRESS_SNAPSHOT.md

H!veAI still actively watches only:
https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
