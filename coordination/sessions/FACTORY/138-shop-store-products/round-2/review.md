# Review round 2: 138-shop-store-products

## Checks
- git diff --check: pass
- m57_store_products: PASS 9/9
- m43_master_c006_shop: PASS 15/15
- m60_release_gates: PASS 6/6 (001-005 PASS, 006 FAIL as before)

## Verified
- store_service.deliver(): for every purchased delivery, including duplicates, `_save_cb` runs and `acknowledge` is called only if the save succeeded. It is the only call site of `acknowledge` (grep). Cancel/fail/pending/unknown/no-token never save or ack. A duplicate without a save callback acknowledges, which is fine.
- c07 asserts the safe sequence: failing save, so no ack; duplicate re-delivery with a failing save, so the save is retried, still no ack, no second grant; later successful save, so ack and no second grant; a non-purchased delivery never saves or acks.
- CI: m57_store_products appended to the validate loop plus the exact `M57 store products evidence: PASS (9/9 cases, 0 fail)` guard; the diff only appends to the list (the other 83 suites are unchanged) and adds the guard.
- PRIVACY_DATA_INVENTORY save row: the only change is the added "No Ads entitlement flag; once a store provider exists, applied purchase tokens as store:<token>..." sentence; the rest of the row is intact.

## Must-fix
None.

VERDICT: PASS
