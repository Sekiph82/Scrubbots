STATUS: READY

# Build: 168-release-signing (SB-RELEASE-SIGNING-2026-11-17)

## Summary
Android: a Google Play upload key now exists and is stored only in GitHub Secrets plus an owner backup outside any repo. The Android workflow has a new mode `aab_release` (with `build_type: release`). It runs validate + clean_clone, then a Gradle build that exports a Play `.aab` signed with the upload key. bundletool turns that AAB into a universal APK, used only for the existing scans and the apksigner/aapt2 checks. Nothing is uploaded anywhere.
iOS: the existing `build_type: release` is already the App Store mode (Apple Distribution + App Store profile, `method app-store-connect`, export only, fails fast naming the four missing secrets). No iOS code change was needed. The missing pieces need the owner's Apple login (steps below).

Files changed (branch `factory/168-release-signing`):
- `.github/workflows/android-family-first10.yml`: `aab_release` option; export-job guard; Gradle AAB step (fails unless `build_type` is release, installs the build template by unzipping `android_source.zip`); AAB jarsigner/cert/manifest + bundletool step; scans/signature use `$CHECK_APK`; upload `.apk` or `.aab`; concurrency group per branch.
- `tools/check_release_versioning.py`: export guard includes `aab_release`; new rule plus selftest: there is exactly one AAB step, it is guarded by mode `aab_release`, and it refuses a debug `build_type`.
- `docs/RELEASE_BUILDS.md`: AAB row and section; the signing secrets / owner-steps section is rewritten.
- `tests/m60_release_gates.gd`, `docs/RELEASE_GATES.json`, `docs/RELEASE_GATES.md`: OWNER-SIGNING / OWNER-STORE-SUBMISSION evidence text updated (regenerated with `-- --write`; the verdicts did not change).

Commits: `45985582` (code), `be9f9e07` (fix: the bare `--install-android-build-template` CLI call hung the headless editor until the 90-min job timeout), `4abb5b20` (concurrency per branch). The brief asked for one code commit. Two extra small fixes were unavoidable because the CI verification only showed these problems after the first push, and force-push is not allowed. TASKS.md was not edited (per the orchestrator instruction).

## Acceptance criteria
1. [x] Upload keystore generated locally with strong random passwords: JDK 17 keytool, PKCS12, RSA 4096, valid 30 years (until 2056-11-09), alias `scrubbots-upload`, DN `CN=ScrubBots Upload, O=Sekiph82, C=TR`, cert SHA-256 `42:D6:B3:1E:7E:4E:31:2A:BA:2B:B8:14:DB:D4:D8:DF:80:27:15:3F:8E:A3:B5:1B:E0:77:01:06:C4:F3:49:87`. The password came from Python `secrets.token_urlsafe(32)` and was never printed.
2. [x] GitHub secrets set with `gh secret set` (`gh secret list` shows them): ANDROID_RELEASE_KEYSTORE_BASE64 / _PASSWORD / _ALIAS / _KEY_PASSWORD. PKCS12 has a single password, so _KEY_PASSWORD equals _PASSWORD; the workflow reads _PASSWORD.
3. [x] Not committed: the keystore and passwords live only in `C:/Users/sekip/Documents/ScrubBots-signing/` (`scrubbots-upload.keystore` + `README.txt` with alias and passwords) and in GitHub Secrets. A grep of the full CI log for the password finds 0 matches; the env shows `***`.
4. [x] Workflow mode `aab_release` exports a signed release AAB. Run https://github.com/Sekiph82/Scrubbots/actions/runs/44105591683 (branch factory/168-release-signing, head 4abb5b20): validate, clean_clone and export all succeeded. Artifact `ScrubBots-Android-release-v0.1.0-b98.aab` (396,110,926 bytes).
5. [x] Signed with the upload key: `jarsigner -verify` printed `jar verified.`; the AAB signer is `Owner: CN=ScrubBots Upload...` with SHA256 `42:D6:B3...49:87`, the same as the local keystore. The bundletool universal APK passes `apksigner verify` (v2+v3, certificate SHA-256 42d6b31e...34987). The debuggable / debug-DN gate passed.
6. [x] SDK and versioning: AAB manifest has `compileSdkVersion=36`, `minSdkVersion=24`, `targetSdkVersion=36` (meets the current Play requirement). Package `com.sekiph82.scrubbots`, versionCode 98 (= run_number + build_offset from `data/config/app_version.json`), versionName `0.1.0`. ABIs arm64-v8a + armeabi-v7a.
7. [x] apk_only / validation_only / build_apk unchanged. Their guards and steps behave the same: PKG_EXT defaults to apk and CHECK_APK to the exported APK. `check_release_versioning.py` passes with all old rules.
8. [x] No debug seams in the release build: `--export-release`; PCK_SCAN `forbidden=0 missing=0 verdict=PASS`, APK_SCAN `forbidden_total=0`; `m45_debug_tooling` (no shipping script reaches the debug harness) and `m60_release_gates` (SB-M60-003 no debug tools) are LOCAL_PASS, and both also ran green in the CI validate job.
9. [x] iOS inspected. The `ios-ipa.yml` `build_type: release` path already archives with manual signing ("Apple Distribution" + profile), exports `method app-store-connect` / `destination export`, and fails before any build when IOS_DIST_CERT_P12_BASE64 / IOS_DIST_CERT_PASSWORD / IOS_PROVISIONING_PROFILE_BASE64 / IOS_TEAM_ID is missing. `gh secret list` shows none of them exist. An App Store Connect API key is needed only for a CI TestFlight upload, which neither workflow does. Owner steps are below.
10. [x] No store upload, no production release, no spending: the UPLOAD regex check in `check_release_versioning.py` passes.

