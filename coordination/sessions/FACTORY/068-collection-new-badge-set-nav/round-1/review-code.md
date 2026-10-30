VERDICT: PASS

## Checks
git diff --check origin/main...HEAD: pass (clean)
m43_master_c007_collection (headless): pass, 19/19 cases, 0 fail
m44_new_badge (headless): pass, 6/6
m42_home (headless): 3 FAIL, all asset-binding checks (World 01 background, Scrubby, manifest). The log shows "No loader found" for home_background.png and scrubby_home_pose.png, so the worktree is missing those image imports. It is an environment problem, unrelated to the badge. The shortcut badge is the only Home code this change touches, and m44_new_badge (6/6) exercises it.

## Findings
None.

## Notes
- In-place switch is correct. `_show_set` removes each old tile's `card:<id>` action through the `card_id` meta, then frees the tile. It builds the new tiles and marks them viewed. It sets `newly_seen` and calls `mark_dirty` only when there is something new. The `action_selected` handler is connected once in `open_set`, so signals are neither leaked nor double-connected. `rearm()` runs after prev/next, and the `rearm()` on a null `open_card` still works. The texture cache is passed through unchanged.
- k19 asserts the real properties: the `Tile_*` names, the exact `card:` action ids, `newly_seen`, the dirty flag, the modal-stack ids (so no extra popup), the 15 to 1 and 1 to 15 wraps, DETAILS on the new set, an unchanged collection snapshot and balances, 88 px sizes, and arrows sitting outside the card grid but inside the frame.
- k18 asserts a per-set count against the NEW truth for all 15 sets, the badge style and mouse filter, clearing after BACK, and a live new grant.
- The k09 change is not weaker. It used to require the action list to equal `["back"]`, and now requires no `card:` ids. The extra `prev`, `next` and `back` actions are expected now, and the silhouette/name leak check is unchanged.
- `remove_action` is new and used only by the pager. It is guarded by `has` and frees the button. `_sync_buttons` iterates `_actions`, which is already erased by then, so nothing touches the freed button.
- `make_badge` is a pure extraction. `UiShortcutButton._init` still assigns `badge` and adds it as before, so Home behavior is unchanged. The other `Badge` and `NewBadge` hits (`gameplay_screen`, `meta_ceremonies`) are separate code.
- The CI guard changed from 17/17 to 19/19, and the TASKS.md rows are present.
- Nit: the "<" and ">" strings sit in UiText, which fits the localization suite. The pager adds `center.minimum_size_changed` and an explicit `pager.custom_minimum_size` update, which is slightly fiddly but well commented.
