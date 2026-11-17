STATUS: READY

# Build: 165-unused-asset-purge (SB-ASSET-PURGE-2026-11-17)

## Summary
The branch deletes (git rm, with their tracked .import/.uid files) 159 media files that nothing in the shipped game loads: 208.3 MiB of source bytes. Nothing that is shown on screen was removed. The files are:
- the files the spec names (the four park-baked Home videos and their still, the old Home background, six V02 gameplay shells and `scrubbots_gameplay_master.png`);
- the other retired Home manifest entries (V04 world-baked props, the platform top, the disabled face/brush overlays, the PLAY frame) that only HOME_ASSET_MANIFEST and the presentation map mention;
- 124 `assets/ui/final/**` files that no runtime script, scene, resource or runtime-read config names, either by path or by file name, and that no pattern-built path can reach.

Manifest and doc truth:
- `assets/ui/HOME_ASSET_MANIFEST.json`: the 24 deleted entries now have status `RETIRED_DELETED` with a `deleted_note`. Their historical sha pins are kept. The park-baked `home_scrubby_videos_v1` video set is removed, so only `home_scrubby_videos_keyed_v2` is left.
- `scripts/tools/home_asset_manifest_validator.gd`: `RETIRED_DELETED` is a valid status. Like every non-APPROVED status, it needs no file and never binds.
- `scripts/ui/home/home_presentation_map.gd`: a header note, and the HOME-121/123 reason text now says the files were deleted. The rows stay, so every entry is still accounted for.
- `ASSET_GENERATION_MANIFEST.json`, `assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json`, `assets/ui/README.md` and `assets/ui/VISUAL_ASSET_INDEX.md`: the entries for deleted files are marked `RETIRED_DELETED`, or their rows are removed (148 index rows), with a purge note.

