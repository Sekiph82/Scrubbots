# ScrubBots Agent Instructions

## H!veAI GitHub tracking [OWNER-LOCKED — 2026-09-10]

- GitHub `origin/main` is repository/project-state authority.
- Repository-root `TASKS.md` is the **only live project-status tracker** consumed by H!veAI.
- Read root `TASKS.md` before project work and obey its top `Project Status` block.
- When an active ChatGPT prompt authorizes a lifecycle transition, update root `TASKS.md` and push it in the evidence chain that describes that state.
- Former `.hiveai/PROJECT.json`, `.hiveai/RULES.md`, `.hiveai/TASKS.md`, `.hiveai/EVENTS.jsonl`, dashboards, cycle maps and snapshots are retired as live control-plane state. Archived copies under `docs/migration/legacy-task-trackers/` are historical evidence only.
- Do **not** create, revive, synchronize, or maintain any competing `.hiveai` tracker.
- Coordination prompts/logs/audits are evidence artifacts, not competing current-state trackers.
- Independent audit separation remains locked: Claude implements/tests and may hand off `AWAITING_AUDIT`; only ChatGPT audit may assign `AUDITED_*` and close audit-owned task truth.
- Provider-specific behavior must not change these tracking semantics.
