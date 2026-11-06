STATUS: READY

# Build: SB-M43-146 contextual notification permission

## Summary
Branch `factory/110-notification-permission` (commits 7364a675 code+tests, 63c5ef9e TASKS.md).

The only trigger is the player turning REMINDERS ON in Profile > Notifications. Reminders are opt-in and OFF by default (NotificationPolicy), so this is the first point where a reminder can be useful, and it never happens on boot. On Android, when permission is not granted and no cooldown is running, a native BasePopup explainer (`notification_permission`, keyed EN copy) opens on top. ALLOW makes exactly one `OS.request_permission("android.permission.POST_NOTIFICATIONS")` call (Godot built-in, API 33+). NOT NOW, back or dismiss makes no OS call and starts a cooldown read from data. Granted state skips the explainer. iOS and desktop do nothing and keep the existing "cannot ask yet" line. The Android preset now declares the permission. There is no gameplay or economy effect.

Files:
- `scripts/economy/notification_permission.gd` (new): platform seam (`platform`, `granted_fn`, `request_fn`), `should_explain/allow/decline`, strict snapshot. It holds the TODO(iOS) note pointing to SB-M43-171.
- `data/config/notification_permission_v1.json` (new): `decline_cooldown_days: 7`.
- `scripts/economy/economy_services.gd`: `notify_permission` service plus the save section `notify_permission` (absent = fresh, present = strict).
- `scripts/ui/profile/profile_screens.gd`: the REMINDERS ON hook, `open_notification_permission` explainer, and the Platform line shown only when the platform is unsupported.
- `scripts/ui/ui_text.gd`: NOTIFY_PERMISSION_TITLE/BODY/ALLOW/NOT_NOW.
- `scripts/economy/notification_policy.gd`: header comment no longer says SB-M43-146 BLOCKED.
- `.github/android/export_presets_family_first10.cfg`: `permissions/post_notifications=true` (Godot 4.7.2 built-in permission list includes POST_NOTIFICATIONS, verified in the editor binary).
- `tests/m43_146_notification_permission.gd` (new).
- `TASKS.md`: SB-M43-146 queue row DONE and checklist [x]; new READY SB-M43-171 (iOS plugin) row and checklist entry.

## Acceptance criteria
1. [x] Not shown on boot: p01 covers a fresh boot and a relaunch with reminders ON, using the fake Android not-granted API. No explainer and no OS request in either case. The explainer has exactly one call site, and main.gd, home_screen.gd and app_state.gd never touch the flow.
2. [x] Shown at the trigger: p02 checks that REMINDERS ON puts `notification_permission` on top with the OS not yet asked, and that the title, benefit text and Allow/Not now buttons use the keyed copy.
3. [x] Not now = no OS call + cooldown: p03 checks there are 0 requests. The cooldown matches the JSON (7 d). The explainer stays hidden at cooldown-1 s and shows again exactly at the cooldown. Back/dismiss counts as Not now. A temp config with 2 days gives 2 days, and a missing config falls back to 7.
4. [x] Allow = one OS request: p04 double-taps Allow and gets exactly 1 request. With permission granted the explainer never shows again (30 d later). If the OS denied, it shows again only after the cooldown.
5. [x] Granted state skips: p04.
6. [x] Non-Android no-op: p05 runs iOS/Windows/macOS/Linux/Web. Each gets no explainer, 0 request calls and 0 granted calls, and the Platform line is shown. The real seam on this desktop host never explains.
7. [x] Asked/declined persisted: p06 checks that declined_at survives a relaunch together with the cooldown, an absent section loads as fresh, and 5 malformed snapshots are rejected.
8. [x] No gameplay/economy effect: in p07 only the `notifications` and `notify_permission` economy sections change.
9. [x] POST_NOTIFICATIONS in the Android preset: p08.
10. [x] iOS no-op with a TODO note and follow-up row: TODO in notification_permission.gd, and READY SB-M43-171 in TASKS.md.

## Validation
Godot 4.7.2 console, `--import` once, then headless suites. All exited 0 with 0 SCRIPT ERROR/Parse Error, last line PASS (LOCAL_PASS):
- `tests/m43_146_notification_permission.gd`: "SB-M43-146 notification permission: PASS (8/8 cases, 0 fail)". Run after the final edits too.
- `tests/m43_master_c011_c014.gd`: PASS 28/28 (notifications, comeback, cloud save, a04 copy key).
- `tests/m43_master_c010_meta.gd`: PASS 12/12 (Profile surfaces).
- `tests/m51_localization_readiness.gd`: PASS 4/4.
- `tests/m43_r15_001_r01_sequential_unlock.gd`: PASS 14/14 (economy section isolation).
- `tests/m40_save_system.gd`, `tests/m40_v02_safety.gd`, `tests/m39_v02_atomicity.gd`: PASS (new save section).
- `git diff --check`: clean.

Every suite also prints "N resources still in use at exit", as the existing suites already do.

After the runs, the worktree import churn (`.import`, `.uid`, docs `*.translation`, project.godot) was restored or removed. `git status --porcelain` is empty. No CI run, no phone build.

Notes:
- The UiText table is EN only. The repo has no TR table or translation resources, so only EN keys were added; they go through the same TranslationServer seam.
- Delivery is still not wired: Godot has no local-notification scheduling API. This job only asks for the permission.
- The owner's gitignored local `export_presets.cfg` contains only a Web preset and was not touched.

## Log
### Round 1
Built the Android contextual permission flow, the explainer popup, persisted state, the data-driven cooldown, the preset permission and the iOS/desktop no-op. Added the focused suite (8 cases) and ran the affected suites, all passing. Updated TASKS.md (SB-M43-146 DONE, SB-M43-171 READY). The first run failed only because the explainer body Label was named "Body", which clashed with BasePopup's own Body container. Renamed it to "Explain".
