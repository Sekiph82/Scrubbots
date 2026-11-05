# Review round 1 - 096-orphan-image-cleanup (SB-M22-027)

1. icon_pause.png unused: grep of code/scenes/data/yml/cfg finds no reference outside workflow comment, docs, and old coordination logs. Pause button is a native Button ("PauseButton" + _pause_glyph Control) in gameplay_screen.gd. OK.
2. ios-ipa.yml: the special case only excluded the file from the CI sparse checkout, asserted its absence, and counted it in the PCK. The file is now deleted from the repo, so removing the sparse-checkout line, the absence check, the exclude_filter entry and the informational grep is consistent. The PCK scan gate (verdict=PASS) is untouched. Cannot break the build; the deletion also removes the import error that the fail-closed import step would otherwise hit.
3. Diff vs origin/main: only deletion is icon_pause.png (7531 B, truncated); modified files are ios-ipa.yml, TASKS.md, VISUAL_ASSET_INDEX.md, IOS_TOOLCHAIN.md. Added: inventory md/csv and tool. No art overwritten.
4. Inventory tool: writes only the csv/md outputs (open(..., "w") for csv_out/md_out), no delete/unlink calls. `python -I tools/m22_027_image_inventory.py --selftest` prints "selftest PASS". Spot-checked rows: FUTURE_NEEDED (spark_tool_arm_layer, button_speed_2x_active: named in index/manifest) and DYNAMIC_REF (addons icons dir-load, pack_opening premium frames via dir/pattern refs in ceremony scripts) are conservative and honest. Counts: 145 FUTURE_NEEDED, 74 DYNAMIC_REF, 1 CONFIRMED_ORPHAN.

Must-fix: none.

VERDICT: PASS
