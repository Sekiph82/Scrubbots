# Review round 1: 117-release-export-versioning (SB-M59-001..005)

## Checks
- git diff --check origin/main...HEAD: pass
- python -I tools/check_release_versioning.py: pass (0 problems); --selftest: pass
- yaml.safe_load both workflows: pass (android inputs mode+build_type, ios inputs build_type)
- tests/m59_app_version.gd: exit 0, PASS 4/4; tests/m41_settings.gd: exit 0, PASS
- No workflow run (as instructed). Worktree import churn restored for project.godot only (worktree is disposable).

## Debug-path diff (line by line)
Android debug, unchanged: package com.sekiph82.scrubbots.familydev, label "ScrubBots Family Dev", same debug-keystore secret steps (same env, same GODOT_ANDROID_KEYSTORE_DEBUG_*; the editor-settings file is now written in an earlier step and the debug lines appended, result identical), --export-debug, ABIs armeabi-v7a + arm64-v8a, vibrate + post_notifications still true, same hashing/scan steps. version/code = run_number + build_offset(0) = old run_number, so install-over keeps working (monotonic). versionName changes from 0.1.N-family-first10-dev to 0.1.0-debug: harmless. Output dir/artifact names change (Android artifact now ScrubBots-Android-debug-v0.1.0-bN.apk): Iphone_Yukle_Guncel.bat takes a path argument and does not depend on names.
Release path: no debug key in release steps, fails fast on missing secrets and on unopenable keystore, debuggable/debug-DN post check, no upload to any store, secrets not echoed (only passed through env / GITHUB_ENV file vars, not printed). Good.

## Findings
1. .github/workflows/ios-ipa.yml (preset `export_path="${OUT_DIR}/${ARTIFACT}.ipa"`, Godot export step, Xcode step, inventory step): the iOS DEBUG path now gives Godot an export basename with dots and hyphens (`ScrubBots-iOS-debug-v0.1.0-b12`), where it used to be `Scrubbots`. Godot's iOS exporter derives the Xcode project/scheme/PRODUCT_NAME and the `<binary_name>.pck` name from that basename, and Godot locates the main pack next to the executable via basename-with-extension-stripped logic, so dots (".1.0-b12") can break the pack lookup on device (black screen / "project not found") or the project/scheme naming. This is untestable here and sits on the owner's primary install path. Must-fix: keep the Godot export_path and xcodeproj/scheme/binary name fixed as before (`${OUT_DIR}/Scrubbots.ipa`, same `build/ios/...` project folder under OUT_DIR is fine), build with xcodebuild as now, and only at the end `mv`/zip the final IPA to `${OUT_DIR}/${ARTIFACT}.ipa` (inventory, upload and summary then read the renamed file). The same applies to the release branch (the `rm -f "${ARTIFACT}.ipa"` placeholder goes away accordingly). Android is not affected (apk/pck names are not used at runtime).

## Notes
- IOS_TOOLCHAIN.md says artifacts `Scrubbots-ipa`; the artifact is now named `<ARTIFACT>.ipa`. Builder said docs were updated; confirm the artifact-name lines match after finding 1 is fixed.
- Release Android package com.sekiph82.scrubbots matches the iOS bundle id; fine, needs owner secrets before first use.

VERDICT: CHANGES
