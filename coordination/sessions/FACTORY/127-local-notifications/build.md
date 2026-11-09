STATUS: READY

# Build: Local notifications (SB-M43-172) + iOS notification permission (SB-M43-171)

## Summary
The game can now schedule and cancel ONE local reminder through its own native code. It uses no push server, no paid SDK and no third-party code. On desktop, web and headless runs, and in any build without the native plugin, it does nothing. The native code goes into a build only when the workflow input `local_notifications` is set. That input defaults to false, so the debug APK and IPA the owner installs are unchanged.

- `scripts/economy/local_notifications.gd` (new): the LocalNotifications facade, kept in economy services as `local_notify`.
  - When the app pauses or closes (`main.gd`), it schedules the earliest of three reminders: hearts full, next local day's daily reward, or 24 h before the end of an active event that has a claimable reward. Gift is never predicted because it needs play.
  - It only schedules when reminders are ON, the OS permission is granted and the save is not blocked.
  - It respects per-category toggles and quiet hours (the time moves to quiet_to), and treats the policy's 24 h cap high-water as a lower bound. If two reminders fall at the same time, policy priority decides.
  - Every open (cold start and resume) cancels the reminder. If its time has already passed, it counts as sent (`mark_sent`).
  - It saves the pending time in the economy section `local_notify` (absent = fresh, present = strict).
  - The backend and UTC offset can be injected for tests.
- `scripts/economy/notification_permission.gd`: adds the native seam. On iOS it is supported only when the native class is present; Allow then calls `request_authorization()` and granted reads `notifications_enabled()`. On Android with the plugin, granted means `areNotificationsEnabled` (correct on API < 33 too). The SB-M43-146 explainer flow is unchanged.
- `scripts/economy/notification_policy.gd`: adds `last_sent()` and updates the header comment.
- `scripts/economy/economy_services.gd`, `scripts/app/main.gd`: wiring and lifecycle hooks.
- `native/android/scrubbots_notify/`: Godot v2 Android plugin in Java.
  - `ScrubbotsNotifyPlugin` provides `notifications_enabled` / `schedule` / `cancel_all`. It uses `AlarmManager.setAndAllowWhileIdle`, which needs no permission. Exact alarms are not used.
  - `ReminderReceiver` posts the notification on a "reminders" channel, using the app icon; tapping it opens the app.
  - The manifest has the v2 meta-data, a non-exported receiver and `uses-sdk` (so no implied legacy permissions). It declares no new permission and no BOOT_COMPLETED: a reboot drops the reminder, and the next app close schedules it again.
  - `build_aar.py` builds the AAR with javac against `android.jar` plus the godot-lib classes from the export templates. No Gradle project and no downloads.
- `native/ios/scrubbots_notify/`: `scrubbots_notify.m` is a plain C GDExtension in Objective-C (no godot-cpp). It registers a RefCounted class `ScrubbotsNotify` with `notifications_enabled`, `request_authorization`, `schedule` (UNTimeIntervalNotificationTrigger, fixed id) and `cancel_all`. Also adds `scrubbots_notify.gdextension`. `native/.gdignore` keeps these files out of the Godot import.
- `addons/scrubbots_notify/` (plugin.cfg, plugin.gd): an EditorExportPlugin that passes the AAR to Android exports only when the preset uses the Gradle build. It is not enabled in `project.godot`; the workflow enables it when the input is set.
- `.github/workflows/android-family-first10.yml`:
  - New input `local_notifications`. When true: build the AAR, set the preset to `use_gradle_build=true`, enable the addon and run `--install-android-build-template`.
  - Adds `m43_172_local_notifications` to validate with an exact 12/12 guard.
- `.github/workflows/ios-ipa.yml`:
  - New input `local_notifications`. When true: dump `gdextension_interface.h` from the same Godot, compile the dylib for iphoneos arm64 into `res://bin/` and copy the .gdextension there.
  - The import and boot gates ignore the expected "no macOS library" load error for scrubbots_notify.
  - The fixed `Scrubbots` basename is unchanged.
- `tests/m43_172_local_notifications.gd` (new, 12 cases).
- Docs: `docs/PRIVACY_DATA_INVENTORY.md` (component row, native calls, save contents, Android/iOS permission notes; the planned "local notifications plugin" row is removed), `docs/RELEASE_BUILDS.md` (new section on the input), `docs/IOS_TOOLCHAIN.md`.
- `TASKS.md`: both rows stay READY and the checkboxes stay unchecked. The evidence is recorded, plus "Remaining: CI run with the input + device verification".
- `.gitignore`: ignores `addons/scrubbots_notify/android/` and `/bin/`, which are CI build outputs.

