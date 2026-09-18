# Collection Runtime Module

Economy V1 Collection contract:

- 15 owner-reference sets.
- 9 cards per set.
- First owned copy is protected.
- Extra copies are exchangeable through Cards Exchange.
- Set completion 9/9 grants 500 SB + 10 Bot Parts exactly once.
- Standard Pack: 3 eligible draws.
- Premium Pack: 5 eligible draws and at least one Rare-or-better.
- Duplicates are allowed.
- Cards Exchange values: Common 25, Rare 75, Epic 200, Legendary 500 SB.
- `EXCHANGE ALL EXTRAS` must be atomic and may never reduce a collected card below one owned copy.

Planned M39 module:

- `collection_inventory.gd`

Canonical source: `coordination/OWNER_ECONOMY_REWARDS_V01.md`.