Export filters: `factory/*` and `flow_videos/*` (the owner's local, untracked Flow masters) were added to the Android preset template and the iOS preset `exclude_filter`, to `.github/android/family_first10_export_exclusions.txt`, and to both export jobs' sparse-checkout lists. `tools/check_release_versioning.py` keeps those three in step. Neither tree holds a runtime file: `factory/` already has `.gdignore`, and `flow_videos/` is not in git. So nothing changes at runtime.

Tests rewritten to the new truth (no unrelated check was weakened):
- the approved counts go from 56 to 32, with an explicit check that the 24 entries are RETIRED_DELETED and their files are gone;
- the binder and validator mutation fixtures moved from the deleted `home_bg_sky` to the live `scrubby_home_pose` / `scrubby_portrait`;
- `m42_c003` video cases now run on the keyed v2 set (all 5 gestures after job 166);
- the "historical master preserved" check became "retired master + V02 shells deleted".

Files changed: 159 media files deleted (+6 tracked .import/.uid), `.github/android/export_presets_family_first10.cfg`, `.github/android/family_first10_export_exclusions.txt`, `.github/workflows/android-family-first10.yml`, `.github/workflows/ios-ipa.yml`, `ASSET_GENERATION_MANIFEST.json`, `assets/ui/HOME_ASSET_MANIFEST.json`, `assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json`, `assets/ui/README.md`, `assets/ui/VISUAL_ASSET_INDEX.md`, `scripts/tools/home_asset_manifest_validator.gd`, `scripts/ui/home/home_presentation_map.gd`, `tests/m28_c002_c002_static_shell.gd`, `tests/m42_assets.gd`, `tests/m42_c003_scrubby_animation.gd`, `tests/m42_home_composition.gd`, `tests/m42_home_v04.gd`, `tests/m42_home_v05.gd`, `tests/m42_home_v06.gd`, `tests/maint_home_export_asset_gate_c001.gd`.
None of job 164's files were touched: data/levels, level previews and sources, the catalog, and `tools/import_release_pool_levels.py`. TASKS.md was not edited, as the caller instructed.

## How "unused" was decided (scan method)
1. Inventory: every tracked png/jpg/webp/ogv/ogg/wav/mp3/svg/mp4 outside the trees already excluded from export: 838 files, 766.7 MiB.
2. Runtime sources: every tracked .gd/.tscn/.tres/.gdshader/.cfg/project.godot outside coordination, docs, tests, tools, level_factory, content_pipeline, factory and native, plus the JSON the runtime reads (`data/config/*`, `data/palettes/*`, `assets/ui/HOME_ASSET_MANIFEST.json`).
3. For each file, I looked for its full res path, its import uid, its file name, its stem as a whole word, and its directory path.
4. Every path the code builds at runtime was enumerated with `grep` for `+ "....png/.ogv"`, `% ` formats and `DirAccess`. These are: `ui_event_card` `rewards/%s.png` (fixed REWARD_ICONS map), card art `set_%02d/card_%02d`, `gameplay_v03_plaza_shell_%s`, robot unlock videos `ROBOT_VIDEO_DIR + id + "_unlock"(.ogv|_still.png)`, gift video stills `GIFT_VIDEO_DIR + art + "_opening_still.png"` and pack video stills `VIDEO_DIR + _video_name() + "_" + kind + ".png"`. Every file those patterns can reach is kept. No runtime code scans an asset directory.
5. HOME_ASSET_MANIFEST entries were deleted only when the presentation-map mode is inactive (WORLD_BAKED_RETIRED / OWNER_RETIRED / OWNER_DISABLED) and neither the slug nor the path appears in any other runtime file.

## Kept, possibly dynamic or deliberately kept (not deleted)
- `assets/ui/final/robots/unlock_videos/*` (20): built path `ROBOT_VIDEO_DIR + id + "_unlock"`.
- `assets/ui/final/rewards/gift_videos/*_opening_still.png` and `assets/ui/final/rewards/pack_opening/videos/*_first.png` / `*_peak.png`: built paths.
- `assets/ui/final/gameplay/master/gameplay_v03_plaza_shell_*.png` (6) and `collection/cards/set_*/card_*.png`: built paths. The plaza shells are the live gameplay shells.
- `assets/ui/final/characters/scrubby/home_animation/**` (63 frames): the Home frame-set fallback (`home_scrubby_gestures_v03`), loaded through `HomeArtBinder.animation_set` in `home_screen.gd`.
- Home entries that are retired on Home but loaded elsewhere: HOME-062/063 (achievements_v2.json), HOME-066 (shop_screen), HOME-069 (standard_pack_ceremony), HOME-087 (reuse of HOME-042) and HOME-120 `world_01_whispering_park_1080x2160.png` (worlds_v1.json, the World Transition fallback_art).
- `assets/ui/final/system/splash/splash_{background,logo,scrubby}.png`: splash assets, kept per spec (only `boot_splash_portrait.png` is bound).
- `assets/ui/final/branding/*`, `assets/ui/final/marketing/*`: app icons and store assets, kept per spec.
- `assets/brand/opening/final_15_seconds_opening_video.mp4` (24.1 MiB): the owner master of the opening .ogv (PROVENANCE.md). It is not a Godot resource, so the export never packs it.
- `collection/card_frame_{common,rare,epic,legendary}.png`, `robots/robot_perk_emblem_frame.png`, `popups/level_intro/level_intro_frame.png`, `popups/level_intro/normal_level_emblem.png`: the dev preview harnesses `tests/tools/ceremony_preview/ceremony_candidates.gd` and `tests/tools/character_motion_capture.gd` load them. Kept so those tools don't break (about 9.7 MiB; candidates for a later purge together with the tools).
- `addons/game_feel_flow/icons/*.svg`: editor icons of an enabled plugin.
- `assets/art/levels/**`: level previews and sources (job 164's area).
- `assets/ui/generated/**`, `assets/ui/candidates/**`, `assets/art/references/**`: these are already in every export exclude filter and the export sparse checkout, so they never reach the APK/IPA. The spec prefers deletion only when they are exported, so they were left alone.

## Export size estimate (no apk_only build, per spec)
- Media bytes in exported trees: 766.7 MiB before, minus the 24.1 MiB mp4 that is never packed = **742.6 MiB before -> 534.4 MiB after (-208.3 MiB, -28%)**.
- Of the removed bytes, 12.8 MiB are .ogv, which ship byte-for-byte. The rest are PNG sources. Exports pack the imported textures (lossless), so the real APK/IPA saving is about the same size but not byte-exact. A real apk_only build measures it.

## Deleted files
| # | File | Bytes | Why |
|---|---|---|---|
| 1 | `assets/ui/final/home/videos/home_scrubby_wave.ogv` | 3,315,021 | spec-named retired |
| 2 | `assets/ui/final/home/videos/home_scrubby_bow.ogv` | 3,364,758 | spec-named retired |
| 3 | `assets/ui/final/home/videos/home_scrubby_turn.ogv` | 3,250,678 | spec-named retired |
| 4 | `assets/ui/final/home/videos/home_scrubby_full_turn.ogv` | 3,449,361 | spec-named retired |
| 5 | `assets/ui/final/home/videos/home_scrubby_still.png` | 1,715,416 | spec-named retired |
| 6 | `assets/ui/final/home/background/home_background.png` | 2,783,991 | spec-named retired |
| 7 | `assets/ui/final/gameplay/master/gameplay_v02_shell_5slot_3col.png` | 3,146,269 | spec-named retired |
| 8 | `assets/ui/final/gameplay/master/gameplay_v02_shell_5slot_4col.png` | 3,116,061 | spec-named retired |
| 9 | `assets/ui/final/gameplay/master/gameplay_v02_shell_5slot_5col.png` | 3,137,122 | spec-named retired |
| 10 | `assets/ui/final/gameplay/master/gameplay_v02_shell_6slot_3col.png` | 3,192,510 | spec-named retired |
| 11 | `assets/ui/final/gameplay/master/gameplay_v02_shell_6slot_4col.png` | 3,177,191 | spec-named retired |
| 12 | `assets/ui/final/gameplay/master/gameplay_v02_shell_6slot_5col.png` | 3,168,182 | spec-named retired |
| 13 | `assets/ui/final/gameplay/master/scrubbots_gameplay_master.png` | 2,500,673 | spec-named retired |
| 14 | `assets/ui/final/home/background/home_bg_sky.png` | 1,389,273 | Home manifest retired (RETIRED_DELETED) |
| 15 | `assets/ui/final/home/background/home_bg_city_far.png` | 1,333,722 | Home manifest retired (RETIRED_DELETED) |
| 16 | `assets/ui/final/home/background/home_bg_city_mid.png` | 2,525,140 | Home manifest retired (RETIRED_DELETED) |
| 17 | `assets/ui/final/home/background/home_bg_street_foreground.png` | 1,301,742 | Home manifest retired (RETIRED_DELETED) |
| 18 | `assets/ui/final/home/area_banner/home_arch_whispering_park.png` | 1,774,284 | Home manifest retired (RETIRED_DELETED) |
| 19 | `assets/ui/final/home/area_banner/home_arch_decor.png` | 1,225,643 | Home manifest retired (RETIRED_DELETED) |
| 20 | `assets/ui/final/home/platform/home_platform_main.png` | 2,112,595 | Home manifest retired (RETIRED_DELETED) |
| 21 | `assets/ui/final/home/platform/home_platform_top.png` | 1,801,797 | Home manifest retired (RETIRED_DELETED) |
| 22 | `assets/ui/final/home/environment/home_prop_cleaning_bucket.png` | 1,466,978 | Home manifest retired (RETIRED_DELETED) |
| 23 | `assets/ui/final/home/environment/home_prop_hose.png` | 1,555,110 | Home manifest retired (RETIRED_DELETED) |
| 24 | `assets/ui/final/home/environment/home_prop_foam_cluster.png` | 1,305,053 | Home manifest retired (RETIRED_DELETED) |
| 25 | `assets/ui/final/home/environment/home_prop_puddles.png` | 824,488 | Home manifest retired (RETIRED_DELETED) |
| 26 | `assets/ui/final/home/environment/home_prop_wet_floor_sign.png` | 1,219,232 | Home manifest retired (RETIRED_DELETED) |
| 27 | `assets/ui/final/home/environment/home_prop_keep_clean_sign.png` | 1,020,218 | Home manifest retired (RETIRED_DELETED) |
| 28 | `assets/ui/final/home/environment/home_prop_cleaning_equipment.png` | 1,555,215 | Home manifest retired (RETIRED_DELETED) |
| 29 | `assets/ui/final/home/environment/home_prop_neon_details.png` | 2,167,940 | Home manifest retired (RETIRED_DELETED) |
| 30 | `assets/ui/final/characters/helper_bots/helper_bot_floor_cleaner.png` | 956,334 | Home manifest retired (RETIRED_DELETED) |
| 31 | `assets/ui/final/characters/helper_bots/helper_bot_cart.png` | 1,360,982 | Home manifest retired (RETIRED_DELETED) |
| 32 | `assets/ui/final/characters/helper_bots/helper_bot_alt_pose.png` | 1,286,130 | Home manifest retired (RETIRED_DELETED) |
| 33 | `assets/ui/final/characters/scrubby/scrubby_face_blink_layer.png` | 1,456,169 | Home manifest retired (RETIRED_DELETED) |
| 34 | `assets/ui/final/characters/scrubby/scrubby_brush_arm_layer.png` | 774,383 | Home manifest retired (RETIRED_DELETED) |
| 35 | `assets/ui/final/home/play_cta/play_button_frame.png` | 1,224,010 | Home manifest retired (RETIRED_DELETED) |
| 36 | `assets/ui/final/boosters/states/booster_tutorial_pointer.png` | 1,264,198 | no runtime reference |
| 37 | `assets/ui/final/cards_exchange/card_exchange_arrow.png` | 1,492,384 | no runtime reference |
| 38 | `assets/ui/final/cards_exchange/card_stack_placeholder.png` | 1,433,570 | no runtime reference |
| 39 | `assets/ui/final/cards_exchange/exchange_all_button_frame.png` | 1,834,063 | no runtime reference |
| 40 | `assets/ui/final/cards_exchange/exchange_button_frame.png` | 1,455,680 | no runtime reference |
| 41 | `assets/ui/final/cards_exchange/scrub_bucks_receive_bundle.png` | 1,201,225 | no runtime reference |
| 42 | `assets/ui/final/characters/helper_bots/rail_scrubbot.png` | 862,650 | no runtime reference |
| 43 | `assets/ui/final/characters/robots/atlas/atlas_face_blink_layer.png` | 1,617,088 | no runtime reference |
| 44 | `assets/ui/final/characters/robots/atlas/atlas_tool_arm_layer.png` | 1,077,609 | no runtime reference |
| 45 | `assets/ui/final/characters/robots/bubbles/bubbles_face_blink_layer.png` | 1,319,776 | no runtime reference |
| 46 | `assets/ui/final/characters/robots/bubbles/bubbles_tool_arm_layer.png` | 1,174,562 | no runtime reference |
| 47 | `assets/ui/final/characters/robots/cleaning_crew_group.png` | 2,817,625 | no runtime reference |
| 48 | `assets/ui/final/characters/robots/clippy/clippy_face_blink_layer.png` | 1,381,170 | no runtime reference |
| 49 | `assets/ui/final/characters/robots/clippy/clippy_tool_arm_layer.png` | 2,040,378 | no runtime reference |
| 50 | `assets/ui/final/characters/robots/dusty/dusty_face_blink_layer.png` | 1,887,897 | no runtime reference |
| 51 | `assets/ui/final/characters/robots/dusty/dusty_tool_arm_layer.png` | 1,986,177 | no runtime reference |
| 52 | `assets/ui/final/characters/robots/moppy/moppy_face_blink_layer.png` | 1,533,342 | no runtime reference |
| 53 | `assets/ui/final/characters/robots/moppy/moppy_tool_arm_layer.png` | 934,313 | no runtime reference |
| 54 | `assets/ui/final/characters/robots/polly/polly_face_blink_layer.png` | 1,633,171 | no runtime reference |
| 55 | `assets/ui/final/characters/robots/polly/polly_tool_arm_layer.png` | 1,088,135 | no runtime reference |
| 56 | `assets/ui/final/characters/robots/rinse/rinse_face_blink_layer.png` | 1,481,771 | no runtime reference |
| 57 | `assets/ui/final/characters/robots/rinse/rinse_tool_arm_layer.png` | 1,096,109 | no runtime reference |
| 58 | `assets/ui/final/characters/robots/spark/spark_face_blink_layer.png` | 1,519,529 | no runtime reference |
| 59 | `assets/ui/final/characters/robots/spark/spark_tool_arm_layer.png` | 964,618 | no runtime reference |
| 60 | `assets/ui/final/characters/robots/squeegee/squeegee_face_blink_layer.png` | 1,182,631 | no runtime reference |
| 61 | `assets/ui/final/characters/robots/squeegee/squeegee_tool_arm_layer.png` | 1,927,476 | no runtime reference |
| 62 | `assets/ui/final/collection/collection_panel_frame.png` | 1,364,299 | no runtime reference |
| 63 | `assets/ui/final/collection/set_header_frame.png` | 1,269,723 | no runtime reference |
| 64 | `assets/ui/final/collection/set_navigation_arrow_left.png` | 968,318 | no runtime reference |
| 65 | `assets/ui/final/collection/set_navigation_arrow_right.png` | 784,769 | no runtime reference |
| 66 | `assets/ui/final/common/badges/badge_generic_frame.png` | 1,423,420 | no runtime reference |
| 67 | `assets/ui/final/common/badges/badge_notification_frame.png` | 1,015,502 | no runtime reference |
| 68 | `assets/ui/final/common/badges/badge_quantity_frame.png` | 1,608,674 | no runtime reference |
| 69 | `assets/ui/final/common/frames/button_blue_frame.png` | 999,275 | no runtime reference |
| 70 | `assets/ui/final/common/frames/button_disabled_frame.png` | 1,147,105 | no runtime reference |
| 71 | `assets/ui/final/common/frames/button_green_frame.png` | 988,660 | no runtime reference |
| 72 | `assets/ui/final/common/frames/button_purple_frame.png` | 994,676 | no runtime reference |
| 73 | `assets/ui/final/common/frames/button_red_frame.png` | 1,355,866 | no runtime reference |
| 74 | `assets/ui/final/common/frames/popup_confirmation_frame.png` | 1,314,662 | no runtime reference |
| 75 | `assets/ui/final/common/frames/progress_bar_fill.png` | 504,992 | no runtime reference |
| 76 | `assets/ui/final/common/frames/progress_bar_frame.png` | 474,996 | no runtime reference |
| 77 | `assets/ui/final/common/icons/icon_arrow_left.png` | 685,980 | no runtime reference |
| 78 | `assets/ui/final/common/icons/icon_arrow_right.png` | 665,089 | no runtime reference |
| 79 | `assets/ui/final/common/icons/icon_close.png` | 1,009,619 | no runtime reference |
| 80 | `assets/ui/final/common/icons/icon_cloud_save.png` | 1,098,404 | no runtime reference |
| 81 | `assets/ui/final/common/icons/icon_connection_lost.png` | 903,129 | no runtime reference |
| 82 | `assets/ui/final/common/icons/icon_download.png` | 1,234,098 | no runtime reference |
| 83 | `assets/ui/final/common/icons/icon_haptics.png` | 875,521 | no runtime reference |
| 84 | `assets/ui/final/common/icons/icon_language.png` | 1,181,189 | no runtime reference |
| 85 | `assets/ui/final/common/icons/icon_maintenance.png` | 1,277,402 | no runtime reference |
| 86 | `assets/ui/final/common/icons/icon_music.png` | 690,769 | no runtime reference |
| 87 | `assets/ui/final/common/icons/icon_notification.png` | 863,041 | no runtime reference |
| 88 | `assets/ui/final/common/icons/icon_notifications.png` | 1,191,952 | no runtime reference |
| 89 | `assets/ui/final/common/icons/icon_offline.png` | 1,341,812 | no runtime reference |
| 90 | `assets/ui/final/common/icons/icon_player_id.png` | 1,666,390 | no runtime reference |
| 91 | `assets/ui/final/common/icons/icon_privacy.png` | 1,517,460 | no runtime reference |
| 92 | `assets/ui/final/common/icons/icon_refresh.png` | 1,153,880 | no runtime reference |
| 93 | `assets/ui/final/common/icons/icon_save_conflict.png` | 1,085,284 | no runtime reference |
| 94 | `assets/ui/final/common/icons/icon_sound.png` | 745,752 | no runtime reference |
| 95 | `assets/ui/final/common/icons/icon_support.png` | 1,442,400 | no runtime reference |
| 96 | `assets/ui/final/common/icons/icon_update_required.png` | 1,542,946 | no runtime reference |
| 97 | `assets/ui/final/common/icons/icon_warning.png` | 1,179,858 | no runtime reference |
| 98 | `assets/ui/final/daily/daily_header_emblem.png` | 1,399,306 | no runtime reference |
| 99 | `assets/ui/final/difficulty/hard_emblem.png` | 1,466,122 | no runtime reference |
| 100 | `assets/ui/final/difficulty/very_hard_emblem.png` | 1,594,534 | no runtime reference |
| 101 | `assets/ui/final/gameplay/batch/batch_panel.png` | 1,616,743 | no runtime reference |
| 102 | `assets/ui/final/gameplay/batch/batch_tile_frame.png` | 802,572 | no runtime reference |
| 103 | `assets/ui/final/gameplay/batch/batch_tile_front_highlight.png` | 662,375 | no runtime reference |
| 104 | `assets/ui/final/gameplay/batch/batch_tile_locked_overlay.png` | 838,142 | no runtime reference |
| 105 | `assets/ui/final/gameplay/board/board_inner_frame.png` | 21,679 | no runtime reference |
| 106 | `assets/ui/final/gameplay/controls/button_pause.png` | 915,660 | no runtime reference |
| 107 | `assets/ui/final/gameplay/controls/button_speed_2x.png` | 1,020,738 | no runtime reference |
| 108 | `assets/ui/final/gameplay/controls/button_speed_2x_active.png` | 943,779 | no runtime reference |
| 109 | `assets/ui/final/gameplay/controls/button_speed_2x_countdown_frame.png` | 1,033,006 | no runtime reference |
| 110 | `assets/ui/final/gameplay/decorative/bubble_bucket.png` | 1,221,375 | no runtime reference |
| 111 | `assets/ui/final/gameplay/decorative/caution_wet_floor_sign.png` | 1,064,090 | no runtime reference |
| 112 | `assets/ui/final/gameplay/decorative/cleaning_equipment_cluster.png` | 1,606,629 | no runtime reference |
| 113 | `assets/ui/final/gameplay/decorative/flexible_hose.png` | 1,355,163 | no runtime reference |
| 114 | `assets/ui/final/gameplay/effects/fx_batch_commit.png` | 1,310,757 | no runtime reference |
| 115 | `assets/ui/final/gameplay/effects/fx_rail_travel_glow.png` | 1,512,800 | no runtime reference |
| 116 | `assets/ui/final/gameplay/effects/fx_slot_spawn_glow.png` | 1,493,862 | no runtime reference |
| 117 | `assets/ui/final/gameplay/effects/fx_tornado_clean.png` | 1,602,181 | no runtime reference |
| 118 | `assets/ui/final/gameplay/environment/gameplay_environment.png` | 1,835,673 | no runtime reference |
| 119 | `assets/ui/final/gameplay/profile/bot_parts_bar_fill.png` | 2,075 | no runtime reference |
| 120 | `assets/ui/final/gameplay/profile/bot_parts_bar_frame.png` | 2,189 | no runtime reference |
| 121 | `assets/ui/final/gameplay/profile/level_badge_frame.png` | 14,538 | no runtime reference |
| 122 | `assets/ui/final/gameplay/profile/profile_panel_frame.png` | 17,763 | no runtime reference |
| 123 | `assets/ui/final/gameplay/railroad/rail_corner_90.png` | 1,101,090 | no runtime reference |
| 124 | `assets/ui/final/gameplay/railroad/rail_end_cap.png` | 1,365,039 | no runtime reference |
| 125 | `assets/ui/final/gameplay/railroad/rail_ingress_marker.png` | 1,017,973 | no runtime reference |
| 126 | `assets/ui/final/gameplay/railroad/rail_intersection.png` | 1,047,467 | no runtime reference |
| 127 | `assets/ui/final/gameplay/railroad/rail_straight_vertical.png` | 1,052,797 | no runtime reference |
| 128 | `assets/ui/final/gameplay/railway/rail_straight.png` | 7,938 | no runtime reference |
| 129 | `assets/ui/final/gameplay/slots/slot_active.png` | 13,108 | no runtime reference |
| 130 | `assets/ui/final/gameplay/slots/slot_empty.png` | 7,379 | no runtime reference |
| 131 | `assets/ui/final/gameplay/slots/slot_filled_base.png` | 5,726 | no runtime reference |
| 132 | `assets/ui/final/gameplay/slots/slot_locked.png` | 1,082,738 | no runtime reference |
| 133 | `assets/ui/final/popups/failure/heart_empty.png` | 850,326 | no runtime reference |
| 134 | `assets/ui/final/popups/failure/refill_button_frame.png` | 1,482,866 | no runtime reference |
| 135 | `assets/ui/final/popups/failure/retry_button_frame.png` | 1,278,132 | no runtime reference |
| 136 | `assets/ui/final/popups/help/help_button_frame.png` | 1,309,135 | no runtime reference |
| 137 | `assets/ui/final/popups/help/help_panel_emblem.png` | 1,395,594 | no runtime reference |
| 138 | `assets/ui/final/popups/level_intro/hard_level_emblem.png` | 1,347,579 | no runtime reference |
| 139 | `assets/ui/final/popups/level_intro/very_hard_level_emblem.png` | 1,598,581 | no runtime reference |
| 140 | `assets/ui/final/popups/victory/continue_button_frame.png` | 1,292,779 | no runtime reference |
| 141 | `assets/ui/final/rewards/bot_parts_bundle_large.png` | 1,762,769 | no runtime reference |
| 142 | `assets/ui/final/rewards/scrub_bucks_bundle_large.png` | 2,037,038 | no runtime reference |
| 143 | `assets/ui/final/robots/bot_parts_progress_frame.png` | 507,078 | no runtime reference |
| 144 | `assets/ui/final/robots/robot_card_frame_locked.png` | 1,717,165 | no runtime reference |
| 145 | `assets/ui/final/robots/robot_card_frame_unlocked.png` | 1,632,947 | no runtime reference |
| 146 | `assets/ui/final/robots/robot_detail_hero_frame.png` | 1,607,914 | no runtime reference |
| 147 | `assets/ui/final/robots/robot_locked_silhouette.png` | 1,361,708 | no runtime reference |
| 148 | `assets/ui/final/robots/robot_portrait_frame.png` | 843,090 | no runtime reference |
| 149 | `assets/ui/final/robots/robot_selected_ring.png` | 929,259 | no runtime reference |
| 150 | `assets/ui/final/robots/robot_unlock_glow.png` | 1,407,156 | no runtime reference |
| 151 | `assets/ui/final/shop/shop_booster_bundle.png` | 1,554,079 | no runtime reference |
| 152 | `assets/ui/final/shop/shop_featured_frame.png` | 1,218,029 | no runtime reference |
| 153 | `assets/ui/final/shop/shop_item_frame.png` | 1,399,717 | no runtime reference |
| 154 | `assets/ui/final/shop/shop_purchase_button_frame.png` | 1,360,218 | no runtime reference |
| 155 | `assets/ui/final/system/loading/loading_glow.png` | 1,910,130 | no runtime reference |
| 156 | `assets/ui/final/system/loading/loading_scrubby.png` | 1,336,509 | no runtime reference |
| 157 | `assets/ui/final/system/loading/loading_spinner_ring.png` | 1,152,953 | no runtime reference |
| 158 | `assets/ui/final/system/placeholders/content_loading_placeholder.png` | 1,957,052 | no runtime reference |
| 159 | `assets/ui/final/system/placeholders/level_preview_placeholder.png` | 1,351,161 | no runtime reference |
| | **Total (159 files)** | **218,383,700** (208.3 MiB) | |

## Acceptance criteria
1. [x] **The known retired assets are deleted where nothing loads them at runtime.**
   - Deleted: `home_scrubby_{wave,bow,turn,full_turn}.ogv`, `home_scrubby_still.png`, `home_background.png`, the six `gameplay_v02_shell_*.png` and `scrubbots_gameplay_master.png`, plus 22 more retired Home manifest entries.
   - Kept, because something still loads them: HOME-062/063/066/069/087/120.
   - Evidence: m42_assets "exactly the 24 retired entries are RETIRED_DELETED and their files are gone"; m28_c002_c002_static_shell "retired scrubbots_gameplay_master.png + six V02 shells deleted"; m42_home_v04 "retired HOME-121 file was deleted".
2. [x] **Systematic scan; conservative keep list.** 124 more files with zero runtime references were deleted. The method and the kept list are above, and the deleted files are in the table.
   - The spec's never-delete classes were all kept: level previews/data, APPROVED/STATIC entries, the World Transition fallback_art (HOME-120), the keyed Home videos and their still, the plaza shells, fonts, app icons/splash, and store/branding.
3. [x] **assets/ui/generated:** already excluded from the APK/IPA (exclude_filter, plus absent from the export sparse checkout), so it was not deleted.
4. [x] **Export filters:** `factory/*` and `flow_videos/*` were added to both presets, to the exclusions file and to both sparse-checkout lists. `python -I tools/check_release_versioning.py` -> `RELEASE_VERSIONING_CHECK PASS (0 problems)`.
5. [x] **Manifests and tests now match the new truth.**
   - Manifests: HOME_ASSET_MANIFEST status `RETIRED_DELETED` (the validator accepts it), the v1 video set removed, and the ASSET_GENERATION / PLAYER_EXPERIENCE manifests, VISUAL_ASSET_INDEX, README, MASTER_UI_SYSTEM and `docs/ui_vis_006_asset_qa.csv` (36 rows) updated.
   - Tests: the counts in m42_assets, m42_home_composition, m42_home_v04/v05/v06, maint_home_export_asset_gate_c001, m42_c003 and m28 static shell were updated. The new checks are: deleted files absent, RETIRED_DELETED never binds and needs no file, and only the keyed video set remains.
6. [x] **Must not change:** no runtime script logic changed. The only runtime-file edits are comments and reason strings in `home_presentation_map.gd`, and the validator's status list.
   - Nothing that was displayed was removed: every STATIC/bound Home entry still binds (m42_home, m42_home_composition "every STATIC entry presents its approved texture"), and the texture budget, collection and robots suites PASS.
   - data/levels, previews, the catalog and the import tool are untouched (`git show --stat HEAD` lists none of them).

## Validation
All runs are LOCAL_PASS with Godot 4.7.2 (`$GODOT --headless --path <worktree> -s res://tests/<suite>.gd`), after a one-off `--import` in the fresh worktree.
- **Full CI suite list** (`python -I tools/run_suites.py --path .`, 95 suites): 94 PASS on the first run. The one failure was `ui_vis_006_asset_qa`: its CSV still listed 5 deleted PNGs ("no .import"). I pruned the 36 deleted rows from `docs/ui_vis_006_asset_qa.csv` and re-ran: `UI-VIS-006 ASSET QA: PASS` (572 PNGs, 163 with a drawn size). Result: 95/95.
- Relevant CI lines:
  - `M42 home evidence: PASS`
  - `M60 release gates evidence: PASS (6/6 cases, 0 fail)`
  - `M43 master C007 Collection evidence: PASS (19/19 cases, 0 fail)`
  - `M54 COLLECTION SET/MASTER EXACTLY-ONCE: PASS`
  - `M43 master C008 Robots evidence: PASS (10/10 cases, 0 fail)`
  - `M44 robot assembly stages evidence: PASS (4/4 cases, 0 fail)`
  - `M55 ECONOMY RELEASE REGRESSION: PASS`
  - `M49 responsive matrix evidence: PASS (8/8 cases, 0 fail)`
  - `M28-C002-C001 Gameplay V02 core evidence: PASS (14/14 cases, 0 fail)`
- **Affected suites outside the CI list** (exit 0, no SCRIPT ERROR / Parse Error):
  - m42_assets: `M42 assets evidence: PASS`
  - m42_home_composition: `9/9 cases, 0 failures`
  - m42_home_v04: `18/18 cases, 0 failures`
  - m42_home_v05: `13/13 cases, 0 failures`
  - m42_home_v06: `13/13 cases, 0 failures`
  - m42_c002_scrubby_scale: `7/7 cases, 0 failures`
  - m42_c003_scrubby_animation: `25/25 cases, 0 failures`
  - maint_home_export_asset_gate_c001: `11/11 cases, 0 failures`
  - m28_c002_c002_static_shell: `PASS (16/16 cases, 0 fail)`
  - m28_c002_c003_r01_remediation: `PASS (24/24 cases, 0 fail)`
  - m22_026_texture_budget: `M22-026 TEXTURE BUDGET: PASS`
  - m43_c005_c006_standard_pack_presentation: `PASS (28/28 cases, 0 fail)`
- `tools/check_release_versioning.py`: PASS. `git diff --check`: clean.
- The tree is clean after the commit. project.godot and the import churn were restored, and the untracked generated .import/.uid/.translation files were removed by explicit list (no git clean/stash).

## Log
### Round 1
- Inventoried and scanned the media (method above), then deleted 159 files with `git rm` (165 paths including the tracked .import/.uid).
- Introduced the `RETIRED_DELETED` manifest status and updated the manifests, docs and tests listed above.
- Added the `factory` / `flow_videos` export exclusions.
- One commit (3c24ca5c, now e8a1e874 after the rebase) on factory/165-unused-asset-purge, not pushed. TASKS.md was not edited (caller instruction).
- Deliberately kept: the dev-tool-only frames (about 9.7 MiB), the opening mp4 master and the raw-candidate trees that are already excluded from export.

### Round 1b (rebase onto job 166)
- `git pull --rebase origin main` onto 070d1786 (job 166 added the bow, full_turn and sweep keyed videos). The rebase applied with no conflicts.
- The keyed v2 set keeps all 5 gestures, and the 24 RETIRED_DELETED entries and the 32 APPROVED entries are unchanged.
- `tests/m42_c003_scrubby_animation.gd`: `VIDEO_GESTURES` is now the 5 keyed gestures, and the stream and video counts follow its size.
- Amended into the single branch commit **e8a1e874** (not pushed).
- Re-ran `--import`, then these suites. All LOCAL_PASS:
  - m42_home_v04: `18/18 cases, 0 failures`
  - m42_assets: `M42 assets evidence: PASS`
  - m42_home: `M42 home evidence: PASS`
  - m42_home_composition: `9/9 cases, 0 failures`
  - m42_c003_scrubby_animation: `25/25 cases, 0 failures`
  - maint_home_export_asset_gate_c001: `11/11 cases, 0 failures`
  - m28_c002_c003_r01_remediation: `PASS (24/24 cases, 0 fail)`
- The tree is clean.
