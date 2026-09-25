# M33-C001 V02 — Claude Implementation Log (Audio Clutter / Cleaning Tail / Music)

Milestone: M33 — Audio
Implementation actor: Claude
Batch: `coordination/sessions/M33-M41-BATCH/CHATGPT_MASTER_PROMPT_V01.md` (M33 V02 -> M41 V01)
Handoff: `AWAITING_AUDIT / M33-C001 V02 / OWNER_F6_AND_MUSIC_SELECTION_REQUIRED`

## 1. Inputs read

- Prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M33-C001/CHATGPT_PROMPT_V02.md
- Criteria: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M33-C001/CHATGPT_AUDIT_CRITERIA_V02.md
- Owner decision: `coordination/OWNER_M33_AUDIO_SELECTION_DECISION_V02.md`
- Prior audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M33-C001/CHATGPT_AUDIT_V01.md (notes A/B/C used as test-planning input)
- `coordination/AUDIT_INDEX.md`, `coordination/AUDIT_POLICY.md`, root `TASKS.md` (read only)

Audit learnings applied: AL-067 (production-stack signal tests, not direct handler calls),
AL-080/AL-090 (canonical AppState graph, not opt-in test wiring), AL-083 (strict settings
validation — M41), AL-091 (expected/completed case ledger + SCRIPT ERROR rejection),
AL-036 (headless voice diagnostics are bound/authority evidence, not listening evidence).

## 2. SHAs

- Implementation + tests: `e4ccd7f` (`M33-C001 V02: remove dispatch SFX, bounded dispatch.wav cleaning, Music-bus loop controller`)
- This log + `task_logs_v02/`: follow-up docs commit on `main`.
- Base: `d6bb8df` (owner palette v3 commit that landed during this batch; the implementation
  was first committed on `c203f97` as `5700ff9`, then rebased without conflict).

M33 V02 prompt item 10 (M41 settings integration) lands in the M41-C001 V01 commit; see
`coordination/sessions/M41-C001/CLAUDE_LOG_V01.md`.

## 3. Changes (e4ccd7f)

| File | Change |
|------|--------|
| `scripts/audio/gameplay_audio_controller.gd` | DISPATCH category/pool/observer/seam removed. Cleaning uses `dispatch.wav`, cap 3, `CLEANING_MAX_SEC 0.24` hard stop with `CLEANING_FADE_SEC 0.06` linear fade, `CLEANING_VOLUME_DB -3`. `advance_voices(delta)` (from `_process`) ages voices; non-finite/negative delta ignored. `reset_for_new_attempt()` stops cleaning AND completion voices. New diagnostics: `cut`, `get_max_voice_age`, `get_voice_max_sec`, `get_category_stream_path`. |
| `scripts/audio/music_controller.gd` (new) | One looping AudioStreamPlayer on `Music`; idempotent `start()`, explicit `stop()`, stops on `_exit_tree`; loop set on a duplicate (shared import untouched); `APPROVED_TRACK_PATH` absent -> `OWNER_MUSIC_SELECTION_REQUIRED`. |
| `scripts/gameplay/runtime/production_gameplay_host.gd` | No audio connection on `assignment_dispatched`; MusicController child created at build; `get_music_controller()`. |
| `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` | Signal doc only. |
| `tests/m33_audio_runtime.gd` | Rewritten for V02 with 9-case ledger. |
| `scripts/debug/m33_audio_playtest.gd` | F6 scene: AppState on isolated `user://debug_m33_m41_playtest_save.dat`, no TEST DISPATCH, music status, DEBUG-ONLY generated sine test tone (not a music asset). M41 commit adds the SETTINGS button. |

No asset added/removed/modified. `cleaning.wav` and `dispatch.wav` preserved.

## 4. Criteria mapping

| # | Criterion | Evidence |
|---|-----------|----------|
| 1 | no production dispatch sound | `controller_unit`, `real_stack_1x/2x` (no audio callable on `assignment_dispatched`; SFX requests == clears + 1); probe `dispatchsfx` |
| 2 | dispatch.wav is cleaning source | `controller_unit` (live player stream path); probe `oldcleaningwav` |
| 3 | short-bounded, no tail after pixel disappears | `cleaning_tail_bound` (0.24 s <= echo 0.28 / FX 0.30, fade, stop, release); real-stack max age 0.233 s; probe `tailbound` |
| 4 | no movement loop | `controller_unit` |
| 5 | completion WON-only once | `controller_unit`, `real_stack_1x` |
| 6 | lower concurrency | cap 3 (< 8), 4 SFX nodes; real-stack max active 3 at 1x/2x |
| 7 | Retry no stale tail | `retry_cleanup_unit`, `real_stack_1x`; probe `retrytail` |
| 8 | real production-stack tests | `real_stack_1x/2x` drive ProductionGameplayHost to WON |
| 9 | looping Music-bus track supported | `music_controller_unit`, `real_stack_*` start count 1 across drain + Retry, scene exit stops; probe `musicrestart` |
| 10 | music asset not approved | `OWNER_MUSIC_SELECTION_REQUIRED` (asserted) |
| 11 | M41 settings slice | M41-C001 V01 log |
| 12 | owner F6 re-listening | OWNER gate, below |

