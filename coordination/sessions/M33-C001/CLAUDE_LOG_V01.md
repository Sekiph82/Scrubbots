# M33-C001 V01 — Claude Implementation Log

Milestone: M33 — Audio
Implementation actor: Claude
Handoff: `AWAITING_AUDIT / M33-C001 V01 / OWNER_F6_REQUIRED`

## 1. Implementation SHA

Implementation + focused tests commit:
`b7adf873379af4355d6714f67d90d9f69f2dc4d9`

Documentation-only commit (this log): a separate follow-up commit on `main`.

## 2. Files added / modified

Added:
- `default_bus_layout.tres`
- `scripts/audio/audio_settings_service.gd`
- `scripts/audio/gameplay_audio_controller.gd`
- `scripts/debug/m33_audio_playtest.gd`
- `scenes/debug/m33_audio_playtest.tscn`
- `tests/m33_audio_runtime.gd`

Modified:
- `project.godot` — `[audio] buses/default_bus_layout="res://default_bus_layout.tres"`.
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` — added the presentation-only
  `assignment_dispatched(owner_id, target_index, color_id, agent)` signal and its
  post-commit emit on both successful dispatch paths.
- `scripts/gameplay/runtime/production_gameplay_host.gd` — instantiates the
  `AudioSettingsService` + `GameplayAudioController`, connects the three authoritative
  observer seams, and re-arms the completion audio latch on the RetryCoordinator
  post-restore hook.

Owner-approved untracked `.import` files under `assets/art/...` were preserved and are
not part of this commit.

## 3. Bus architecture

`default_bus_layout.tres` and `[audio] buses/default_bus_layout` in `project.godot`
define exactly three deterministic buses:

```
Master
  ├─ Music -> Master
  └─ SFX   -> Master
```

`Music` and `SFX` send to `Master`. Existence is deterministic at engine startup via
the project setting. No music track ships in M33 (the `assets/audio/music/` directory
remains empty); the Music bus + volume seam still exist so a later M41 Settings UI can
consume them.

## 4. Canonical audio assets

Runtime uses exactly the owner-locked canonical files (WAV, mono, 24 kHz, 16-bit PCM):

- `assets/audio/sfx/dispatch.wav`
- `assets/audio/sfx/cleaning.wav`
- `assets/audio/sfx/completion.wav`

No canonical file was replaced, regenerated, normalized destructively, pitch-shifted,
or otherwise mutated.

## 5. Explicit no-movement-audio statement

**No robot movement audio in V1.** The `GameplayAudioController` creates no continuous
movement stream, no looping AudioStreamPlayer, and no movement loop of any kind. The
owner-repurposed former `movement_loop_01` is now `cleaning.wav` and is used only as
the one-shot cleaning SFX driven by `authenticated_clear`.

`tests/m33_audio_runtime.gd` explicitly asserts:
- exactly three canonical stream paths;
- none of them is a movement stream;
- no `AudioStreamPlayer` uses a looping stream.

## 6. Explicit no-new-audio-generation statement

**No new audio was generated, downloaded, replaced, or added.** M33 references the
three existing owner-approved WAVs. No music track was generated. No new SFX file was
created. `assets/audio/music/` remains empty. `SB-M33-005..008` remain owner-approved
content tasks and were not recreated by this implementation.

## 7. Dispatch SFX event authority

Presentation-only signal added to `ScrubbotDispatcher`:

```
signal assignment_dispatched(owner_id: int, target_index: int, color_id: int, agent)
```

Emitted **exactly once** per assignment, only after the agent is fully attached,
validated, and registered in `_active` on a **successful dispatch path**. Both live
dispatch paths emit it:

- legacy `dispatch()` — after the final coherence checks, agent completion signal
  connection, and `_active[owner_id] = { ... }` registration;
- production `dispatch_preclaimed()` — after the same coherence/attach/register
  sequence on the M26 batch-scheduler path.

Never emitted on any failure path:
- `INVALID_REQUEST`, `NO_REACHABLE_TARGET`, `ROUTE_FAILED`, `AGENT_ASSIGN_FAILED`,
  `COHERENCE_FAILED`, `RESETTING`, `REENTRANT`.

The signal is **observation only**. It does not gate reservation truth, dispatch
success/failure semantics, assignment identity, scheduling, or agent lifetime. It is
never emitted by player tap, slot placement, scheduler intent, `child_entered_tree`
alone, or route-request creation.

`GameplayAudioController._on_assignment_dispatched(...)` observes this signal and
requests one dispatch voice per committed dispatch.

## 8. Cleaning SFX event authority

`CompleteClearingLoop.authenticated_clear(owner_id, target_index, color_id, agent)` is
the sole cleaning audio authority. One committed clear -> one cleaning-audio request,
subject only to presentation-level concurrency suppression. Rejected/rolled-back/
fatal/reset paths of the clearing loop never emit `authenticated_clear` and therefore
never request cleaning audio. M20 clear timing and M31 FX timing are unchanged.

## 9. Completion SFX authority

`CompletionController.terminal_reached(status, detail)` is observed. The controller
plays `completion.wav` only when `status == CompletionEvaluator.WON` (mirrored as the
`WON` StringName constant to avoid a runtime dependency on the evaluator script). A
per-attempt latch (`_completion_played_this_attempt`) ensures at most one WON
completion sound per attempt. `LOST` and `ERROR` play nothing.

`reset_for_new_attempt()` re-arms the latch AND frees the single completion voice so a
later fresh WON reliably plays completion again on Retry.

## 10. Voice pool caps, concurrency, suppression policy

Fixed voice pools of `AudioStreamPlayer` children on the `SFX` bus, sized once at
`_ready` and never resized:

| category   | cap |
|-----------:|:---:|
| DISPATCH   | 4   |
| CLEANING   | 8   |
| COMPLETION | 1   |

Total allocated players: **13**. This count never changes at runtime — the pool never
grows. A request either takes a free voice or is deterministically **suppressed** (no
queue, no fresh per-event node allocation). Overflow increments a `suppressed` counter;
active never exceeds cap; `peak_active` records the high-water mark.

Per-category diagnostics (`get_diagnostics(category)`):
`{ requests, played, suppressed, active, peak, cap }`. `get_allocated_voice_count()`
returns the total player count. These are presentation-only.

The `finished` signal on each player releases its voice back to the pool. A test seam
`debug_release_all()` releases voices deterministically in headless test runs where
the dummy audio driver may not emit `finished`.

Caps chosen conservatively from the 20x20 Hazard Bot burst evidence (see §14). Real
peak usage stays at the cap under a full auto-solve at 1x and 2x; both remain
listenable and never allocate additional players.

## 11. Persistence path, keys, defaults

`AudioSettingsService` uses `ConfigFile`:

- Production path: `user://audio_settings.cfg`
- Test-injectable path via `AudioSettingsService.new(path)`
- Section: `audio`
- Keys: `version` (int), `master` (float 0..1), `music` (float 0..1), `sfx` (float 0..1)
- Defaults on missing/corrupt file: `1.0` for each (full-neutral)

