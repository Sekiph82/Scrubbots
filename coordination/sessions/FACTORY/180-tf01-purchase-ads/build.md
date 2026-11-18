STATUS: READY

# Build: SB-TF-01 fix StoreKit/Play purchases and make ads fill on TestFlight/internal builds

## Summary
Branch `factory/180-tf01-purchase-ads`, commits `31574aaf` (code + tests) and `ad3a7be3` (CI + docs) on base `d73e5041`.

- Store: a failed purchase now carries the store's own text/code as `error` from the provider through `StoreService.deliver` into `resolved` and the Shop failure text ("The purchase didn't go through. (<code>: <message>)", EN + TR). A refused purchase also returns `error`. Every failed purchase, failed product query and unknown product id prints one device-log line `STORE_ERROR product=.. code=.. msg=..` / `STORE_INVALID_IDS product=..`. `last_error` on the provider holds the newest one. A failed StoreKit product query is retried once. Prices are now also requested once at launch, right after the native store provider is installed.
- Ads: every failed rewarded/interstitial load logs `ADS_LOAD_FAILED kind=.. code=.. msg=..` and schedules one reload after 5 s, then 15 s, then 45 s. The cap is 3 in a row, a successful load resets the count, and after the cap the old lazy reload applies. The timer is injectable (`schedule`). `ADS_INIT_DONE test_units=..`, `ADS_CONSENT_FAILED`, `ADS_ATT_DENIED` are logged, and consent/ATT failures still fall through to init.
- Ad ids: new workflow input `ads_test_mode` (boolean, default `true`) in `ios-ipa.yml` and `android-family-first10.yml`. Real AdMob ids and the missing-secret failure apply only when `ads_test_mode=false` and `build_type=release`. `ads_test_mode=false` with `build_type=debug` fails with `::error::`. The billing_ads check step prints `ads_mode=test|real` and fails if test mode wrote `scrubbots_real_ids.gd` or produced a non-sample app id.
- Booster popup: when no rewarded video is loaded, it now shows `REWARDED_UNAVAILABLE_NOTE` in its Status line. Before, it only hid the video CTA without a message.

Files: `scripts/economy/store_provider.gd`, `scripts/economy/app_store_provider.gd`, `scripts/economy/play_billing_store_provider.gd`, `scripts/economy/store_service.gd`, `scripts/economy/admob_ad_provider.gd`, `scripts/app/main.gd`, `scripts/ui/shop/shop_screen.gd`, `scripts/ui/popup/acquisition_flow.gd`, `scripts/ui/ui_text.gd`, `scripts/ui/ui_text_tr.gd`, `tests/m57_native_providers.gd`, `.github/workflows/ios-ipa.yml`, `.github/workflows/android-family-first10.yml`, `AGENTS.md`, `docs/RELEASE_BUILDS.md`, `docs/PRIVACY_DATA_INVENTORY.md`.

TASKS.md is not touched. The spec (req. 9) says the factory loop updates the SB-TF-01 entry after review.

## Audit (req. 1): StoreKit / Play Billing causes
I read the pinned plugin sources: godot-ios-plugins `caafb2c7` `plugins/inappstore/in_app_store.mm`, GodotGooglePlayBilling 3.3.0 `GodotGooglePlayBilling.kt` / `Utils.kt`, and godot-admob v7.0 `Admob.gd`, `model/AdError.gd`, `LoadAdError.gd`, `FormError.gd`, `config/AdmobExportConfig.gd`, plus `AdmobPlugin.gd`.

Real StoreKit event keys:
- `product_info`: `result` ok|error. On error the only extra key is `error` (localizedDescription). On ok the keys are `ids`, `localized_prices`, `titles`, `descriptions`, `prices`, `currency_codes`, `invalid_ids`.
- `purchase`: `result` ok|error|progress|unhandled, plus `product_id` and `type_code` (SKPaymentTransactionState). On ok it adds `transaction_id` and `receipt`. On error it adds `error` = `transaction.error.localizedDescription`. There is no numeric error code, and the plugin itself finishes failed transactions.
- `restore`: ok|completed|error.

