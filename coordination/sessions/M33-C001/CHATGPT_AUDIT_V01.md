# M33-C001 V01 — ChatGPT Code Audit

Date: 2026-09-23  
Repository: `Sekiph82/Scrubbots`  
Milestone: `M33 — Audio`  
Auditor: ChatGPT

Implementation SHA: `b7adf873379af4355d6714f67d90d9f69f2dc4d9`  
Claude log commit: `9f201bf792364e14d08c51baaea6e9896efaec7e`  
Claude log: `coordination/sessions/M33-C001/CLAUDE_LOG_V01.md`  
Audit authority: `coordination/sessions/M33-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`

## Verdict

**CODE_AUDIT_PASS / M33-C001 V01 / OWNER_F6_REQUIRED**

The implementation satisfies the M33 code-level contract. Final closure remains blocked on the owner listening gate because headless tests cannot judge mix quality, clipping, perceived density, or whether the selected voice caps sound good on the real runtime.

## Audit findings

### 1. Canonical audio asset discipline — PASS

Runtime references exactly the owner-locked one-shots:

- `assets/audio/sfx/dispatch.wav`
- `assets/audio/sfx/cleaning.wav`
- `assets/audio/sfx/completion.wav`

No movement stream is introduced, and no new music/SFX generation is added.

### 2. Bus architecture — PASS

`default_bus_layout.tres` defines `Master`, `Music`, and `SFX`; Music and SFX route to Master. The project points to the layout deterministically.

### 3. Volume model / persistence — PASS

`AudioSettingsService` provides independent normalized Master/Music/SFX values, clamps invalid values, maps 0.0 to mute, persists under `user://audio_settings.cfg`, supports injected test paths, and safely falls back to neutral defaults for missing/corrupt data.

### 4. Dispatch SFX authority — PASS

`ScrubbotDispatcher.assignment_dispatched(...)` is emitted only after a successful assignment has been attached, validated, connected and inserted into `_active`. Both successful legacy and production preclaimed paths emit after registration. Failure paths do not emit. Audio remains an observer and does not gate dispatch truth.

### 5. Cleaning SFX authority — PASS

Cleaning audio observes only `CompleteClearingLoop.authenticated_clear(...)`. Presentation-level suppression does not alter or delay the committed clear.

### 6. Completion SFX authority — PASS

Completion audio observes `CompletionController.terminal_reached(...)`, accepts `WON` only, latches once per attempt, ignores LOST/ERROR, and re-arms after successful Retry.

### 7. No movement audio — PASS

The production audio controller contains only the three one-shot canonical streams. No continuous robot movement player/loop is created.

### 8. Bounded concurrency — PASS

Voice allocation is fixed at:

- Dispatch: 4
- Cleaning: 8
- Completion: 1
- Total `AudioStreamPlayer` nodes: 13

Overflow is dropped deterministically and counted as suppressed. There is no unbounded voice-node creation and no backlog queue.

### 9. 1x / 2x semantics — PASS

Audio does not alter `Engine.time_scale` or `pitch_scale`. Production 2x changes gameplay event density while canonical one-shots remain at normal pitch.

### 10. Regression floor — PASS

Claude records the focused M33 test and root suite as green, together with M29-M32 regressions. The root suite itself contains the M19 dispatcher and M20 clearing lifecycle test families, so the required M19/M20 regression floor is covered by the recorded root-suite PASS.

### 11. Dedicated F6 scene — PASS

`res://scenes/debug/m33_audio_playtest.tscn` exists on the real production stack and exposes the required listening/debug controls for dispatch, cleaning, completion, 1x/2x, Retry, volume, persistence and stress.

## Important non-blocking audit notes for the owner gate

### A. Headless 400-request diagnostics are not listening evidence

The real-stack headless test drives `runtime.tick()` in a tight loop. Audio playback time is not a reliable wall-clock/listening model in that loop, so figures such as `dispatch played=4 / suppressed=396` and `cleaning played=8 / suppressed=392` should be read as event-authority + bounded-pool evidence, not as a prediction of what the player will actually hear during normal realtime auto-solve.

The final 4/8 voice caps must therefore be judged by the owner in F6 at actual realtime 1x/2x. If the mix becomes a wall of sound, caps/timing may be tuned without changing gameplay authority.

### B. Music volume is infrastructure-only in M33

There is no music track in M33. Therefore the Music slider can be verified for bus value + save/reload persistence, but not by audible music output. This is expected and not a blocker.

### C. Retry audible-tail check remains owner-visible

`reset_for_new_attempt()` explicitly stops/releases the completion voice and re-arms the WON latch. Dispatch/cleaning pools are not globally stopped by that method. Because Retry occurs after the terminal gate, this is not a code-audit blocker, but the owner should press Retry promptly after terminal audio and confirm no objectionable prior-attempt SFX tail is heard. If a stale audible tail is noticeable, M33 should be reopened for a small audio-only cleanup change.

## Owner F6 listening gate

Run:

`res://scenes/debug/m33_audio_playtest.tscn`

Verify:

1. real successful dispatch produces the dispatch sound;
2. committed cleaning produces the cleaning sound;
3. WON produces completion exactly once;
4. LOST/ERROR do not use completion SFX;
5. there is no robot movement loop;
6. actual realtime 1x is listenable;
7. actual realtime 2x is listenable and not pitch-shifted;
8. CLEANING STRESS does not produce unacceptable clipping/audio-wall behavior;
9. Master volume works;
10. SFX volume works;
11. Music bus value changes and persists despite no music track;
12. SAVE/RELOAD persistence works;
13. Retry allows a fresh later WON completion and leaves no objectionable stale audio tail.

## Verdict string

`CODE_AUDIT_PASS / M33-C001 V01 / OWNER_F6_REQUIRED`