Loading tolerates:
- missing file -> full-neutral defaults, `load()` returns `false`, applied to buses;
- corrupt file -> full-neutral defaults, never blocks startup;
- non-numeric / out-of-range stored values -> clamped to `0..1` or fall back to the
  neutral default.

Saving only writes this file. Audio settings are decoupled from gameplay/progression
state.

Bus mapping: `set_bus_volume_db(idx, linear_to_db(value))`; `value <= 0.0` sets
`set_bus_mute(idx, true)`; `>0` unmutes; a missing bus is a safe no-op. `NaN` is
coerced to the neutral default before it can reach the AudioServer.

## 12. 1x / 2x behavior

Audio does not touch `Engine.time_scale` and never sets `pitch_scale`. All voices keep
`pitch_scale = 1.0`. 2x gameplay increases dispatch/clean event density but each
canonical one-shot plays at normal pitch. Concurrency management (§10) is what keeps
2x listenable.

Evidence (`tests/m33_audio_runtime.gd` real-stack pass, drop=0, Hazard Bot 20x20):

- 1x: dispatch req=400 played=4 suppressed=396 peak=4/cap=4;
- 1x: cleaning req=400 played=8 suppressed=392 peak=8/cap=8;
- 1x: completion req=1 played=1;
- 2x: same shape; canonical pitch unchanged (`is_equal_approx(pitch_scale, 1.0)` for
  every player).

## 13. Retry behavior

`ProductionGameplayHost._on_retry_restored()` (called only on the RetryCoordinator
post-success restore seam) invokes `GameplayAudioController.reset_for_new_attempt()`
which:

- clears the per-attempt WON latch so a fresh WON can play completion again;
- frees the single completion voice (stops any playing completion) so the fresh WON
  is not blocked;
- leaves user volume settings unchanged.

User volume state is never mutated by Retry. The M30 Retry gate is not weakened by
audio; audio is a pure observer.

Verified in `tests/m33_audio_runtime.gd`:
- Retry re-arms the latch;
- a subsequent fresh WON plays completion again (`played == 2`).

## 14. Test commands and results

All headless runs on Godot 4.7.2. Exact commands:

```
godot --headless --path . -s res://tests/m33_audio_runtime.gd
godot --headless --path . -s res://tests/run_tests.gd
godot --headless --path . -s res://tests/m30_completion_authority.gd
godot --headless --path . -s res://tests/m30_manual_playtest_smoke.gd
godot --headless --path . -s res://tests/m30_transaction_safe_retry.gd
godot --headless --path . -s res://tests/m31_cleaning_effects_evidence.gd
godot --headless --path . -s res://tests/m32_scrubbot_visual_evidence.gd
godot --headless --path . -s res://tests/m29_hazard_bot_runtime_smoke.gd
godot --headless --path . -s res://tests/m29_speed_authority_evidence.gd
godot --headless --path . -s res://tests/m29_realtime_movement_smoke.gd
git diff --check
```

Results: **ALL PASS**. Selected output summaries:

- `M33 audio runtime evidence: PASS`
- `RESULT: ALL PASS` (root `tests/run_tests.gd`)
- `M30 completion authority: PASS`
- `M30 manual playtest smoke: PASS`
- `M30 transaction-safe retry: PASS`
- `M31 cleaning-effects evidence: PASS`
- `M32 scrubbot-visual evidence: PASS`
- `M29 Hazard Bot runtime smoke: PASS`
- `M29 speed authority evidence: PASS`
- `M29 realtime movement smoke: PASS`
- `git diff --check`: clean

## 15. Stress / concurrency evidence

Isolated controller burst (each burst >= cap + 6):

- cleaning burst 20 -> played 8, suppressed 12, active 8, peak 8, cap 8;
- dispatch burst 10 -> played 4, suppressed 6, active 4, peak 4, cap 4;
- allocated voice nodes unchanged (13) before/after every burst;
- freed voice reused after `debug_release_all()`.

Real production stack (20x20 Hazard Bot, 400 ACTIVE cells, drop=0):

- 1x dispatch: req 400, played 4, suppressed 396, active 4, peak 4, cap 4;
- 1x cleaning: req 400, played 8, suppressed 392, active 8, peak 8, cap 8;
- 1x completion: req 1, played 1, suppressed 0, active 1, peak 1, cap 1;
- 2x identical shape;
- allocated voice node count remains 13 throughout;
- all `pitch_scale == 1.0`;
- board fully clears under Master muted -> audio never blocks gameplay;
- Retry post-restore: fresh WON completion played (`played == 2`);
- failed (unbound) `ScrubbotDispatcher.dispatch()` -> zero dispatch-audio requests.

No physical-device FPS/latency claims are made.

## 16. Dedicated M33 F6 scene

`res://scenes/debug/m33_audio_playtest.tscn`
`res://scripts/debug/m33_audio_playtest.gd`

Hosts the real `ProductionGameplayHost` on the 20x20 Hazard Bot level. Debug-only
overlay controls:

- AUTO-SOLVE (drives the real committed dispatch + clear flow);
- SPEED 1x/2x (real M29 speed authority; canonical audio pitch stays 1.0);
- RETRY (transaction-safe retry; must re-arm completion audio);
- TEST DISPATCH / TEST CLEANING / TEST COMPLETION (isolated presentation seams);
- CLEANING STRESS (48-request burst well beyond cap);
- Master / Music / SFX sliders (0..1);
- SAVE / RELOAD (persisted settings round-trip);
- live per-category voice diagnostics readout.

Owner F6 audio-listening checklist is documented in the scene script header.

## 17. Known limitations

- No music track ships in M33 by design. The Music bus and volume seam exist and
  persist; the Music slider audibly changes the bus but there is no runtime music
  player. A future M-track will add music content.
- The M41 Settings UI is not implemented in M33. `AudioSettingsService` is the seam
  M41 will consume.
- Headless tests use the dummy audio driver. `AudioStreamPlayer.finished` timing is
  not authoritative in headless; the `debug_release_all()` seam is used only in the
  isolated controller-unit burst assertions. All real-stack authority assertions do
  not depend on that seam.
- Voice caps (4/8/1) are conservative defaults chosen from the 20x20 stress evidence
  and the owner-F6 listening plan. They may be tuned during the F6 gate if the owner
  requests it.
- The pre-existing cosmetic header/ordering diff in `project.godot` was preserved and
  committed together with the `[audio]` section.

## 18. Handoff

Code audit target:

`CODE_AUDIT_PASS / M33-C001 V01 / OWNER_F6_REQUIRED`

Final handoff (this log's SHA is the second, documentation-only commit; the
implementation SHA above is authoritative for the audio runtime code and tests):

`AWAITING_AUDIT / M33-C001 V01 / OWNER_F6_REQUIRED`
