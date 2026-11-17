# Release builds: debug vs release, versioning, build numbers

SB-M59-001..005. Both build workflows are manual (`workflow_dispatch`) and run only while the
repository is public. Neither workflow uploads anything to Google Play or the App Store.

## Making a build

| Want | Workflow | Inputs |
|---|---|---|
| Android debug APK (family testing) | `Android Family First10 APK` | `mode: build_apk` (or `apk_only`), `build_type: debug` |
| Android release APK | same | `mode: build_apk` (or `apk_only`), `build_type: release` |
| Android Google Play AAB (upload-key signed) | same | `mode: aab_release`, `build_type: release` |
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
- Google Play needs an AAB: `mode: aab_release` (with `build_type: release`; a debug build_type
  stops the run) runs `validate` + `clean_clone`, switches the preset to the Gradle build with
  `gradle_build/export_format=1`, installs the Android build template and exports
  `${ARTIFACT}.aab`, signed with the same release (upload) key. The run checks the AAB with
  `jarsigner -verify` and prints its signer certificate SHA-256, then bundletool builds a
  universal APK from it (same key) only for the APK scan, `apksigner` and `aapt2` checks
  (`targetSdkVersion` comes from the Godot 4.7.2 Gradle template: compile/target SDK 36, min 24).
  Artifact: `<ARTIFACT>.aab`. Nothing is uploaded; the owner uploads it in Play Console.

## Local reminders (SB-M43-171/172, input `local_notifications`)

Both workflows take a boolean input `local_notifications` (default `false`). Off, every build is
exactly the earlier one. On, the build includes the ScrubbotsNotify native code (own code, no
third-party SDK, no push server):

- Android: `native/android/scrubbots_notify/build_aar.py` compiles the plugin with `javac`
  against the SDK's `android.jar` and the Godot classes from the export templates'
  `android_source.zip` (no Gradle project, no downloads) into
  `addons/scrubbots_notify/android/scrubbots_notify.aar`. The run then switches the preset to
  `gradle_build/use_gradle_build=true`, enables `addons/scrubbots_notify/plugin.cfg` in
  `project.godot` and installs the Android build template (`--install-android-build-template`),
  because Godot adds Android plugins only to Gradle builds. Package, signing key and version
  stay the same, so the APK installs over the earlier one and keeps the save.
- iOS: the run dumps `gdextension_interface.h` from the same Godot, compiles
  `native/ios/scrubbots_notify/scrubbots_notify.m` into `bin/libscrubbots_notify.dylib` with the
  iPhoneOS SDK and copies `scrubbots_notify.gdextension` next to it before the import, so the
  export embeds it. The `Scrubbots` export / Xcode / binary basename is unchanged.

```
gh workflow run android-family-first10.yml -f mode=apk_only -f build_type=debug -f local_notifications=true
gh workflow run ios-ipa.yml -f build_type=debug -f local_notifications=true
```

Not verified yet: neither path has run in CI or on a device (the Gradle build, the GDExtension
compile and load, the OS prompt and the delivered reminder). The game side
(`scripts/economy/local_notifications.gd`) is a no-op whenever the native class is absent.

## Purchases and ads (SB-M57-014..016 / 022, input `billing_ads`)

Both workflows take a boolean input `billing_ads` (default `false`). Off, every build is exactly
the earlier one (null store / ad providers: Shop UNAVAILABLE, no ads). On, the run adds free MIT
plugins, each pinned:

| Plugin | Source | Pin |
|---|---|---|
| GodotGooglePlayBilling 3.3.0 (Android) | https://github.com/godot-sdk-integrations/godot-google-play-billing/releases/download/3.3.0/godot-google-play-billing.zip | sha256 `20d75623d6f337f08d8283c83098b73678d5f575e39247af5a8eb80588b18568` |
| Godot AdMob plugin v7.0 (Android + iOS) | https://github.com/godot-sdk-integrations/godot-admob/releases/download/v7.0/AdmobPlugin-Multi-v7.0.zip | sha256 `d96e1734b889434c0a77f0bafe2f09f4cdb9e5b518b9d6809757b251a17cf8a2` |
| godot-ios-plugins `inappstore` (iOS StoreKit) | https://github.com/godot-sdk-integrations/godot-ios-plugins (no 4.x binary release; built in the run against the Godot 4.7.2-stable headers) | commit `caafb2c7fbfb5c72a64f163c76449274fa49abaa`, Godot tag commit `ed1daf0bf001b61586d9930840f2f1394092c079` |

