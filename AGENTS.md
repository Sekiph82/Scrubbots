# H!veAI GitHub-first adapter (v3)

- GitHub `origin/main` is the H!veAI project-state authority.
- Read `.hiveai/RULES.md` before project work.
- Read `.hiveai/TASKS.md` for the current project state.
- Do not maintain a competing current-task, next-action, milestone, or
  progress tracker in this file, coordination files, or dashboards.
- If project state changes, update `.hiveai/TASKS.md` and append one
  `hiveai-event/v1` row to `.hiveai/EVENTS.jsonl`, then commit and push to
  `origin/main` before reporting completion. If push fails, report
  `GITHUB_TRACKING_NOT_SYNCED`.

Canonical H!veAI file set: `.hiveai/PROJECT.json`, `.hiveai/TASKS.md`,
`.hiveai/RULES.md`, `.hiveai/EVENTS.jsonl`. Legacy `STATE.json`,
`HANDOFF.md`, and `PROJECT_DASHBOARD.md` are historical evidence only.
Provider-specific behavior must not change H!veAI state semantics.

# Project-specific Codex instructions
