# 12 Haptics Platform Research (M34)

Audit context: `coordination/sessions/M34-C001/CHATGPT_AUDIT_CRITERIA_V01.md` SB-M34-001.

## Godot 4.7.2 built-in vibration API

Public seam: `Input.vibrate_handheld(duration_ms: int)`.

- Android: implemented via `Vibrator` service, permission `android.permission.VIBRATE` (already granted by default at manifest level for the export template). Duration is milliseconds. There is no amplitude/pattern parameter in the built-in call for 4.7.2 (advanced patterns require a native/gdextension).
- iOS: implemented via `AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)`. Duration is ignored (system decides). Modern devices honor a short buzz.
- Desktop / headless / web: **no-op**. `Input.vibrate_handheld` returns without effect. This is the fail-open path we rely on for tests.

The gamepad seam `Input.start_joy_vibration()` is NOT used — SCRUBBOTS is portrait-first mobile-touch and does not target gamepads in V1.

## What is directly testable headless

- `HapticsController` request accounting (requests/played/suppressed).
- Toggle OFF suppresses all requests without mutating gameplay.
- Anti-spam throttle window keeps `_platform_calls` bounded under a burst.
- Completion latch fires once per attempt; Retry re-arms it.
- Failed/rolled-back clears never invoke `_on_authenticated_clear`.
- `HapticsSettingsService` load/save/round-trip through an isolated `user://` path.

Tests inject a platform sink (`set_platform_sink`) so the exact call count and
duration sum can be asserted without a real device.

## Device-only

- Whether the vibration is actually perceptible on a given handset.
- Whether iOS AudioServices system-sound feel is acceptable (owner F6 gate).
- Whether cleaning bursts on a physical Android phone feel like spam.

These stay explicitly `DEVICE_REQUIRED` / `OWNER_REQUIRED`. The M34 debug scene
`scenes/debug/m34_haptics_playtest.tscn` is the checklist harness for that gate.

## Dependencies

No paid SDK, no gdextension, no custom native module. Owner-approved built-in
only (§3 rule 6 in `CLAUDE.md`).
