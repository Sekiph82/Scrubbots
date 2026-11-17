# 178-testflight (SB-IOS-TESTFLIGHT-2026-11-18)
Owner 2026-11-18: "sen gerisini hallet" (owner asleep). Goal: ScrubBots iOS on TestFlight + iOS in-app products Ready to Submit.
Known state:
- App Store Connect app id 6836042282, bundle com.sekiph82.scrubbots, team C8NYQF627W.
- iOS App Store signing secrets IOS_DIST_CERT_P12_BASE64 / IOS_DIST_CERT_PASSWORD / IOS_PROVISIONING_PROFILE_BASE64 / IOS_TEAM_ID work
  (ios-ipa.yml build_type=release run 44126843348 success).
- App Store Connect API key secrets: APP_STORE_CONNECT_API_KEY_P8, APP_STORE_CONNECT_KEY_ID (PJB45444PJ),
  APP_STORE_CONNECT_ISSUER_ID (team key; JWT iss = issuer id). A working Python JWT helper is
  factory/jobs/178-testflight/asc_reference.py (reads the key from env ASC_P8_PATH; never print/commit the key).
  The local key file is C:/Users/sekip/Downloads/AuthKey_PJB45444PJ.p8 (read only; do not move/copy into the repo).
- 6 iOS IAPs exist with price/availability/en-US localization, state MISSING_METADATA (review screenshot missing):
  scrubbucks_100 6836043642, scrubbucks_550 6836047946, scrubbucks_1200 6836053914, scrubbucks_2600 6836054309,
  scrubbucks_7000 6836054522, no_ads 6836054963.
## Do
1. ios-ipa.yml: add an opt-in upload step (e.g. input `testflight_upload: true`, only with build_type=release) that uploads
   the signed IPA to App Store Connect/TestFlight using the API key secrets (xcrun altool --upload-app with --apiKey/--apiIssuer
   and the .p8 placed in ~/.appstoreconnect/private_keys on the runner, or the iTMSTransporter/`xcrun altool` equivalent).
   Must support billing_ads=true (real AdMob ids in release are already wired by job 170). Ensure Info.plist has
   ITSAppUsesNonExemptEncryption=false (no custom encryption) so TestFlight does not block on export compliance, and a
   CFBundleVersion that increases per run. No secret echoed. Keep other modes unchanged.
2. Dispatch the workflow on main after merge-prep? -> No: push only your branch factory/178-testflight and dispatch
   ios-ipa.yml on that branch with build_type=release, billing_ads=true, testflight_upload=true. Confirm via the API that a
   build appears for app 6836042282 (GET /v1/builds?filter[app]=6836042282) and its processingState.
3. IAP review screenshots: capture the real in-game Shop screen (GPU capture, throw-away save, iPhone size 1290x2796 or
   1242x2688) showing the Scrub Bucks packs / Remove Ads, and upload one screenshot per IAP via the API
   (inAppPurchaseAppStoreReviewScreenshots: create reservation -> PUT upload operations -> PATCH uploaded=true with md5).
   Verify each IAP state becomes READY_TO_SUBMIT.
4. TestFlight internal testing: if the build processed, add it to an internal beta group (create group "ScrubBots internal"
   with the account holder as tester if needed) via the API, so the owner sees it in the TestFlight app. Do not submit anything
   for App Review, no external testing, no production release.
## Report
build.md with run ids, build number/state, IAP states, what the owner must do (if anything). One commit for the workflow change;
do not push to main; do not edit TASKS.md. Never use git stash/clean.
