# SB-M33-MUSIC-FINAL — Owner-approved gameplay music integration

Status: IMPLEMENTED (AWAITING_AUDIT) / OWNER_F6_REQUIRED
Implementation SHA: `18020ef`
Owner decision: `coordination/OWNER_M33_MUSIC_SELECTION_DECISION_V03.md` (gameplay = Pixel Polish Parade; Workshop track NOT integrated)

## Asset verification (before any code change)
| Check | Value |
|-------|-------|
| path | `assets/audio/music/background_loop.ogg` |
| SHA-256 (working file and committed blob `git show origin/main:... \| sha256sum`) | `8c94897ea022924bb32c1e8384fd0b73ea21863f522c4d1dd682ca773ef9ae2a` (match) |
| size | 2,686,777 bytes |
| codec / channels / rate | Ogg Vorbis, 2 ch, 44,100 Hz (Vorbis identification header) |
| duration | last-page granule 6,048,464 frames / 44,100 = 137.153379 s; Godot `get_length()` 137.153381 s |
| Godot import | `AudioStreamOggVorbis` (importer `oggvorbisstr`, default params, `loop=false` in import) |

No transcode / normalize / resample / edit. The `.ogg.import` sidecar is not committed (repo convention: `.import` files untracked).

## Integration
- Single authority: existing `MusicController` (no second player). Auto-discovers `APPROVED_TRACK_PATH`, duplicates the stream and sets `loop = true` on the duplicate (shared imported resource stays `loop=false`).
- Defect fixed: V02 auto-start ran in `_enter_tree`, before the child AudioStreamPlayer is in the tree, so Godot refused `play()` ("Playback can only happen when a node is inside the scene tree"). V02 tests masked it by injecting a track and calling `start()` explicitly. Now starts in `_ready`; re-entry after removal resumes via deferred `start()`.
- F6 playtest: debug-only MUSIC TEST TONE removed (it would replace the approved track); checklist updated for loop seam / level / fatigue.

## Evidence
- `tests/m33_audio_runtime.gd::approved_music_asset`: path, SHA-256, size, stereo, 44.1 kHz, container duration 137.153379 s, Godot class/length within 10 ms, no extra file in `assets/audio/music`.
- `::music_controller_unit`: auto-discovery (source path), OGG `loop == true`, shared resource unmutated, PLAYING with start count 1 on tree entry, Music bus, no-track path.
- `::real_stack_1x/2x`: production host music = approved looping OGG, PLAYING on normal gameplay entry, start count 1 through dispatch/clear drain, 2x toggle, Retry, second drain; scene exit stops.
- `tests/m41_settings.gd::real_host_bus_routing`: music playing; SFX 0/OFF leaves music unmuted; Music OFF mutes music only; Master 0 mutes all; haptics toggles leave music playing, bus volume unchanged, start count 1.
- Probes: pre-fix `_enter_tree` start -> 7 FAIL (observed before the fix); loop flag not set -> 3 FAIL.
