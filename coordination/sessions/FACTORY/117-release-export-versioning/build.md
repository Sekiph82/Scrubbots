STATUS: READY

# Build: SB-M59-001..005 debug/release export, output directories, versioning, build numbers

## Summary
Branch `factory/117-release-export-versioning` (commits 0419f569, f90b1799, a8259c0b, round 2 5a4d1327; not pushed).

- `data/config/app_version.json` is the single version source: `version` 0.1.0 (semver, hand-bumped), `build` 0 / `channel` debug as committed (local/editor), `build_offset` 0.
- `.github/scripts/app_version.py <android|ios> <debug|release> <run_number>` (stdlib, run with `python3 -I`) stamps the JSON in the disposable CI workspace (build = run_number + build_offset, channel) and exports APP_VERSION, APP_BUILD, APP_VERSION_NAME (`0.1.0-debug` / `0.1.0`), OUT_DIR=`build/<platform>/<mode>`, ARTIFACT=`ScrubBots-<Android|iOS>-<mode>-v<ver>-b<build>`.
- `.github/workflows/android-family-first10.yml`: new input `build_type` (debug default | release). Debug = the earlier path (debug keystore secret or generated key, `--export-debug`, familydev package). Release = `ANDROID_RELEASE_KEYSTORE_BASE64/_PASSWORD/_ALIAS` only, fails fast when absent or when the keystore does not open, `--export-release`, package `com.sekiph82.scrubbots`, post-export check fails if the APK is debuggable or its cert DN says debug. Version/code and name come from APP_BUILD / APP_VERSION_NAME. Outputs and artifacts use OUT_DIR / ARTIFACT. `validate` also runs `tools/check_release_versioning.py` and the new `m59_app_version` suite.
- `.github/android/export_presets_family_first10.cfg`: `@PACKAGE@` / `@APP_LABEL@` placeholders, header comment.
- `.github/workflows/ios-ipa.yml`: Godot export_path, Xcode project/scheme/binary and .pck keep the fixed basename `Scrubbots` (`${OUT_DIR}/Scrubbots.ipa`, env APP_NAME); only the finished IPA is renamed to `${OUT_DIR}/${ARTIFACT}.ipa`, which the inventory, summary and upload steps read. Input `build_type`. Debug = earlier unsigned IPA. Release = `IOS_DIST_CERT_P12_BASE64`, `IOS_DIST_CERT_PASSWORD`, `IOS_PROVISIONING_PROFILE_BASE64`, `IOS_TEAM_ID` only (fail fast), temp keychain, `xcodebuild archive` + `-exportArchive` with `destination export` (no upload), keychain removed afterwards. `application/short_version` = APP_VERSION, `application/version` = APP_BUILD.
- `scripts/ui/settings_panel.gd`: `VersionLabel` under CLOSE, text from `SettingsPanel.version_text()` reading the same JSON; `scripts/ui/ui_text.gd`: `SETTINGS_VERSION` "VERSION %s · BUILD %d".
- `tools/check_release_versioning.py` (python -I, `--selftest`), `tests/m59_app_version.gd`.
- `docs/RELEASE_BUILDS.md` (new), `docs/IOS_TOOLCHAIN.md` (signing/credentials lines), `TASKS.md` (queue row DONE, M59-001..005 checked).

