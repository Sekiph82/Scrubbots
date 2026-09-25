# M41-C002 V01 — Claude Implementation Log (SB-M41-005 Reduced Effects)

Prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M41-C002/CHATGPT_PROMPT_V01.md
Criteria: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M41-C002/CHATGPT_AUDIT_CRITERIA_V01.md
Read: root `TASKS.md` (read-only), `CLAUDE.md`, `M41-C001/CHATGPT_AUDIT_V01.md`,
`coordination/OWNER_M41_SETTINGS_ACCEPTANCE_V01.md`, `M31-C001/CHATGPT_AUDIT_V01.md`,
`cleaning_effects_controller.gd`, AppState/SaveService graph.
Base: `780491e`. Handoff: `AWAITING_AUDIT / M41-C002 V01 / SB-M41-005`

## 1. SHAs
- Implementation + tests: `380754c` (`M41-C002 V01: SB-M41-005 Reduced Effects on the canonical settings graph`)
- Test-only regression fix: `2851a7e` (M33 music-dir guard, §5)
- Logs: follow-up docs commit.

## 2. Files (380754c)
| File | Change |
|------|--------|
| `scripts/settings/effects_settings_service.gd` (new) | canonical bool, default OFF, `changed` signal, `snapshot`, strict import |
| `scripts/save/save_service.gd` | optional 6th ctor arg (pre-C002 callers get a private OFF service); `settings.effects` collect / strict validate (`effects_malformed`) / apply / exact restore |
| `scripts/app/app_state.gd` | owns `effects`, passes it to SaveService, `set_reduced_effects(on)` (blocked => refused) |
| `scripts/gameplay/runtime/production_gameplay_host.gd` | build-time consume + live `changed` binding to the accepted M31 `set_reduced_effects` |
| `scripts/ui/settings_panel.gd` | one `REDUCED EFFECTS` CheckButton |
| `tests/m41_settings.gd` | 4 new ledger cases + updated assertions (17 cases) |

Not changed: `cleaning_effects_controller.gd` (M31), audio/music, haptics, economy/progression/routing/completion/clearing, M42, `TASKS.md`, ChatGPT/owner artifacts.

## 3. Sensitivity probes (temporary edits, restored; `git diff --stat` identical after)
| Probe | Mutation | m41_settings |
|-------|----------|--------------|
| nolivebind | drop `changed` -> FX connection | exit 1, 6 FAIL |
| nobuildconsume | drop build-time `set_reduced_effects` | exit 1, 2 FAIL |
| lenient | accept any `settings.effects` | exit 1, 3 FAIL |
| noapply | skip applying effects on load | exit 1, 2 FAIL |

## 4. Regression on actual main (`380754c`; m33 rerun at `2851a7e`)
`godot --headless --path . -s res://tests/<name>.gd`; each checked for exit, footer, `FAIL:` lines, `SCRIPT ERROR`.

| Suite | Exit | SCRIPT ERROR | Result |
|-------|------|--------------|--------|
| m41_settings | 0 | 0 | 17/17 PASS |
| m31_cleaning_effects_evidence | 0 | 0 | PASS |
| m31_scale_59_effects | 0 | 0 | PASS |
| m33_audio_runtime (at 2851a7e) | 0 | 0 | 10/10 PASS |
| m34_haptics_production / m34_haptics_runtime | 0 | 0 | PASS |
| m40_save_system / m40_v02_safety / m40_v03_canonical / m40_v04_bootstrap | 0 | 0 | PASS |
| m29_hazard_bot_runtime_smoke (production host) | 0 | 0 | PASS |
| m30_transaction_safe_retry | 0 | 0 | PASS (its 6 `FAIL:` substrings are `ok: REBUILD-FAIL:` labels; 0 non-ok FAIL lines) |
| m38_v02_strict | 0 | 0 | 11/11 PASS |
| m39_v04_integration | 0 | 0 | PASS |
| palette_v3_leveldata_contract | 0 | 0 | 6/6 PASS |
| root run_tests | 0 | 0 | 5322 checks, ALL PASS |

`git diff --check`: clean.

Root count 5322 (was 5336 at `5850043`): owner commit `89eb552` (MAINT-PALETTE-V3-001) rewrote part of
`tests/run_tests.gd`. Baseline at this cycle's parent `780491e` (clean worktree): 5322, ALL PASS, 0 SCRIPT
ERROR — identical after this cycle; this cycle does not touch `run_tests.gd`.

## 5. Findings during the run
- `m33_audio_runtime` first run at `380754c`: 1 FAIL — the M33 V03 "no other music file" guard saw the
  owner's untracked local `assets/audio/music/workshop_loop.ogg` (owner-reserved Workshop track, decision
  V03). Owner file preserved untouched. Test-only fix `2851a7e`: allow exactly that file and assert the
  gameplay MusicController never references it. Rerun 10/10 PASS.
- Godot headless once rewrote `project.godot` dropping the `[audio]` bus-layout section (known M40
  headless strip); restored with `git checkout -- project.godot`, never committed.

## 6. Owner gate
Visual/manual F6 of the new row: main scene -> SETTINGS -> REDUCED EFFECTS (layout; during gameplay the
cleaning cue becomes a single shorter puff). The audit decides whether F6 is required.

Root `TASKS.md` untouched. No audit file/verdict created. M42 not started.