API: `request_product_info({"product_ids"})`, `purchase({"product_id"})` returns Error (`ERR_UNAVAILABLE` when `canMakePayments` is false, `ERR_INVALID_PARAMETER` when the product is not in `loadedProducts`), `finish_transaction(product_id)`, `set_auto_finish_transaction(bool)`, `restore_purchases()`, `get_pending_event_count()`, `pop_pending_event()`.

| Suspect | Verdict | Evidence |
|---|---|---|
| Error text/code dropped on a failed purchase | **Confirmed bug, fixed** | Old `app_store_provider.gd` `elif result == "error": _deliver.call({... "outcome": "failed"})` ignored `e["error"]`, so the player and the log saw nothing. It now passes `error` and logs `STORE_ERROR`. Play's `_on_purchase_updated` dropped `debug_message` the same way and is fixed the same way. |
| Failed product query ignored | **Confirmed bug, fixed** | Old `if result == "ok" and _prices_cb.is_valid():` silently dropped `result == "error"`. It now logs `STORE_ERROR product=*` and retries once (`_info_retried`). Play's `_on_product_details` dropped `response_code != OK` silently and now logs it. |
| `invalid_ids` ignored | **Confirmed bug (diagnostic), fixed** | `invalid_ids` was never read. It now logs `STORE_INVALID_IDS`, and those ids still get no price, so they cannot be bought. Play `unfetched_products` gets the same handling. |
| Refused purchase invisible | **Confirmed bug (diagnostic), fixed** | `purchase()` returned only `== OK`. It now logs `STORE_ERROR code=<Error>` (31 = product not loaded, 2 = payments disabled), and `StoreService.purchase` returns `error`. |
| Product ids / bundle prefix mismatch | **Ruled out in code** | The plugin passes ids verbatim (`initWithUTF8String`). The config ids are `scrubbucks_100/550/1200/2600/7000`, `no_ads` with no bundle prefix, and Apple product ids need none. Whether they exactly match App Store Connect is an owner device check (below). A mismatch now shows up as `STORE_INVALID_IDS`. |
| Purchase before products loaded | **Ruled out** | `StoreService.can_purchase` needs `price_text(id)` non-empty, and a price exists only after a `product_info ok` whose `ids` came from `response.products`. Those are exactly the products added to the plugin's `loadedProducts`. A buy button is therefore never enabled for an unloaded product. |
| `refresh_prices()` never called / before the singleton is ready | **Ruled out for purchases; launch call added** | `shop_screen.gd::_build` calls `store.refresh_prices()` on every Shop open, after `main.gd` installed the provider at boot (the singleton exists from engine start). Prices then arrive async and `prices_changed` triggers `refresh`. Spec req. 4 added one launch call in `main.gd::_install_native_providers` (`economy.store.refresh_prices()`), which is a no-op for the null provider and for a not-yet-connected Play client. |
| Wrong event keys / signals | **Ruled out** | `type`, `result`, `product_id`, `transaction_id`, `type_code`, `ids`, `localized_prices` match the .mm. Play signals `connected`, `disconnected`, `query_product_details_response`, `query_purchases_response`, `on_purchase_updated` and `response_code` / `debug_message` / `product_details` / `unfetched_products` match the .kt. |
| Missing `finish_transaction` | **Ruled out** | Auto-finish is off. A purchased tx is kept in `pendingTransactions[productIdentifier]` and finished by `acknowledge(token)` -> `finish_transaction(_tx[token])` (product id, as the plugin keys it) after the grant is saved. Failed and restored transactions are finished by the plugin itself. |
| Restore | **Ruled out** | `restore` ok rows are collected, and `completed` / `error` both call back once. |
| iOS user cancel shows the failure text | **Known limitation (not fixable in GDScript)** | The pinned plugin reports `SKErrorPaymentCancelled` as `result=error` with only a localized message and no code, so a cancel cannot be told apart from a real failure. It still shows the failure popup, now with the store's message. A real fix needs a plugin change, which is out of scope. |

