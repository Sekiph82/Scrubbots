# M40-C001 V04 — Claude Actual Bootstrap & Durable Lifecycle Log

V03 audit: `coordination/sessions/M40-C001/CHATGPT_AUDIT_V03.md`
(`CHANGES_REQUIRED / F-M40-V03-001..004`)
V04 prompt: `coordination/sessions/M40-C001/CHATGPT_PROMPT_V04.md`
V04 criteria: `coordination/sessions/M40-C001/CHATGPT_AUDIT_CRITERIA_V04.md`
Post-M39 V04 base: implementation `3a8943d`, log `e7cb549`
(`coordination/sessions/M39-C001/CLAUDE_LOG_V04.md`).

Scope: only F-M40-V03-001..004. Accepted safe-write/schema work untouched. No
M41+ UI. Root `TASKS.md` untouched. No audit verdict created.

## Finding-by-finding closure

| Finding | Status | Fix | Direct test |
|---------|--------|-----|-------------|
| F-M40-V03-001 AppState not the real bootstrap | IMPLEMENTED | `project.godot` still launches `res://scenes/app/main.tscn`; its root script `scripts/app/main.gd` now OWNS exactly one `AppState` (created in `_enter_tree`, canonical `user://scrubbots_save.dat`, loads at startup). Exposes `get_app_state()`, `is_blocked()`; `launch_gameplay()` is the only production gameplay creation path and injects this same AppState into `ProductionGameplayHost` (no second graph). Blocked/future-schema: no gameplay, no flush, no settings write, file never overwritten. Debug labels kept, status label shows frontier/entry or block. Test-only static boot seams (`boot_save_path_override`, `boot_clock_override`, `boot_local_day_override`). | `tests/m40_v04_bootstrap.gd::_check_project_main_scene`, `::_fresh_boot`, `::_future_schema_blocks` |
| F-M40-V03-002 frontier not mapped to content | IMPLEMENTED | New `scripts/app/gameplay_launch_resolver.gd`: frontier -> LevelCatalog entry with `order == current_level()`; `CONTENT_MISSING` / `CATALOG_INVALID` / `APP_BLOCKED` explicit. Host AppState path calls it in `build()` and overrides the exported `level_path`/`progression_level` (records `launch_entry_id`); failure -> `_build_error = CONTENT_MISSING`, no build. The exports remain only for the no-AppState debug/test harness. | `::_frontier_resolves_catalog`, `::_frontier_missing_content` |
| F-M40-V03-003 save boundaries were a caller convention | IMPLEMENTED | Consumes M39 V04 `ProductionActionFacade`: `AppState.actions` (economy-only, menus) bound to `AppState.request_save`; host facade saves via `host.request_save()`, now routed to `AppState.request_save` when injected (blocked-safe, clears dirty). Only committed actions save + emit `action_committed`. Settings go through `AppState.set_haptics_enabled` / `set_volumes`. Terminal and post-action Retry Heart consume also save. Root lifecycle: `_notification` flushes on `NOTIFICATION_APPLICATION_PAUSED`, `NOTIFICATION_APPLICATION_FOCUS_OUT`, `NOTIFICATION_WM_CLOSE_REQUEST` via `flush_lifecycle()` -> `AppState.flush()`; `mark_dirty()/is_dirty()`. No per-frame writes. | `::_durable_action_relaunch`, `::_failed_action_no_save`, `::_settings_relaunch`, `::_lifecycle_flush_relaunch`, `::_no_per_frame_writes` |
| F-M40-V03-004 Daily needs real local-day wiring | IMPLEMENTED | M39 V04 `LocalCalendar.system_provider()` is injected by AppState in production; the real root is booted end-to-end with deterministic clock/local-day seams for the boundary tests. | `::_daily_local_boundary_relaunch` |

## Integration evidence (actual root, isolated user:// paths)

fresh boot; future schema blocks (gameplay/flush/save/settings refused, bytes
unchanged, close-request flush refused); frontier 1 -> catalog entry
`m21_level_001_hazard_bot`; stale exports overridden; frontier 2 (after
record_win + save + relaunch) -> CONTENT_MISSING from root and direct host
build; Daily login + +1 Slot charge -> relaunch without terminal persists and
same-day regrant refused; failed unlock/unknown 2x -> no signal, save file
byte-identical; settings -> relaunch; pause / focus-out / close-request flush
-> relaunch sees state; Daily: UTC-5 same local day across UTC new year
refused, next local day (year boundary) streak 2, rollback blocked, month
boundary consecutive, production root provider == OS local date; 60 gameplay
frames with no durable action -> save file untouched. 56 checks, PASS.

## Regression

See table appended below (M33/M34 settings/haptics, M35, M37, M38, M39 V03/V04,
M40 V01/V02/V03/V04, M29/M30 host smoke, root suite). `git diff --check` clean.
`project.godot` [audio] headless strip restored before commit.

## Remaining gates

- None code-side for M40. (M39 SB-M39-033 device gate is tracked in M39.)

Handoff: `AWAITING_AUDIT / M40-C001 V04 / ACTUAL_BOOTSTRAP_REAUDIT_REQUIRED`

### Regression table (all exit 0)

| Suite | Result |
|-------|--------|
| m33_audio_runtime, m34_haptics_production, m34_haptics_runtime | PASS |
| m35_level_catalog, m35_v02_hardening | PASS |
| m37_level_progression, m37_v02_strict, m37_v03_forward_only | PASS |
| m38_win_streak, m38_v02_strict | PASS (m38_v02_strict: pre-existing `_FakeReward` typed-arg SCRIPT ERROR in one sub-check, files untouched; noted in M39 V04 log) |
| m39_v03_integration, m39_v04_integration, m39_v04_tornado_inflight | PASS |
| m40_save_system, m40_v02_safety, m40_v03_canonical, m40_v04_bootstrap | PASS |
| m29_hazard_bot_runtime_smoke, m30_transaction_safe_retry | PASS (m30 prints `ok: REBUILD-FAIL/FAIL-CLOSED` labels only) |
| root `tests/run_tests.gd` | 5336 checks, 0 failures |