## Acceptance criteria
1. [x] Single source of truth for version with semantic version name: `data/config/app_version.json`; `python -I tools/check_release_versioning.py` -> `RELEASE_VERSIONING_CHECK PASS (0 problems)` (asserts semver, committed build 0/debug, preset only placeholders, no literal versions in workflows/preset, both workflows stamp through app_version.py, Settings reads the JSON).
2. [x] Build number derived deterministically in CI (run_number + offset, monotonic) and injected into Android version/code+name and iOS CFBundleVersion/short version: local run of app_version.py on a scratch copy: `android release 57` -> APP_BUILD=57, APP_VERSION_NAME=0.1.0, OUT_DIR=build/android/release, ARTIFACT=ScrubBots-Android-release-v0.1.0-b57; `ios debug 12` -> APP_VERSION_NAME=0.1.0-debug, OUT_DIR=build/ios/debug; invalid channel `beta` -> usage error, exit 1. Preset sed run locally: version/code=57, version/name="0.1.0", unique_name/name filled. Offset 0 keeps Android codes >= the old run-number codes.
3. [x] Debug builds clearly marked: Android versionName and the in-game label carry `-debug` for every channel except release (m59 v02).
4. [x] Debug vs release modes behind explicit workflow_dispatch input; release fails fast without release secrets, never falls back to debug signing; no store upload: check script + `--selftest` -> caught unguarded debug key, release step reading the debug key, missing fail-fast, store upload, swapped export flags; `RELEASE_VERSIONING_SELFTEST PASS`. Release secret names documented in docs/RELEASE_BUILDS.md. Not exercised in CI (instructed: no workflow run).
5. [x] Output directories `build/<platform>/<mode>/`, artifact names with version+build: OUT_DIR/ARTIFACT used for every export, scan, hash and upload path (check script asserts the upload path). iOS builds under the fixed basename Scrubbots and renames the finished IPA (check_ios_basename, selftest case).
6. [x] Settings shows version + build from the same source: `m59_app_version` LOCAL_PASS 4/4 (label text == version_text(), "VERSION 0.1.0-debug · BUILD 0", font >= 30, inside frame, keyed under pseudo-locale).
7. [x] Tests: static check (python -I) + headless Settings label suite, both wired into the Android validate job.
8. [x] docs/RELEASE_BUILDS.md: how to build, versioning rules, owner-only secrets and store steps.

## Validation
- `python -I tools/check_release_versioning.py` PASS; `--selftest` PASS.
- Workflows parse as YAML (both show their `build_type` input); `bash -n` on all 27 `run:` blocks: no syntax errors.
- Godot 4.7.2 (`--import` once in the worktree), `python -I tools/run_suites.py`: LOCAL_PASS m59_app_version (4/4), m41_settings, m51_localization_readiness (4/4), m50_accessibility_audit (4/4), m49_responsive_matrix (8/8), m42_navigation, m44_ftue (23/23); all exit 0, diag=0.
- `git diff --cached --check` clean on every commit; import churn (.import, .uid, .translation, project.godot) restored/removed; `git status --porcelain` empty.
- No CI run, no APK/IPA built, nothing pushed.

## Log
### Round 1
Implemented the above. Choices: version source is a JSON under data/config rather than project.godot (owner's Desktop has local project.godot edits; CI rewrites the JSON in its disposable workspace, so the shipped game shows the stamped build). Release Android is a signed APK, not an AAB (AAB needs the Gradle template; noted in docs as store work). iOS debug keeps `--export-release` + unsigned xcodebuild as before; its "debug" marker comes from the stamped channel. Release Android package `com.sekiph82.scrubbots` matches the iOS bundle id; debug keeps `familydev`. Release signing needs owner-added secrets; release runs fail fast until then.

### Round 2
Review round-1 (VERDICT: CHANGES), one must-fix plus a docs note:
- Finding 1 (iOS export basename with dots/hyphens could break the .pck lookup, scheme and binary name): fixed in 5a4d1327. ios-ipa.yml has env APP_NAME: Scrubbots again; preset export_path and the Godot export go to `${OUT_DIR}/${APP_NAME}.ipa`, the Xcode step builds/zips (debug) or exports (release) to Scrubbots.ipa and only then runs `mv "${APP_NAME}.ipa" "${ARTIFACT}.ipa"`; inventory, summary and upload read ${OUT_DIR}/${ARTIFACT}.ipa. The ARTIFACT-named rm placeholder is gone.
- check_release_versioning.py: new check_ios_basename (APP_NAME Scrubbots, export_path and --export-release use APP_NAME, rename after build, no ARTIFACT in export_path) + selftest case. `python -I tools/check_release_versioning.py` PASS (0 problems); `--selftest` PASS (6 cases incl. versioned iOS export basename). `bash -n` on the new Xcode step: OK; YAML parses.
- Note (artifact names in docs): docs/IOS_TOOLCHAIN.md steps/artifacts lines and docs/RELEASE_BUILDS.md (iOS fixed-basename paragraph, artifact names, checks list) updated.
- Removed the worktree import churn left by the review run (1191 generated .uid/.import/.translation files, stat-dirty .import files restored); git status clean. No workflow run, no push, no rebase.
