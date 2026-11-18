APPROVE — SB-TF-01 (factory 180-tf01-purchase-ads), round 1 reviewer-code VERDICT: PASS (CLAUDE_PEER_REVIEW).
Store errors now surfaced (STORE_ERROR / STORE_INVALID_IDS logs + SHOP_STORE_FAILED_DETAIL), product query retry; ads_test_mode workflow input (default true, real AdMob ids only with false + release), AdMob load retry 5/15/45 s x3 with ADS_* logs, rewarded-unavailable note in booster popup.
LOCAL_PASS: m57_native_providers 14/14, m57_store_products 9/9 (re-run by reviewer), plus suites listed in build.md.
Known limit: iOS user cancel still shows failure popup (plugin reports cancel as error). Owner device checks pending (sandbox purchase, test rewarded video) on the next batched TestFlight/APK build.
