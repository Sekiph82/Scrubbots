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

## iOS readiness (SB-M42-033)

Static / configuration readiness checked in this repository (no macOS/Xcode, iOS export
template or iOS device available here, so physical playback is **IOS_DEVICE_LATER**):

| Check | Result |
|---|---|
| Codec path | runtime asset is Ogg Theora/Vorbis decoded by Godot's built-in, platform-independent `VideoStreamTheora` (no H.264/MP4, no AVFoundation dependency) |
| Same fail-safe | missing/undecodable stream -> `failed(reason)` -> Home exactly once (identical code path on every platform) |
| Same aspect rules | letterbox fit is computed from the Control size, no platform branches; safe-area insets do not affect the full-screen letterbox |
| Same lifecycle cleanup | `cleanup()` on outcome and on `_exit_tree`; watchdog independent of platform `finished` delivery |
| Same frequency contract | `LaunchSession` static state resets only with a new process; iOS app termination/relaunch = new process; suspend/resume keeps the process -> no replay |
| Orientation | `display/window/handheld/orientation=1` (portrait) applies to iOS export |
| Lifecycle notifications | iOS delivers `NOTIFICATION_APPLICATION_PAUSED/RESUMED/FOCUS_*`; app root flush and opening behaviour identical to Android |
| Platform-specific branches | none in `main.gd`, `opening_screen.gd`, `launch_session.gd`, `navigation_controller.gd` |
| Export preset | no `export_presets.cfg` in the repository yet; an iOS preset (bundle id, signing team, icons) is an owner/tooling step |

Physical iOS checks to run later: the same 12-item checklist above on an iPhone
(record the `[OPENING_METRICS]` line from the Xcode console).
