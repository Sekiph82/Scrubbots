# M33-C001 V01 — Audio Runtime Integration Master Prompt

Repository: `Sekiph82/Scrubbots`  
Branch: `main`  
Milestone: `M33 — Audio`  
Implementation actor: Claude  
Tracker authority: root `TASKS.md` is ChatGPT-write-owned. Claude MUST NOT edit it.

## 0. Start / sync

Before editing:

1. Confirm repo `Sekiph82/Scrubbots`, branch `main`.
2. Fetch and fast-forward safely. Never force-push or hard-reset over owner work.
3. Read:
   - `CLAUDE.md`;
   - root `TASKS.md` read-only;
   - `coordination/sessions/M33-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`;
   - `coordination/OWNER_M33_AUDIO_SELECTION_DECISION_V01.md`;
   - `assets/audio/sfx/README.md`;
   - `scripts/gameplay/dispatch/scrubbot_dispatcher.gd`;
   - `scripts/gameplay/dispatch/auto_dispatch_scheduler.gd`;
   - `scripts/gameplay/clearing/complete_clearing_loop.gd`;
   - `scripts/gameplay/completion/completion_controller.gd`;
   - `scripts/gameplay/completion/completion_evaluator.gd`;
   - `scripts/gameplay/runtime/production_gameplay_host.gd`;
   - `scripts/gameplay/runtime/production_runtime_controller.gd`;
   - M29-M32 evidence relevant to 1x/2x, committed clear, terminal latch and Retry.
4. Inspect `git status`; preserve owner files/unrelated work.
5. Run relevant baseline regressions before invasive changes when practical.
6. M32 is CLOSED. Do not redesign Scrubby visuals, M31 FX, M30 Retry, M29 speed or M20 clear authority.
7. Do not start M34 haptics, M39 economy, M41 settings UI or later systems.

## 1. Locked owner audio

Use the existing canonical files exactly:

- `assets/audio/sfx/dispatch.wav`;
- `assets/audio/sfx/cleaning.wav`;
- `assets/audio/sfx/completion.wav`.

Owner decision: **NO robot movement audio in V1**.

Do not generate new audio. Do not replace these WAVs. Do not turn `cleaning.wav` back into a movement loop.

The owner decision records canonical format: WAV / mono / 24 kHz / 16-bit PCM.

## 2. M33 scope

Complete runtime audio infrastructure for:

- `SB-M33-001` audio buses;
- `SB-M33-002` Master volume;
- `SB-M33-003` Music volume;
- `SB-M33-004` SFX volume;
- runtime integration of already-approved Dispatch/Cleaning/Completion SFX;
- `SB-M33-009` concurrency management;
- `SB-M33-010` persisted audio settings.

`SB-M33-005..008` are already owner-approved tracker items. Do not recreate the assets just to “complete” them.

## 3. Bus layout

Create/ensure stable Godot buses:

`Master`
`  ├─ Music`
`  └─ SFX`

`Music` and `SFX` route to `Master`.

There is currently no production music track in `assets/audio/music/`. Implement the Music bus + setting/persistence seam, but do **not** generate, download or invent music in M33.

Prefer project-level bus configuration (`default_bus_layout.tres`) when appropriate so bus existence is deterministic at startup. If current Godot project architecture strongly favors a different stable approach, document it.

## 4. Reusable audio settings service

Implement a narrow reusable service, suggested:

`scripts/audio/audio_settings_service.gd`

Responsibilities:

- read/set Master/Music/SFX normalized volume;
- clamp to `0.0..1.0`;
- map safely to AudioServer bus volume/mute;
- save/load persistent settings;
- expose read-only current values;
- fail safely when config is absent/corrupt.

Recommended production persistence path:

`user://audio_settings.cfg`

or an equivalently clear user-data path.

Tests must be able to inject/use an isolated test path so they never overwrite the owner's real settings.

Default when no settings exist: full neutral volume (`1.0`) for Master/Music/SFX unless an existing canonical setting already defines otherwise.