Conclusion on the owner's "purchase didn't go through": the button is enabled only with a StoreKit price, so the product was loaded. The failure therefore came from StoreKit itself: either a failed transaction (the most likely), or `ERR_UNAVAILABLE` / `ERR_INVALID_PARAMETER` from `purchase()`. The integration dropped the reason, so it could not be diagnosed. The next TestFlight build shows the reason in the popup and in the `STORE_ERROR` log line. Typical StoreKit causes (sandbox account, Paid Apps Agreement, product metadata state) are listed under Owner device checks.

Ads ("never show"):
- **Confirmed cause, fixed:** every `build_type=release` build, including TestFlight, wrote `scrubbots_real_ids.gd` and `is_real=true` with the real app id. A new unpublished AdMob app gets no or very low fill, and failed loads were silent with no retry. The fix is `ads_test_mode` (default true) plus `ADS_LOAD_FAILED` logs and the bounded retry.
- **Ruled out:** a test-mode build still requesting real units. With no ids file, `AdmobAdProvider` never sets `is_real` (test n09). With `is_real=false`, `AdmobExportConfig`/`AdmobPlugin.gd` writes the `[Debug]` sample app id into the manifest / Info.plist.
- **Ruled out:** the consent / ATT ordering. `update_consent_info` -> form if REQUIRED -> ATT on iOS -> `initialize`. Failures still init (n06).
- **Fixed, with the dismissed-close check:** the godot-admob `consent_form_dismissed` always passes a `FormError`, and an empty message means a normal close. Only a non-empty message is logged as `ADS_CONSENT_FAILED`.

## Rewarded callers (AC 8)
Command: `grep -rn "start_rewarded\|rewarded.request\|rewarded.begin" scripts`, plus `rewarded.start` / `_start_rewarded`. Every caller shows a message on `unavailable` / `failed`:

| Caller | unavailable / not ready / load failed | failed (show failed) / timeout |
|---|---|---|
| `scripts/ui/daily/rewarded_ads_screen.gd::_watch` (`app.actions.start_rewarded_daily`) | Slot row shows `RADS_STATE_UNAVAILABLE` + button `RADS_NO_VIDEO` (blocked). On a refused start the note shows `_reason_text("unavailable"/"provider_refused")` = `REWARDED_UNAVAILABLE_NOTE`. | `_outcome` -> `_reason_text("failed")` = `REWARDED_NO_GRANT` + `REWARDED_REASON_FAILED`; timeout -> `REWARDED_NO_GRANT` + `REWARDED_REASON_TIMEOUT` |
| `scripts/ui/popup/acquisition_flow.gd` Heart popup `"watch"` -> `_start_rewarded(HEART)` | `_refresh_life`: `watch` blocked, text `REWARDED_UNAVAILABLE` ("NO VIDEO"), RewardedNote `REWARDED_UNAVAILABLE_NOTE`. A refused start gives Status `REWARDED_UNAVAILABLE_NOTE`. | `_apply_reward_outcome` -> Status `REWARDED_NO_GRANT` + reason |
| `acquisition_flow.gd` Need a Hand `"watch:<id>"` -> `_start_rewarded(booster)` | `_refresh_nah`: blocked + card Note `NAH_AD_UNAVAILABLE`. A refused start gives Status `REWARDED_UNAVAILABLE_NOTE`. | Status `REWARDED_NO_GRANT` + reason |
| `acquisition_flow.gd` Booster popup `"watch"` -> `_start_rewarded(booster)` | **Was silent** (CTA hidden, no text). Now, with no charge and reason `unavailable`, Status shows `REWARDED_UNAVAILABLE_NOTE` (only when Status is empty, so it never overwrites a result). A refused start gives Status `REWARDED_UNAVAILABLE_NOTE`. | Status `REWARDED_NO_GRANT` + reason |
| `scripts/economy/production_action_facade.gd::start_rewarded` / `start_rewarded_daily` | Service layer, no UI. It returns `{ok:false, reason}` to the callers above. | Same |

