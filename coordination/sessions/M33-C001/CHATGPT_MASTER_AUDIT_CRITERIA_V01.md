# M33-C001 V01 — ChatGPT Master Audit Criteria

Milestone: `M33 — Audio`

Authority:
- root `TASKS.md`;
- `CLAUDE.md`;
- `coordination/OWNER_M33_AUDIO_SELECTION_DECISION_V01.md`;
- `assets/audio/sfx/README.md`;
- accepted M19/M20/M26/M29/M30/M31/M32 runtime contracts.

## 1. Canonical audio assets are owner-locked

Runtime M33 must use exactly the existing canonical SFX:

- dispatch: `assets/audio/sfx/dispatch.wav`;
- cleaning: `assets/audio/sfx/cleaning.wav`;
- completion: `assets/audio/sfx/completion.wav`.

Movement audio in V1 is **NONE**.

Do not generate, replace, normalize destructively, pitch-shift into a new canonical file, or silently swap these owner-approved assets.

The canonical export contract is WAV, mono, 24 kHz, 16-bit PCM.

## 2. Bus architecture

PASS requires stable Godot audio buses for:

- `Master`;
- `Music`;
- `SFX`.

`Music` and `SFX` must route through `Master`.

No music content currently exists in `assets/audio/music/`; M33 must still provide Music volume infrastructure but must not invent/generate/download a music track.

## 3. Volume model

Master, Music and SFX volumes must each be independently readable/settable through a narrow reusable audio-settings API.

Use a stable normalized user-facing range such as 0.0..1.0, map safely to Godot bus dB, clamp invalid inputs, and handle zero volume deterministically (mute or an equivalent silence policy).

Changing audio volume must never mutate gameplay state.

## 4. Persistence

`SB-M33-010` requires real persistence under `user://` or an equivalently appropriate Godot user-data location.

PASS requires:
- defaults when no settings file exists;
- save + reload of Master/Music/SFX;
- malformed/out-of-range data handled safely;
- tests isolated from real owner settings through an injectable/test path or equivalent;
- no dependency on project source files for per-user runtime settings.

Future M41 Settings UI may consume the service, but M33 must not implement the full M41 UI.

## 5. Dispatch SFX authority

Dispatch SFX must correspond to a **successfully committed Scrubbot assignment**, at most once per successful dispatch.

Failed/rejected/rolled-back dispatch attempts must emit no dispatch SFX request.

If the repository has no suitable post-success observer seam, M33 may add one narrow presentation notification to `ScrubbotDispatcher` after the assignment is fully registered. It must not change dispatch success/failure semantics, reservation truth, assignment identity, or scheduling.

Do not infer dispatch from button input, slot placement, child-entered-tree alone, or route intent.

## 6. Cleaning SFX authority

Cleaning SFX must observe the already-authoritative:

`CompleteClearingLoop.authenticated_clear(owner_id, target_index, color_id, agent)`

A rollback/rejected/reset path must not produce a cleaning SFX request.

High-density suppression is allowed and expected at the audio presentation layer, but it must never suppress or delay the gameplay clear itself.

## 7. Completion SFX authority

Completion SFX must observe the accepted M30 terminal latch and play only for `WON`.

`LOST` and `ERROR` must not use the owner-approved completion sound.

At most one completion SFX request per WON attempt. Retry must allow a later fresh WON attempt to play completion again.

## 8. No movement audio

Any continuous robot movement loop is a blocking violation of the owner-locked V1 decision.

Do not reinterpret the repurposed `cleaning.wav` as movement audio.

## 9. SFX concurrency / spam protection

Audio presentation must have finite concurrency.

Use fixed/bounded AudioStreamPlayer voice pools or an equivalently bounded strategy. No unbounded per-event player creation and no unbounded queue.

At minimum protect high-density cleaning SFX. Dispatch SFX must also remain bounded under 2x/high concurrency. Completion must remain reliably audible without creating duplicate voices.

Overflow may be deterministically dropped/suppressed at the audio layer. Expose diagnostics such as played/suppressed counts and peak active voices for audit.

Choose final voice caps from actual stress/listening evidence; do not treat an arbitrary cap as gameplay truth.

## 10. 1x / 2x behavior

Gameplay 2x must not globally pitch-shift audio.

More dispatch/clean events may occur per wall-clock interval at 2x, so concurrency protection must handle the increased event density. Audio remains presentation-only.

## 11. Pause / Retry / terminal hygiene

Pause must produce no new gameplay-event SFX while the gameplay engines are paused because no authoritative events are firing.

Retry must not leave stale queued audio callbacks or attempt-scoped completion latches.

M33 must not weaken M30 Retry or terminal authority.

## 12. Headless-test strategy

Do not rely on human audibility in headless tests.

Provide deterministic test seams/counters proving event requests, voice allocation bounds, suppression, volume mapping and persistence. The owner F6 gate provides final listening acceptance.

## 13. High-density evidence

Stress event density substantially beyond the configured voice caps.

Record at minimum:
- configured voice counts;
- maximum simultaneous active/allocated voices;
- played requests;
- suppressed requests;
- evidence that node/player count remains bounded;
- 1x and 2x/high-rate behavior;
- no gameplay mutation.

59x59 board truth only needs to be involved where the chosen integration path scales with board/event density; do not fabricate an audio FPS benchmark.

## 14. Owner F6 audio gate

Code audit may return:

`CODE_AUDIT_PASS / M33-C001 V01 / OWNER_F6_REQUIRED`

Final closure requires owner listening acceptance using a dedicated production-stack scene, expected path:

`res://scenes/debug/m33_audio_playtest.tscn`

The owner must be able to hear/verify:
- dispatch sound on real successful dispatch;
- cleaning sound on real committed clears;
- completion sound once on WON;
- no movement loop;
- high-density/2x behavior is not an audio wall or clipping mess;
- Master volume control works;
- SFX volume control works;
- persisted values reload correctly;
- Music volume infrastructure exists even though no music track is shipped in M33;
- Retry permits a fresh later completion sound and leaves no stale audio state.

## 15. Regression floor

Require at least:
- focused M33 audio settings/event/concurrency tests;
- root test suite;
- M32 visual/runtime smoke;
- M31 authenticated-clear FX evidence;
- M30 terminal/Retry evidence;
- M29 speed/runtime evidence;
- M20 clear lifecycle;
- M19 dispatch lifecycle;
- `git diff --check`.

Any gameplay regression caused by audio is blocking.

## 16. Checklist closure

`SB-M33-005..008` are already owner-approved content/decision tasks and must remain complete.

M33 implementation closes `SB-M33-001..004`, `SB-M33-009` and `SB-M33-010` only after evidence + owner gate. Runtime must nevertheless integrate the already-approved 005..007 assets correctly and honor 008.

Claude must not edit root `TASKS.md`.

## Verdict targets

Before owner listening gate:

`CODE_AUDIT_PASS / M33-C001 V01 / OWNER_F6_REQUIRED`

After owner acceptance:

`AUDITED_PASS / M33 AUDIO CLOSED`