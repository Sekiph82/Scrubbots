VERDICT: PASS

## Checks
- git diff --check origin/main...HEAD: pass (clean)
- godot --headless --import: pass
- tests/sb_polish_004_006_ui_batch.gd: pass (10/10 cases, 0 fail; only the usual exit-time leak warnings)

## Findings
None.

## Notes
- 004: the fix is in the shared input controller (`_sync_hit_areas`, driven by both `set_terminal_stopped` and `set_modal_blocked`). That covers WON, LOST and ERROR, and Retry restores the HitAreas. HitAreas created later respect `_hits_pickable`. Correct root-cause location.
- 005: `_on_row_input` rejects a press-to-release move beyond the TouchScroll deadzone, a release on the action button, and a roster that is not the top popup. Unlocked `open_detail` drops the lock and Bot Parts lines. ACTIVE and UNLOCK paths are untouched. Tested.
- 006: the popup has no purchase path and no new currency. The pack action is blocked and UNAVAILABLE, and MORE IN SHOP reuses `open_shop`. Presentation only. Economy lock is respected.
- The `set_action_blocked` and `_balance_row` usage matches the Life popup pattern.
- Minor: the shop_screen.gd header comment line is now over-long. Style only.
