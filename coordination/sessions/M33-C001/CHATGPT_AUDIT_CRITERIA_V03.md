# M33-C001 V03 — Final Gameplay Music Asset Integration Criteria

Date: 2026-09-25

Authority:
- `coordination/OWNER_M33_AUDIO_SELECTION_DECISION_V02.md`
- `coordination/OWNER_M33_MUSIC_SELECTION_DECISION_V03.md`
- accepted M33 V02 code audit
- owner-selected source: `Pixel Polish Parade(1).mp3`

## Approved runtime asset

Final target:
`assets/audio/music/background_loop.ogg`

Prepared loop provenance:
- source track: `Pixel Polish Parade(1).mp3`
- source loop start: 5.841610 s
- source loop end: 142.994989 s
- loop duration: 137.153379 s
- stereo, 44.1 kHz
- OGG Vorbis
- final SHA-256:
  `8c94897ea022924bb32c1e8384fd0b73ea21863f522c4d1dd682ca773ef9ae2a`

The file supplied by ChatGPT is the owner-selected loop asset. Do not regenerate,
normalize, remix, time-stretch, EQ, compress, resample or replace it during this integration.

## PASS criteria

1. Exact asset identity
   - final repo path exists;
   - SHA-256 exactly matches the approved hash above;
   - duration approximately 137.153379 s;
   - 2 channels / 44.1 kHz;
   - OGG imports successfully in Godot.

2. MusicController integration
   - controller auto-discovers `background_loop.ogg`;
   - `has_track()==true`;
   - status becomes PLAYING after normal gameplay entry;
   - OGG loop property is enabled;
   - start_count remains 1 across dispatch, clear, Retry and speed changes;
   - scene exit stops playback.

3. Settings isolation
   - Music toggle/slider controls gameplay music only;
   - SFX toggle/slider does not mute music;
   - Master mutes all audio;
   - Haptics setting has no music side effect;
   - relaunch restores settings.

4. No audio behavior regression
   - dispatch SFX remains NONE;
   - cleaning still uses bounded `dispatch.wav`;
   - completion remains WON-only;
   - no movement audio;
   - cleaning concurrency remains bounded.

5. Loop technical evidence
   Add a test/evidence check that:
   - loaded stream is looping;
   - duration is within tolerance;
   - no extra outro/silence file replaces the approved OGG;
   - exact SHA is checked in a deterministic source/provenance test or log.

6. Required actual-main regressions, zero SCRIPT ERROR:
   - m33_audio_runtime
   - m41_settings
   - m40_v04_bootstrap
   - repaired m38_v02_strict
   - m39_v04_integration
   - root run_tests
   - git diff --check

7. Owner manual gate
   Code audit does NOT close final M33.
   After implementation the owner must listen in:
   `res://scenes/debug/m33_audio_playtest.tscn`

   Owner checks:
   - no audible click/gap at loop boundary;
   - music level is comfortable under cleaning SFX;
   - cleaning remains readable;
   - Music/SFX/Master controls behave correctly;
   - repeated listening is not fatiguing.

8. Do not edit `TASKS.md`.
9. Do not implement SB-M41-005 Reduced Effects.
10. Do not alter Workshop music selection.

Successful implementation handoff:
`AWAITING_AUDIT / M33-C001 V03 / APPROVED_GAMEPLAY_MUSIC_INTEGRATED / OWNER_F6_REQUIRED`
