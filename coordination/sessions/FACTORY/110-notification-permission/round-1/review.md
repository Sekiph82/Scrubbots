# Review round 1 - job 110 SB-M43-146

## Checks
- git diff --check origin/main...HEAD: clean
- tests/m43_146_notification_permission.gd: PASS (8/8)
- tests/m40_save_system.gd: PASS
- project.godot restored after import.

## Verified
- No OS call on boot: only call site is the REMINDERS ON toggle in profile_screens.gd; request_fn only runs from allow().
- Not now / back / dismiss: closed reason other than action:allow -> decline(), no OS call, cooldown from JSON (default 7 d, clamped >= 1 day, missing file falls back).
- Allow: one request; popup closes on action so a double tap cannot re-fire (test p04 covers). Granted skips; non-Android supported() false, no seam calls.
- Save: notify_permission section absent = fresh, present = strict (version, non-negative integral numbers); older saves load.
- No economy change; no data leaves the device (local state only, permission request is the OS's own).
- Preset: permissions/post_notifications=true is the correct Godot 4.7.2 Android preset key.
- Android <=12: POST_NOTIFICATIONS is unknown/auto-allowed there; worst case the explainer shows once, Allow is a harmless OS no-op, cooldown applies. Sensible.
- Docs: TASKS rows updated incl. SB-M43-171 iOS follow-up; header comment in notification_policy.gd fixed.

## Notes (non-blocking)
- Turning REMINDERS OFF then ON inside the cooldown correctly does not re-explain.
- EN-only keys match the repo state.

## Must-fix
None.

VERDICT: PASS
