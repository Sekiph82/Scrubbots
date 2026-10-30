# Shop destination verify-close (SB-M43-078..080, 082..083, 085..089)

> Feature: Factory job 060-m43-078-shop: SB-M43-078..080 (real Shop destination from SHOP/`+`, Shop visual master, Hearts/boosters/2x product groups), plus 082..083 (live wallet/Heart/booster/entitlement state; soft-currency buys via authoritative services) and 085..089 (confirmation, return context, sold/offline/error states, rapid-tap/idempotency tests, honest feedback).

## Context
Finding: the Shop is ALREADY BUILT (commit 79544a75 "real Shop destination (SB-M43-078..089)", touched by c2b1c3c7). Only its bookkeeping is open: TASKS.md still lists the rows READY/unchecked, and its suite is NOT in the CI `validate` list.

Existing pieces (reuse, do not rebuild):
- `scripts/ui/shop/shop_screen.gd`: native-Control popup. Sections Hearts, Boosters, 2X speed, SB packs, No Ads. `offer()` reads live values from the economy (no baked prices). Every buy goes through a confirm popup, then `ProductionActionFacade` (`buy_heart`, `refill_hearts`, `buy_booster_charge`, `buy_timed_2x`). Feedback is shown only after the authority result. `sb_pack` and `no_ads` are `store_gated` (disabled, "Available when the store opens"), and `speed:level` is in-level only.
- `scripts/app/shop_handoff.gd`: ticket with detached return context. `scripts/app/main.gd` lines ~154-160 and ~371 wire Home SHOP and the SB `+` via `_acq.open_shop`. `scripts/ui/popup/acquisition_flow.gd` does the return/resume.
- Art: `assets/ui/final/shop/*` (header emblem, heart/booster/SB bundles, 2x icon, item/featured/button frames) plus currency, booster and no_ads icons. The "visual master" is already promoted art plus native theme. No new art is needed.
- Suite: `tests/m43_master_c006_shop.gd` (11 cases s01..s11). Locally it prints `M43 master C006 Shop evidence: PASS (11/11 cases, 0 fail)`.
- Owner decisions (TASKS.md SB-M57-001/013): AdMob; bottom banner; interstitial every 5 plays; No Ads is a one-time $4.99 that keeps rewarded videos. No ad SDK or IAP provider exists yet, and CLAUDE.md §0D.5 forbids a public store release or new spending.

Classification:
- verify-close (no code change): 078, 079 (§0D.1 grants visual sign-off; assets are in `assets/ui/final/shop`), 080, 082, 083, 085, 086, 087 (sold/full/insufficient/in-level/store-gated states, no dead button), 089.
- verify-close with scope note: 088 covers rapid taps, insufficient SB, facade refusal and background/resume. Provider cancel/failure/restore are N/A until SB-M43-084 and M57 exist. 088 stays a closed row, and the note says those sub-items move to 084.
- Stays READY: 081 (No Ads entry exists as a gated card, but the product is M57-gated) and 084 (real-money cards, prices, restore).

## Requirements
1. Add `m43_master_c006_shop` to the `for s in ...; do` suite loop of the `validate` job in `.github/workflows/android-family-first10.yml`, with an exact-summary guard `M43 master C006 Shop evidence: PASS (11/11 cases, 0 fail)`. Copy the neighbouring guard style (e.g. the m43_c005f_phase6 `grep -qxF` block). Update the header comment and the suite total (52 to 53). Put any new `m43_master_c006_*` suite into the same loop with its own guard.
2. Fill gaps in the suite only if the audit finds one. Required assertions, each already covered or to be added to `tests/m43_master_c006_shop.gd` (extend `EXPECTED_CASES` and the summary count):
   a. Home SHOP and the SB `+` both open the Shop.
   b. Price and balance labels are read live. Change the wallet or config, call `refresh()`, and the labels change.
   c. A real-money pack and No Ads render disabled with no purchase path: no IAP or store call, no balance change on tap, and no success feedback or SFX.
   d. No Star/Event currency and no fifth booster appear in the Shop. Booster products are exactly the existing four ids.
   e. UI code never writes `wallet`, `hearts` or `boosters` directly (grep of `shop_screen.gd` finds only facade calls).
3. No real-money flow is wired. No store or billing API, SDK, product id or price is added. IAP and No Ads cards stay disabled with the "available when the store opens" text.
4. Docs: update TASKS.md. Mark `[x]` SB-M43-078, 079, 080, 082, 083, 085, 086, 087, 088, 089 with a DONE verify-close note giving factory 060, the suite line and the CI list change. Remove them from the READY queue lines 55-57 (keep 081 and 084 READY). Add a line to the CHANGELOG/AGENTS.md test list if AGENTS.md lists the suites. The visual master in 079 is marked given by §0D.1, with a note that it was built from existing assets and native Controls.
5. No new art generation, and no changes to the economy or services.

## Acceptance criteria
1. `"$GODOT" --headless --path <worktree> -s res://tests/m43_master_c006_shop.gd` prints `M43 master C006 Shop evidence: PASS (N/N cases, 0 fail)` (N is 11, or larger if cases are added per Req 2, with the guard matching).
2. `grep -n "m43_master_c006_shop" .github/workflows/android-family-first10.yml` shows the suite in the loop plus its exact-summary guard. `python tools/run_suites.py` runs it (53 suites) and reports all PASS.
3. `python tools/run_suites.py` is green overall (regression gate).
4. `grep -nE "wallet\.|hearts\.|boosters\." scripts/ui/shop/shop_screen.gd` shows only reads (`scrub_bucks()`, `hearts()`, `max_hearts()`, `charges()`, `booster_price` etc.). No `spend`, `add`, `grant` or `set` calls.
5. `grep -rniE "billing|storekit|admob|purchase_token" scripts/ui/shop scripts/app/shop_handoff.gd` returns nothing.
6. `git diff --check` is clean. `git diff --stat` shows only the workflow, TASKS.md, doc files, and optionally `tests/m43_master_c006_shop.gd` (and `shop_screen.gd` only if an audit gap forces it).
7. TASKS.md: 078, 079, 080, 082, 083, 085..089 are `[x]` with evidence. 081 and 084 remain `[ ]`. `grep -n "READY SB-M43-0[78]" TASKS.md` lists only 081 and 084.

## Out of scope
- Real-money purchase, receipt or restore wiring, the AdMob SDK, banner or interstitial, and No Ads fulfilment (SB-M43-081, 084, M57).
- New Shop art or a redesign. New currencies or boosters. A free manual 2x. Economy or service changes.
- Provider-cancel and restore tests (they need a provider).

## Assumptions
- The existing Shop satisfies 078..089 as written. The audit found the suite green, so closing by verification is the smallest change.
- The `store_gated` stubs for SB packs and No Ads count as the "disabled / coming soon" state the job requires.
- The visual master is the existing promoted art plus native theme, because §0D.1 grants all visual sign-offs and no art generation is allowed.
- 088's provider sub-items are deferred to 084 because no provider exists.