## Owner-only steps (Claude cannot do these without your login)
1. Back up `C:/Users/sekip/Documents/ScrubBots-signing/` (keystore + README with alias/passwords) to a USB stick or password manager. It is the Play **upload** key; if it is lost, a reset through Play support takes days.
2. Play Console: create the app `com.sekiph82.scrubbots` (free, account already paid). Accept **Play App Signing** with a Google-generated app key, then upload the artifact `ScrubBots-Android-release-v0.1.0-b98.aab` from run 44105591683 to the **Internal testing** track. Play records the upload key from this first upload.
3. Apple Developer > Certificates: create an **Apple Distribution** certificate (from a CSR; Claude can make the CSR and the `.p12` once you download the `.cer`), and send Claude the `.cer` (or a `.p12` + password).
4. Apple Developer > Identifiers: register the App ID `com.sekiph82.scrubbots` (if missing). Then Profiles: create an **App Store** distribution provisioning profile for it with that certificate, and download the `.mobileprovision`.
5. Apple Developer > Membership: read the **Team ID** (10 characters).
6. App Store Connect > Apps: create the app record (bundle id `com.sekiph82.scrubbots`, name, SKU).
7. Optional, only if you want CI TestFlight uploads later: App Store Connect > Users and Access > Integrations > App Store Connect API: create a key (App Manager), download the `.p8` once, and note the Key ID and Issuer ID.
After steps 3-5, Claude sets IOS_DIST_CERT_P12_BASE64 / IOS_DIST_CERT_PASSWORD / IOS_PROVISIONING_PROFILE_BASE64 / IOS_TEAM_ID and runs `ios-ipa.yml` with `build_type: release`.

Risk to know (outside this job's scope): the AAB is about 396 MB, almost all of it the game PCK in base assets. Google Play limits the base module's compressed download to 200 MB. Expect the Play upload to reject it until the assets are reduced or moved to Play Asset Delivery (an asset pack). That is a follow-up task, not a signing problem.

## Validation
- `python -I tools/check_release_versioning.py`: RELEASE_VERSIONING_CHECK PASS (0 problems), LOCAL_PASS.
- `python -I tools/check_release_versioning.py --selftest`: RELEASE_VERSIONING_SELFTEST PASS (21 cases, including the new "caught debug AAB"), LOCAL_PASS.
- `godot --headless --path . -s res://tests/m60_release_gates.gd -- --write` (after `--import`): `M60 release gates evidence: PASS (6/6 cases, 0 fail)`, exit 0, LOCAL_PASS. The gate verdicts are unchanged (SB-M60-006 FAIL and the owner gates BLOCKED, as before).
- `python tools/run_suites.py m45_debug_tooling m59_app_version`: aggregate=PASS (2/2), LOCAL_PASS.
- `git diff --check`: clean.
- CI run 44105591683 (`mode=aab_release build_type=release`): success (validate, clean_clone, export).
- Earlier runs: 44072698616 timed out (the template-install hang, fixed in be9f9e07). 44097839297 and 44102005376 were pending runs cancelled by other branches' dispatches in the shared concurrency group (fixed in 4abb5b20).

## Log
### Round 1
- Found that the release-keystore plumbing (SB-M59) and the iOS App Store release path already existed. Only the AAB, the actual key and the owner steps were missing.
- Generated the upload keystore, set the 4 secrets, and wrote the owner backup + README outside the repo.
- Added the `aab_release` mode plus the static-check rule and selftest; updated the docs and the m60 owner-gate evidence.
- CI fixes: installed the build template by unzip instead of the bare CLI flag, and made the concurrency group per ref. A main-branch dispatch had preempted the pending factory runs twice.
- Verified the signed AAB in CI against the local keystore fingerprint.
