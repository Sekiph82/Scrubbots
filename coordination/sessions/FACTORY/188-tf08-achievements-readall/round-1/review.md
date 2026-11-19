VERDICT: PASS

## Suite results (run sequentially, foreground, in the worktree)
- git diff --check 7bf6c2aa..HEAD: clean
- sb_tf08_achievements_readall: PASS (12/12 cases, 0 fail), exact guard line printed
- sb_tf03_home_profile: PASS 11/11
- m43_master_c007_collection: PASS 19/19
- m44_new_badge: PASS 7/7
- m43_master_c010_meta: PASS 12/12
- m50_accessibility_audit: PASS 11/11
- m51_localization_readiness: PASS 8/8
- m22_028_collection_card_lru: not run. The branch diff touches no .import or thumbnail files (grep over the changed-file list was empty), so the builder's claim that it fails the same way on main is consistent. Not blocking.

## Findings
None.

## Spec check
- Order: `Achievements.sort_for_display` is pure and non-mutating. It returns claimable, then claimed, then in progress, with catalogue order kept inside each group. `open_achievements` uses it. `evaluate` and `claimable_count` are unchanged. In-place claim behaviour is untouched, and the new popup order is applied only on open.
- Scroll: a new ScrollContainer starts at 0. The suite covers it.
- Facade: `mark_all_cards_seen` goes through `_finish_durable`, so there is one save with rollback. It marks only `card:<id>` for owned cards (owned > 0). `MetaUiState.mark_all_seen` counts only newly marked keys, so the call is idempotent. Nothing else in the economy is touched. The UI calls only the facade.
- Button: `ReadAll` (action id `read_all`) sits on its own row above `SetList`. Its visibility is re-evaluated in `_refresh_album`, so it reappears after a new card is granted. The SetList height is reduced by the button's height so the album frame does not grow. The press handler calls the facade and then `back.call()`, which rebuilds the album.
- Text: the `COLLECTION_READ_ALL` key exists in EN ("READ ALL") and TR ("TÜMÜNÜ OKU"), and m51 parity passes.
- CI: the suite is added to the validate list, and a PASS-line guard block is added in the style of the SB-TF-07 guard.
- Commits: no committed `.import` files.

## Evidence PNGs (all 6 viewed)
- Achievements EN and TR: the two CLAIM rows come first, then COMPLETED, then the in-progress rows. Text is not clipped.
- Collection with READ ALL, EN and TR: the button sits on its own centred row above the list. The labels fit and the set NewBadges show 2 and 1. Both language buttons look to be at least touch-minimum height.
- After READ ALL, EN and TR: the button is gone, the badges are cleared, and the frame size is unchanged.

## Notes
- A "+100" reward-fly overlay is stamped over the list in every screenshot. It looks like a capture-time leftover from the harness and is not part of the change. It is cosmetic and covers some row text in the evidence only.
- The own-row layout is acceptable and keeps the album frame at the same height.
- The Profile popup's collection badge and the Home badge are covered by suite case 10, which passed.
