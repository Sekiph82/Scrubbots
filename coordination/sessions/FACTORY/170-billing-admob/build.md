STATUS: READY

# Build: 170-billing-admob (SB-M57-014..016 + SB-M57-022) real purchases + real ads

## Summary
Branch `factory/170-billing-admob` connects real Google Play Billing (Android), StoreKit (iOS) and
Google AdMob (Android + iOS) to the existing provider seams. It uses free MIT plugins only. The
plugins go into a build only when the new workflow input `billing_ads` is set (default `false`, so a
default build is unchanged). Editor, desktop and headless runs keep the null providers, so every
suite stays on mocks. AdMob requests only Google TEST ad units (`is_real = false`, Google's sample
app ids). No live ids, no prices and no rewards were changed, and no placement was added.

- `scripts/economy/play_billing_store_provider.gd` (new): StoreProvider over the
  `GodotGooglePlayBilling` singleton. It connects, queries product details (the store's
  `formatted_price` is shown verbatim) and starts the purchase. A grant happens only when
  `purchase_state == PURCHASED`; PENDING grants nothing. USER_CANCELED maps to cancelled and any
  other error to failed. SB packs are consumed and No Ads is acknowledged, in both cases after the
  grant is saved. At launch, `queryPurchases` re-delivers unacknowledged PURCHASED purchases. Restore
  uses `queryPurchases`.
- `scripts/economy/app_store_provider.gd` (new): StoreProvider over the godot-ios-plugins
  `InAppStore` singleton. Auto-finish is OFF, and the transaction is finished only in
  `acknowledge()` after the saved grant, so StoreKit re-delivers an interrupted purchase. The
  token is the transaction id. Deferred (Ask to Buy) maps to pending and an error to failed. Restore
  collects the `restore` events until `completed`. `main.gd` polls the plugin's event queue every
  0.25 s.
- `scripts/economy/admob_ad_provider.gd` (new): AdProvider over the plugin's `Admob` node. The order
  is fixed: Google UMP `update_consent_info`, then the consent form only when the status is
  REQUIRED, then on iOS the ATT prompt, then `initialize`, and only then the loads. The banner sits
  at the bottom, anchored to the safe area, and follows `AdService.update_banner()` (No Ads hides
  it). An interstitial shows only when one is loaded; otherwise the provider loads one and
  AdService keeps the ad due. A rewarded ad reports `completed` + verified only when the SDK's
  earned-reward callback arrived before the ad closed. Closing early is `cancelled` and a failed show
  is `failed`. The existing placements and RewardedGrantService rules are unchanged.
- `scripts/app/main.gd`: `_install_native_providers()` sets these providers only when
  `Engine.has_singleton(...)` is true. For AdMob it also checks that `res://addons/AdmobPlugin/Admob.gd`
  exists.
- `tests/m57_native_providers.gd` (new, 8 cases): the real adapters driven by fake native backends
  that have the plugins' method, signal and event shapes.
- `.github/workflows/android-family-first10.yml`: new input `billing_ads` and one step that
  downloads the billing and AdMob zips, checks their sha256 and unpacks them. The step also writes
  `android_export.cfg`, turns on the Gradle build, unpacks `android_source.zip` into
  `android/build` and enables the two editor plugins. A second step checks the APK manifest after
  the export.
- `.github/workflows/ios-ipa.yml`: new input `billing_ads` and one step. It handles the AdMob zip
  (sha256), builds `inappstore` from a pinned commit against the Godot 4.7.2-stable headers, writes
  `ios_export.cfg` (ATT text), installs the `xcodeproj` gem for the system Ruby (the AdMob export
  plugin adds GoogleMobileAds through SPM) and enables the plugins in the preset. A post-build step
  checks the linked app binary and Info.plist.
- `docs/RELEASE_BUILDS.md`, `docs/PRIVACY_DATA_INVENTORY.md`, `AGENTS.md`: the input, the pinned
  plugins, the permissions and plist keys these builds add, and the owner steps.

