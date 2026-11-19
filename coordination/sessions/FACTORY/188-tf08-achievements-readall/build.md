STATUS: READY

# Build: Achievements earned-first order + Collection "Read all"

## Summary
Branch `factory/188-tf08-achievements-readall`, commit `342dc151`.

The Achievements popup now opens with claimable entries first, then claimed, then in progress. Each group keeps catalogue order. A claim made while the popup is open keeps the existing in-place COMPLETED pill, so cards never move during a session.

The Collection album has a READ ALL / TÜMÜNÜ OKU button (`ReadAll`, action `read_all`, secondary style). It sits in its own header row between PackRow and SetList and is visible only while at least one owned card is unseen. Pressing it calls `ProductionActionFacade.mark_all_cards_seen()`, which is `_finish_durable`: one save, and rollback if that save fails. The album then refreshes and re-arms.

The button's row height is taken out of the SetList's minimum height, so the album frame stays 1915 px tall whether the button shows or not. My first version put the button inside PackRow. In TR that squeezed the packs label into a 330 px-tall row, so I moved it.

Files changed:
- `scripts/progression/achievements.gd`: new `sort_for_display(list)`. It is pure and returns a new array. `evaluate()` and `claimable_count()` are unchanged.
- `scripts/ui/profile/profile_screens.gd`: `open_achievements` builds its cards in `sort_for_display` order.
- `scripts/economy/meta_ui_state.gd`: new `mark_all_seen(keys) -> int`.
- `scripts/economy/production_action_facade.gd`: new `mark_all_cards_seen() -> {ok, marked}`. It marks `card:<id>` for owned cards only, which is the same set as `CollectionScreen.unseen_cards`. It computes this inline so the economy facade does not preload a UI script.
- `scripts/ui/collection/collection_screen.gd`: the ReadAll button; `_refresh_album` sets its visibility and the SetList height; `_on_album_action` handles `read_all`; the header comment mentions READ ALL.
- `scripts/ui/ui_text.gd` / `scripts/ui/ui_text_tr.gd`: `COLLECTION_READ_ALL` = "READ ALL" / "TÜMÜNÜ OKU".
- `tests/sb_tf08_achievements_readall.gd` (new suite, 12 cases) and `tests/tools/sb_tf08_capture.gd` (GPU capture tool).
- `.github/workflows/android-family-first10.yml`: the suite is in the validate list, with a comment line and an `ACH-READ-ALL` exact 12/12 guard after the AD-PLACEMENTS block.

As the orchestrator instructed, I did not edit TASKS.md; it is updated at merge. No doc under `docs/` makes a statement about achievement order or about when cards are marked seen, so no doc needed changing.

## Acceptance criteria
Unless noted, every item below is from `godot --headless --path <wt> -s res://tests/sb_tf08_achievements_readall.gd`. It exited 0 with no SCRIPT ERROR or Parse Error.