No new UiText key was needed for the rewarded texts. `SHOP_STORE_FAILED_DETAIL` is the only new key (EN `ui_text.gd`, TR `ui_text_tr.gd`).

## Acceptance criteria
1. [x] `m57_native_providers` exact case count: `"$GODOT" --headless --path . -s res://tests/m57_native_providers.gd` -> exit 0, 0 `SCRIPT ERROR`/`Parse Error`, 0 `FAIL` lines, last line `M57 native providers evidence: PASS (14/14 cases, 0 fail)`. All 14 `EXPECTED_CASES` (n01..n14) ran once through the case ledger. `grep -rn "9/9" .github tests/m57_native_providers.gd | grep -i native` prints nothing. The CI guard at `android-family-first10.yml` now reads `PASS (14/14 cases, 0 fail)`, and the old header comment's "exact 9/9 guard" text was replaced.
2. [x] StoreKit error event (n10): `{type:"purchase", result:"error", product_id:"scrubbucks_100", error:"Cannot connect to iTunes Store", error_code:0}` -> `resolved` `ok=false`, `reason="failed"`, `error="0: Cannot connect to iTunes Store"`. Wallet and applied-tx count are unchanged, and `can_purchase("scrubbucks_100").ok` is true again. The suite also covers a code-less plugin event (`error` = message), a refused purchase (`provider_refused`, `error="31: purchase refused"`), Play `6: Server error`, and Play cancel without `error`.
3. [x] invalid_ids (n11): `invalid_ids=["scrubbucks_100"]` -> `price_text("scrubbucks_100")==""` (others priced), `last_error=="unknown to App Store Connect"` and the log line `STORE_INVALID_IDS product=scrubbucks_100 ...`. A `product_info` error gives `last_error` set, exactly one retry (2 `info` calls), and the retry prices the products. Repeated errors still give only 2 requests. Play `unfetched_products` is recorded too.
4. [x] Rewarded load retry (n12, fake `schedule`): 3 consecutive `rewarded_ad_failed_to_load` -> 3 scheduled retries with delays `[5.0, 15.0, 45.0]`, each firing exactly one reload. The 4th failure schedules none. `rewarded_ad_loaded` -> `is_available("x")` true, and the next failure schedules 5 s again (counter reset). `is_available` stays false while in `retry`. n07/n08 now assert one backoff retry and no immediate reload, and the interstitial timer firing reloads it.
5. [x] `m57_store_products.gd` -> `M57 store products evidence: PASS (9/9 cases, 0 fail)` (exit 0). `m57_ads_cadence.gd` -> `M57 ads cadence evidence: PASS (6/6 cases, 0 fail)` (exit 0).
6. [x] UiText parity: `tests/m51_localization_readiness.gd` (EN/TR key parity, imports `ui_text_tr`) -> `M51 localization readiness evidence: PASS (8/8 cases, 0 fail)`. The new key `SHOP_STORE_FAILED_DETAIL` is in both `scripts/ui/ui_text.gd` and `scripts/ui/ui_text_tr.gd`.
7. [x] Shop failure text (n14, real `ShopScreen._feedback` + `Popups.feedback` Body label): with an error the text is `The purchase didn't go through. (0: Cannot connect to iTunes Store)`. With no error it is the plain `SHOP_STORE_FAILED`. Pending is unchanged. TR gives `Satın alma tamamlanmadı. (2: purchase refused)` and plain `Satın alma tamamlanmadı.`. Cancel and duplicate stay silent (unchanged `_on_store_resolved` filter; `m57_store_products` c08 "cancel: silent" passes). Choice: the detail shows whenever the store sent one. Only a native store (billing_ads builds = TestFlight / internal) ever sends `error`, and the null provider never does. The spec's assumption allows this.
8. [x] Rewarded callers are listed above, and none is silent. The booster popup gap is fixed and checked in n13.
9. [x] Workflows: `grep -n ads_test_mode` finds the input with `default: true` in both files. The real-ids branch is `if [ "$ADS_TEST_MODE" != true ] && [ "$BUILD_TYPE" = release ]`, and a debug + `ads_test_mode=false` run fails with `::error::`. Both files parse: `python -c "import yaml; yaml.safe_load(open(f))"` gives OK for both, and the parsed input is `{'type': 'boolean', 'default': True}`. A `git diff` scan for `ca-app-pub-`, `.p8` and `BEGIN .*KEY` finds only Google's public sample app ids, which already existed in context lines. No secret or real id is in the diff.
10. [x] `git diff --check` over the 16 changed files is clean (`DIFFCHECK_OK`). `"$GODOT" --headless --path . --quit` exits 0 with 0 `SCRIPT ERROR`/`Parse Error` lines.
11. [x] Docs: `ads_test_mode` is in `AGENTS.md` (ads paragraph; the store paragraph also notes the error detail and `STORE_ERROR`) and in `docs/RELEASE_BUILDS.md` (new "Ads test mode" paragraph, real ids only with `ads_test_mode=false` + release, how to read `STORE_ERROR` / `STORE_INVALID_IDS` / `ADS_*` in the device log). `docs/PRIVACY_DATA_INVENTORY.md` l.34 now reads "Google TEST ad units in every build with `ads_test_mode=true` (default, incl. TestFlight / internal testing); the owner's real ids only in a release build with `ads_test_mode=false`".
12. [x] Causes are listed above as confirmed or ruled out, and the Owner device checks section is below. No device result is claimed.

