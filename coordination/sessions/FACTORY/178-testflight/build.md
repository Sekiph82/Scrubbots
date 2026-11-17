STATUS: READY

# Build: 178-testflight (SB-IOS-TESTFLIGHT-2026-11-18)

## Summary
`ios-ipa.yml` has a new opt-in input, `testflight_upload` (default false). It works only with
`build_type=release`; a debug run that sets it fails in the Version step. When it is on, the run
uploads the signed IPA to App Store Connect with `xcrun altool --upload-app --apiKey/--apiIssuer`.
The `.p8` key sits in `~/.appstoreconnect/private_keys` only during the upload and is then deleted.
The three APP_STORE_CONNECT_* secrets are required, and the run stops with an error if any is missing.
Before uploading, the step checks that `ITSAppUsesNonExemptEncryption` is false in the IPA's
Info.plist. Every IPA now declares that key through `application/additional_plist_content`.
CFBundleVersion is still run_number + build_offset, so it goes up on every run. No step submits
for App Review, enables external testing or releases anything.

The static checker `tools/check_release_versioning.py` used to forbid every store upload. It now
allows exactly one upload step, and only one guarded by
`inputs.build_type == 'release' && inputs.testflight_upload`. It also requires the input, the
debug-run refusal and the plist key, and its selftest has three new cases that must be caught.

Files changed:
- `.github/workflows/ios-ipa.yml`
- `tools/check_release_versioning.py`
- `docs/RELEASE_BUILDS.md`
- `docs/PRIVACY_DATA_INVENTORY.md`
- `tests/m60_release_gates.gd` (the OWNER-STORE-SUBMISSION evidence text)
- `docs/RELEASE_GATES.json` and `docs/RELEASE_GATES.md` (regenerated with `-- --write`)

Commits on factory/178-testflight (pushed; main was not touched):
- a6e508f8: the workflow change
- 1a8b7c83: the privacy inventory lists the new plist content (a fix found by CI)

## Acceptance criteria
1. [x] Opt-in TestFlight upload step in ios-ipa.yml, release only, API-key secrets, no secret echoed, other modes unchanged. Evidence: the diff in a6e508f8. The step reads the key only from env and writes it to a file. GitHub masks secrets, and the run log shows only the CFBundleVersion and altool's output.
2. [x] `ITSAppUsesNonExemptEncryption=false` and a CFBundleVersion that increases per run. Evidence: the run's upload step passed its plist assertion. The App Store Connect API reports `usesNonExemptEncryption=False` for the build, which is CFBundleVersion 24 (run_number + offset).
3. [x] Dispatched on factory/178-testflight with build_type=release, billing_ads=true, testflight_upload=true:
   - **Run 44188786334** failed in release_gate: m58_privacy_inventory failed because the new plist key was not listed in `docs/PRIVACY_DATA_INVENTORY.md`. The other 98 of 99 suites passed. Fixed in 1a8b7c83.
   - **Run 44195307315** succeeded (release_gate success, ipa success). The upload printed `UPLOAD SUCCEEDED with no errors, 1 warning` and delivery UUID d306b660-a3f0-4c9a-bdf8-4c0fb539e698. The warning: the iOS 26.5 SDK is accepted until April 2027, when the iOS 27 SDK / Xcode 27 becomes mandatory.
4. [x] The build appears in the API. `GET /v1/builds?filter[app]=6836042282` returns build id d306b660-a3f0-4c9a-bdf8-4c0fb539e698, version 24 (0.1.0), processingState **VALID**, internalBuildState **IN_BETA_TESTING**.
5. [x] IAP review screenshots:
   - **Capture:** a GPU capture of the real Shop in main.tscn at 1290x2796. It used a throw-away `user://iap_review_*.save`, which was deleted afterwards. A price-only provider double shows the reference USD prices ($0.99 / $1.99 / $2.99 / $4.99 / $9.99, and Remove Ads $4.99). The Shop is scrolled to SCRUB BUCKS and NO ADS. The one-off script and PNG are in the session scratchpad, not the repo.
   - **Upload:** the API flow was reservation, PUT, then PATCH with uploaded=true and the md5. All six assets reached assetDeliveryState COMPLETE.
   - **States:** all six IAPs went from MISSING_METADATA to **READY_TO_SUBMIT**: scrubbucks_100 / 550 / 1200 / 2600 / 7000 and no_ads.
6. [x] Internal TestFlight:
   - Created the internal group "ScrubBots internal" (id 850cc6c5-31da-4760-8ed2-2812b524bd15, isInternalGroup=true, hasAccessToAllBuilds=true).
   - Added the account holder (the only App Store Connect user) as a tester. The email was read from the API and never printed.
   - Build 24 is in the group, and the tester state is **INVITED**.
   - Nothing was submitted for App Review: no external group, no beta review, no release.

## Validation
- `python -I tools/check_release_versioning.py`: RELEASE_VERSIONING_CHECK PASS (0 problems).
- `python -I tools/check_release_versioning.py --selftest`: RELEASE_VERSIONING_SELFTEST PASS, including the new TestFlight cases (missing release guard, upload on every release, upload outside the TestFlight step).
- Godot suites, headless, after a one-off `--import`, run locally (LOCAL_PASS): m59_app_version PASS (4/4), m60_release_gates PASS (6/6), m58_privacy_inventory PASS (7/7). All exited 0 with no SCRIPT ERROR or Parse Error lines.
- CI run 44195307315: the release_gate (clean clone, versioning check, content validator, all 99 Android validate suites) and the ipa job (import gate, PCK scan, billing_ads linkage with real AdMob ids, headless boot, TestFlight upload) all succeeded.
- `git diff --check` is clean. The worktree is clean: the import artefacts (EOL-only `.import` rewrites, generated `.uid` / `.import` / `.translation` files) were removed. No stash or clean was used.

## What the owner must do
- Accept the TestFlight invite in the email sent to the account holder (or open the TestFlight app with that Apple ID). Build 0.1.0 (24) is then installable.
- Nothing else is required. The IAPs are Ready to Submit; they go to Apple with the first app version submitted for review, which is owner-only.
- Note: I re-set the GitHub secret APP_STORE_CONNECT_API_KEY_P8 from the local AuthKey file (`gh secret set` from stdin, never printed), so the secret is guaranteed to be the raw `.p8` PEM that the step expects. It is the same key.
- TASKS.md was not edited (per instructions).

## Log
### Round 1
- Added the workflow input and step, the plist key, the checker allowance and its selftests, and the docs.
- Ran the checker, its selftest and m59/m60 locally.
- The first CI run failed only on m58 (the privacy inventory must list `application/additional_plist_content`). I documented the key, m58 passed locally, and the redispatched run succeeded and uploaded build 24.
- Captured and uploaded the six IAP review screenshots; all six IAPs are READY_TO_SUBMIT.
- Created the internal beta group, added the account holder, and confirmed build 24 is in the group.
