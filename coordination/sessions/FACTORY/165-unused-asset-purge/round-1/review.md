VERDICT: PASS

- All 159 deleted media files: stem scan against runtime sources (scripts, scenes, resources, data/config, palettes) found hits only in home_presentation_map.gd and the manifest validator (retired rows, text only) and substring false positives (slot_active, rail_straight, home_background vs home_background_plaza, bot_parts_bar_fill slug). No path-building or DirAccess code reaches a deleted file. Deleted robots/collection/cards_exchange/shop/boosters files are unreferenced frames and layers. Kept built-path families (unlock_videos, card sets, plaza shells) are intact.
- Deleted .import uids: not referenced by any non-import file.
- Export exclusions: only factory/* and flow_videos/* added (preset, txt, two workflows). tools/check_release_versioning.py: PASS.
- RETIRED_DELETED is in the validator STATUSES list and never binds.
- Godot (after --import): m42_assets PASS, m42_home_v04 18/18 0 failures, m43_master_c008_robots 10/10 PASS, m43_master_c007_collection 19/19 PASS.
- Note: --import dirtied tracked .import files in the worktree (uncommitted, not part of the branch).