## Owner device checks (not done here; need the iPhone / App Store Connect)
None of these was run or claimed. They need a new TestFlight build (`ios-ipa.yml`, `build_type=release`, `billing_ads=true`, `testflight_upload=true`, `ads_test_mode` left at its default `true`), which only happens with the owner's OK.
1. A Sandbox Apple Account (App Store Connect > Users and Access > Sandbox) is signed in on the iPhone (Settings > App Store > Sandbox Account / Developer > Sandbox Apple Account).
2. The Paid Apps Agreement is Active (App Store Connect > Business), with tax and banking complete.
3. The six product ids in App Store Connect exactly match `scrubbucks_100`, `scrubbucks_550`, `scrubbucks_1200`, `scrubbucks_2600`, `scrubbucks_7000`, `no_ads` (case-sensitive, no bundle prefix), with type Consumable x5 / Non-Consumable x1 and state READY_TO_SUBMIT (fine for TestFlight sandbox). Any mismatch now shows as `STORE_INVALID_IDS` in the device log and as a missing price in the Shop.
4. A Shop purchase shows the sandbox payment sheet, grants once (+N Scrub Bucks / No Ads), and a relaunch does not grant again.
5. A rewarded test video ("Test Ad" label) plays from the Rewarded Ads screen, the Heart popup and Need a Hand, and grants once. With no fill, the "Free videos aren't available right now." note shows. The device log shows `ADS_INIT_DONE test_units=true`, plus `ADS_LOAD_FAILED ...` if loads fail.
6. If a purchase still fails: the popup now reads "The purchase didn't go through. (<detail>)". Note the detail text and the `STORE_ERROR ...` line from the device console (Xcode > Devices and Simulators > Open Console, filter `STORE_`).