- Android: the zips are verified, unpacked into `addons/`, `addons/AdmobPlugin/android_export.cfg`
  gets Google's sample AdMob app id, the preset switches to the Gradle build, the export templates'
  `android_source.zip` is unpacked into `android/build` (what `--install-android-build-template`
  does; that flag alone starts the editor and never exits) and `project.godot` enables both editor
  plugins (they add the AARs, `billing-ktx` and `play-services-ads` by Gradle).
  A check step reads the APK manifest for both plugins, the BILLING permission and the AdMob app id.
- iOS: the AdMob zip adds `addons/` + `ios/plugins/AdmobPlugin*`; `inappstore` is compiled with
  scons into `ios/plugins/inappstore.{release,debug}.xcframework` + `inappstore.gdip`;
  `ios_export.cfg` gets Google's sample iOS app id and the ATT text; the preset enables
  `plugins/AdmobPlugin` and `plugins/InAppStore`. The AdMob export plugin adds GoogleMobileAds by
  Swift Package Manager (Ruby `xcodeproj` gem).
- Game side: `scripts/app/main.gd` installs `PlayBillingStoreProvider` / `AppStoreProvider` /
  `AdmobAdProvider` only when the native singleton exists. The Admob node keeps `is_real = false`,
  so only Google TEST ad units are requested.

```
gh workflow run android-family-first10.yml -f mode=apk_only -f build_type=debug -f billing_ads=true
gh workflow run ios-ipa.yml -f build_type=debug -f billing_ads=true
```

Owner steps before real money / real ads: the AdMob account with an app and unit ids per platform
(then `is_real`, the real app id in the two cfg files and the real unit ids on the Admob node), the
Play merchant profile, the App Store Paid Apps agreement, and the six products of
`data/config/store_products_v1.json` in both consoles. Real purchases also need a Play test track
build (the Play Billing plugin works only for an app installed from Play) and a StoreKit sandbox
tester.

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

## Release gate (SB-M59-006..009)

A release build never exports untested code:

| Dispatch | Runs before export |
|---|---|
| Android `mode: build_apk`, `build_type: debug` | `validate` (as before) |
| Android `mode: build_apk` or `apk_only`, `build_type: release` | `validate` + `clean_clone`, both green |
| Android `mode: apk_only`, `build_type: debug` | nothing: the owner's quick path for already-proven levels (owner 2026-10-30) |
| iOS `build_type: release` | `release_gate`, green |
| iOS `build_type: debug` | nothing (as before) |

- `validate` (Android): the release/versioning check, the **content validator**
  `tools/validate_content.gd` (production catalog manifest, every level file, metadata,
  preview, supply plan and its engine, plus `LevelCatalog.validate_all()`: LevelLoader, TEST
  rejection, ProductionLevelValidator, square shell; last line `CONTENT_VALIDATION PASS|FAIL`),
  then every focused suite with its exact guard.
- `clean_clone` (Android): `tools/clean_clone_check.py` clones the committed commit
  (`git clone --depth 1`, the validate tree set), imports it headless (exit 0 and no script
  diagnostics), then runs the smoke suites `m59_app_version` (Settings),
  `m43_c001a_results_foundation` (Results on the real app root) and
  `m43_c005f_phase6_unlock_feel` (GameFeelFlow + Spark) through the clone's own
  `tools/run_suites.py`. Nothing untracked comes along: no `.godot` cache, no local
  `project.godot` edits, no owner-local `addons/godot_ai`.
- `release_gate` (iOS, ubuntu): the clean-clone check, the release/versioning check, the content
  validator and every Android validate suite with its exact guard (`tools/run_suites.py` reads
  the list from the Android workflow).

