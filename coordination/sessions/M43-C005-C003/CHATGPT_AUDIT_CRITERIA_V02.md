# M43-C005-C003 — CHATGPT AUDIT CRITERIA V02

## Provenance hard gate
- [ ] 135 final assets were generated independently one card at a time.
- [ ] No final asset is a crop from an owner 3x3 sheet.
- [ ] No final asset is a slice from a generated multi-card sheet/collage.
- [ ] Manifest marks every card `final_asset_origin = individually_generated`.
- [ ] Old crop hashes were captured before replacement.

## Inventory
- [ ] exactly 15 sets.
- [ ] exactly 9 cards/set.
- [ ] exactly 135 cards.
- [ ] 135-row pre-generation inventory exists.
- [ ] names, identities and rarity come from owner references.
- [ ] no 16th set from Cleaning Crew duplicate source.

## Technical
- [ ] all 135 = 1024×1536 RGBA PNG.
- [ ] transparent exterior.
- [ ] one complete card per PNG.
- [ ] no clipping.
- [ ] exact canonical paths retained.
- [ ] no neighboring-card contamination.
- [ ] no album/sheet UI baked around cards.

## Visual
- [ ] Common/Rare/Epic/Legendary share coherent templates.
- [ ] each unique card illustration is individually generated.
- [ ] exact card name is readable/correct.
- [ ] rarity label and star treatment correct.
- [ ] subject identity matches source card.
- [ ] no watermark/prompt garbage/malformed production-breaking art.
- [ ] all 15 set contact sheets manually reviewed.
- [ ] master 135-card contact sheet manually reviewed.

## Mapping
- [ ] card_01..09 preserve row-major owner identity mapping.
- [ ] Sets 1–14 = 4C/2R/2E/1L.
- [ ] Set 15 = 3R/3E/3L.
- [ ] card IDs unchanged.

## Scope
- [ ] TASKS.md untouched by builder.
- [ ] no economy/config changes.
- [ ] no pack-opening frame changes.
- [ ] no Collection UI/runtime implementation.
- [ ] no Booster-of-choice work in this cycle.

## Tests
- [ ] dedicated card validator PASS.
- [ ] M39 Collection tests PASS.
- [ ] relevant M43 card-path tests PASS.
- [ ] root suite PASS apart from explicitly documented historical unrelated failures.
- [ ] git diff --check clean.

Any crop/slice-based final card is an automatic FAIL regardless of visual quality.
