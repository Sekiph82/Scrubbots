# M43-C005F-PHASE2 — INDEPENDENT AUDIT AMENDMENT R01

Date: 2026-10-08
Repository: `Sekiph82/Scrubbots`

## Runtime finding

The owner tested the real shipping game and found that earned Standard/Premium card packs do **not** open the accepted pack-opening ceremony at all. Gift Bar screenshots show pack rewards being claimed, after which the cards are already present in Collection without a pack ceremony.

Independent source review confirms the production cause:

- `EconomyServices._register_handlers()` maps `standard_card_packs` and `premium_card_packs` directly to `CardPackService.open_standard()/open_premium()`.
- Those methods draw and immediately add cards to `CollectionInventory`.
- `HomeScreen._on_popup_action("gift_bar")` calls `ProductionActionFacade.claim_gift()`, which returns and refreshes Home; it never routes to StandardPackCeremony/PremiumPackCeremony.
- `AppState.commit_pack()` and the accepted Standard/Premium ceremony implementations exist, but there is no real production reward-to-pack-presentation wiring.
- The Phase 2 F005 builder log itself stated that no production pack call site existed.

Therefore the earlier technical PASS for F005 was too narrow: it proved the ceremony's feel behavior in harness/runtime evidence but did not prove that the shipping reward flow ever reaches that ceremony.

## Revised disposition

- `SB-M43-C005F-003`: **TECHNICAL PASS + OWNER VISUAL PASS / CLOSED**
- `SB-M43-C005F-004`: **TECHNICAL PASS + OWNER VISUAL PASS / CLOSED**
- `SB-M43-C005F-005`: **CHANGES REQUIRED / PRODUCTION WIRING REMEDIATION**

This is not merely a sparkle-tuning issue. The missing shipping route must be fixed first.

## Required remediation

Create a durable earned-pack presentation path so every earned Standard/Premium pack:
1. is granted exactly once as a pending earned pack, not silently resolved straight into Collection;
2. is committed/drawn exactly once through the canonical pack transaction path;
3. yields the durable receipt/model consumed by the accepted Standard/Premium ceremony;
4. opens on the real ModalStack in the real app, with the canonical FeedbackAdapter bound;
5. survives app restart before/during presentation without reroll or duplicate grant;
6. serializes multiple earned packs;
7. preserves Reduced Effects and all existing pack/card/set/master truth.

Gift Meter and Daily Login are current configured pack-reward sources and must be covered. The design must be generic for any future reward grant carrying `standard_card_packs` or `premium_card_packs`.

Future `SB-M43-098` Collection manual pack-inventory/open-entry remains a separate destination unless the implementation explicitly and safely completes it; do not falsely close it merely because an internal pending-pack queue is added.