## 5. Tests run

Command form: `godot --headless --path . -s res://tests/<name>.gd`. Every run checked for
exit code, footer, `^  FAIL:` lines and `SCRIPT ERROR` count (AL-091). "Resources still
in use / ObjectDB leaked" exit noise is pre-existing (identical class in the `c203f97`
baseline run).

### 5a. At implementation SHA (clean detached worktree)

Run at pre-rebase `5700ff9` (all four below) and re-run at rebased `e4ccd7f` (m33 + root; see 5a-2).

| Test | Exit | SCRIPT ERROR | Result |
|------|------|--------------|--------|
| m33_audio_runtime | 0 | 0 | 9/9 cases, PASS |
| m34_haptics_production | 0 | 0 | PASS |
| m40_v04_bootstrap | 0 | 0 | PASS |
| run_tests (root) | 0 | 0 | 5336 checks, ALL PASS |

### 5a-2. Re-run at rebased e4ccd7f — UPSTREAM BLOCKER (not caused by this batch)

| Test | Exit | SCRIPT ERROR | Result |
|------|------|--------------|--------|
| m33_audio_runtime | 1 | 0 | 7/9 cases; `real_stack_1x/2x`: `production host built (level load failed)` |
| run_tests (root) | 1 | 16 | 5126 checks, FAIL (M21 production-art bridge/reachability sub-tests: `Nil` level) |

Cause: owner commit `d6bb8df` ("palette: adopt Alpix-aligned canonical v3 runtime data")
changed `data/levels/m21_level_001_hazard_bot.json` to `"version": 2`, but
`LevelLoader` still accepts only version 1:
`Level m21_level_001_hazard_bot: unsupported version 2.0 (expected 1)`.
Proven independent of M33/M41: `d6bb8df` alone (clean worktree, no batch commits) fails
`m29_hazard_bot_runtime_smoke` with the same `level load failed`. Every test that builds the
real Hazard Bot host is blocked at current `origin/main` until the owner/ChatGPT palette-v3
migration updates the loader/validators. Not fixed here (outside batch scope; would invent
a level/palette contract change). All non-level cases (7/9) pass at `e4ccd7f`.

### 5b. Baseline at c203f97 (clean worktree, before changes)

root 5336 ALL PASS; m33 (V01) PASS; m34_haptics_production PASS; m40_v04_bootstrap PASS;
m38_v02_strict PASS — all exit 0, 0 SCRIPT ERROR.

### 5c. Full batch regression on the final M33+M41 tree

Recorded in `coordination/sessions/M41-C001/CLAUDE_LOG_V01.md` §6 (M30/M31/M32/M33/M34/M38/M39/M40/M41 + root).

### 5d. Sensitivity probes (temporary production edits, restored byte-exact; `git diff` unchanged after)

| Probe | Mutation | Result |
|-------|----------|--------|
| tailbound | `CLEANING_MAX_SEC 5.0` | exit 1, 4 FAIL (bound vs echo/FX, source longer than bound, ...) |
| dispatchsfx | host connects `assignment_dispatched` -> cleaning request | exit 1, 4 FAIL (requests != clears at 1x/2x, total != clears+1) |
| retrytail | Retry releases completion only | exit 1, 3 FAIL |
| musicrestart | host stop()+start() music on Retry | exit 1, 2 FAIL |
| oldcleaningwav | cleaning stream -> cleaning.wav | exit 1, 4 FAIL |

## 6. Real-stack diagnostics (headless; not listening evidence)

1x: cleaning requests 400, played 33, suppressed 367, cut 30, peak 3, max age 0.233 s.
2x: requests 400, played 24, suppressed 376, cut 21, peak 3, max age 0.233 s.
The drain ticks gameplay at DT 1.0 per step while presentation ages 1/60 s per step, so
event density is far above realtime; suppression numbers are a bound proof, not the
realtime mix. Owner F6 judges the audible mix.

## 7. False-positive risks noted

- Headless `playing` is observable only in-tree (probe confirmed); tail test asserts it.
- Tail bound uses controller-counted time, not the audio driver's playback position; on a
  real device a frame hitch can extend a voice by at most one frame beyond 0.24 s.
- The source asset's audible energy is mostly in 0–0.25 s (measured envelope), so the cut
  removes only the low-level decay; owner listening confirms.

## 8. Owner gates (unchanged by code)

- `OWNER_MUSIC_SELECTION_REQUIRED`: approve a background loop and export it to
  `res://assets/audio/music/background_loop.ogg` (or direct a different path).
- Owner F6 re-listening: `res://scenes/debug/m33_audio_playtest.tscn` — no dispatch sound;
  cleaning = dispatch.wav, short, no tail after the pixel is gone; completion once on WON;
  no movement loop; 1x/2x auto-solve listenable; MUSIC TEST TONE + Settings Music/SFX/Master
  behave; Retry leaves no stale tail.

Root `TASKS.md` untouched. No audit file/verdict created.

Handoff: `AWAITING_AUDIT / M33-C001 V02 / OWNER_F6_AND_MUSIC_SELECTION_REQUIRED`