1. [x] sort_for_display (t01): a mixed list gives `[c,f,b,e,a,d]` (claimable, then claimed, then in progress, each group stable). The input is not mutated, an empty list gives an empty list, and an all-in-progress list keeps catalogue order.
2. [x] Real popup (t02).
   - Fixture: `gift_hunter` (#42) and `first_order` (#47) are claimable, `first_discovery` (#13) is claimed, and `clean_start` (#0) is in progress.
   - The VBox order equals `sort_for_display` over all 50 cards, and the groups are contiguous in the right order.
   - Positions: gift_hunter is at 0, first_discovery at 2, clean_start at 3.
   - `evaluate()` still returns catalogue order.
3. [x] Scroll (t03): `scroll_vertical` is 0 while the list is scrollable (max 7628 > page 1000).
4. [x] Claim (t04): CLAIM pays +100 SB once, the CLAIM button is removed and the COMPLETED pill shows, and the achievements badge goes 2 to 1. No card is re-parented or reordered, and a second claim is refused.
5. [x] Visibility (t05): on a fresh profile with no unread cards, ReadAll exists and is hidden. With 3 unread cards, ReadAll is visible, Set 1 shows NEW 2, Set 2 shows NEW 1, and no other set has a badge.
6. [x] Press (t06): goes through the real `_on_action("read_all")` path.
   - Exactly one facade commit: `mark_all_cards_seen`, marked 3, save ok.
   - All 3 cards are seen; every NewBadge and the ReadAll button are hidden; the album is re-armed and still open.
   - `HomeBadges` collection is 0 and every other badge key is unchanged.
7. [x] Scope (t07): the economy snapshot is identical outside `meta_ui`. `seen` gained exactly `card:s1_c0`, `card:s1_c1` and `card:s2_c0`. The unowned card `s3_c0` is not marked.
8. [x] Idempotent (t08): a second call returns `{ok: true, marked: 0}` and the snapshot does not change.
9. [x] Persistence and rollback (t09).
   - Persistence: `meta_ui.snapshot()` holds every key; a new `EconomyServices.import_snapshot` still reports them seen; reloading the AppState from the temp save on disk shows them seen with the collection badge at 0.
   - Rollback: with the save fault injector (`temp_write`) on, the result is `ok:false, reason:save_failed, restored:true`, the state is exactly the pre-press state, and 3 cards are still unread.
10. [x] Profile (t10): the Home profile badge includes the 3 cards and the Profile CollectionBadge shows 3. After Collection, READ ALL and close, the CollectionBadge is hidden and the Home profile badge drops by 3.
11. [x] Reappears (t11): a new card plus `_refresh_album` brings ReadAll back with Set 4 at NEW 1. The real top_changed path also works: after the exchange popup closes, ReadAll is visible with Set 5 at NEW 1.
12. [x] Layout (t12), EN and TR at 1080x2160.
    - Height is 88 (>= TOUCH_MIN 88), and the button lies inside the content and frame rects.
    - The label fits: EN 160/160, TR 240/240, and the minimum size is no larger than the button size.
    - The button is below PackRow and above SetList, and `text_fits()` holds with the frame on screen.
    - The frame height stays 1915 when the button hides.
    - The EN and TR keys exist.
13. [x] The suite prints `SB-TF-08 achievements order + collection read all evidence: PASS (12/12 cases, 0 fail)`.
14. [~] Regressions: all LOCAL_PASS except `m22_028_collection_card_lru`, which fails one case for a reason that predates this branch (see Validation). No existing assertion needed changing for the new order.
15. [x] The CI list and the guard were added. `git diff --check` is clean.

Captures (GPU, temp save, `tests/tools/sb_tf08_capture.gd`, 1080x2160) are in `factory/jobs/188-tf08-achievements-readall/evidence/`:
- `achievements_en.png` and `achievements_tr.png`: Gift Hunter and First Order CLAIM on top, then First Discovery COMPLETED, then Clean Start 0/1 and the rest.
- `collection_read_all_en.png` and `collection_read_all_tr.png`: the READ ALL / TÜMÜNÜ OKU row above the sets, with NEW 2 on Set 1 and NEW 1 on Set 2.
- `collection_after_read_all_en.png` and `collection_after_read_all_tr.png`: the button and badges are gone and the frame size is unchanged.

The capture process exited 139 on quit, after all six PNGs were written with err=0. That is a shutdown crash in the throwaway tool, not a test.

## Validation
Run with `$GODOT --headless --path <worktree> -s res://tests/<suite>.gd`, Godot 4.7.2. All results are LOCAL_PASS (exit 0, no SCRIPT ERROR or Parse Error, final line PASS) except where noted:
- sb_tf08_achievements_readall: PASS (12/12)
- sb_tf03_home_profile: PASS (11/11)
- m43_master_c010_meta: PASS (12/12)
- m44_meta_verify_achievements_gift: PASS (4/4)
- m44_new_badge: PASS (7/7)
- m43_master_c007_collection: PASS (19/19)
- m54_collection_set_master_exactly_once: PASS
- m47_touch_r01_mobile_ux: PASS (14/14)
- m49_surface_matrix: PASS (3/3)
- m49_surface_stress: PASS (4/4)
- m50_accessibility_audit: PASS (11/11)
- m51_localization_readiness: PASS (8/8)
- m41_settings: PASS
- m22_028_collection_card_lru: FAIL (1), and it fails on main too. Its only failing case is the thumbnail import check, which expects `compress/mode=0`. The committed `.import` files at HEAD have `compress/mode=1`, set by the earlier commit b3d68b14 ("lossy WebP import for big final/ UI art"). This branch touches no thumbnails and no `.import` file, and every LRU/album case in that suite passes. It needs a separate decision: either revert those thumbnail imports to lossless or update the test.
- `git diff --check`: clean.

## Log
### Round 1
- Implemented `sort_for_display`, sorted popup construction, `MetaUiState.mark_all_seen`, the facade action `mark_all_cards_seen` (durable), the album READ ALL button with live visibility, the EN/TR keys, the new suite, the CI list entry and guard, and the capture tool.
- Moved the button out of PackRow into its own row after the TR layout squeeze (330 px row). The row's height now comes out of the SetList, so the album frame never grows.
- Ran the new suite and all spec regression suites. One failure on main also shows here (m22_028 thumbnail import mode). Took the EN/TR captures. Did not touch TASKS.md (orchestrator).
