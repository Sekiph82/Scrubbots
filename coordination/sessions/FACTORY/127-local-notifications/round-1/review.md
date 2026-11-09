# Review round 1, job 127-local-notifications

## Checks
- git diff --check origin/main...HEAD: pass
- check_release_versioning.py: PASS (0 problems); --selftest PASS
- yaml parse android-family-first10.yml, ios-ipa.yml: ok
- m43_172_local_notifications: PASS 12/12; m58_privacy_inventory: PASS 7/7; m55_economy_release_regression: PASS (no SCRIPT ERROR; "resources still in use" is the usual exit noise). project.godot restored (import touched only .import files in the throwaway worktree).

## Default-input build equivalence (highest risk)
- Android: the only workflow change besides the validate list is one step with `if: inputs.local_notifications` (AAR, Gradle sed, addon enable in project.godot, template install). Default false = step skipped; preset stays use_gradle_build=false; project.godot is NOT changed in the branch (enabled= still only game_feel_flow, saltmire_spark); import/export/boot checks untouched. Validate gains m43_172 plus an exact 12/12 summary guard; the test is present and passes.
- iOS: the dylib step is `if`-gated; default = no bin/, no dylib. Basename/preset untouched. The two log greps gained `| grep -v scrubbots_notify`: with no extension no line contains that string, so the pass/fail result is identical; it only filters the expected macOS load error when the extension exists. Scoped narrowly enough.
- Game side: addon dir has no autoload and is not enabled in project.godot; the .gdextension lives under native/ (.gdignore) and is copied to res://bin/ only in CI with the input, so desktop/headless/editor never see a missing library. native_backend() returns null via Engine.has_singleton/ClassDB.class_exists (no errors); all facade calls are no-ops on null.
- No new Android permission: manifest declares none, uses-sdk set, receiver exported=false; preset already has post_notifications=true. Alarm via setAndAllowWhileIdle needs no permission. No secrets.
- Scheduling: requires backend, not blocked, reminders ON, permission granted; quiet hours moved to quiet_to; 24h cap as lower bound; cancel on every open and boot; mark_sent for elapsed reminder. Save section local_notify: absent = fresh, present strict (version/int/non-negative). Backward compatible.
- Native sanity: Java uses valid Godot v2 plugin API (GodotPlugin, @UsedByGodot, plugin.v2 meta-data); cancel PendingIntent matches by component. ObjC C-API usage plausible; device/CI proof is still pending (rows correctly left READY).
- m58 inventory updated (dependency row, API use, permission row, iOS note).

## Findings
None.

## Notes
- ReminderReceiver: getLaunchIntentForPackage can in theory return null (setContentIntent would crash); negligible for a launcher app.
- First real proof requires a CI run with local_notifications=true plus a device; not claimable from this review.

VERDICT: PASS