## Validation
All LOCAL_PASS with Godot 4.7.2 (`C:/Users/sekip/AppData/Local/Microsoft/WinGet/Links/godot.exe`, headless). Each suite exited 0 with 0 `SCRIPT ERROR` / `Parse Error`:
- `tests/m57_native_providers.gd`: `M57 native providers evidence: PASS (14/14 cases, 0 fail)`. The exit-time "ObjectDB instances leaked" / "42 resources still in use" warnings were already there at base (the 9/9 version prints the same lines).
- `tests/m57_store_products.gd`: `M57 store products evidence: PASS (9/9 cases, 0 fail)`
- `tests/m57_ads_cadence.gd`: `M57 ads cadence evidence: PASS (6/6 cases, 0 fail)`
- `tests/m51_localization_readiness.gd`: `M51 localization readiness evidence: PASS (8/8 cases, 0 fail)`
- `tests/m43_master_c006_shop.gd`: `M43 master C006 Shop evidence: PASS (15/15 cases, 0 fail)`
- `tests/m43_c003_c001_acquisition.gd`: `M43-C003-C001 acquisition evidence: PASS (34/34 cases, 0 fail)`
- `tests/m49_ad_store_return_layout.gd`: `M49 ad/store return layout evidence: PASS (6/6 cases, 0 fail)`
- `tests/m46_r07_ui_legality.gd`: `M46 R07 UI LEGALITY: PASS`
- `tests/m50_accessibility_audit.gd`: `M50 accessibility audit evidence: PASS (11/11 cases, 0 fail)`
- `tests/m58_privacy_inventory.gd`: `M58 privacy inventory evidence: PASS (7/7 cases, 0 fail)`
- `tests/m60_release_gates.gd`: `M60 release gates evidence: PASS (6/6 cases, 0 fail)`. Its gate report prints `FAIL SB-M60-006`, a verdict row (the TASKS.md M49..M59 regression aggregate) that this job does not touch. It is not a test failure.
- `godot --headless --path . --quit`: exit 0, no script errors
- YAML parse of both workflows: OK
- `git diff --check` on the changed files: clean

No CI run was dispatched (no APK/IPA build per the job rules). The CI guard for the new count is in `android-family-first10.yml`.

## Log
### Round 1
- Read the pinned inappstore, Play Billing 3.3.0 and godot-admob v7.0 sources (fetched read-only into the session scratchpad) and audited the full StoreKit / Play / AdMob flow (table above).
- Added `last_error` + `_diag` to the StoreProvider base. AppStore/Play providers pass `error`, log `STORE_ERROR` / `STORE_INVALID_IDS`, and AppStore retries a failed product query once. StoreService forwards `error` in `deliver` / `resolved` and in `provider_refused`. `main.gd` refreshes prices once at launch.
- Shop failure text gets the detail via the new `SHOP_STORE_FAILED_DETAIL` (EN + TR). The booster popup no longer hides the video CTA silently.
- AdmobAdProvider: `ADS_*` logs, bounded 5/15/45 s retry with an injectable `schedule`, and a `retry` state so `is_available` never reloads early. A normal consent-form close is not logged as a failure.
- Workflows: `ads_test_mode` input (default true), real ids only with release + `ads_test_mode=false`, debug + false is rejected, the check step prints `ads_mode`. Docs updated.
- Tests: `m57_native_providers` grew 9 -> 14 cases (n10..n14), n07/n08/n09 adjusted to the retry/test-mode behaviour, and the CI guard was bumped to 14/14.
- Godot import artefacts (about 385 untracked `.import`, 708 `.uid` and 27 docs `.translation` files, modified tracked `.import` files and a `project.godot` key reorder) come from the pre-done import and the headless runs. They were NOT committed, and I left them in the worktree on purpose: reviewers re-running the suites need the import state. So `git status --porcelain` is not empty, but every job change is committed (`31574aaf`, `ad3a7be3`). The worktree is deleted when the job ends.
