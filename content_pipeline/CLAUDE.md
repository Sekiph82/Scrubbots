# SCRUBBOTS Content Pipeline — CLAUDE Governance

This file applies when an implementation prompt targets \`content_pipeline/\`.

## Canonical truth

- Root tasks: \`tasks.md\` (\`SB-CPxx-xxx\`)
- Root governance: \`CLAUDE.md\`
- Pipeline docs: this directory
- H!veAI-facing status: root \`.hiveai/PROJECT_DASHBOARD.md\`

## Security rules

- Remote content is declarative data only.
- Never store real publishing secrets/tokens in Git.
- Never put publisher credentials into the mobile app.
- Never make a dry-run mutate staging/production.
- Never activate an unverified pack/manifest.
- Never rewrite production history silently.
- Current store policies must be re-verified before release.

## GitHub coordination

Use \`content_pipeline/coordination/sessions/CPxx-Cyyy/\`:
ChatGPT writes prompt/criteria/audit; Claude implements/tests and appends to
one \`CLAUDE_IMPLEMENTATION_LOG.md\`; ChatGPT independently audits.

Claude never creates audit/self-audit files and never assigns audit verdicts.


## Coordination v4 owner override — version-matched Claude logs [LOCKED]

This section supersedes older references in this file to a single
`CLAUDE_IMPLEMENTATION_LOG.md` per cycle.

For every material ChatGPT prompt version:

```text
CHATGPT_PROMPT_VNN.md
CHATGPT_AUDIT_CRITERIA_VNN.md
CLAUDE_LOG_VNN.md
CHATGPT_AUDIT_VNN.md
```

The prompt version and Claude log version must match exactly. Work performed
under VNN is recorded in `CLAUDE_LOG_VNN.md` in the same cycle directory.
If V02 and V03 are intentionally delivered/executed together, Claude still
creates both logs and identifies shared commits/tests explicitly.

Historical `CLAUDE_IMPLEMENTATION_LOG.md` files are legacy evidence only.
Do not delete them, but do not use that naming pattern for new prompt work.

Before ending a material session, update these derived H!veAI sources:

- `.hiveai/ACTIVE_CYCLES.md`
- `.hiveai/ARTIFACT_MAP.md`
- `.hiveai/PROGRESS_SNAPSHOT.md`

Then materialize the latest state into
`.hiveai/PROJECT_DASHBOARD.md`. H!veAI actively watches only the dashboard.
`tasks.md` remains the only canonical task ledger.

Canonical policy:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/VERSIONED_LOG_POLICY.md