### Plugins (official GitHub releases / source, all MIT, free)
| Plugin | Version | URL | sha256 / pin |
|---|---|---|---|
| GodotGooglePlayBilling (godot-sdk-integrations) | 3.3.0 (Play Billing `billing-ktx` 9.1.0) | https://github.com/godot-sdk-integrations/godot-google-play-billing/releases/download/3.3.0/godot-google-play-billing.zip | `20d75623d6f337f08d8283c83098b73678d5f575e39247af5a8eb80588b18568` (matches the GitHub release digest) |
| Godot AdMob plugin (godot-sdk-integrations/godot-admob) | v7.0 (play-services-ads 24.9.0, iOS GoogleMobileAds SPM 12.14.0) | https://github.com/godot-sdk-integrations/godot-admob/releases/download/v7.0/AdmobPlugin-Multi-v7.0.zip | `d96e1734b889434c0a77f0bafe2f09f4cdb9e5b518b9d6809757b251a17cf8a2` (matches the release digest) |
| godot-ios-plugins `inappstore` (godot-sdk-integrations, official) | master (no 4.x binary release exists) | https://github.com/godot-sdk-integrations/godot-ios-plugins | commit `caafb2c7fbfb5c72a64f163c76449274fa49abaa`, built against godotengine/godot tag `4.7.2-stable` = `ed1daf0bf001b61586d9930840f2f1394092c079` |

I rejected godot-storekit2 v0.2 (official, MIT). It exposes no transaction id, so a grant could
not be made idempotent. It also finishes the transaction before the app can save the grant, and it
is built only for Godot 4.6.

