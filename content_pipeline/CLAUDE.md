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
