# ScrubBots Agent Instructions

## NEWEST OWNER DECISION 2026-10-22
`CLAUDE.md` §0D overrides this file: factory peer review closes tasks (no ChatGPT audit required), Actions freeze lifted, worktrees allowed with mandatory cleanup.

## Local Godot
`$GODOT` = `C:\Users\sekip\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe` (local Godot 4.7.2 console executable, installed with winget; `--version` = `4.7.2.stable.official.ed1daf0bf`; the WinGet link `%LOCALAPPDATA%\Microsoft\WinGet\Links\godot_console.exe` points to it). Run suites as `"$GODOT" --headless --path <checkout> -s res://tests/<suite>.gd`; the full suite list is in `.github/workflows/android-family-first10.yml`.
One command for those suites with the CI PASS/FAIL rule: `python tools/run_suites.py [suite ...]` (`--list`, `--selftest`); conventions in `docs/TESTING_CONVENTIONS.md`.

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
