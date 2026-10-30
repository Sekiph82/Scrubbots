# M34 Haptics Device Validation (SB-M34-006)

Status: **device ON/OFF capture PENDING** (factory 072 rounds 1-2). The permission defect below is fixed and proven in the rebuilt APK; the handset run has not happened yet.

## Device
Samsung Galaxy A10 (32-bit, armeabi-v7a), adb serial `RF8M62956YF`. Not attached during round 1 (`adb devices` empty after `adb kill-server`/`start-server`; no Samsung/ADB device in Windows PnP).

## Defect found: APK declared no VIBRATE permission
Godot's Android `Input.vibrate_handheld` only vibrates when `android.permission.VIBRATE` is in the manifest. The family preset only listed `permissions/internet=false`, so the APK declared no permissions and every haptic call was dropped.

| APK | Source | `aapt2 dump badging` uses-permission |
|---|---|---|
| 0.1.41 (versionCode 41), installed on the A10 | main `d88a3944`, run 41116404350 | none |
| 0.1.43 (versionCode 43) | `factory/072-m34-haptics-device` `5fbcb019`, run 41127683939 (`apk_only`) | `android.permission.VIBRATE` |

Fix: `.github/android/export_presets_family_first10.cfg` adds `permissions/vibrate=true`. No GDScript changed.

## Signing: stable debug key (owner 2026-10-31)
Until `64ac9084` CI generated a fresh debug keystore per run, so every APK had a new certificate (run 41116404350 `a1e105d1...e3482f606`, run 41127683939 `1b40e0cc...7c659e5c9`) and could not install over the previous one without an uninstall, which deletes the save.

Now the export job decodes `ANDROID_DEBUG_KEYSTORE_BASE64` / `_PASSWORD` / `_ALIAS` from GitHub Secrets (generated key only when the secret is absent). Two `apk_only` runs on `64ac9084`, both logging "debug keystore: stable GitHub Secret", have the same signer certificate SHA-256 `770a894ee0e76737c24640f749c26142522cdd3d5fa35ca02d027591666eba27`:

| Run | versionCode | uses-permission |
|---|---|---|
| 41129466216 | 44 | VIBRATE |
| 41129478628 | 45 | VIBRATE |

The phone still has the old-key build (run 41116404350). Moving it to the stable key needs one last reinstall. To keep the save, copy it out first with `adb shell run-as com.sekiph82.scrubbots.familydev` (the build is debuggable), then restore it after installing. Every later family APK then installs with `adb install -r`.

## Commands for the device run
```
adb -s RF8M62956YF install -r ScrubBots-Family-First10-Android-Debug.apk   # versionCode >= 44, stable key, VIBRATE
adb -s RF8M62956YF shell dumpsys vibrator          # history before
adb -s RF8M62956YF logcat -c
# Settings haptics ON: start a level, tap supply slots to trigger clears and a win
adb -s RF8M62956YF shell dumpsys vibrator          # history after: expect com.sekiph82.scrubbots.familydev entries (20 ms clears, 220 ms win)
adb -s RF8M62956YF logcat -d | grep -iE "vibrat|godot"
# Settings haptics OFF: same taps; expect 0 new entries for the package
```

## Owner note
Whether the 20 ms clear tick and 220 ms win buzz feel right (strength, length) cannot be proven by a machine. It is an owner note and not a blocker.