Locally:

```
python -I tools/clean_clone_check.py              # temp dir, deleted afterwards (--keep to inspect)
godot --headless --path . -s res://tools/validate_content.gd
```

`clean_clone_check.py` only reads the source checkout through `git clone`; commit first, since
uncommitted work is not in the clone.

## Export hygiene and third-party notices (SB-M59-010)

- `.github/android/family_first10_export_exclusions.txt` lists every tree that never ships:
  `coordination`, `docs`, `tests`, `tools`, `level_factory`, `content_pipeline`, the dev-art
  trees and the editor-only `addons/godot_ai` (owner-local MCP plugin, untracked). Each is in
  both presets' `exclude_filter` and absent from both export checkouts; the Android PCK/APK scans
  fail on any packaged path under them.
- Shipped addons: Game Feel Flow (`addons/game_feel_flow`, autoload `GameFeelFlow`) and
  Saltmire Spark (`addons/saltmire_spark`, autoload `Spark`), both MIT. Their licence files ship
  through the presets' `include_filter` (they are not resources) and Settings > CREDITS shows
  them verbatim, with the Godot licence and the engine's third-party notices (which cover its
  built-in default font; the game bundles no other font).
- `project.godot` registers each addon autoload exactly once and never references `godot_ai`.

## Checks

- `python -I tools/check_release_versioning.py`: every version consumer derives from the JSON,
  there are no literal versions in the workflows or preset, debug-key steps are guarded
  `build_type != 'release'`, release signing steps are guarded `== 'release'` and fail fast,
  the Android export uses `--export-release` only for release, outputs and artifacts use
  `OUT_DIR` / `ARTIFACT`, iOS exports under the fixed basename `Scrubbots` and renames afterwards,
  and there is no store upload; the release gate and export hygiene rules above. `--selftest`
  proves each rule catches a broken workflow. The Android `validate` job runs it.
- `tests/m59_app_version.gd` (in the CI suite list): the Settings label text, font and position,
  the debug and release suffix, and that the label is localization-keyed.
- `tests/m59_credits.gd` (in the CI suite list): the Settings CREDITS row, the popup's notices
  against their sources, scrolling, CLOSE, Turkish title.

The first CI run of the new gate jobs is still pending (no workflow was dispatched for this change).

## Signing secrets and owner-only steps

Android (set 2026-11-17, SB-RELEASE-SIGNING-2026-11-17): a Google Play **upload** key was
generated outside the repository (PKCS12, RSA 4096, 30 years, alias `scrubbots-upload`) and stored
as `ANDROID_RELEASE_KEYSTORE_BASE64` / `_PASSWORD` / `_ALIAS` / `_KEY_PASSWORD` (PKCS12 has one
password, so `_KEY_PASSWORD` equals `_PASSWORD`; the workflow reads `_PASSWORD`). The owner keeps
the offline backup; Play App Signing holds the app signing key. When the app is created in Play
Console, choose "Use Google-generated key" and upload the first AAB; the upload key is then the
one in the secrets.

iOS: `build_type: release` is the App Store mode. It needs these secrets and stops with an error
naming them when any is absent:

| Secret | Content |
|---|---|
| `IOS_DIST_CERT_P12_BASE64` | Apple Distribution certificate + private key, `.p12`, base64 |
| `IOS_DIST_CERT_PASSWORD` | `.p12` password |
| `IOS_PROVISIONING_PROFILE_BASE64` | App Store provisioning profile for `com.sekiph82.scrubbots`, base64 |
| `IOS_TEAM_ID` | Apple Developer team id |

An App Store Connect API key (`.p8`, key id, issuer id) is needed only to upload to TestFlight
from CI; neither workflow uploads, so it is not read yet.

The owner signs in to Apple Developer / App Store Connect / Play Console (credentials and store
records need the owner's login). A public production store release stays owner-only
(CLAUDE.md §0D.5). Keys and passwords go only into GitHub Secrets, never into the repository.
