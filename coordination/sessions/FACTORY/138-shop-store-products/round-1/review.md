# Review round 1: 138-shop-store-products

## Checks
- git diff --check: pass
- m57_store_products: PASS 9/9
- m43_master_c006_shop: PASS 15/15
- m43_c003_c001_acquisition: PASS 34/34
- m40_save_system: PASS
- m60_release_gates: PASS 6/6 (001-004 PASS, 005/006 FAIL as before)

Verified: exact owner IDs/amounts, reference_usd never read by code, prices only from the provider string, null provider default grants nothing, grants only on purchased+token via RewardGrantService `store:<token>`, cancel/fail/pending grant nothing, No Ads persisted in a backward-compatible strict `store` section, restore re-applies No Ads only, ads_allowed keeps rewarded, Home banner collapse wired safely, UI never mutates economy, EN/TR keys added.

## Must-fix
1. scripts/economy/store_service.gd deliver(), duplicate branch: after a failed save, the re-delivery returns "duplicate" (the tx is already in the in-memory ledger), `saved` stays true, and the purchase is acknowledged/consumed WITHOUT any save. If the app dies before another save, the player has paid and the grant is lost, and the store will not redeliver. Test c07 (tests/m57_store_products.gd ~line 203) asserts exactly this unsafe behaviour. Fix: on duplicate, also run `_save_cb` and set `saved` from its result before acknowledging. A duplicate with no save callback may acknowledge. Extend c07 to fail the save on the re-delivery too (still no ack) and then succeed (ack, no second grant).

## Notes (non-blocking)
- Same pattern in `_on_restore`: the result of the save is returned but not acted on. That is acceptable because restore has nothing to acknowledge.
- Add m57_store_products to CI: yes, with the exact `9/9` guard (it is a pure headless suite, about 1 minute).
- `_unbind_store` disconnects three signals on popup close; fine, as long as `popup.closed` fires once (CONNECT_ONE_SHOT).

VERDICT: CHANGES