Do not implement the future M41 Settings screen here. M41 should later consume this service.

## 5. Audio presentation controller

Implement one narrow gameplay-audio presentation component, suggested:

`scripts/audio/gameplay_audio_controller.gd`

It should preload/reference the three canonical streams and own only presentation players/voice pools + diagnostics.

It must not select targets, reserve cells, move agents, clear cells, decide terminal state or alter speed.

## 6. Dispatch SFX event authority

Play/request `dispatch.wav` only when a Scrubbot assignment has **actually committed successfully**.

Current dispatcher has no dedicated successful-dispatch presentation signal.

Preferred safe change:

- add a narrow signal such as `assignment_dispatched(owner_id, target_index, color_id, agent)` to `ScrubbotDispatcher`;
- emit it exactly once only after the assignment is fully attached/validated/registered in `_active` on a successful dispatch path;
- emit on both production `dispatch_preclaimed()` and any legacy successful `dispatch()` path where applicable;
- emit nothing on invalid request, route failure, reset abort, coherence failure or agent assignment failure.

The signal is observation only. Do not make gameplay depend on an audio listener.

If you find a cleaner already-authoritative post-success seam, you may use it instead, but document why it is equivalent.

Do not trigger dispatch sound from:
- player tap;
- slot placement;
- scheduler intent;
- `child_entered_tree` alone;
- route request creation.

## 7. Cleaning SFX event authority

Observe:

`CompleteClearingLoop.authenticated_clear(owner_id, target_index, color_id, agent)`

One committed clear may request one cleaning sound, subject only to presentation-level concurrency suppression.

Rejected, rolled-back, fatal or reset clear paths produce no cleaning SFX request.

Do not change M31 FX timing or M20 clear timing.

## 8. Completion SFX authority

Observe the M30 completion latch:

`CompletionController.terminal_reached(status, detail)`

Play `completion.wav` only when `status == CompletionEvaluator.WON`.

No completion sound for `LOST` or `ERROR`.

At most once per WON attempt. Retry/new attempt must permit a later WON completion sound again.

## 9. Voice concurrency

Do not create a fresh unbounded `AudioStreamPlayer` Node per event.

Use fixed voice pools or another strictly bounded strategy.

At minimum:

- finite dispatch voice count;
- finite cleaning voice count;
- one reliable completion channel or equally bounded completion policy;
- deterministic suppression/drop when a category has no free voice;
- no unbounded backlog.

Cleaning is the main spam hazard because committed clears can arrive rapidly. Dispatch density also rises at 2x.

Choose/tune final caps from headless stress evidence plus F6 listening. Start conservatively rather than making a wall of sound.

Expose diagnostics:

- requests;
- played;
- suppressed;
- active voices;
- peak active voices;
- configured voice cap per category.

These are presentation diagnostics only.

## 10. Speed behavior

Do not use `Engine.time_scale` and do not alter audio pitch for gameplay 2x.

M29 2x increases gameplay event density by halving dispatch cadence and doubling robot travel delta. Audio should therefore encounter events more frequently, but each canonical one-shot should retain normal pitch/speed unless the owner later decides otherwise.

Concurrency management must make 2x listenable.

## 11. Pause / Retry

No new dispatch/clean/completion events should be synthesized while gameplay is paused.

On Retry:

- no stale deferred audio callback may fire from the prior attempt;
- any attempt-scoped completion latch/diagnostic state resets as needed;
- global user volume settings remain unchanged;
- later fresh WON can play completion again.

Do not weaken M30 Retry to accomplish audio cleanup.

## 12. Music volume without music content

`SB-M33-003` means the Music bus/settings seam must exist and persist.

It does **not** authorize generating a music track.

Tests should prove Music volume changes the Music bus and persists/reloads even though no runtime music player is required in M33.

## 13. Persistence details

Persist at minimum:

- Master volume;
- Music volume;
- SFX volume.

Use stable keys/versioning if useful.

Malformed values must clamp/fall back safely. A corrupt settings file must never prevent the game from starting.

Saving/loading audio settings must not modify gameplay save/progression state.

