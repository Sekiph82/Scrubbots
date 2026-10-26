# ScrubBots Agent Instructions

## NEWEST OWNER DECISION 2026-10-22
`CLAUDE.md` §0D overrides this file: factory peer review closes tasks (no ChatGPT audit required), Actions freeze lifted, worktrees allowed with mandatory cleanup.

## Local Godot
`$GODOT` = `C:\Users\sekip\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe` (local Godot 4.7.2 console executable, installed with winget; `--version` = `4.7.2.stable.official.ed1daf0bf`; the WinGet link `%LOCALAPPDATA%\Microsoft\WinGet\Links\godot_console.exe` points to it). Run suites as `"$GODOT" --headless --path <checkout> -s res://tests/<suite>.gd`; the full suite list is in `.github/workflows/android-family-first10.yml`.
One command for those suites with the CI PASS/FAIL rule: `python tools/run_suites.py [suite ...]` (`--list`, `--selftest`); conventions in `docs/TESTING_CONVENTIONS.md`.

## Feature unlock gate (SB-M44-031)
Owner unlock table (feature id -> campaign level): `data/config/feature_unlocks_v1.json`, read by `scripts/progression/feature_unlocks.gd` (fails open: bad config or unknown id = unlocked). UI asks only `AppState.feature_unlocked(id)` (and `feature_unlock_level(id)` for copy); never put a level number in UI code. Grandfather default: a save that is not a new FTUE profile keeps every feature; a fresh profile unlocks by frontier (`progression.current_level() >= level`). Gated today: Home shortcuts/nav tabs, the booster bar (`"locked"` state) and FTUE coachmarks. Tests: `tests/m44_unlock_gate.gd`.

## Difficulty lane calibration (SB-M36-013)
Lane targets for v2 D come from the anchor corpus, never from shipped levels or owner ratings: `docs/DIFFICULTY_LANE_ANCHOR_CALIBRATION.md` (outcome RESCALE -> `data/config/level_progression_v2.json`; v1 file frozen). Rebuild fixtures `-s res://tools/build_difficulty_anchors.gd`; measure `-s res://tools/measure_difficulty_anchors.gd -- --measure=<id>` per fixture then `-- --merge`; suite `-s res://tests/m36_anchor_calibration.gd`. Opt-in v2 lanes: `DifficultyProgressionV1.V2_CONFIG_PATH`, `difficulty_playtest.gd -- --progression v2` (suite `m36_progression_v2_reader`). Recovery component checks (SB-M36-014): `recovery.componentChecks` in the playtest output, suite `m36_recovery_component_checks`.

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