## Acceptance criteria
1. [x] Reminders are scheduled and cancelled per notification_policy, with quiet hours and the cap: m43_172 cases n04 (earliest reminder, copy key, seconds, UTC+3 local day), n05 (quiet hours 14-16 move 14:33 to 16:00; from == to means no quiet hours), n06 (24 h cap lower bound, tie goes to daily by priority) and n07 (category toggles; event 24 h before its end; dropped when cap + quiet hours push it past the end).
2. [x] Reminders OFF schedules nothing, and permission denied or a blocked save schedules nothing: n02, n03.
3. [x] Opening the app cancels the reminder, and a reminder whose time has passed counts toward the cap: n08 (unit) and n10 on the real main.tscn (pause schedules and saves the pending time, resume cancels, a cold start after the fire time sets `last_sent`).
4. [x] No-op on desktop / web / headless: n01 (no backend on this host), and m43_146 p05 still passes.
5. [x] iOS permission goes through the factory 110 explainer: n11, with a fake native object. Without the class: unsupported and no explainer. With it: explainer, Allow sends exactly one requestAuthorization, then granted. Android plugin: granted = notifications_enabled. m43_146 8/8 unchanged.
6. [x] Plugin wired in presets/workflows (static check): n12 checks plugin names and methods, the v2 meta-data, that the receiver is not exported, `uses-sdk` and no uses-permission, that the iOS entry symbol and class match, `native/.gdignore`, that the family preset keeps `use_gradle_build=false`, that the export plugin is Gradle-gated, that project.godot does not enable it, the wiring in both workflows, and that `APP_NAME: Scrubbots` is kept.
7. [x] Android plugin compiles: built locally with `build_aar.py` (JDK 17 javac, android-37 android.jar, godot-lib 4.7.2 template_release classes). The AAR contains AndroidManifest.xml, classes.jar (2 classes) and R.txt. `d8 --min-api 24` dexed it to classes.dex (4064 bytes). The only javac note was the expected deprecation of `Notification.Builder(Context)` on the API < 26 branch.
8. [ ] iOS GDExtension compiles: NOT verified, because there is no Mac or C compiler locally. The typedef and function names were checked against the 4.7.2 `--dump-gdextension-interface` header only. Pending a CI run of ios-ipa.yml with `local_notifications=true`.
9. [ ] Gradle-build APK with the plugin, and reminders delivered on a device: NOT verified, because the job does not run workflows or builds (owner rule). Pending.
10. [x] Privacy inventory updated and the m58 guard is green: m58 7/7.

## Validation
All results are LOCAL_PASS on Godot 4.7.2 in the worktree, using `python tools/run_suites.py` (the CI rule):
- m43_172_local_notifications PASS (12/12). m58_privacy_inventory PASS (7/7). m56_analytics_taxonomy PASS (21/21). m40_save_system PASS. m40_v04_bootstrap PASS. m43_master_c010_meta PASS (12/12). m43_master_c011_c014 PASS (29/29). m42_navigation PASS. m41_settings PASS. m43_r15_001_r01_sequential_unlock PASS (14/14). m59_app_version PASS (4/4).
- m55_economy_release_regression: FAIL on the first run (Object growth: 121 over 60 saves). The cause was my self-capturing lambdas in NotificationPermission, a reference cycle. Fixed in a3cb15f4, then PASS. m43_172 and m58 also re-passed after the fix.
- m43_146_notification_permission (not in the workflow list, run directly): PASS (8/8) after the fix, 0 SCRIPT ERROR.
- `python -I tools/check_release_versioning.py`: PASS (0 problems). Both workflow YAMLs parse (PyYAML) and show the new input.
- `git diff --check` was clean on every commit.
- No workflow was run, and no APK or IPA was built.

Commits: 49951088 (native sources), 45e38aed (facade, hooks, test), 1d155bbe (CI), dc085413 (docs/tasks), a3cb15f4 (leak fix), c78dbdd7 (tasks SHA). Not pushed.

## Log
### Round 1
- Built the work as described above. Native wiring sits behind a feature flag that defaults OFF (workflow input `local_notifications`), because Android plugins require the Gradle build. Switching the owner's debug APK path to Gradle without a CI run would be risky.
- The reminder is scheduled from `main.gd` on PAUSED and WM_CLOSE_REQUEST, before `flush_lifecycle` so the pending time is saved. It is not scheduled on FOCUS_OUT, to avoid scheduling while the app stays in use.
- Only one reminder is scheduled at a time, which keeps the 24 h cap trivially true. When it has fired and the player does not return, no further reminders are sent until the next open/close.
- Simplifications with a known limit: the quiet-hours conversion uses today's UTC offset, so a DST switch before the reminder can shift it by an hour (marked in code). Android uses the app icon as the small icon (Android may render it as a silhouette). Tapping a reminder opens the app on Home with no deep link.
- The local `--import` churn (.import, .uid, .translation, project.godot) was restored or removed; the tree is clean.
