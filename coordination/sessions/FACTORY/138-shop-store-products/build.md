STATUS: READY

# Build: Shop store products (SB-M57-012, SB-M57-013, SB-M43-081, SB-M43-084, provider-independent part)

## Summary
Branch `factory/138-shop-store-products`, rebased onto origin/main c1e1560b, 6 commits, not pushed:
- bdd4d84f store seam
- 4902aa73 Shop UI
- 248f218a docs/tasks
- 77de31c4 save before acknowledging a duplicate re-delivery (review fix)
- 8fd09be8 CI validate + release gates evidence
- 77a88a87 TASKS hashes

- `data/config/store_products_v1.json` (new): the owner's five SB packs `scrubbucks_100/550/1200/2600/7000` (100/550/1200/2600/7000 SB) plus `no_ads` (non-consumable). `reference_usd` is metadata only and is never read by code.
- `scripts/economy/store_provider.gd` (new): the provider contract (`is_available`, `query_products(ids, deliver)` returning localized price strings, `purchase(id, deliver)`, `restore(deliver)`, `acknowledge(token, consume)`). The base class is the null provider and the shipping default, so everything is UNAVAILABLE. This follows the RewardedAdProvider pattern.
- `scripts/economy/store_service.gd` (new): the one grant authority.
  - It grants through RewardGrantService under `store:<token>`, so each token grants exactly once (double callback, relaunch, import).
  - Only outcome `purchased` with a token grants. Every purchased delivery, a new grant or a duplicate re-delivery, is saved before it is acknowledged; if that save fails, the purchase stays unacknowledged.
  - No Ads is a saved entitlement (economy section `store`; a save without the section means no entitlement, a bad section fails closed).
  - `restore()` re-applies No Ads only.
  - The ad-decision seam is `ads_allowed("banner"|"interstitial"|"rewarded")`.
- `scripts/economy/economy_services.gd`: wires `store`, the `store_no_ads` grant handler, and snapshot/import.
- `scripts/app/app_state.gd`: `store.bind_save(request_save)`.
- `scripts/app/main.gd`: the Home bottom banner slot follows `store.ads_allowed("banner")`, live after a purchase or restore.
- `scripts/ui/shop/shop_screen.gd`:
  - Five SB pack cards, a No Ads card (shows OWNED when owned), and a RESTORE PURCHASES button.
  - Store buttons show the provider's localized price string verbatim. With the null provider they show UNAVAILABLE and the existing `SHOP_STORE_LATER` copy.
  - A tap opens only the store sheet (no SB confirm). The grant and the feedback popup arrive through `StoreService.resolved`. Cancel and duplicate results stay silent.
- `scripts/ui/ui_text.gd`, `ui_text_tr.gd`: 9 new EN+TR keys (`SHOP_SB_PACK_ITEM`, `SHOP_NO_ADS_DETAIL`, `SHOP_NO_ADS_OWNED`, `SHOP_OWNED`, `SHOP_STORE_PENDING`, `SHOP_STORE_FAILED`, `SHOP_RESTORE`, `SHOP_RESTORED`, `SHOP_RESTORE_NONE`).
- Tests:
  - `tests/m57_store_products.gd` (new, MockProvider).
  - `tests/m43_master_c006_shop.gd` s07/s13 and `tests/m43_c003_c001_acquisition.gd` now target the new card ids.
  - `tests/m60_release_gates.gd` g004 checks all six store cards, that the provider is the null StoreProvider, and that RESTORE is disabled.
  - `docs/RELEASE_GATES.json/.md` were regenerated with `-- --write`. Verdicts are unchanged; only evidence text changed.
- Docs: `AGENTS.md` gets a store section, `docs/LOCALIZATION.md` the price rule, `docs/PRIVACY_DATA_INVENTORY.md` the save contents (No Ads flag, `store:<token>` ids). `TASKS.md` queue and checklist rows updated.

Not changed: the Home SB "+" popup (AcquisitionFlow) still shows its single UNAVAILABLE pack entry. MORE IN SHOP leads to the real packs.