## 14. Tests

Add focused M33 evidence proving at minimum:

### Bus/settings
- Master/Music/SFX buses exist;
- Music/SFX route through Master;
- independent volume set/get;
- 0.0 silence behavior;
- out-of-range clamp;
- persistence round-trip;
- missing/corrupt settings safe defaults.

### Dispatch authority
- one successful committed assignment -> one dispatch-audio request;
- failed/rejected/reset-aborted dispatch -> zero dispatch-audio request;
- adding the observer seam changes no DispatchResult/gameplay truth.

### Cleaning authority
- committed authenticated clear -> cleaning-audio request;
- rollback/rejected/reset clear -> no request;
- audio suppression never changes board clear count.

### Completion authority
- WON -> one completion request;
- repeated terminal evaluation -> no duplicate;
- LOST/ERROR -> no completion sound;
- Retry/fresh attempt -> a later WON can request completion again.

### No movement audio
- no movement stream/player/loop is created by the production controller.

### Concurrency
- burst well above each configured voice cap;
- allocated/player node count stays fixed;
- active voice count never exceeds cap;
- overflow increments suppression rather than queueing;
- no gameplay mutation.

### 1x/2x
- production-stack or equivalent event-density evidence at both actual speed modes;
- canonical audio pitch remains unmodified.

## 15. High-density stress

Use an event burst substantially beyond voice caps and, where practical, a real production auto-solve/clear flow.

Record voice caps, request counts, played counts, suppressed counts and peak active voices.

Do not invent physical-device audio latency/FPS measurements.

## 16. Dedicated owner F6 audio scene

Create:

`res://scenes/debug/m33_audio_playtest.tscn`

on the real production gameplay stack.

Useful debug-only controls:

- AUTO-SOLVE;
- SPEED 1x/2x;
- RETRY;
- isolated TEST DISPATCH;
- isolated TEST CLEANING;
- isolated TEST COMPLETION;
- CLEANING STRESS/BURST;
- Master volume slider/value;
- SFX volume slider/value;
- Music volume slider/value;
- SAVE / RELOAD settings if useful;
- voice diagnostics.

Direct isolated test buttons may call presentation test seams, but real AUTO-SOLVE must also prove the authoritative production event wiring.

Owner F6 listening checklist:

1. dispatch.wav sounds once per real successful dispatch and is appropriate;
2. cleaning.wav sounds on committed cleaning and does not become intolerable under density;
3. completion.wav plays once on WON;
4. no robot movement loop exists;
5. actual 1x and 2x remain listenable;
6. cleaning/dispatch overlap does not clip into an uncontrolled wall;
7. Master slider works;
8. SFX slider works;
9. Music slider infrastructure changes/persists its bus value even though no music track exists;
10. settings survive save/reload/restart check;
11. Retry allows a clean next attempt.

Claude cannot self-close M33. Final handoff remains owner F6 required.

## 17. Regression floor

Run at least:

- new M33 focused tests;
- root `tests/run_tests.gd`;
- M32 visual/runtime evidence;
- M31 cleaning FX evidence;
- M30 completion + Retry evidence;
- M29 speed/runtime evidence;
- M20 lifecycle;
- M19 dispatcher lifecycle;
- `git diff --check`.

Any audio-caused gameplay regression is blocking.

## 18. Commit/log discipline

Do not edit root `TASKS.md`.

Commit implementation/tests first.

Then create in a separate documentation commit:

`coordination/sessions/M33-C001/CLAUDE_LOG_V01.md`

Record:

- implementation SHA;
- exact bus architecture;
- exact canonical files used;
- event authority for dispatch/clean/completion;
- voice caps and suppression policy;
- persistence path/keys/defaults;
- stress diagnostics/results;
- regressions;
- F6 scene path;
- explicit no-movement-audio statement;
- explicit no-new-audio-generation statement;
- known limitations;
- handoff status.

Expected final handoff:

`AWAITING_AUDIT / M33-C001 V01 / OWNER_F6_REQUIRED`