### Product table (from `data/config/store_products_v1.json`; the same ids in Play Console and App Store Connect)
| Product id | Type | Price tier (reference USD, set in the console; the game shows only the store's localized string) | Grants |
|---|---|---|---|
| `scrubbucks_100` | consumable | 0.99 | +100 Scrub Bucks |
| `scrubbucks_550` | consumable | 4.99 | +550 Scrub Bucks |
| `scrubbucks_1200` | consumable | 9.99 | +1200 Scrub Bucks |
| `scrubbucks_2600` | consumable | 19.99 | +2600 Scrub Bucks |
| `scrubbucks_7000` | consumable | 49.99 | +7000 Scrub Bucks |
| `no_ads` | non-consumable | 4.99 | No Ads entitlement: removes the bottom banner and the every-5-plays interstitial; rewarded videos stay |

Play Console: all six are one-time in-app products ("consumable" is decided in code: packs are
consumed, `no_ads` is only acknowledged). App Store Connect: the five packs are Consumable and
`no_ads` is Non-Consumable.

### Owner-only steps (not done; need the owner's accounts)
1. AdMob: create the AdMob account and one app per platform (Android `com.sekiphayit.scrubbots`, iOS
   `com.sekiph82.scrubbots`). Create the ad units: banner, interstitial and rewarded per platform.
   Then a later job sets the real app ids in `android_export.cfg` / `ios_export.cfg` (workflow
   steps), `is_real = true` and the real unit ids on the Admob node, injected from GitHub Secrets,
   never committed. Configure the UMP / GDPR consent message (Privacy & messaging) in AdMob, and the
   IDFA explainer if wanted.
2. Google Play: complete the Payments merchant profile in Play Console. Then create the six
   products above. Real test purchases need a build uploaded to an internal test track (the plugin
   works only for an app installed from Play) and license testers.
3. Apple: accept the Paid Apps agreement (banking + tax) in App Store Connect. Then create the six
   products (5 Consumable + 1 Non-Consumable) with their review screenshots, and a sandbox tester for
   StoreKit tests.
4. Product creation in both consoles uses the table above. Prices are set per tier in the
   consoles; the game never formats a price.

## Acceptance criteria
1. [x] Android Google Play Billing provider (query, purchase, acknowledge/consume, restore via
   queryPurchases, pending; grant only on a verified PURCHASED state, idempotent):
   `play_billing_store_provider.gd`. `m57_native_providers` cases n02/n03/n04 PASS. Real plugin
   build: see criterion 5.
2. [x] iOS StoreKit provider (products, purchase, restore, transaction finish):
   `app_store_provider.gd` over the official inappstore plugin. n05 PASS. The plugin was built and
   linked in CI iOS run 44076280937 (`** BUILD SUCCEEDED **`, app binary contains `InAppStore`).
3. [x] AdMob ads at the existing placements only, UMP before ads, iOS ATT, Google TEST ids,
   no new placement or reward change: `admob_ad_provider.gd`. n06/n07/n08 PASS. The iOS app binary
   contains `GADMobileAds` and `UMPConsentInformation`; Info.plist `GADApplicationIdentifier` =
   `ca-app-pub-3940256099942544~1458002511` (Google sample) and `NSUserTrackingUsageDescription` is
   present (run 44076280937, step "StoreKit + AdMob linked into the app").
4. [x] Product table: above, taken from `store_products_v1.json` unchanged.
5. [x] Export wiring; debug/apk_only and ios builds still succeed:
   - iOS `billing_ads=true`: run 44076280937 success (IMPORT_GATE PASS, BUILD SUCCEEDED,
     PCK_SCAN files=3166 forbidden=0 missing=0 verdict=PASS, headless boot clean).
   - iOS default: run 44077148479 success (BUILD SUCCEEDED, PCK_SCAN verdict=PASS).
   - Android `apk_only` debug `billing_ads=true`: run 44108551008 success. Both zips passed
     `sha256sum -c` (OK). The Gradle export succeeded, with PCK_SCAN files=3164 forbidden=0
     missing=0 verdict=PASS, APK_SCAN forbidden_total=0, apksigner `Verifies` and a clean headless
     boot. The manifest has `org.godotengine.plugin.v2.GodotGooglePlayBilling`,
     `org.godotengine.plugin.v2.AdmobPlugin`, `com.android.vending.BILLING` and
     `com.google.android.gms.ads.APPLICATION_ID` = `ca-app-pub-3940256099942544~3347511713`
     (Google sample).
   - Android default (`billing_ads=false`): not dispatched separately. It runs the same steps
     minus the two `if: billing_ads` steps, and its only code difference is GDScript that the runs
     above packed and booted. The shared `android-family-first10` concurrency group was saturated
     (each Android run waited 1-2 h). Re-run it if a separate green run is wanted.
6. [x] Tests: `tests/m57_native_providers.gd` LOCAL_PASS `M57 native providers evidence: PASS (8/8
   cases, 0 fail)`, exit 0, no SCRIPT ERROR / Parse Error. Cases: purchase grants once, restore,
   cancel, pending, rewarded completion grants once, ad failure grants nothing, consent order,
   No Ads. Full CI suite list (`python tools/run_suites.py`, 96 suites): 95/96 PASS; the one FAIL
   was `m46_performance` (timing: `retry() on 59x59 worst 77.59 ms <= 50.1` while CI watchers and
   other Godot processes were running). The rerun alone PASSED 22/22. `m59_app_version`,
   `m60_release_gates` and `m58_privacy_inventory` were rerun after the doc edits: PASS.

## Validation
- `godot --headless --path . -s res://tests/m57_native_providers.gd`: PASS 8/8 (LOCAL_PASS).
- `python tools/run_suites.py` (full CI list): 95/96, plus m46_performance rerun PASS 22/22.
- `python tools/run_suites.py m58_privacy_inventory m60_release_gates m57_store_products
  m57_ads_cadence`: 4/4 PASS. `m46_performance m59_app_version m60_release_gates
  m58_privacy_inventory`: 4/4 PASS.
- `python -I tools/check_release_versioning.py`: PASS (0 problems).
- `git diff --check` on the changed files: clean. Both workflows parse as YAML (`yaml.safe_load`).
- CI on `factory/170-billing-admob`: see criterion 5.

## Notes for review / follow-ups
- I did not add `m57_native_providers` to the validate suite list: the caller asked me to keep
  workflow edits to the plugin steps (job 168 edits the same workflow). Add it with an exact
  `M57 native providers evidence: PASS (8/8 cases, 0 fail)` guard after the merge.
- I found an existing bug. The `local_notifications` Android step runs
  `--install-android-build-template` alone, which starts the editor and never exits (Godot 4.7.2
  `main.cpp` only uses the flag together with `--export-*`). That path was never verified and would
  hang. My step unpacks the template instead.
- I found a second existing gap. The iOS "Xcode build" step pipes xcodebuild into `tail`, and the
  shell has no pipefail, so a failed link still passes the step (my first iOS run had a link error
  and was still green). My `billing_ads` check step catches it for these builds; default builds
  still rely on the PCK checks.
- Not verified: a device run (consent form, ATT prompt, test ads, a sandbox purchase). That needs
  the owner steps above and a phone install.
- There are several commits instead of one: CI fixes went in as new commits because force-push
  is denied. Squash on merge if one commit is wanted. The commits on the branch: a5be51a5 (code),
  4a78fa71, 7a46dce4, c28432aa and 24c03f7c (workflow fixes), 60aa51a8 and a50cf657 (docs).
- In `billing_ads` APKs, Google Mobile Ads also merges the ADSERVICES_*, WAKE_LOCK and
  FOREGROUND_SERVICE permissions. `docs/PRIVACY_DATA_INVENTORY.md` lists them. The Play Data
  safety form must be updated before an ads build ships.
- The worktree still holds Godot import churn from the local suite runs (`*.import`, `*.uid`,
  `*.translation`, `project.godot`). Reverting it was denied by the permission classifier. All job
  work is committed; the churn disappears with the worktree.

## Merge prep (after review PASS)
- Branch `factory/170-billing-admob-r2` holds the rebase onto origin/main. It is a new branch
  because force-push is not allowed. android-family-first10.yml conflicted with job 168
  (aab_release). I kept both sides; 174's suites merged cleanly.
- `billing_ads` also works with `mode=aab_release`. The manifest check reads `$CHECK_APK`
  (bundletool's universal APK for an AAB).
- `m57_native_providers` is in the validate list with an exact guard, now
  `M57 native providers evidence: PASS (9/9 cases, 0 fail)`.
- I fixed a bug that came from main: in the APK summary step,
  `cat out/aab_cert.txt out/aab_manifest.txt` failed every apk-mode run. The fix is `|| true`.
- Real AdMob ids (coordinator request): a `billing_ads` + `build_type=release` build reads
  `ADMOB_{ANDROID,IOS}_{APP,BANNER,INTERSTITIAL,REWARDED}_ID` from GitHub Secrets. It fails with
  a `::error::` naming the secret when any of the four for its platform is missing. The ids are
  written only into the CI workspace: the cfg files get `is_real=true`, and the generated
  `addons/AdmobPlugin/scrubbots_real_ids.gd` makes `AdmobAdProvider` switch the node to the real
  units. Nothing is echoed. The post-build check asserts the Google sample app id is ABSENT in
  release and PRESENT in debug, and it no longer prints the app id. A scrub step (`if: always()`)
  replaces the real app id in the uploaded text logs, because the AdMob export plugin logs it.
  Debug and test builds keep Google's TEST ids. New test case n09 covers this.
  `m57_native_providers` LOCAL_PASS 9/9.
- The Android release package is now `com.sekiphayit.scrubbots` (`com.sekiph82.scrubbots` is taken
  on Play). I changed it in the workflow and in `docs/RELEASE_BUILDS.md`. The debug package
  `com.sekiph82.scrubbots.familydev` and the iOS bundle id `com.sekiph82.scrubbots` are unchanged
  (ios-ipa.yml untouched). No test or check pins the Android release package;
  `check_release_versioning.py` PASS.

### Final merge branch: `factory/170-billing-admob-r3` @ 36b1f64a
r2 (891e606e) was rebased onto origin/main @ 4658c2f8 so it includes db37c926, main's fix for the
`m43_c001a` "economy untouched" failure, which reproduced on r2 locally and in CI. I pushed it as
a new branch because force-push is not allowed.
- validation_only: run 44134603570 success. validate success with `M57-NATIVE verdict=PASS (9/9)`;
  clean_clone success.
- apk_only debug + billing_ads: run 44134628219 success. "AdMob ids: Google TEST"; PCK_SCAN
  verdict=PASS; APK_SCAN forbidden_total=0; `billing_ads manifest check PASS (build_type=debug,
  Google test app id=yes)`; "APK signature / metadata / hash" success.
- Earlier on r2: iOS debug + billing_ads run 44126671386 success (BUILD SUCCEEDED; "billing_ads
  app check PASS"); apk_only run 44128992754 success at 891e606e.
- Local on r3: `m43_c001a_results_foundation` PASS 11/11; `m57_native_providers` PASS 9/9.
- Not run: a release build (aab_release / iOS release), so the real-id path and the
  missing-secret failure have not run in CI.

## Log
### Round 1 (merge prep)
The rebase, the aab wiring, the validate guard, the summary-step fix and the real-id injection are
described above. The real-id path has not run in CI: it needs a release build, and a run with the
real ids was not requested.

### Round 0
I read the provider seams, the economy config and the CI workflows, then picked and checked the
plugins (license, release digests). I wrote the three providers, the main.gd install and the
fake-backend suite, then wired both workflows and the docs. CI iterations: a YAML fix (a heredoc
for the cfg files); iOS needed the generated Godot headers (`gdextension_interface.gen.h` etc.); the
system Ruby needed the xcodeproj gem, without which the GoogleMobileAds SPM step failed and the link
failed; Android hung on the template-install flag, so I unpacked the template instead. A queued
Android run was cancelled by the shared concurrency group and re-dispatched. After the green Android
run I added the merged permissions to the privacy inventory (a50cf657); `m58_privacy_inventory`
rerun: PASS 7/7.