## Acceptance criteria
1. [x] Config holds the 5 SB packs with the exact owner IDs and amounts plus `no_ads`, with no display prices: m57 c01 checks ids and amounts exactly and that bad or missing config fails closed (no products). c09 confirms `reference_usd` is never read by store or UI code.
2. [x] StoreService facade over a provider interface (query_products -> localized strings, async purchase, restore, acknowledge), with the null provider as the shipping default and a MockProvider for tests: m57 c02 and c03; the MockProvider class is inside the m57 suite.
3. [x] An SB pack purchase grants the exact SB once per token, under tx `store:<token>`: m57 c03 covers +550 on the first callback, a double callback granting nothing (`duplicate`), relaunch via save import followed by a re-delivery granting nothing, and a new token granting its own pack. c08 covers the real app: +1200, success feedback, the reloaded canonical save holds it, and a duplicate stays silent.
4. [x] Cancelled, failed or pending results grant nothing: m57 c04 covers cancelled, failed, pending, empty outcome, missing token and unknown product. In each case there is no SB, no ledger entry and no acknowledge, and the pack can be bought again. c08 shows a cancel in the Shop is silent.
5. [x] No Ads entitlement persists, disables banner and interstitial, keeps rewarded videos, and Restore re-applies the non-consumable only: m57 c05 (grant, `ads_allowed` false/false/true, owned, persists through import, old save without the section, malformed section fails closed) and c06 (restore on a fresh profile brings back No Ads and not the owned SB pack; idempotent; zero case). c08 shows the Home banner slot collapsed and the No Ads card OWNED.
6. [x] Shop UI shows the SB packs section, the No Ads card and RESTORE, with provider prices when available and UNAVAILABLE / store-later otherwise, EN+TR via UiText: m57 c08 (every button text equals the mock's localized string, for example `₺179,99` and `9,99 €`), m43_master_c006_shop s07/s13 (null provider), m51 8/8 (TR key parity).
7. [x] NullProvider shows UNAVAILABLE and grants nothing, and release gate 004 still passes: m57 c02; m60_release_gates `SB-M60-004: PASS` (shop_store_gated now covers all six cards, the null StoreProvider and RESTORE disabled).
8. [x] Guard against hand-formatted prices: m57 c09 scans shop_screen, store_service, store_provider, acquisition_flow and ui_text/ui_text_tr for `$`, `USD`, `€`, `₺`, `%.2f` and `reference_usd`. No hits.
9. [x] Tree layout: no per-cell Nodes and no gameplay changes (economy, UI and config only).

## Validation
Godot 4.7.2 (`$GODOT`), run in the worktree after one `--import`. The import churn (409 tracked `.import`, project.godot, 1217 untracked generated files) was restored or removed, and the tree is clean.
- `m57_store_products`: LOCAL_PASS 9/9, exit 0, no SCRIPT ERROR. It ends with the usual "resources still in use at exit" line, which m42_home_v04 and others also print.
- `python tools/run_suites.py`: m43_master_c006_shop 15/15, m43_c003_c001_acquisition 34/34, m54_regression_pack_022_027 12/12, m51_localization_readiness 8/8, m58_privacy_inventory 7/7, sb_polish_004_006_ui_batch 10/10. Aggregate PASS 6/6.
- `python tools/run_suites.py`: m40_save_system, m40_v04_bootstrap, m44_ftue 23/23, m39a_economy_core, m39e_full_matrix, m39_v02_atomicity, m39_v03_full_surface, m39_v04_integration, m44_meta_l1_unlock_ftue 6/6, m56_analytics_taxonomy 27/27. Aggregate PASS 10/10.
- Direct runs: m60_release_gates PASS 6/6 (gate verdicts unchanged: 001-004 PASS, 005/006 FAIL as before, owner gates BLOCKED; `-- --write` rerun PASS), m42_home_v04 18/18, m42_home_v05 13/13, m43_146_notification_permission 8/8.
- `git diff --check` is clean.
- `m57_store_products` is in the CI validate list in `.github/workflows/android-family-first10.yml`, with the exact guard `M57 store products evidence: PASS (9/9 cases, 0 fail)`. `python tools/run_suites.py --list` shows it (84 suites), and `--selftest` passes.
- Round 2 re-run after the rebase and fix: m57_store_products 9/9, m43_master_c006_shop 15/15, m43_c003_c001_acquisition 34/34, m60_release_gates 6/6 (aggregate PASS 4/4). m60 was then run with `-- --write`: still PASS, and RELEASE_GATES.* evidence text was regenerated (574 English strings; my shop_store_gated text).
- Not done: no CI run and no phone build.

## Log
### Round 1
Built the provider-independent store seam, Shop cards, No Ads entitlement and banner seam, the m57 suite, updates to the existing gate and shop tests, docs and TASKS rows.
- The real Play Billing / StoreKit provider and sandbox remain READY (SB-M57-014..016), and the live store release stays with the owner.
- The interstitial ad provider (SB-M57-001..011) must ask `store.ads_allowed("interstitial")`.
- `docs/PRIVACY_DATA_INVENTORY.md` row 86 got a one-line addition. If job 135 edits that file, the merge needs a small reconcile.
- The release-gate string count changed (530 -> 551 English UiText strings, 9 of them from this job). It may conflict trivially with other jobs regenerating RELEASE_GATES.

### Round 2
Review round-1/review.md: VERDICT CHANGES.
- **Must-fix 1 (money safety): fixed in 77de31c4.** `StoreService.deliver()` now calls `_save_cb` for every purchased delivery, duplicates included, and acknowledges only when that save returns ok. With no save callback bound it still acknowledges. Test c07 was rewritten:
  - The first delivery's save fails: the SB is granted but not acknowledged.
  - A duplicate re-delivery with a failing save retries the save, is still NOT acknowledged, and grants nothing a second time.
  - A later re-delivery with a successful save is acknowledged, with no second grant.
  - A cancelled delivery neither saves nor acknowledges.
- **Other acknowledge paths:** `deliver()` is the only caller of `acknowledge`. `_on_restore` saves but has nothing to acknowledge (reviewer note: acceptable).
- **Note, CI:** done in 8fd09be8 (exact 9/9 guard, header comment line).
- **Note, `_unbind_store`:** no change. It is connected with CONNECT_ONE_SHOT to `popup.closed`.
- **Rebase onto origin/main c1e1560b:**
  - `docs/RELEASE_GATES.*` conflicted: I took upstream's version, then regenerated it with `-- --write`.
  - `docs/PRIVACY_DATA_INVENTORY.md` row 86 conflicted with job 135's edit: I kept their text (weekly Ranks count, PRIVACY switch) and added my No Ads / `store:<token>` clause.
  - TASKS.md merged cleanly; I updated its hashes to the rebased commits (77a88a87).

