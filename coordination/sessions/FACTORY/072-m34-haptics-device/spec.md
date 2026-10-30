# M34 haptics real-device (Android) evidence + stale queue-row fix

> Feature: SB-M34-006 haptics real-device test on an Android debug build. Also correct TASKS.md row SB-CAMPAIGN-L11-L30 (stale "OPEN: m55_long_session FAIL").

## Context
- Haptics: `scripts/haptics/haptics_controller.gd` (CLEAN_MS=20 per authenticated clear, throttled 60 ms; COMPLETION_MS=220 on WON once per attempt; every call goes through `_platform_vibrate` -> `Input.vibrate_handheld`). Toggle: `scripts/haptics/haptics_settings_service.gd`, exposed in `scripts/ui/settings_panel.gd`; wired in `scripts/gameplay/runtime/production_gameplay_host.gd`. Desktop tests: `tests/m34_haptics_production.gd`, `tests/m34_haptics_runtime.gd`. Platform notes: `docs/12_HAPTICS_PLATFORM_RESEARCH.md`. A scaffold scene exists at `scripts/debug/m34_haptics_playtest.gd`.
- Device: Samsung Galaxy A10, adb serial `RF8M62956YF`, adb at `C:/Users/sekip/AppData/Local/Android/Sdk/platform-tools/adb.exe`. The current main debug APK (workflow `.github/workflows/android-family-first10.yml`) is installed.
- TASKS.md: queue line 45 (`READY SB-M34-006`), checklist line ~959 (`- [ ] SB-M34-006 Real-device test.`), line ~955 (says DEVICE/OWNER_REQUIRED). Row `SB-CAMPAIGN-L11-L30` (line ~138) ends with stale "OPEN: m55_long_session FAIL ...".
- A device script can show the OS vibrator received calls; it cannot prove subjective feel.

## Requirements
1. Using adb only (no code change unless a defect is found), drive the installed debug build on the A10: start a level, trigger clears (taps), with Settings haptics ON, and capture vibrator activity (`dumpsys vibrator_manager` and/or `dumpsys vibrator` history, plus a filtered logcat) before/after.
2. Repeat with the Settings haptics toggle OFF, same actions; capture the same evidence.
3. If the OS shows no vibration in the ON case, diagnose (e.g. missing Android `VIBRATE` permission in the export preset / APK `uses-permission` from `aapt2 dump badging`); fix only that cause, with a re-run of the two haptics suites, and note the need to rebuild/reinstall the APK.
4. Write one short doc `docs/M34_HAPTICS_DEVICE_VALIDATION.md`: device, APK source (run ID or commit), exact commands, ON vs OFF vibrator-history excerpts (counts/timestamps), result, and an "Owner note" that subjective feel (strength/length of 20 ms tick and 220 ms win buzz) is not machine-provable and is not a blocker.
5. Update TASKS.md: mark SB-M34-006 done with the evidence label `DEVICE_AUTOMATED_PASS` (not owner feel acceptance); update lines 45, ~955, ~959 consistently.
6. Correct the SB-CAMPAIGN-L11-L30 row text: replace the "OPEN: m55_long_session FAIL ..." clause with a statement that the m55 driver was fixed on main in `06fbfbad` (plan clicks in proof-kernel serial order, counts non-VOID cells), and that CI/test re-validation of the release-pool levels was skipped by owner decision 2026-10-30 (no pass claimed). Keep the `m52_owner_supply_plans not re-run` note if still true.
7. No secrets or device identifiers beyond the model name and adb serial in the doc.

## Acceptance criteria
1. `docs/M34_HAPTICS_DEVICE_VALIDATION.md` exists and contains the ON and OFF captures; ON shows >= 1 vibrator entry attributable to the app package during the tap sequence, OFF shows 0 entries for the same sequence (check: read the file; reviewer may re-run `adb -s RF8M62956YF shell dumpsys vibrator_manager`).
2. The doc states the APK source and that subjective feel is an owner note.
3. `grep -n "SB-M34-006" TASKS.md` shows no `READY`/`[ ]` state; it shows done with `DEVICE_AUTOMATED_PASS`, and line ~955 no longer says it is blocked on the device.
4. `grep -n "SB-CAMPAIGN-L11-L30" TASKS.md` row contains `06fbfbad` and "skipped by owner decision" and does not contain "m55_long_session FAIL".
5. Regression: `"$GODOT" --headless --path <worktree> -s res://tests/m34_haptics_production.gd` and `.../m34_haptics_runtime.gd` still print their PASS lines (required only if any code was touched; otherwise state "no code change").
6. `git diff --check` clean; changed files limited to the doc, TASKS.md (and the minimal fix from Req 3 if needed).

## Out of scope
- Subjective feel tuning, changing CLEAN_MS/COMPLETION_MS or throttle, new haptic patterns.
- iOS testing, new Settings UI, repeating other device checks.
- Re-running m55 or the L11-L30 CI suites, or editing campaign data.
- Committing the APK or logcat dumps (excerpts only in the doc).

## Assumptions
- The A10 vibrator service exposes call history via `dumpsys vibrator_manager` (Android 9/10 may only offer `dumpsys vibrator`); whichever is available is acceptable, with logcat as supplement.
- Toggle OFF is set through the in-app Settings UI via `adb shell input tap` (coordinates from `uiautomator dump` or a screenshot); no debug hook is added.
- If the OS history is unavailable on this Android build, fall back to logcat/`dumpsys vibrator` current-state sampling during taps and state the weaker evidence honestly in the doc.
