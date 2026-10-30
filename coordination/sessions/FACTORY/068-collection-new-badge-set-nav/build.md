STATUS: READY

# Build: Collection set NEW-count badge + set detail prev/next (SB-COL-NAV-001)

## Summary
Branch `factory/068-collection-new-badge-set-nav`, commits 658906a1 (code + test + CI guard) and 9544c4f0 (TASKS.md).
- Album: each set row has a red count badge on its thumbnail showing how many cards of that set the player owns but has not viewed yet (`not meta_ui.is_seen(card_key(cid))`, the existing NEW truth). The badge is hidden at 0 and is re-read in `_refresh_album`, which already runs on top_changed and on every detail close. The badge reuses the Home shortcut badge through the new `UiShortcutButton.make_badge()` (the old inline code was moved there). No new art.
- Set detail: `<` / `>` buttons (88x88, UiText keys `COLLECTION_PREV_SET` / `COLLECTION_NEXT_SET`). They sit on the left and right borders of the frame, vertically centred on the card grid. The 3-card grid already fills the frame interior (646 of 652 px), so the arrows live in a plain `Pager` Control and are anchored just outside the grid, inside the frame. `_show_set()` rebuilds the detail in place in `set_rewards` config order, wrapping both ways: title, 9 tiles, the `card:<id>` actions (old ones go through the new `BasePopup.remove_action`), `mark_seen` + `app.mark_dirty`, and the `newly_seen` meta. The album's texture cache is reused. No extra popup is stacked, and BACK still returns to the refreshed album.
- Files: `scripts/ui/collection/collection_screen.gd`, `scripts/ui/components/ui_shortcut_button.gd`, `scripts/ui/popup/base_popup.gd`, `scripts/ui/ui_text.gd`, `tests/m43_master_c007_collection.gd`, `.github/workflows/android-family-first10.yml` (C007 exact guard 17/17 -> 19/19, header comment), `TASKS.md`.

## Acceptance criteria
1. [x] Badge count = owned unseen cards per set, hidden at 0: k18 checks every set 1..15 against an independent count (set 2 = "2", set 5 = "1", set 1 hidden). It also checks the same red style and that the badge ignores mouse input.
2. [x] Badge clears after viewing and updates after a grant: k18 opens set 2 and goes BACK, and the badge has cleared. After `add_card("s7_c3")`, set 7 shows "1" on the next refresh. k19 also shows sets 15/1/14 cleared after BACK while set 2 stays at "1".
3. [x] Next/prev, wrap, no stacking: k19 shows `>` from 15 goes to 1, `<` from 1 goes to 15, and `<` from 15 goes to 14. The stack ids stay `["collection", "collection_set"]`.
4. [x] Tiles and ids match the new set: k19 sees the tiles `Tile_s1_c0..8`. The card actions are exactly `["card:s1_c0"]`, the set 15 ids are gone, and the pager is re-armed.
5. [x] Viewed marks for the switched-to set: k19 sees `newly_seen == ["s1_c0"]`, `is_seen`, and the app going from not dirty to dirty. For set 14, `newly_seen == ["s14_c5"]`.
6. [x] DETAILS works after a switch: k19 sees `card:s14_c5` open `collection_card` with that card_id. After BACK the set detail is usable again.
7. [x] No economy change: k18 and k19 compare SB, Bot Parts and the collection snapshot before and after, and they are unchanged.
8. [x] Touch targets >= 88: k19 measures both arrows at (88, 88). They are visible, inside the frame rect and clear of the card grid. k10 (all buttons in the album >= 64 px, set-detail build budget) still passes.
9. [x] Regressions: see Validation, all LOCAL_PASS.
10. [x] TASKS.md: the `- DONE SB-COL-NAV-001 ...` row is in the Autonomous Queue after SB-M44-025, and the ticked `SB-COL-NAV-001` line is under `#### M43-C007` after SB-M43-101. The CRLF line endings were kept and the diff is 2 inserted lines.

## Validation
Godot 4.7.2 headless (`--headless --path <worktree> -s res://tests/<suite>.gd`). The worktree needed a one-time `--import` first, and its .import/.uid/project.godot noise was reverted afterwards. Every suite exited 0 with no SCRIPT ERROR or Parse Error. LOCAL_PASS:
- m43_master_c007_collection: `M43 master C007 Collection evidence: PASS (19/19 cases, 0 fail)`
- m47_touch_r01_mobile_ux: `PASS (14/14 cases, 0 fail)`
- m22_026_texture_budget: `M22-026 TEXTURE BUDGET: PASS`
- m44_pending_packs_gate: `PASS (6/6 cases, 0 fail)`
- m43_master_c005_meta_ceremonies: `PASS (32/32 cases, 0 fail)`
- m42_home: `M42 home evidence: PASS` (the shortcut badge now comes from make_badge)
- m44_new_badge: `PASS (6/6 cases, 0 fail)`
- m51_localization_readiness: `PASS (4/4 cases, 0 fail)` (new UiText keys)
- m54_collection_set_master_exactly_once: `PASS`
- m43_c005_c008_pack_commit_transaction: `PASS (27/27 cases, 0 fail)`
- m42_navigation: `PASS`
- m50_board_symbols: `PASS (8/8 cases, 0 fail)`
- `git diff --check`: clean.

## Log
### Round 0
- Wrote spec.md from the owner request and built it.
- Changed the k09 assertion from `get_action_ids() == ["back"]` to "no `card:` action", because the set detail now always has prev/next actions. The no-leak intent is unchanged.
- In k19 a lifecycle flush was added before the dirty baseline, because opening set 15 already dirties the save legitimately.
- No new suite was added: k18 and k19 extend m43_master_c007_collection, which is already in CI validate, and its exact guard was bumped to 19/19. The suite total stays at 59.

CI: GitHub Actions run 41066769861 success; M43-C007 verdict=PASS (19/19).
