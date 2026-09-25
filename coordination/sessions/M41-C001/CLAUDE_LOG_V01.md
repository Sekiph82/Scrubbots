# M41-C001 V01 — Claude Implementation Log (Early Audio/Haptics Settings Slice)

Milestone: M41 — Settings (owner-authorized early slice)
Implementation actor: Claude
Batch: `coordination/sessions/M33-M41-BATCH/CHATGPT_MASTER_PROMPT_V01.md`
Handoff: `AWAITING_AUDIT / M41-C001 V01 / SETTINGS_OWNER_F6_REQUIRED`

## 1. Inputs read

- Prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M41-C001/CHATGPT_PROMPT_V01.md
- Criteria: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M41-C001/CHATGPT_AUDIT_CRITERIA_V01.md
- Owner decision: `coordination/OWNER_M33_AUDIO_SELECTION_DECISION_V02.md` §6
- M40 audits V02–V04 findings consumed via current AppState/SaveService code; `AUDIT_INDEX.md`
- `docs/MASTER_UI_SYSTEM.md` (touch 88, body 30 / button 34 / title 48, no Settings button on gameplay)

Audit learnings applied: AL-080/AL-090 (actual app root owns the graph; UI bound to it),
AL-083 (strict toggle validation, no silent normalization), AL-082/AL-088 (settings saved
at commit/lifecycle boundaries, not by convention), AL-067 (real host tests), AL-091
(case ledger + SCRIPT ERROR rejection), AL-092 (typed doubles — the haptics bad-settings
double is duck-typed on purpose because `bind_settings` accepts any object with
`is_enabled()`; the production field is untyped).

## 2. Scope

Implemented: SB-M41-001 Master, -002 Music, -003 SFX, -004 Haptics, -006 Persistence,
-007 Settings UI, -008 Relaunch tests.
**SB-M41-005 Reduced Effects: NOT implemented, no control, no code path touched**
(`settings_ui_controls` asserts no "reduced" UI node exists).
No other M41+ scope started. Root `TASKS.md` untouched. No audit file created.

## 3. SHAs

- Implementation + tests: `8a423d3` (`M41-C001 V01: early audio/haptics Settings slice on canonical AppState`), parent `997e8f0` (M33 V02 log) -> `e4ccd7f` (M33 V02 impl) -> `d6bb8df`.
- This log + `task_logs/`: follow-up docs commit on `main`.

## 4. Changes (8a423d3)

| File | Change |
|------|--------|
| `scripts/audio/audio_settings_service.gd` | `master_on/music_on/sfx_on` toggles (OFF mutes, keeps level), `set_*_enabled`, `is_*_enabled`, `snapshot()`; setters/apply_all honor toggles. Legacy cfg path documented as read-only migration. |
| `scripts/save/save_service.gd` | `collect()` uses `audio.snapshot()`; validate: toggles optional, non-bool => `audio_<k>_type` reject; `_apply` + exact-restore apply toggles. VERSION unchanged (additive optional keys). |
| `scripts/app/app_state.gd` | `set_audio_volume(bus, v, persist=true)`, `set_audio_enabled(bus, on)`, `flush_if_dirty()`; unknown bus rejected w/o mutation; refused while blocked. |
| `scripts/haptics/haptics_controller.gd` | `bind_settings(svc)`; `is_enabled()` = local seam AND live canonical setting; malformed answer => OFF. |
| `scripts/gameplay/runtime/production_gameplay_host.gd` | `_haptics.bind_settings(_haptics_settings)` instead of a build-time copy. |
| `scripts/ui/settings_panel.gd`, `scenes/ui/settings_panel.tscn` (new) | Native Settings panel (see SB-M41-007). |
| `scripts/app/main.gd` | SETTINGS button + panel on the real app root, bound to its AppState. |
| `scripts/debug/m33_audio_playtest.gd` | SETTINGS button on the F6 scene (isolated debug save). |
| `tests/m41_settings.gd` (new) | 13-case ledger. |

Competing authorities: none revived. Settings never call `AudioSettingsService.save()` /
`HapticsSettingsService.save()`; legacy files' existence/mtime/size asserted unchanged.

## 5. Criteria mapping

| Criterion | Evidence (`tests/m41_settings.gd`) |
|-----------|-------------------------------------|
| Master, Music, SFX controls | `settings_ui_controls`, `main_root_settings` |
| Haptics on/off control | `settings_ui_controls` (VIBRATION), `haptics_live_no_gameplay_mutation` |
| each value applies live | `live_apply_actions`, `settings_ui_controls` (bus dB/mute after control signal), haptics toggled after build |
| each value persists | `exact_relaunch`, `settings_ui_controls` (toggle immediate, drag-end, Close) |
| relaunch restores exact values | `exact_relaunch` (snapshot dict equality), `main_root_settings` (real root) |
| 0 Music -> only music | `bus_isolation_via_appstate`, `real_host_bus_routing` |
| 0 SFX -> SFX not music | `bus_isolation_via_appstate` |
| Master 0 -> all audio | `bus_isolation_via_appstate` (Master muted; Music+SFX send to Master) |
| Haptics OFF suppresses vibration, no gameplay mutation | `haptics_live_no_gameplay_mutation` (ON 141 calls / OFF 0; both WON, 400 clears) |
| canonical services, no duplicate authority | `real_host_bus_routing` (host audio == app.audio), `main_root_settings`, `no_legacy_side_files` |
| mobile-readable, no gameplay mutation | `settings_ui_layout` (4 viewports), panel calls only AppState actions |

