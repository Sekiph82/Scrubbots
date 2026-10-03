# M43-C005-C001 — Ceremony Asset Inventory V01

Date: 2026-10-02
Scope: SB-M43-076 ceremony visual-master candidates (preview harness only)

**Rule:** per `CLAUDE.md` §16, only owner-approved production art lives in `assets/ui/final/`. "Final" below means present under `assets/ui/final/`.

- No art was generated, regenerated or overwritten in this cycle.
- Every path listed as used was verified to exist (focused suite c16: 38 bound textures plus all 135 card arts).

## 1. Shared chrome (all candidates)

| Component | Path | Present | Final |
|---|---|---|---|
| Large frame (packs, world shell) | `assets/ui/final/common/frames/popup_large_frame.png` | yes | yes |
| Reward frame (set, master, robot, Gift) | `assets/ui/final/common/frames/popup_reward_frame.png` | yes | yes |
| Medium frame (feature) | `assets/ui/final/common/frames/popup_medium_frame.png` | yes | yes |
| Small frame (generic reward) | `assets/ui/final/common/frames/popup_small_frame.png` | yes | yes |
| Celebration glow behind heroes | `assets/ui/final/popups/victory/reward_glow.png` | yes | yes |
| Royal title pill, cream reward rows, green / cream CTAs, rarity / NEW chips | native StyleBoxes (M43-C002 BasePopup family) | — | — |

## 2. Per candidate

| Candidate | Art used (exact paths) | Present / final | Missing component art | Built entirely from native chrome + final art? |
|---|---|---|---|---|
| **1 Standard Pack** | `rewards/card_pack_standard.png`; `collection/card_frame_{common,rare,epic,legendary}.png`; `collection/states/card_new_glow.png`; card art `collection/cards/set_NN/card_MM.png` | all yes | none | **Yes** |
| **2 Premium Pack** | `rewards/card_pack_premium.png` plus the same card frames, glow and card art | all yes | none | **Yes** |
| **3 Set Complete** | `collection/collection_complete_emblem.png`; the set's 9 card arts as thumbnails; `common/currencies/icon_currency_scrub_bucks.png`; `robots/bot_parts_icon.png` | all yes | none | **Yes** |
| **4 Master Collection** | `collection/master_collection_emblem.png`; SB / Bot Parts icons | all yes | none | **Yes** |
| **5 Robot Unlock (Moppy)** | `characters/robots/moppy/moppy_master.png`; `robots/robot_unlocked_burst.png`; `robots/perks/perk_first_clear_sb_bonus.png`; `robots/bot_parts_icon.png` | all yes | none | **Yes** |
| **6a Gift milestone (250)** | `rewards/gift_box.png`; SB, Bot Parts, `rewards/card_pack_standard.png` icons | all yes | none | **Yes** |
| **6b Gift milestone (1000)** | `home/gift_meter/gift_meter_reward_crate.png`; SB, Bot Parts, `rewards/card_pack_premium.png`; `collection/states/card_back.png` (guaranteed NEW card) | yes | **"Booster of your choice" icon:** no final asset. The candidate shows a native "?" chip, recorded here instead of fabricated. | Yes, except that one row icon |
| **7 Feature unlock (fixture: Cards Exchange)** | `home/shortcuts/icon_shortcut_cards_exchange.png` | yes | none for this fixture. Each future feature needs its own approved icon (existing shortcut icons cover Shop, Collection, Tasks, Daily, Gift Bar, Cards Exchange, Win Streak and No Ads). | **Yes** |
| **8 World transition shell** | `home/worlds/world_01_whispering_park_1080x2160.png`, used only as a **PREVIEW HARNESS · SHELL TEST ONLY** art-slot sample | yes | Future world art is intentionally absent; it needs an owner world registry and approved art later. | Shell: **yes**. A real World 02: **no (by design)** |
| **9 Generic small reward** | SB, Bot Parts, `rewards/card_pack_standard.png`, `boosters/random.png`, `common/currencies/icon_currency_heart.png` | all yes | Same "booster of your choice" gap, if a Daily reward ever uses that resource | Yes |

## 3. Card art observations (owner attention; nothing changed)

- **Mapping:** 135 card arts exist: 15 sets × `card_01..09`. Canonical card ids are `s<set>_c<k>` with k = 0..8 in rarity-profile order (`CollectionInventory`), and the candidates map `k` to `card_(k+1)`.
  - Spot checks agree with the baked rarity banners: set 1 card 5 shows "Rare" (k = 4, RARE); set 1 card 9 shows "Legendary"; set 15 card 1 shows "Rare" (profile 3R/3E/3L).
  - The mapping itself is not yet written down as an owner-locked data contract.
- **Names:** card names ("Mud Blob", "Slimeball", ...) and rarity banners are **baked into the art**. There is no card-name data authority, so the candidates show names only through the art.
- **Image quality:** the card images are small sheet crops with **inconsistent sizes**: 266 or 297 px wide, 306–323 px tall. Several show a sliver of the neighbouring sheet cell, such as stars or frame edges. They read fine inside the rarity frame at about 200 px, but a clean re-export at a uniform size would improve the pack reveal. This is an **owner decision**; nothing was regenerated.

## 4. Final assets available but not used by these candidates

These are available for owner direction:

- `robots/robot_unlock_glow.png`, `robots/robot_detail_hero_frame.png`, `robots/robot_portrait_frame.png`;
- `collection/set_header_frame.png`, `collection/collection_panel_frame.png`;
- `rewards/reward_chest.png`, `rewards/chest_small.png`;
- `rewards/scrub_bucks_bundle_{small,large}.png`, `rewards/bot_parts_bundle_{small,large}.png`.

The large bundle art could replace the flat SB / Bot Parts row icons on Master or Gift 1000 if the owner wants more weight there.

## 5. Genuinely missing art (blockers only if the owner wants them)

1. **Booster-of-your-choice icon.** It affects Gift 500 / 1000 (and a possible Daily D5) rows. A native "?" chip is used meanwhile.
   - **Resolved by M43-C005-C004 (2026-10-03):** the owner-approved icon `assets/ui/final/rewards/booster_of_choice.png` is promoted byte-exact and bound in the preview harness Booster-of-your-choice row; the "?" chip is removed. The 6b / 9 table rows above are historical C001 state.
2. **Future world art and names.** Intentionally absent until an owner-approved world registry exists.
3. **Optional:** a uniform-size card art re-export (quality, not a blocker).

No other component of the nine required candidates is missing.
