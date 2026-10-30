# Spec: Collection set NEW-count badge + set detail prev/next (SB-COL-NAV-001)

Owner request, chat 2026-10-30 (Turkish): "collections a yeni kartlar geldiginde hangi koleksiyona yeni kart eklendiyse onun uzerine kac tane kart eklendigi gosteren kirmizi bir uyari isareti koyalim. bir de koleksiyon packlerinden birini actigimizda acilan sayfanin sagina ve soluna koleksiyonlar arasinda ileri geri yapabilecegimiz dugmeler ekleyelim"

## Scope
File: `scripts/ui/collection/collection_screen.gd` (plus a minimal shared helper where reuse needs it).

A. Album set rows: a red count badge (same style as the Home shortcut badge, `UiShortcutButton`) on each set row, showing the number of owned-but-unseen cards in that set (`not meta_ui.is_seen(card_key(cid))`, the existing NEW truth). Hidden at 0. Re-read in `_refresh_album`, so it updates after a pack grant and clears after the set has been viewed.

B. Set detail popup (`open_set`): a LEFT and a RIGHT arrow button on the left/right sides of the page. They switch to the previous/next set in `collection_config().set_rewards` order, wrapping (15 -> 1, 1 -> 15). The switch happens in place: title, 9 tiles, NEW/EXTRAS state, `card:<cid>` DETAILS actions for the shown set, viewed marks (`mark_seen` + `app.mark_dirty`) and `newly_seen` meta. No extra popup is stacked. BACK still returns to the album, which refreshes. Native Controls, touch targets >= 88 px, the album's per-visit texture cache is reused.

Presentation only: no economy mutation, no save-schema change, no new art.

## Acceptance criteria
1. Badge count per set equals the owned unseen cards in that set; hidden at 0.
2. Badge clears after the set is viewed and the album refreshes; updates after a grant.
3. Next/prev change the shown set, including wrap 15 -> 1 and 1 -> 15, without stacking popups.
4. After a switch, the tiles and `card:<cid>` action ids match the new set; the old set's ids are gone.
5. Viewed marks and `newly_seen` are applied for the switched-to set; the app is marked dirty.
6. Card DETAILS opens for a card of the switched-to set.
7. No balance / collection count change from badge or navigation.
8. Arrow buttons are >= 88 px touch targets.
9. Regressions PASS: m43_master_c007_collection, m47_touch_r01_mobile_ux, m22_026_texture_budget, m44_pending_packs_gate, m43_master_c005_meta_ceremonies, plus suites that cover the collection popup.
10. TASKS.md: DONE row SB-COL-NAV-001 in the Autonomous Queue; M43-C007 checklist line if one exists.
