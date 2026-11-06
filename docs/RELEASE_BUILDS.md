# Release builds: debug vs release, versioning, build numbers

SB-M59-001..005. Both build workflows are manual (`workflow_dispatch`) and run only while the
repository is public. Neither workflow uploads anything to Google Play or the App Store.

## Making a build

| Want | Workflow | Inputs |
|---|---|---|
| Android debug APK (family testing) | `Android Family First10 APK` | `mode: build_apk` (or `apk_only`), `build_type: debug` |
| Android release APK | same | `mode: build_apk` (or `apk_only`), `build_type: release` |
| iOS unsigned IPA (owner signs with xtool) | `iOS IPA` | `build_type: debug` |
| iOS distribution-signed IPA | same | `build_type: release` |

```
gh workflow run android-family-first10.yml -f mode=build_apk -f build_type=debug
gh workflow run ios-ipa.yml -f build_type=debug
```

Debug is the default and is the earlier behaviour:

- Android: `--export-debug`, package `com.sekiph82.scrubbots.familydev` ("ScrubBots Family
  Dev"), so it installs beside a store build. Signed with the stable debug key from
  `ANDROID_DEBUG_KEYSTORE_BASE64` / `_PASSWORD` / `_ALIAS`, or a key generated in the run
  when those are absent.
- iOS: Godot exports the Xcode project and `xcodebuild` builds it unsigned
  (`CODE_SIGNING_ALLOWED=NO`); see `docs/IOS_TOOLCHAIN.md`.

Release:

- Android: `--export-release`, package `com.sekiph82.scrubbots` ("SCRUBBOTS"), signed only
  with the release keystore secrets below. If any of them is missing, or the keystore does not
  open with the password and alias, the run stops with an error before export. It never falls
  back to the debug key. After export the run fails if the APK is debuggable or its signer
  certificate DN contains "debug".
- iOS: `xcodebuild archive` with manual signing ("Apple Distribution" plus the provisioning
  profile from the secrets), then `-exportArchive` with `method app-store-connect`,
  `destination export`. The IPA stays on the runner and becomes an artifact; nothing is
  uploaded. Missing secrets stop the run before any build.
- The release APK is an APK, not an AAB. Google Play needs an AAB (Gradle build template);
  that belongs to the store-release work, which stays with the owner.

## Versioning (single source)

`data/config/app_version.json` is the only place a version lives:

```json
{"version": "0.1.0", "build": 0, "channel": "debug", "build_offset": 0}
```

- `version`: semantic `MAJOR.MINOR.PATCH`. Bump it by hand in a commit when a release changes.
- `build`, `channel`: committed as `0` / `debug`, which is what a local or editor run shows.
  CI overwrites both in its disposable workspace before export (never committed back).
- `build_offset`: added to the GitHub run number. Raise it only if the run counter ever resets
  (for example a renamed or recreated workflow), so build numbers keep going up.

At export, `.github/scripts/app_version.py <android|ios> <debug|release> <run_number>` stamps
the JSON and exports these variables:

| Variable | Value | Used for |
|---|---|---|
| `APP_VERSION` | `0.1.0` | iOS `CFBundleShortVersionString` (`application/short_version`) |
| `APP_BUILD` | run_number + build_offset | Android `version/code`, iOS `CFBundleVersion` (`application/version`) |
| `APP_VERSION_NAME` | `0.1.0-debug` / `0.1.0` | Android `version/name` |
| `OUT_DIR` | `build/<android or ios>/<debug or release>` | export output directory |
| `ARTIFACT` | `ScrubBots-<Android or iOS>-<channel>-v<version>-b<build>` | file and artifact name |

iOS is the exception for the export itself: Godot names the Xcode project, scheme, binary and
`.pck` after the export basename, and dots or hyphens there can break the pack lookup. So
the iOS export and Xcode build always use the fixed name `Scrubbots` (`${OUT_DIR}/Scrubbots.ipa`),
and only the finished IPA is renamed to `${OUT_DIR}/${ARTIFACT}.ipa`. The scan, upload and
summary steps read the renamed file. Artifacts: `<ARTIFACT>.ipa` and
`ScrubBots-iOS-<channel>-ipa-inspection`; Android: `<ARTIFACT>.apk`, `<ARTIFACT>-inspection`
and `ScrubBots-Android-validation-logs`.

Build numbers come from each workflow's own `github.run_number`, so they rise per platform.
Android debug APKs before SB-M59 used the plain run number as `version/code`; with offset 0
the new codes keep rising, so a new debug APK still installs over an old one.

The game shows `VERSION <version>[-debug] · BUILD <n>` at the bottom of Settings
(`SettingsPanel.version_text()`, reading the same JSON). Every channel except `release` gets
`-debug`.

## Checks

- `python -I tools/check_release_versioning.py`: every version consumer derives from the JSON,
  there are no literal versions in the workflows or preset, debug-key steps are guarded
  `build_type != 'release'`, release signing steps are guarded `== 'release'` and fail fast,
  the Android export uses `--export-release` only for release, outputs and artifacts use
  `OUT_DIR` / `ARTIFACT`, iOS exports under the fixed basename `Scrubbots` and renames afterwards,
  and there is no store upload. `--selftest` proves each rule catches a
  broken workflow. The Android `validate` job runs it.
- `tests/m59_app_version.gd` (in the CI suite list): the Settings label text, font and position,
  the debug and release suffix, and that the label is localization-keyed.

## Owner-only steps

Add these as GitHub repository secrets before the first release build. Release runs fail
until they exist; this is expected.

| Secret | Content |
|---|---|
| `ANDROID_RELEASE_KEYSTORE_BASE64` | `base64 -w0 release.keystore` (upload key; keep the original offline) |
| `ANDROID_RELEASE_KEYSTORE_PASSWORD` | keystore and key password |
| `ANDROID_RELEASE_KEYSTORE_ALIAS` | key alias |
| `IOS_DIST_CERT_P12_BASE64` | Apple Distribution certificate + private key, `.p12`, base64 |
| `IOS_DIST_CERT_PASSWORD` | `.p12` password |
| `IOS_PROVISIONING_PROFILE_BASE64` | App Store provisioning profile for `com.sekiph82.scrubbots`, base64 |
| `IOS_TEAM_ID` | Apple Developer team id |

The owner also has to create the release keystore and the Apple distribution certificate
(credentials), and do any store sign-in. A public production store release stays owner-only
(CLAUDE.md §0D.5). Internal testing and TestFlight uploads are allowed autonomously but are not
part of these workflows yet. Keys and passwords go only into GitHub Secrets, never into the
repository.