Sensitivity probes (temporary production edits, restored; `git diff` unchanged after):
`hapticlive` (build-time copy) -> 2 FAIL; `togglestrict` (accept any type) -> 2 FAIL;
`togglepersist` (skip applying toggles on load) -> 3 FAIL.

## 6. Batch regression (final tree `8a423d3`)

Command form `godot --headless --path . -s res://tests/<name>.gd`; each run checked for
exit code, footer, `^  FAIL:` lines and `SCRIPT ERROR` count. Exit-time "resources still
in use / ObjectDB leaked" lines are pre-existing (present in the `c203f97` baseline).

### 6a. UPSTREAM BLOCKER at current origin/main

Owner commit `d6bb8df` ("palette: adopt Alpix-aligned canonical v3 runtime data", landed
during this batch) set `data/levels/m21_level_001_hazard_bot.json` `"version": 2`;
`LevelLoader` accepts only version 1 (`unsupported version 2.0 (expected 1)`), so the
catalog is invalid and every real Hazard Bot host build fails. `d6bb8df` ALONE (no batch
commits) fails `m29_hazard_bot_runtime_smoke` identically. Not fixed here: it needs the
owner/ChatGPT palette-v3 level/loader migration (would otherwise invent a contract).

### 6b. Run A — `8a423d3` with `d6bb8df` reverted in a throwaway worktree (not committed)

Isolates batch code from the upstream break.

| Suite | Exit | SCRIPT ERROR | Result |
|-------|------|--------------|--------|
| root `run_tests` | 0 | 0 | 5336 checks, ALL PASS |
| m33_audio_runtime | 0 | 0 | 9/9, PASS |
| m41_settings | 0 | 0 | 13/13, PASS |
| m30_completion_authority / m30_manual_playtest_smoke / m30_transaction_safe_retry | 0 | 0 | PASS |
| m31_cleaning_effects_evidence / m31_scale_59_effects | 0 | 0 | PASS |
| m32_scrubbot_visual_evidence | 0 | 0 | PASS |
| m34_haptics_production / m34_haptics_runtime | 0 | 0 | PASS |
| m40_save_system / m40_v02_safety / m40_v03_canonical / m40_v04_bootstrap | 0 | 0 | PASS |
| m38_v02_strict (repaired strict regression) | 0 | 0 | 11/11, PASS |
| m38_win_streak | 0 | 0 | PASS |
| m29_hazard_bot_runtime_smoke / m29_speed_authority_evidence | 0 | 0 | PASS |
| m39_v04_integration | 0 | 0 | PASS |

The same set also passed (all exit 0, 0 SCRIPT ERROR, root 5336) on the pre-rebase local
tree based on `c203f97`.

### 6c. Run B — real `8a423d3` (includes `d6bb8df`)

| Suite | Exit | SCRIPT ERROR | Note |
|-------|------|--------------|------|
| root `run_tests` | 1 | 16 | 5126 checks; M21 art bridge/reachability `Nil` level |
| m33_audio_runtime | 1 | 0 | 7/9; real_stack_* `level load failed` |
| m41_settings | 1 | 0 | 11/13; host-building cases `CATALOG_INVALID` |
| m40_v04_bootstrap | 1 | 4 | `CATALOG_INVALID` then Nil host |
| m29 x2, m30 manual/retry, m31 effects, m32, m34 production, m40_v02, m39_v04 | 1 | 0 | host build / level load failed |
| m30_completion_authority, m31_scale_59, m34_runtime, m40_save_system, m40_v03, m38 x2 | 0 | 0 | PASS |

Every FAIL line in run B was inspected: all are `level load failed`, `CATALOG_INVALID`,
`CONTENT_MISSING`/catalog-entry consequences or the resulting `did not complete` ledger
entries — none is an audio/settings assertion. These are NOT ignored; they are the
upstream blocker above.

`git diff --check`: clean.

## 7. False-positive risks

- Layout test measures Control rects in a SubViewport headless; it proves bounds/touch
  sizes, not visual quality (owner F6).
- Slider drag-end persistence is exercised by emitting `drag_ended(true)`; real touch
  release is covered by owner F6 plus the Close/lifecycle flush fallbacks.
- Haptics platform calls are counted through the test sink; real vibration feel is the
  separate M34 device gate.

## 8. Owner / device gates

- M41 Settings owner visual/manual F6: run the project (main scene) -> SETTINGS, and the
  F6 scene `scenes/debug/m33_audio_playtest.tscn` -> SETTINGS during auto-solve with MUSIC
  TEST TONE: Master 0 silences all; Music 0/OFF only the tone; SFX 0/OFF only cleaning/
  completion; Vibration OFF; values survive relaunch; readability on phone.
- M33 final background music asset selection (`OWNER_MUSIC_SELECTION_REQUIRED`) and M33
  owner F6 re-listening.
- M34 SB-M34-006 real-device haptics; M36 human difficulty playtest; M39 SB-M39-033
  sixth-slot device evidence — unchanged, separate.
- Upstream: palette-v3 level `version: 2` vs `LevelLoader` (6a) must be resolved before any
  real-host test can pass on `main`.

Root `TASKS.md` untouched. SB-M41-005 untouched. No audit file/verdict created.

Handoff: `AWAITING_AUDIT / M41-C001 V01 / SETTINGS_OWNER_F6_REQUIRED`
