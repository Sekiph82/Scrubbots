# Collection Runtime Module

Economy V1 Collection contract:

- 15 owner-reference sets.
- 9 cards per set.
- First owned copy is protected.
- Extra copies are exchangeable through Cards Exchange.
- Set completion 9/9 rewards are tiered by the owner-approved 15-set table in `OWNER_ECONOMY_REWARDS_V01.md`; they are not flat.
- Sets 1–14 use the standard 4C/2R/2E/1L profile with increasing later-set rewards.
- Set 15 Ultimate Cleaners uses 3R/3E/3L and grants 2500 SB + 20 Bot Parts.
- Completing all 15 sets grants an additional Master Collection reward of 2500 SB + 20 Bot Parts exactly once.
- Standard Pack: 3 eligible draws.
- Premium Pack: 5 eligible draws and at least one Rare-or-better.
- Duplicates are allowed.
- Cards Exchange values: Common 25, Rare 75, Epic 200, Legendary 500 SB.
- `EXCHANGE ALL EXTRAS` must be atomic and may never reduce a collected card below one owned copy.
- Featured Cards (SB-M44-026, `featured_cards.gd` + `data/config/featured_cards_v1.json`): all 135 cards scheduled by level as highlights only; packs stay random. The only card grants are first clears of L20 (Scrubby) and L30 / L40 (first Set 01 card not owned yet, else the row's fallback duplicate), once each via RewardGrantService tx `featured_card:L<level>:<card>`.

Planned M39 module:

- `collection_inventory.gd`

Canonical source: `coordination/OWNER_ECONOMY_REWARDS_V01.md`.
