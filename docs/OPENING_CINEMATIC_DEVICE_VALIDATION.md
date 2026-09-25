# Opening cinematic — device validation checklist (SB-M42-032 / SB-M42-033)

Status: code-side checks complete; **real-device runs pending** (`DEVICE_OWNER_REQUIRED`
for Android, `IOS_DEVICE_LATER` for iOS). Nothing below is claimed as passed until a
real device run records its evidence here.

## Build under test

- Runtime asset: `assets/brand/opening/scrubbots_opening_720p30.ogv`
  (Theora 1280x720 30 fps + Vorbis 44.1 kHz stereo, SHA-256 in `assets/brand/opening/PROVENANCE.md`).
- Scene: `scripts/app/opening_screen.gd` (VideoStreamPlayer, letterboxed 16:9 fit).
- Boot flow: `scripts/app/main.gd` BOOT -> OPENING -> HOME (exactly once, fail-safe).
- Frequency: `scripts/app/launch_session.gd` (once per cold/native launch).

## Instrumentation

On its single terminal outcome the opening prints one line:

```text
[OPENING_METRICS] {"outcome":"completed:finished","startup_latency_ms":..,"playback_ms":..,
 "max_frame_gap_ms":..,"process_frames":..,"video_size":[1280,720],"video_rect":[x,y,w,h],
 "screen":[w,h],"stream_released":true,"platform":"Android","display":"android"}
```

Capture it with `adb logcat -s godot` (Android) or the Xcode console (iOS).

## Checklist (record device model, OS version, result, metrics line)

| # | Check | Pass criterion |
|---|---|---|
| 1 | Cold launch plays the cinematic | OPENING shown immediately after the splash |
| 2 | Smooth 720p/30 playback | no visible stutter; `max_frame_gap_ms` <= ~50 on a mid device |
| 3 | Audio sync | lip/impact sync by eye/ear through the full 15 s; no drift at the end |
| 4 | Startup latency | `startup_latency_ms` <= ~500 (first decoded frame) |
| 5 | Portrait presentation | 16:9 video letterboxed and centered, no stretch/crop, black bars |
| 6 | Orientation | app stays portrait; rotating the phone does not distort the video |
| 7 | Completion -> Home | exactly one Home, PLAY works, `outcome` = `completed:finished` |
| 8 | Background during cinematic | Home/app returns without crash; no second cinematic; Home reached once |
| 9 | Resume after reaching Home | backgrounding/foregrounding Home never replays the cinematic |
| 10 | Native restart | force-stop + relaunch plays the cinematic again |
| 11 | Memory cleanup | `stream_released` = true; memory after Home returns near pre-opening level (Android Studio profiler / Xcode memory gauge) |
| 12 | Failure fallback | (dev build with the OGV removed) app reaches Home, `outcome` = `failed:stream_unavailable` |

## Evidence log

| Date | Device | OS | Checks passed | Metrics line | Notes |
|---|---|---|---|---|---|
| — | — | — | — | — | not run yet |
