# M43-C005-C001 — Owner Visual Review V01 (Ceremony visual masters)

Date: 2026-10-02
Status: **OWNER_REVIEW_REQUIRED.** These are candidates only; none is self-approved, and production ceremony work stays blocked until you decide.
Evidence: `coordination/sessions/M43-C005-C001/evidence/` (29 PNGs). The images are preview-harness renders on a dark backdrop, not wired into the game.

Reproduce the evidence with:

```bash
godot --path . -s res://tests/tools/ceremony_preview/ceremony_snapshot.gd -- coordination/sessions/M43-C005-C001/evidence
```

All candidates reuse the accepted popup family: promoted frames, a royal title pill, cream reward rows, a green primary and a cream secondary. Every text and number is live. Every image is existing final art; nothing was generated.

## 1. Look at

| Ceremony | Reference image | Also |
|---|---|---|
| Standard Pack | `standard_pack_1080x2160.png` | — |
| Premium Pack | `premium_pack_1080x2160.png` | `premium_pack_reduced_effects_1080x2160.png`, plus the 1080×1920 / 1170 / 1290 / tablet sizes |
| Set Complete | `set_complete_1080x2160.png` | — |
| Master Collection | `master_complete_1080x2160.png` | all viewport sizes |
| Robot Unlock (Moppy) | `robot_unlock_1080x2160.png` | `robot_unlock_reduced_effects_1080x2160.png`, all viewport sizes |
| Gift milestone | `gift_250_1080x2160.png` (small), `gift_1000_1080x2160.png` (big) | Gift 1000 at all viewport sizes |
| Feature unlock | `feature_unlock_1080x2160.png` | — |
| World transition shell | `world_shell_1080x2160.png` | — |
| Generic small reward | `generic_1_1080x2160.png` (1 row), `generic_4_1080x2160.png` (4 rows) | — |

## 2. Decisions requested (approve / adjust each group)

1. **Overall ceremony family**
   - All ceremonies use the Results / Popup cream-and-royal family. The big moments (packs, set, master, robot, Gift) use the promoted *reward* or *large* frames.
   - Celebration level: one slowly rotating glow behind the hero image, plus a card flip-in for packs. There is no confetti and no screen shake. Reduced Effects shows the same information with no motion.
   - Is this the right family and the right amount of celebration? More (confetti, sparkles) or less?
2. **Pack opening**
   - Standard: the pack art, then 3 cards in one row. Premium: 5 cards as 3 + 2.
   - Each card is about 200 px wide: real card art inside its rarity frame (common / rare / epic / legendary).
   - The rarity chip sits under the card. A **NEW** (green) or **DUPLICATE** (brown) badge sits on top, and duplicates also show "You now have N".
   - There is a single CONTINUE; no skip button is shown.
   - Approve the card size, the 3 + 2 premium layout, and the badge hierarchy?
3. **Collection completion**
   - Set Complete: completion emblem, "Set 6 · Bathroom Mayhem", the 9 real card thumbnails, 9/9, and the configured +600 SB / +8 Bot Parts with "already added".
   - Master: a larger emblem, "All 15 sets complete", "One-time master reward", and exactly +2,500 SB / +20 Bot Parts.
   - Is Master's extra emphasis (bigger emblem, bigger rows) enough, or should it use a different frame or the large SB / Bot-Parts bundle art?
4. **Robot Unlock**
   - Hero (Moppy master pose on the unlock burst), about 330 × 396 px.
   - Name; role/personality text verbatim from the roster; perk card ("Clean Bonus" + "+20% first-clear Scrub Bucks."); "Bot Parts left".
   - **EQUIP MOPPY** is the green primary and KEEP CURRENT the cream secondary.
   - Approve the hero size, the perk presentation, and making EQUIP the primary?
5. **Gift milestone**
   - Small milestones (250 shown) use the gift box at 220 px. The 1000 milestone uses the reward crate at 300 px with all five reward rows.
   - The 500 SB fallback is a small note ("If every card is already owned, the NEW card becomes 500 Scrub Bucks."), not a sixth reward.
   - Is this hierarchy clear enough?
6. **Feature / World shells**
   - Feature: the feature icon with a NEW badge, its name, a one-line explanation and GOT IT. There is no level number.
   - World: a title slot, a big art slot, a subtitle slot and CONTINUE. World 01 art appears only as a labelled test sample; there is no World 02, name or range.
   - Approve these shells for reuse once the feature pacing and world registry exist?
7. **Generic small reward**
   - Small frame, a title and 1–4 rows, then CONTINUE. It is visually lighter than the big ceremonies.
   - Is it right for Daily rewards and Tasks 3/3?

## 3. Asset items for your attention (details in `CEREMONY_ASSET_INVENTORY_V01.md`)

- **Missing:** a "Booster of your choice" icon (Gift 500 / 1000 rows). A native "?" chip is used for now. Commission an icon, or keep the chip?
- **Card art:** the card images are small sheet crops with uneven sizes (266–297 × 306–323 px), and some show a sliver of the neighbouring card. They look acceptable at about 200 px. A clean uniform re-export would make pack reveals crisper. Request it?
- **Card names and rarity labels** exist only baked into the art; there is no name data. Is that fine for V1?

**Proposed manifest transitions** (applied only after your approval): in `PLAYER_EXPERIENCE_ASSET_MANIFEST.json`, change `standard_pack_open`, `premium_pack_open`, `collection_set_complete`, `master_collection_complete`, `robot_unlock`, `gift_meter_milestone`, `feature_unlock`, `world_unlock_transition` and `generic_reward_confirmation` from `MASTER_REQUIRED` to `MASTER_OWNER_APPROVED`. The manifest is unchanged in this cycle.
