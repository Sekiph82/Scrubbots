# M34 Haptics Device Validation (SB-M34-006)

Status: **device ON/OFF capture PENDING** (factory 072 round 1). The permission defect below is fixed and proven in the rebuilt APK; the handset run has not happened yet.

## Device
Samsung Galaxy A10 (32-bit, armeabi-v7a), adb serial `RF8M62956YF`. Not attached during round 1 (`adb devices` empty after `adb kill-server`/`start-server`; no Samsung/ADB device in Windows PnP).

## Defect found: APK declared no VIBRATE permission
Godot's Android `Input.vibrate_handheld` only vibrates when `android.permission.VIBRATE` is in the manifest. The family preset only listed `permissions/internet=false`, so the APK declared no permissions and every haptic call was dropped.

| APK | Source | `aapt2 dump badging` uses-permission |
|---|---|---|
| 0.1.41 (versionCode 41), installed on the A10 | main `d88a3944`, run 41116404350 | none |
| 0.1.43 (versionCode 43) | `factory/072-m34-haptics-device` `5fbcb019`, run 41127683939 (`apk_only`) | `android.permission.VIBRATE` |

Fix: `.github/android/export_presets_family_first10.cfg` adds `permissions/vibrate=true`. No GDScript changed.

## Install blocker: signing key changes every CI run
CI generates a fresh debug keystore per run (`android-family-first10.yml`, "Debug keystore" step). Certificate SHA-256: run 41116404350 `a1e105d1...e3482f606`, run 41127683939 `1b40e0cc...7c659e5c9`. `adb install -r` of the fixed APK over the installed one fails with a signature mismatch unless the app is uninstalled first, and uninstalling deletes the owner's save. Stable fix: keep one debug keystore in GitHub Secrets and use it for every family APK.

## Commands for the device run
```
adb -s RF8M62956YF install -r ScrubBots-Family-First10-Android-Debug.apk   # versionCode >= 43 with VIBRATE
adb -s RF8M62956YF shell dumpsys vibrator          # history before
adb -s RF8M62956YF logcat -c
# Settings haptics ON: start a level, tap supply slots to trigger clears and a win
adb -s RF8M62956YF shell dumpsys vibrator          # history after: expect com.sekiph82.scrubbots.familydev entries (20 ms clears, 220 ms win)
adb -s RF8M62956YF logcat -d | grep -iE "vibrat|godot"
# Settings haptics OFF: same taps; expect 0 new entries for the package
```

## Owner note
Whether the 20 ms clear tick and 220 ms win buzz feel right (strength, length) cannot be proven by a machine. It is an owner note and not a blocker.
