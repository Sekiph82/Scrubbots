# SCRUBBOTS — VISUAL ASSET INDEX

Status: CANONICAL VISUAL DISCOVERY INDEX
Branch audited: `codex/visual-assets-production`
Purpose: single lookup map for Claude/Godot UI integration.

## How Claude should use this file

1. Prefer assets under `assets/ui/final/**` for production UI.
2. Treat `assets/ui/generated/**` as generated candidates/source material, not automatic production truth.
3. Treat `assets/art/references/**` as owner/reference material. Never bind reference screenshots directly as runtime UI unless explicitly authorized.
4. For gameplay composition, follow the owner gameplay master/decision files rather than inferring layout from isolated assets.
5. Dynamic text, timers, counts, prices, balances, progress values and gameplay state remain live Godot UI.
6. Do not silently regenerate or overwrite an existing production visual.
7. Legacy duplicate paths are listed separately below. Prefer the canonical path called out in that section.

## Audit summary

- Production visual files under `assets/ui/final/**`: **456**
- Phase 1 canonical target paths: **306**
- Phase 2 canonical target paths: **144**
- Combined canonical target paths: **450**
- Canonical targets missing on audited branch: **0**
- Extra production PNGs outside Phase 1/Phase 2 canonical lists: **6**
- Generated candidate/source visuals: **27**
- Owner/reference visuals: **51**
- Other project art/reference visuals: **4**
- Total visual files indexed here: **538**

## Canonical authorities

- Gameplay master: `assets/ui/final/gameplay/master/scrubbots_gameplay_master.png`
- Home reference: `assets/art/references/_owner_inbox/Game Screens/main screen.png`
- Phase 1 master list: `coordination/codex_visual_assets/CODEX_VISUAL_ASSET_MASTER_LIST.md`
- Phase 2 master list: `coordination/codex_visual_assets/CODEX_PROJECT_VISUALS_PHASE2_MASTER_LIST.md`
- Robot roster: `coordination/OWNER_ROBOT_ROSTER_V01.md`
- Visual publish/log policy: `coordination/codex_visual_assets/CODEX_VISUAL_PUBLISH_AND_LOG_POLICY.md`

## Production assets


### boosters (10)

| Path | Authority | Bytes |
|---|---|---:|
| `assets/ui/final/boosters/extra_slot.png` | Phase 1 | 1,591,751 |
| `assets/ui/final/boosters/random.png` | Phase 1 | 1,249,060 |
| `assets/ui/final/boosters/selector.png` | Phase 1 | 1,179,126 |
| `assets/ui/final/boosters/states/booster_activated_burst.png` | Phase 2 P2-044 | 1,758,413 |
| `assets/ui/final/boosters/states/booster_free_badge_frame.png` | Phase 2 P2-046 | 1,096,228 |
| `assets/ui/final/boosters/states/booster_reward_glow.png` | Phase 2 P2-043 | 1,703,097 |
| `assets/ui/final/boosters/states/booster_selected_ring.png` | Phase 2 P2-041 | 1,115,635 |
| `assets/ui/final/boosters/states/booster_tutorial_pointer.png` | Phase 2 P2-045 | 1,264,198 |
| `assets/ui/final/boosters/states/booster_unavailable_overlay.png` | Phase 2 P2-042 | 1,709,253 |
| `assets/ui/final/boosters/tornado.png` | Phase 1 | 1,179,175 |

### branding (7)

| Path | Authority | Bytes |
|---|---|---:|
| `assets/ui/final/branding/app_icon_android_background.png` | Phase 2 P2-005 | 1,368,868 |
| `assets/ui/final/branding/app_icon_android_foreground.png` | Phase 2 P2-004 | 1,848,535 |
| `assets/ui/final/branding/app_icon_ios_1024.png` | Phase 2 P2-007 | 1,296,441 |
| `assets/ui/final/branding/app_icon_master.png` | Phase 2 P2-003 | 1,354,809 |
| `assets/ui/final/branding/icon_notification_android.png` | Phase 2 P2-006 | 133,438 |
| `assets/ui/final/branding/logo_colorful.png` | Phase 2 P2-001 | 1,312,961 |
| `assets/ui/final/branding/logo_simple_wide.png` | Phase 2 P2-002 | 1,030,768 |

### cards_exchange (6)

| Path | Authority | Bytes |
|---|---|---:|
| `assets/ui/final/cards_exchange/card_exchange_arrow.png` | Phase 1 | 1,492,384 |
| `assets/ui/final/cards_exchange/card_stack_placeholder.png` | Phase 1 | 1,433,570 |
| `assets/ui/final/cards_exchange/cards_exchange_header_emblem.png` | Phase 1 | 1,163,027 |
| `assets/ui/final/cards_exchange/exchange_all_button_frame.png` | Phase 1 | 1,834,063 |
| `assets/ui/final/cards_exchange/exchange_button_frame.png` | Phase 1 | 1,455,680 |
| `assets/ui/final/cards_exchange/scrub_bucks_receive_bundle.png` | Phase 1 | 1,201,225 |

### characters (64)

| Path | Authority | Bytes |
|---|---|---:|
| `assets/ui/final/characters/helper_bots/helper_bot_alt_pose.png` | Phase 1 | 1,286,130 |
| `assets/ui/final/characters/helper_bots/helper_bot_cart.png` | Phase 1 | 1,360,982 |
| `assets/ui/final/characters/helper_bots/helper_bot_floor_cleaner.png` | Phase 1 | 956,334 |
| `assets/ui/final/characters/helper_bots/rail_scrubbot.png` | Phase 1 | 862,650 |
| `assets/ui/final/characters/robots/atlas/atlas_face_blink_layer.png` | Phase 2 P2-140 | 1,617,088 |
| `assets/ui/final/characters/robots/atlas/atlas_gameplay.png` | Phase 2 P2-137 | 1,686,731 |
| `assets/ui/final/characters/robots/atlas/atlas_home_pose.png` | Phase 2 P2-139 | 2,264,391 |
| `assets/ui/final/characters/robots/atlas/atlas_master.png` | Phase 2 P2-136 | 1,934,835 |
| `assets/ui/final/characters/robots/atlas/atlas_portrait.png` | Phase 2 P2-138 | 2,237,835 |
| `assets/ui/final/characters/robots/atlas/atlas_tool_arm_layer.png` | Phase 2 P2-141 | 1,077,609 |
| `assets/ui/final/characters/robots/bubbles/bubbles_face_blink_layer.png` | Phase 2 P2-077 | 1,319,776 |
| `assets/ui/final/characters/robots/bubbles/bubbles_gameplay.png` | Phase 2 P2-074 | 1,555,816 |
| `assets/ui/final/characters/robots/bubbles/bubbles_home_pose.png` | Phase 2 P2-076 | 2,123,120 |
| `assets/ui/final/characters/robots/bubbles/bubbles_master.png` | Phase 2 P2-073 | 1,509,511 |
| `assets/ui/final/characters/robots/bubbles/bubbles_portrait.png` | Phase 2 P2-075 | 1,503,030 |
| `assets/ui/final/characters/robots/bubbles/bubbles_tool_arm_layer.png` | Phase 2 P2-078 | 1,174,562 |
| `assets/ui/final/characters/robots/clippy/clippy_face_blink_layer.png` | Phase 2 P2-131 | 1,381,170 |
| `assets/ui/final/characters/robots/clippy/clippy_gameplay.png` | Phase 2 P2-128 | 1,440,278 |
| `assets/ui/final/characters/robots/clippy/clippy_home_pose.png` | Phase 2 P2-130 | 2,024,325 |
| `assets/ui/final/characters/robots/clippy/clippy_master.png` | Phase 2 P2-127 | 1,557,624 |
| `assets/ui/final/characters/robots/clippy/clippy_portrait.png` | Phase 2 P2-129 | 1,618,890 |
| `assets/ui/final/characters/robots/clippy/clippy_tool_arm_layer.png` | Phase 2 P2-132 | 2,040,378 |
| `assets/ui/final/characters/robots/dusty/dusty_face_blink_layer.png` | Phase 2 P2-104 | 1,887,897 |
| `assets/ui/final/characters/robots/dusty/dusty_gameplay.png` | Phase 2 P2-101 | 1,495,212 |
| `assets/ui/final/characters/robots/dusty/dusty_home_pose.png` | Phase 2 P2-103 | 2,058,202 |
| `assets/ui/final/characters/robots/dusty/dusty_master.png` | Phase 2 P2-100 | 1,545,078 |
| `assets/ui/final/characters/robots/dusty/dusty_portrait.png` | Phase 2 P2-102 | 1,620,173 |
| `assets/ui/final/characters/robots/dusty/dusty_tool_arm_layer.png` | Phase 2 P2-105 | 1,986,177 |
| `assets/ui/final/characters/robots/moppy/moppy_face_blink_layer.png` | Phase 2 P2-068 | 1,533,342 |
| `assets/ui/final/characters/robots/moppy/moppy_gameplay.png` | Phase 2 P2-065 | 1,284,395 |
| `assets/ui/final/characters/robots/moppy/moppy_home_pose.png` | Phase 2 P2-067 | 2,041,722 |
| `assets/ui/final/characters/robots/moppy/moppy_master.png` | Phase 2 P2-064 | 1,460,771 |
| `assets/ui/final/characters/robots/moppy/moppy_portrait.png` | Phase 2 P2-066 | 1,684,947 |
| `assets/ui/final/characters/robots/moppy/moppy_tool_arm_layer.png` | Phase 2 P2-069 | 934,313 |
| `assets/ui/final/characters/robots/polly/polly_face_blink_layer.png` | Phase 2 P2-122 | 1,633,171 |
| `assets/ui/final/characters/robots/polly/polly_gameplay.png` | Phase 2 P2-119 | 1,413,837 |
| `assets/ui/final/characters/robots/polly/polly_home_pose.png` | Phase 2 P2-121 | 1,318,982 |
| `assets/ui/final/characters/robots/polly/polly_master.png` | Phase 2 P2-118 | 1,463,472 |
| `assets/ui/final/characters/robots/polly/polly_portrait.png` | Phase 2 P2-120 | 1,540,128 |
| `assets/ui/final/characters/robots/polly/polly_tool_arm_layer.png` | Phase 2 P2-123 | 1,088,135 |
| `assets/ui/final/characters/robots/rinse/rinse_face_blink_layer.png` | Phase 2 P2-113 | 1,481,771 |
| `assets/ui/final/characters/robots/rinse/rinse_gameplay.png` | Phase 2 P2-110 | 1,462,820 |
| `assets/ui/final/characters/robots/rinse/rinse_home_pose.png` | Phase 2 P2-112 | 1,940,014 |
| `assets/ui/final/characters/robots/rinse/rinse_master.png` | Phase 2 P2-109 | 1,386,814 |
| `assets/ui/final/characters/robots/rinse/rinse_portrait.png` | Phase 2 P2-111 | 1,611,064 |
| `assets/ui/final/characters/robots/rinse/rinse_tool_arm_layer.png` | Phase 2 P2-114 | 1,096,109 |
| `assets/ui/final/characters/robots/spark/spark_face_blink_layer.png` | Phase 2 P2-086 | 1,519,529 |
| `assets/ui/final/characters/robots/spark/spark_gameplay.png` | Phase 2 P2-083 | 1,627,019 |
| `assets/ui/final/characters/robots/spark/spark_home_pose.png` | Phase 2 P2-085 | 1,967,402 |
| `assets/ui/final/characters/robots/spark/spark_master.png` | Phase 2 P2-082 | 1,502,033 |
| `assets/ui/final/characters/robots/spark/spark_portrait.png` | Phase 2 P2-084 | 1,461,468 |
| `assets/ui/final/characters/robots/spark/spark_tool_arm_layer.png` | Phase 2 P2-087 | 964,618 |
| `assets/ui/final/characters/robots/squeegee/squeegee_face_blink_layer.png` | Phase 2 P2-095 | 1,182,631 |
| `assets/ui/final/characters/robots/squeegee/squeegee_gameplay.png` | Phase 2 P2-092 | 1,272,555 |
| `assets/ui/final/characters/robots/squeegee/squeegee_home_pose.png` | Phase 2 P2-094 | 1,962,310 |
| `assets/ui/final/characters/robots/squeegee/squeegee_master.png` | Phase 2 P2-091 | 1,438,622 |
| `assets/ui/final/characters/robots/squeegee/squeegee_portrait.png` | Phase 2 P2-093 | 1,436,695 |
| `assets/ui/final/characters/robots/squeegee/squeegee_tool_arm_layer.png` | Phase 2 P2-096 | 1,927,476 |
| `assets/ui/final/characters/scrubby/scrubby_brush_arm_layer.png` | Phase 1 | 774,383 |
| `assets/ui/final/characters/scrubby/scrubby_face_blink_layer.png` | Phase 1 | 1,456,169 |
| `assets/ui/final/characters/scrubby/scrubby_gameplay.png` | Phase 1 | 1,157,666 |
| `assets/ui/final/characters/scrubby/scrubby_home_pose.png` | Phase 1 | 1,407,303 |
| `assets/ui/final/characters/scrubby/scrubby_master.png` | Phase 1 | 1,143,456 |
| `assets/ui/final/characters/scrubby/scrubby_portrait.png` | Phase 1 | 741,149 |

### collection (145)

| Path | Authority | Bytes |
|---|---|---:|
| `assets/ui/final/collection/card_frame_common.png` | Phase 1 | 1,329,487 |
| `assets/ui/final/collection/card_frame_epic.png` | Phase 1 | 1,557,751 |
| `assets/ui/final/collection/card_frame_legendary.png` | Phase 1 | 1,609,952 |
| `assets/ui/final/collection/card_frame_rare.png` | Phase 1 | 1,511,105 |
| `assets/ui/final/collection/cards/set_01/card_01.png` | Phase 1 | 130,888 |
| `assets/ui/final/collection/cards/set_01/card_02.png` | Phase 1 | 147,614 |
| `assets/ui/final/collection/cards/set_01/card_03.png` | Phase 1 | 124,664 |
| `assets/ui/final/collection/cards/set_01/card_04.png` | Phase 1 | 122,293 |
| `assets/ui/final/collection/cards/set_01/card_05.png` | Phase 1 | 129,958 |
| `assets/ui/final/collection/cards/set_01/card_06.png` | Phase 1 | 128,145 |
| `assets/ui/final/collection/cards/set_01/card_07.png` | Phase 1 | 131,723 |
| `assets/ui/final/collection/cards/set_01/card_08.png` | Phase 1 | 136,879 |
| `assets/ui/final/collection/cards/set_01/card_09.png` | Phase 1 | 150,976 |
| `assets/ui/final/collection/cards/set_02/card_01.png` | Phase 1 | 137,465 |
| `assets/ui/final/collection/cards/set_02/card_02.png` | Phase 1 | 155,075 |
| `assets/ui/final/collection/cards/set_02/card_03.png` | Phase 1 | 132,657 |
| `assets/ui/final/collection/cards/set_02/card_04.png` | Phase 1 | 130,659 |
| `assets/ui/final/collection/cards/set_02/card_05.png` | Phase 1 | 129,705 |
| `assets/ui/final/collection/cards/set_02/card_06.png` | Phase 1 | 123,743 |
| `assets/ui/final/collection/cards/set_02/card_07.png` | Phase 1 | 134,913 |
| `assets/ui/final/collection/cards/set_02/card_08.png` | Phase 1 | 138,500 |
| `assets/ui/final/collection/cards/set_02/card_09.png` | Phase 1 | 147,616 |
| `assets/ui/final/collection/cards/set_03/card_01.png` | Phase 1 | 129,308 |
| `assets/ui/final/collection/cards/set_03/card_02.png` | Phase 1 | 157,341 |
| `assets/ui/final/collection/cards/set_03/card_03.png` | Phase 1 | 135,443 |
| `assets/ui/final/collection/cards/set_03/card_04.png` | Phase 1 | 145,357 |
| `assets/ui/final/collection/cards/set_03/card_05.png` | Phase 1 | 141,368 |
| `assets/ui/final/collection/cards/set_03/card_06.png` | Phase 1 | 131,168 |
| `assets/ui/final/collection/cards/set_03/card_07.png` | Phase 1 | 148,267 |
| `assets/ui/final/collection/cards/set_03/card_08.png` | Phase 1 | 158,662 |
| `assets/ui/final/collection/cards/set_03/card_09.png` | Phase 1 | 151,909 |
| `assets/ui/final/collection/cards/set_04/card_01.png` | Phase 1 | 137,722 |
| `assets/ui/final/collection/cards/set_04/card_02.png` | Phase 1 | 146,845 |
| `assets/ui/final/collection/cards/set_04/card_03.png` | Phase 1 | 136,316 |
| `assets/ui/final/collection/cards/set_04/card_04.png` | Phase 1 | 134,120 |
| `assets/ui/final/collection/cards/set_04/card_05.png` | Phase 1 | 137,284 |
| `assets/ui/final/collection/cards/set_04/card_06.png` | Phase 1 | 128,962 |
| `assets/ui/final/collection/cards/set_04/card_07.png` | Phase 1 | 132,373 |
| `assets/ui/final/collection/cards/set_04/card_08.png` | Phase 1 | 139,238 |
| `assets/ui/final/collection/cards/set_04/card_09.png` | Phase 1 | 153,930 |
| `assets/ui/final/collection/cards/set_05/card_01.png` | Phase 1 | 134,392 |
| `assets/ui/final/collection/cards/set_05/card_02.png` | Phase 1 | 146,120 |
| `assets/ui/final/collection/cards/set_05/card_03.png` | Phase 1 | 122,201 |
| `assets/ui/final/collection/cards/set_05/card_04.png` | Phase 1 | 124,687 |
| `assets/ui/final/collection/cards/set_05/card_05.png` | Phase 1 | 137,575 |
| `assets/ui/final/collection/cards/set_05/card_06.png` | Phase 1 | 122,511 |
| `assets/ui/final/collection/cards/set_05/card_07.png` | Phase 1 | 138,487 |
| `assets/ui/final/collection/cards/set_05/card_08.png` | Phase 1 | 146,152 |
| `assets/ui/final/collection/cards/set_05/card_09.png` | Phase 1 | 140,978 |
| `assets/ui/final/collection/cards/set_06/card_01.png` | Phase 1 | 148,744 |
| `assets/ui/final/collection/cards/set_06/card_02.png` | Phase 1 | 160,333 |
| `assets/ui/final/collection/cards/set_06/card_03.png` | Phase 1 | 146,055 |
| `assets/ui/final/collection/cards/set_06/card_04.png` | Phase 1 | 138,909 |
| `assets/ui/final/collection/cards/set_06/card_05.png` | Phase 1 | 151,142 |
| `assets/ui/final/collection/cards/set_06/card_06.png` | Phase 1 | 135,118 |
| `assets/ui/final/collection/cards/set_06/card_07.png` | Phase 1 | 154,156 |
| `assets/ui/final/collection/cards/set_06/card_08.png` | Phase 1 | 166,106 |
| `assets/ui/final/collection/cards/set_06/card_09.png` | Phase 1 | 154,440 |
| `assets/ui/final/collection/cards/set_07/card_01.png` | Phase 1 | 149,716 |
| `assets/ui/final/collection/cards/set_07/card_02.png` | Phase 1 | 158,548 |
| `assets/ui/final/collection/cards/set_07/card_03.png` | Phase 1 | 137,072 |
| `assets/ui/final/collection/cards/set_07/card_04.png` | Phase 1 | 129,308 |
| `assets/ui/final/collection/cards/set_07/card_05.png` | Phase 1 | 138,092 |
| `assets/ui/final/collection/cards/set_07/card_06.png` | Phase 1 | 127,040 |
| `assets/ui/final/collection/cards/set_07/card_07.png` | Phase 1 | 132,224 |
| `assets/ui/final/collection/cards/set_07/card_08.png` | Phase 1 | 160,318 |
| `assets/ui/final/collection/cards/set_07/card_09.png` | Phase 1 | 157,746 |
| `assets/ui/final/collection/cards/set_08/card_01.png` | Phase 1 | 137,139 |
| `assets/ui/final/collection/cards/set_08/card_02.png` | Phase 1 | 137,064 |
| `assets/ui/final/collection/cards/set_08/card_03.png` | Phase 1 | 128,685 |
| `assets/ui/final/collection/cards/set_08/card_04.png` | Phase 1 | 137,431 |
| `assets/ui/final/collection/cards/set_08/card_05.png` | Phase 1 | 144,016 |
| `assets/ui/final/collection/cards/set_08/card_06.png` | Phase 1 | 127,000 |
| `assets/ui/final/collection/cards/set_08/card_07.png` | Phase 1 | 142,351 |
| `assets/ui/final/collection/cards/set_08/card_08.png` | Phase 1 | 142,510 |
| `assets/ui/final/collection/cards/set_08/card_09.png` | Phase 1 | 157,478 |
| `assets/ui/final/collection/cards/set_09/card_01.png` | Phase 1 | 147,914 |
| `assets/ui/final/collection/cards/set_09/card_02.png` | Phase 1 | 153,092 |
| `assets/ui/final/collection/cards/set_09/card_03.png` | Phase 1 | 137,369 |
| `assets/ui/final/collection/cards/set_09/card_04.png` | Phase 1 | 142,640 |
| `assets/ui/final/collection/cards/set_09/card_05.png` | Phase 1 | 153,775 |
| `assets/ui/final/collection/cards/set_09/card_06.png` | Phase 1 | 137,856 |
| `assets/ui/final/collection/cards/set_09/card_07.png` | Phase 1 | 148,840 |
| `assets/ui/final/collection/cards/set_09/card_08.png` | Phase 1 | 163,305 |
| `assets/ui/final/collection/cards/set_09/card_09.png` | Phase 1 | 168,647 |
| `assets/ui/final/collection/cards/set_10/card_01.png` | Phase 1 | 169,317 |
| `assets/ui/final/collection/cards/set_10/card_02.png` | Phase 1 | 176,693 |
| `assets/ui/final/collection/cards/set_10/card_03.png` | Phase 1 | 155,865 |
| `assets/ui/final/collection/cards/set_10/card_04.png` | Phase 1 | 155,227 |
| `assets/ui/final/collection/cards/set_10/card_05.png` | Phase 1 | 173,236 |
| `assets/ui/final/collection/cards/set_10/card_06.png` | Phase 1 | 151,705 |
| `assets/ui/final/collection/cards/set_10/card_07.png` | Phase 1 | 165,145 |
| `assets/ui/final/collection/cards/set_10/card_08.png` | Phase 1 | 168,552 |
| `assets/ui/final/collection/cards/set_10/card_09.png` | Phase 1 | 167,607 |
| `assets/ui/final/collection/cards/set_11/card_01.png` | Phase 1 | 163,865 |
| `assets/ui/final/collection/cards/set_11/card_02.png` | Phase 1 | 174,776 |
| `assets/ui/final/collection/cards/set_11/card_03.png` | Phase 1 | 162,821 |
| `assets/ui/final/collection/cards/set_11/card_04.png` | Phase 1 | 155,981 |
| `assets/ui/final/collection/cards/set_11/card_05.png` | Phase 1 | 162,170 |
| `assets/ui/final/collection/cards/set_11/card_06.png` | Phase 1 | 148,743 |
| `assets/ui/final/collection/cards/set_11/card_07.png` | Phase 1 | 156,491 |
| `assets/ui/final/collection/cards/set_11/card_08.png` | Phase 1 | 169,308 |
| `assets/ui/final/collection/cards/set_11/card_09.png` | Phase 1 | 169,758 |
| `assets/ui/final/collection/cards/set_12/card_01.png` | Phase 1 | 164,676 |
| `assets/ui/final/collection/cards/set_12/card_02.png` | Phase 1 | 174,501 |
| `assets/ui/final/collection/cards/set_12/card_03.png` | Phase 1 | 149,548 |
| `assets/ui/final/collection/cards/set_12/card_04.png` | Phase 1 | 156,574 |
| `assets/ui/final/collection/cards/set_12/card_05.png` | Phase 1 | 167,903 |
| `assets/ui/final/collection/cards/set_12/card_06.png` | Phase 1 | 150,078 |
| `assets/ui/final/collection/cards/set_12/card_07.png` | Phase 1 | 166,162 |
| `assets/ui/final/collection/cards/set_12/card_08.png` | Phase 1 | 168,514 |
| `assets/ui/final/collection/cards/set_12/card_09.png` | Phase 1 | 165,929 |
| `assets/ui/final/collection/cards/set_13/card_01.png` | Phase 1 | 178,493 |
| `assets/ui/final/collection/cards/set_13/card_02.png` | Phase 1 | 188,320 |
| `assets/ui/final/collection/cards/set_13/card_03.png` | Phase 1 | 166,298 |
| `assets/ui/final/collection/cards/set_13/card_04.png` | Phase 1 | 165,493 |
| `assets/ui/final/collection/cards/set_13/card_05.png` | Phase 1 | 172,931 |
| `assets/ui/final/collection/cards/set_13/card_06.png` | Phase 1 | 158,581 |
| `assets/ui/final/collection/cards/set_13/card_07.png` | Phase 1 | 164,193 |
| `assets/ui/final/collection/cards/set_13/card_08.png` | Phase 1 | 173,302 |
| `assets/ui/final/collection/cards/set_13/card_09.png` | Phase 1 | 169,076 |
| `assets/ui/final/collection/cards/set_14/card_01.png` | Phase 1 | 178,043 |
| `assets/ui/final/collection/cards/set_14/card_02.png` | Phase 1 | 183,622 |
| `assets/ui/final/collection/cards/set_14/card_03.png` | Phase 1 | 180,550 |
| `assets/ui/final/collection/cards/set_14/card_04.png` | Phase 1 | 176,421 |
| `assets/ui/final/collection/cards/set_14/card_05.png` | Phase 1 | 176,588 |
| `assets/ui/final/collection/cards/set_14/card_06.png` | Phase 1 | 165,106 |
| `assets/ui/final/collection/cards/set_14/card_07.png` | Phase 1 | 171,308 |
| `assets/ui/final/collection/cards/set_14/card_08.png` | Phase 1 | 182,586 |
| `assets/ui/final/collection/cards/set_14/card_09.png` | Phase 1 | 190,187 |
| `assets/ui/final/collection/cards/set_15/card_01.png` | Phase 1 | 182,060 |
| `assets/ui/final/collection/cards/set_15/card_02.png` | Phase 1 | 203,416 |
| `assets/ui/final/collection/cards/set_15/card_03.png` | Phase 1 | 172,919 |
| `assets/ui/final/collection/cards/set_15/card_04.png` | Phase 1 | 186,320 |
| `assets/ui/final/collection/cards/set_15/card_05.png` | Phase 1 | 198,636 |
| `assets/ui/final/collection/cards/set_15/card_06.png` | Phase 1 | 169,603 |
| `assets/ui/final/collection/cards/set_15/card_07.png` | Phase 1 | 190,719 |
| `assets/ui/final/collection/cards/set_15/card_08.png` | Phase 1 | 200,193 |
| `assets/ui/final/collection/cards/set_15/card_09.png` | Phase 1 | 184,652 |
| `assets/ui/final/collection/collection_complete_emblem.png` | Phase 1 | 1,313,371 |
| `assets/ui/final/collection/collection_panel_frame.png` | Phase 1 | 1,364,299 |
| `assets/ui/final/collection/master_collection_emblem.png` | Phase 1 | 1,646,178 |
| `assets/ui/final/collection/set_header_frame.png` | Phase 1 | 1,269,723 |
| `assets/ui/final/collection/set_navigation_arrow_left.png` | Phase 1 | 968,318 |
| `assets/ui/final/collection/set_navigation_arrow_right.png` | Phase 1 | 784,769 |

### common (49)

| Path | Authority | Bytes |
|---|---|---:|
| `assets/ui/final/common/badges/badge_generic_frame.png` | Phase 2 P2-036 | 1,423,420 |
| `assets/ui/final/common/badges/badge_notification_frame.png` | Phase 2 P2-037 | 1,015,502 |
| `assets/ui/final/common/badges/badge_quantity_frame.png` | Phase 2 P2-038 | 1,608,674 |
| `assets/ui/final/common/currencies/icon_currency_heart.png` | Phase 1 | 978,806 |
| `assets/ui/final/common/currencies/icon_currency_scrub_bucks.png` | Phase 1 | 1,177,566 |
| `assets/ui/final/common/frames/button_blue_frame.png` | Phase 2 P2-031 | 999,275 |
| `assets/ui/final/common/frames/button_disabled_frame.png` | Phase 2 P2-035 | 1,147,105 |
| `assets/ui/final/common/frames/button_green_frame.png` | Phase 2 P2-032 | 988,660 |
| `assets/ui/final/common/frames/button_purple_frame.png` | Phase 2 P2-033 | 994,676 |
| `assets/ui/final/common/frames/button_red_frame.png` | Phase 2 P2-034 | 1,355,866 |
| `assets/ui/final/common/frames/popup_confirmation_frame.png` | Phase 2 P2-028 | 1,314,662 |
| `assets/ui/final/common/frames/popup_large_frame.png` | Phase 2 P2-027 | 1,148,508 |
| `assets/ui/final/common/frames/popup_medium_frame.png` | Phase 2 P2-026 | 1,220,083 |
| `assets/ui/final/common/frames/popup_reward_frame.png` | Phase 2 P2-029 | 1,564,546 |
| `assets/ui/final/common/frames/popup_small_frame.png` | Phase 2 P2-025 | 1,399,872 |
| `assets/ui/final/common/frames/popup_warning_frame.png` | Phase 2 P2-030 | 1,328,148 |
| `assets/ui/final/common/frames/progress_bar_fill.png` | Phase 2 P2-040 | 504,992 |
| `assets/ui/final/common/frames/progress_bar_frame.png` | Phase 2 P2-039 | 474,996 |
| `assets/ui/final/common/icons/icon_arrow_left.png` | Phase 1 | 685,980 |
| `assets/ui/final/common/icons/icon_arrow_right.png` | Phase 1 | 665,089 |
| `assets/ui/final/common/icons/icon_check.png` | Phase 1 | 1,062,406 |
| `assets/ui/final/common/icons/icon_clock.png` | Phase 1 | 1,004,796 |
| `assets/ui/final/common/icons/icon_close.png` | Phase 1 | 1,009,619 |
| `assets/ui/final/common/icons/icon_cloud_save.png` | Phase 2 P2-059 | 1,098,404 |
| `assets/ui/final/common/icons/icon_connection_lost.png` | Phase 2 P2-063 | 903,129 |
| `assets/ui/final/common/icons/icon_download.png` | Phase 2 P2-023 | 1,234,098 |
| `assets/ui/final/common/icons/icon_haptics.png` | Phase 1 | 875,521 |
| `assets/ui/final/common/icons/icon_info.png` | Phase 1 | 976,772 |
| `assets/ui/final/common/icons/icon_language.png` | Phase 2 P2-054 | 1,181,189 |
| `assets/ui/final/common/icons/icon_lock.png` | Phase 1 | 868,905 |
| `assets/ui/final/common/icons/icon_maintenance.png` | Phase 2 P2-061 | 1,277,402 |
| `assets/ui/final/common/icons/icon_music.png` | Phase 1 | 690,769 |
| `assets/ui/final/common/icons/icon_notification.png` | Phase 1 | 863,041 |
| `assets/ui/final/common/icons/icon_notifications.png` | Phase 2 P2-055 | 1,191,952 |
| `assets/ui/final/common/icons/icon_offline.png` | Phase 2 P2-021 | 1,341,812 |
| `assets/ui/final/common/icons/icon_player_id.png` | Phase 2 P2-058 | 1,666,390 |
| `assets/ui/final/common/icons/icon_plus.png` | Phase 1 | 949,878 |
| `assets/ui/final/common/icons/icon_privacy.png` | Phase 2 P2-056 | 1,517,460 |
| `assets/ui/final/common/icons/icon_refresh.png` | Phase 2 P2-022 | 1,153,880 |
| `assets/ui/final/common/icons/icon_save_conflict.png` | Phase 2 P2-060 | 1,085,284 |
| `assets/ui/final/common/icons/icon_sound.png` | Phase 1 | 745,752 |
| `assets/ui/final/common/icons/icon_support.png` | Phase 2 P2-057 | 1,442,400 |
| `assets/ui/final/common/icons/icon_update_required.png` | Phase 2 P2-062 | 1,542,946 |
| `assets/ui/final/common/icons/icon_warning.png` | Phase 2 P2-024 | 1,179,858 |
| `assets/ui/final/common/navigation/icon_nav_events.png` | Phase 1 | 1,206,416 |
| `assets/ui/final/common/navigation/icon_nav_home.png` | Phase 1 | 878,485 |
| `assets/ui/final/common/navigation/icon_nav_leaderboard.png` | Phase 1 | 1,031,817 |
| `assets/ui/final/common/navigation/icon_nav_robots.png` | Phase 1 | 1,154,798 |
| `assets/ui/final/common/navigation/icon_nav_settings.png` | Phase 1 | 1,197,785 |

### daily (6)

| Path | Authority | Bytes |
|---|---|---:|
| `assets/ui/final/daily/daily_day_reward_frame.png` | Phase 1 | 1,378,753 |
| `assets/ui/final/daily/daily_day5_reward_frame.png` | Phase 1 | 1,521,489 |
| `assets/ui/final/daily/daily_header_emblem.png` | Phase 1 | 1,399,306 |
| `assets/ui/final/daily/daily_login_calendar.png` | Phase 1 | 1,256,722 |
| `assets/ui/final/daily/daily_streak_flame.png` | Phase 1 | 1,581,575 |
| `assets/ui/final/daily/daily_task_check.png` | Phase 1 | 1,279,055 |

### difficulty (2)

| Path | Authority | Bytes |
|---|---|---:|
| `assets/ui/final/difficulty/hard_emblem.png` | Phase 1 | 1,466,122 |
| `assets/ui/final/difficulty/very_hard_emblem.png` | Phase 1 | 1,594,534 |

### gameplay (56)

| Path | Authority | Bytes |
|---|---|---:|
| `assets/ui/final/gameplay/batch/batch_panel.png` | Phase 1 | 1,616,743 |
| `assets/ui/final/gameplay/batch/batch_tile_frame.png` | Phase 1 | 802,572 |
| `assets/ui/final/gameplay/batch/batch_tile_front_highlight.png` | Phase 1 | 662,375 |
| `assets/ui/final/gameplay/batch/batch_tile_locked_overlay.png` | Phase 1 | 838,142 |
| `assets/ui/final/gameplay/board/board_inner_frame.png` | Phase 1 | 21,679 |
| `assets/ui/final/gameplay/buttons/icon_pause.png` | LEGACY / EXTRA | 7,531 |
| `assets/ui/final/gameplay/buttons/icon_speed_2x.png` | LEGACY / EXTRA | 78,180 |
| `assets/ui/final/gameplay/buttons/speed_2x_timer_frame.png` | LEGACY / EXTRA | 35,128 |
| `assets/ui/final/gameplay/controls/button_pause.png` | Phase 1 | 915,660 |
| `assets/ui/final/gameplay/controls/button_speed_2x_active.png` | Phase 1 | 943,779 |
| `assets/ui/final/gameplay/controls/button_speed_2x_countdown_frame.png` | Phase 1 | 1,033,006 |
| `assets/ui/final/gameplay/controls/button_speed_2x.png` | Phase 1 | 1,020,738 |
| `assets/ui/final/gameplay/decorative/bubble_bucket.png` | Phase 1 | 1,221,375 |
| `assets/ui/final/gameplay/decorative/caution_wet_floor_sign.png` | Phase 1 | 1,064,090 |
| `assets/ui/final/gameplay/decorative/cleaning_equipment_cluster.png` | Phase 1 | 1,606,629 |
| `assets/ui/final/gameplay/decorative/flexible_hose.png` | Phase 1 | 1,355,163 |
| `assets/ui/final/gameplay/effects/fx_batch_commit.png` | Phase 1 | 1,310,757 |
| `assets/ui/final/gameplay/effects/fx_clean_puff.png` | Phase 1 | 973,148 |
| `assets/ui/final/gameplay/effects/fx_clean_sparkle.png` | Phase 1 | 704,176 |
| `assets/ui/final/gameplay/effects/fx_rail_travel_glow.png` | Phase 1 | 1,512,800 |
| `assets/ui/final/gameplay/effects/fx_slot_spawn_glow.png` | Phase 1 | 1,493,862 |
| `assets/ui/final/gameplay/effects/fx_tornado_clean.png` | Phase 1 | 1,602,181 |
| `assets/ui/final/gameplay/environment/gameplay_environment.png` | Phase 1 | 1,835,673 |
| `assets/ui/final/gameplay/master/scrubbots_gameplay_master.png` | Phase 1 | 2,500,673 |
| `assets/ui/final/gameplay/profile/bot_parts_bar_fill.png` | Phase 1 | 2,075 |
| `assets/ui/final/gameplay/profile/bot_parts_bar_frame.png` | Phase 1 | 2,189 |
| `assets/ui/final/gameplay/profile/level_badge_frame.png` | Phase 1 | 14,538 |
| `assets/ui/final/gameplay/profile/profile_panel_frame.png` | Phase 1 | 17,763 |
| `assets/ui/final/gameplay/profile/robots/atlas_portrait.png` | Phase 2 P2-142 | 2,067,810 |
| `assets/ui/final/gameplay/profile/robots/bubbles_portrait.png` | Phase 2 P2-079 | 1,695,415 |
| `assets/ui/final/gameplay/profile/robots/clippy_portrait.png` | Phase 2 P2-133 | 1,410,798 |
| `assets/ui/final/gameplay/profile/robots/dusty_portrait.png` | Phase 2 P2-106 | 1,578,752 |
| `assets/ui/final/gameplay/profile/robots/moppy_portrait.png` | Phase 2 P2-070 | 1,485,769 |
| `assets/ui/final/gameplay/profile/robots/polly_portrait.png` | Phase 2 P2-124 | 1,585,730 |
| `assets/ui/final/gameplay/profile/robots/rinse_portrait.png` | Phase 2 P2-115 | 1,562,421 |
| `assets/ui/final/gameplay/profile/robots/spark_portrait.png` | Phase 2 P2-088 | 1,487,295 |
| `assets/ui/final/gameplay/profile/robots/squeegee_portrait.png` | Phase 2 P2-097 | 1,300,252 |
| `assets/ui/final/gameplay/profile/scrubby_portrait.png` | Phase 1 | 107,412 |
| `assets/ui/final/gameplay/railroad/rail_corner_90.png` | Phase 1 | 1,101,090 |
| `assets/ui/final/gameplay/railroad/rail_end_cap.png` | Phase 1 | 1,365,039 |
| `assets/ui/final/gameplay/railroad/rail_energy_node.png` | Phase 1 | 1,299,949 |
| `assets/ui/final/gameplay/railroad/rail_ingress_marker.png` | Phase 1 | 1,017,973 |
| `assets/ui/final/gameplay/railroad/rail_intersection.png` | Phase 1 | 1,047,467 |
| `assets/ui/final/gameplay/railroad/rail_slot_connector.png` | Phase 1 | 977,573 |
| `assets/ui/final/gameplay/railroad/rail_straight_horizontal.png` | Phase 1 | 863,340 |
| `assets/ui/final/gameplay/railroad/rail_straight_vertical.png` | Phase 1 | 1,052,797 |
| `assets/ui/final/gameplay/railway/rail_connector.png` | LEGACY / EXTRA | 13,036 |
| `assets/ui/final/gameplay/railway/rail_corner.png` | LEGACY / EXTRA | 26,341 |
| `assets/ui/final/gameplay/railway/rail_straight.png` | LEGACY / EXTRA | 7,938 |
| `assets/ui/final/gameplay/slots/slot_active.png` | Phase 1 | 13,108 |
| `assets/ui/final/gameplay/slots/slot_empty.png` | Phase 1 | 7,379 |
| `assets/ui/final/gameplay/slots/slot_filled_base.png` | Phase 1 | 5,726 |
| `assets/ui/final/gameplay/slots/slot_locked.png` | Phase 1 | 1,082,738 |
| `assets/ui/final/gameplay/tutorial/speech_bubble.png` | Phase 1 | 1,244,746 |
| `assets/ui/final/gameplay/tutorial/tutorial_highlight_ring.png` | Phase 1 | 1,104,058 |
| `assets/ui/final/gameplay/tutorial/tutorial_pointer.png` | Phase 1 | 1,021,540 |

### home (35)

| Path | Authority | Bytes |
|---|---|---:|
| `assets/ui/final/home/area_banner/home_arch_decor.png` | Phase 1 | 1,225,643 |
| `assets/ui/final/home/area_banner/home_arch_whispering_park.png` | Phase 1 | 1,774,284 |
| `assets/ui/final/home/background/home_bg_city_far.png` | Phase 1 | 1,333,722 |
| `assets/ui/final/home/background/home_bg_city_mid.png` | Phase 1 | 2,525,140 |
| `assets/ui/final/home/background/home_bg_sky.png` | Phase 1 | 1,389,273 |
| `assets/ui/final/home/background/home_bg_street_foreground.png` | Phase 1 | 1,301,742 |
| `assets/ui/final/home/environment/home_prop_cleaning_bucket.png` | Phase 1 | 1,466,978 |
| `assets/ui/final/home/environment/home_prop_cleaning_equipment.png` | Phase 1 | 1,555,215 |
| `assets/ui/final/home/environment/home_prop_foam_cluster.png` | Phase 1 | 1,305,053 |
| `assets/ui/final/home/environment/home_prop_hose.png` | Phase 1 | 1,555,110 |
| `assets/ui/final/home/environment/home_prop_keep_clean_sign.png` | Phase 1 | 1,020,218 |
| `assets/ui/final/home/environment/home_prop_neon_details.png` | Phase 1 | 2,167,940 |
| `assets/ui/final/home/environment/home_prop_puddles.png` | Phase 1 | 824,488 |
| `assets/ui/final/home/environment/home_prop_wet_floor_sign.png` | Phase 1 | 1,219,232 |
| `assets/ui/final/home/gift_meter/gift_meter_emblem.png` | Phase 1 | 1,283,008 |
| `assets/ui/final/home/gift_meter/gift_meter_reward_crate.png` | Phase 1 | 1,373,783 |
| `assets/ui/final/home/platform/home_platform_main.png` | Phase 1 | 2,112,595 |
| `assets/ui/final/home/platform/home_platform_top.png` | Phase 1 | 1,801,797 |
| `assets/ui/final/home/play_cta/play_button_frame.png` | Phase 1 | 1,224,010 |
| `assets/ui/final/home/reward_track/reward_gift_1.png` | Phase 1 | 1,119,397 |
| `assets/ui/final/home/reward_track/reward_gift_10.png` | Phase 1 | 1,522,054 |
| `assets/ui/final/home/reward_track/reward_gift_100.png` | Phase 1 | 1,415,950 |
| `assets/ui/final/home/reward_track/reward_gift_25.png` | Phase 1 | 1,495,001 |
| `assets/ui/final/home/reward_track/reward_gift_5.png` | Phase 1 | 1,335,934 |
| `assets/ui/final/home/reward_track/win_streak_reward_badge.png` | Phase 1 | 1,452,790 |
| `assets/ui/final/home/shortcuts/icon_shortcut_cards_exchange.png` | Phase 1 | 1,631,600 |
| `assets/ui/final/home/shortcuts/icon_shortcut_collection.png` | Phase 1 | 1,649,090 |
| `assets/ui/final/home/shortcuts/icon_shortcut_daily.png` | Phase 1 | 1,352,996 |
| `assets/ui/final/home/shortcuts/icon_shortcut_gift_bar.png` | Phase 1 | 1,135,904 |
| `assets/ui/final/home/shortcuts/icon_shortcut_no_ads.png` | Phase 1 | 1,344,831 |
| `assets/ui/final/home/shortcuts/icon_shortcut_shop.png` | Phase 1 | 1,433,831 |
| `assets/ui/final/home/shortcuts/icon_shortcut_tasks.png` | Phase 1 | 1,379,430 |
| `assets/ui/final/home/shortcuts/icon_shortcut_win_streak.png` | Phase 1 | 1,479,263 |
| `assets/ui/final/home/top_hud/profile_avatar_frame.png` | Phase 1 | 882,518 |
| `assets/ui/final/home/top_hud/profile_rank_badge.png` | Phase 1 | 1,442,327 |

### marketing (5)

| Path | Authority | Bytes |
|---|---|---:|
| `assets/ui/final/marketing/google_play_feature_graphic.png` | Phase 2 P2-014 | 889,503 |
| `assets/ui/final/marketing/store_background.png` | Phase 2 P2-017 | 2,411,363 |
| `assets/ui/final/marketing/store_cleaning_props.png` | Phase 2 P2-016 | 1,937,475 |
| `assets/ui/final/marketing/store_hero_scrubby.png` | Phase 2 P2-015 | 1,385,375 |
| `assets/ui/final/marketing/store_logo_lockup.png` | Phase 2 P2-018 | 1,312,961 |

### popups (35)

| Path | Authority | Bytes |
|---|---|---:|
| `assets/ui/final/popups/failure/fail_header_emblem.png` | Phase 1 | 1,359,229 |
| `assets/ui/final/popups/failure/heart_empty.png` | Phase 1 | 850,326 |
| `assets/ui/final/popups/failure/heart_large.png` | Phase 1 | 1,135,656 |
| `assets/ui/final/popups/failure/refill_button_frame.png` | Phase 1 | 1,482,866 |
| `assets/ui/final/popups/failure/refill_heart_bundle.png` | Phase 1 | 1,281,644 |
| `assets/ui/final/popups/failure/retry_button_frame.png` | Phase 1 | 1,278,132 |
| `assets/ui/final/popups/help/help_button_frame.png` | Phase 1 | 1,309,135 |
| `assets/ui/final/popups/help/help_panel_emblem.png` | Phase 1 | 1,395,594 |
| `assets/ui/final/popups/help/help_scrubby_pose.png` | Phase 1 | 1,253,407 |
| `assets/ui/final/popups/help/robots/atlas_help_pose.png` | Phase 2 P2-143 | 2,261,827 |
| `assets/ui/final/popups/help/robots/bubbles_help_pose.png` | Phase 2 P2-080 | 1,363,183 |
| `assets/ui/final/popups/help/robots/clippy_help_pose.png` | Phase 2 P2-134 | 1,939,661 |
| `assets/ui/final/popups/help/robots/dusty_help_pose.png` | Phase 2 P2-107 | 1,431,146 |
| `assets/ui/final/popups/help/robots/moppy_help_pose.png` | Phase 2 P2-071 | 1,389,466 |
| `assets/ui/final/popups/help/robots/polly_help_pose.png` | Phase 2 P2-125 | 2,068,743 |
| `assets/ui/final/popups/help/robots/rinse_help_pose.png` | Phase 2 P2-116 | 1,887,479 |
| `assets/ui/final/popups/help/robots/spark_help_pose.png` | Phase 2 P2-089 | 1,239,048 |
| `assets/ui/final/popups/help/robots/squeegee_help_pose.png` | Phase 2 P2-098 | 1,262,635 |
| `assets/ui/final/popups/level_intro/hard_level_emblem.png` | Phase 1 | 1,347,579 |
| `assets/ui/final/popups/level_intro/level_intro_frame.png` | Phase 1 | 1,353,000 |
| `assets/ui/final/popups/level_intro/normal_level_emblem.png` | Phase 1 | 1,254,752 |
| `assets/ui/final/popups/level_intro/very_hard_level_emblem.png` | Phase 1 | 1,598,581 |
| `assets/ui/final/popups/victory/continue_button_frame.png` | Phase 1 | 1,292,779 |
| `assets/ui/final/popups/victory/reward_glow.png` | Phase 1 | 1,657,823 |
| `assets/ui/final/popups/victory/robots/atlas_victory_pose.png` | Phase 2 P2-144 | 2,214,718 |
| `assets/ui/final/popups/victory/robots/bubbles_victory_pose.png` | Phase 2 P2-081 | 1,616,191 |
| `assets/ui/final/popups/victory/robots/clippy_victory_pose.png` | Phase 2 P2-135 | 2,046,338 |
| `assets/ui/final/popups/victory/robots/dusty_victory_pose.png` | Phase 2 P2-108 | 2,033,427 |
| `assets/ui/final/popups/victory/robots/moppy_victory_pose.png` | Phase 2 P2-072 | 1,982,720 |
| `assets/ui/final/popups/victory/robots/polly_victory_pose.png` | Phase 2 P2-126 | 2,029,661 |
| `assets/ui/final/popups/victory/robots/rinse_victory_pose.png` | Phase 2 P2-117 | 2,082,587 |
| `assets/ui/final/popups/victory/robots/spark_victory_pose.png` | Phase 2 P2-090 | 1,444,615 |
| `assets/ui/final/popups/victory/robots/squeegee_victory_pose.png` | Phase 2 P2-099 | 1,922,800 |
| `assets/ui/final/popups/victory/victory_emblem.png` | Phase 1 | 1,433,236 |
| `assets/ui/final/popups/victory/victory_scrubby_pose.png` | Phase 1 | 1,250,148 |

### rewards (8)

| Path | Authority | Bytes |
|---|---|---:|
| `assets/ui/final/rewards/bot_parts_bundle_large.png` | Phase 1 | 1,762,769 |
| `assets/ui/final/rewards/bot_parts_bundle_small.png` | Phase 1 | 1,238,744 |
| `assets/ui/final/rewards/card_pack_premium.png` | Phase 1 | 2,135,294 |
| `assets/ui/final/rewards/card_pack_standard.png` | Phase 1 | 2,138,727 |
| `assets/ui/final/rewards/chest_small.png` | Phase 1 | 1,210,295 |
| `assets/ui/final/rewards/gift_box.png` | Phase 1 | 1,269,854 |
| `assets/ui/final/rewards/scrub_bucks_bundle_large.png` | Phase 1 | 2,037,038 |
| `assets/ui/final/rewards/scrub_bucks_bundle_small.png` | Phase 1 | 1,091,823 |

### robots (12)

| Path | Authority | Bytes |
|---|---|---:|
| `assets/ui/final/robots/bot_parts_icon.png` | Phase 1 | 1,075,502 |
| `assets/ui/final/robots/bot_parts_progress_frame.png` | Phase 1 | 507,078 |
| `assets/ui/final/robots/robot_card_frame_locked.png` | Phase 1 | 1,717,165 |
| `assets/ui/final/robots/robot_card_frame_unlocked.png` | Phase 1 | 1,632,947 |
| `assets/ui/final/robots/robot_detail_hero_frame.png` | Phase 2 P2-049 | 1,607,914 |
| `assets/ui/final/robots/robot_lock_emblem.png` | Phase 2 P2-053 | 1,109,523 |
| `assets/ui/final/robots/robot_locked_silhouette.png` | Phase 2 P2-047 | 1,361,708 |
| `assets/ui/final/robots/robot_perk_emblem_frame.png` | Phase 2 P2-052 | 1,554,591 |
| `assets/ui/final/robots/robot_portrait_frame.png` | Phase 2 P2-048 | 843,090 |
| `assets/ui/final/robots/robot_selected_ring.png` | Phase 2 P2-050 | 929,259 |
| `assets/ui/final/robots/robot_unlock_glow.png` | Phase 1 | 1,407,156 |
| `assets/ui/final/robots/robot_unlocked_burst.png` | Phase 2 P2-051 | 1,674,543 |

### shop (8)

| Path | Authority | Bytes |
|---|---|---:|
| `assets/ui/final/shop/shop_booster_bundle.png` | Phase 1 | 1,554,079 |
| `assets/ui/final/shop/shop_featured_frame.png` | Phase 1 | 1,218,029 |
| `assets/ui/final/shop/shop_header_emblem.png` | Phase 1 | 1,398,208 |
| `assets/ui/final/shop/shop_heart_bundle.png` | Phase 1 | 1,088,754 |
| `assets/ui/final/shop/shop_item_frame.png` | Phase 1 | 1,399,717 |
| `assets/ui/final/shop/shop_purchase_button_frame.png` | Phase 1 | 1,360,218 |
| `assets/ui/final/shop/shop_scrub_bucks_bundle.png` | Phase 1 | 1,757,393 |
| `assets/ui/final/shop/shop_speed_2x_icon.png` | Phase 1 | 1,254,419 |

### system (8)

| Path | Authority | Bytes |
|---|---|---:|
| `assets/ui/final/system/loading/loading_glow.png` | Phase 2 P2-013 | 1,910,130 |
| `assets/ui/final/system/loading/loading_scrubby.png` | Phase 2 P2-011 | 1,336,509 |
| `assets/ui/final/system/loading/loading_spinner_ring.png` | Phase 2 P2-012 | 1,152,953 |
| `assets/ui/final/system/placeholders/content_loading_placeholder.png` | Phase 2 P2-020 | 1,957,052 |
| `assets/ui/final/system/placeholders/level_preview_placeholder.png` | Phase 2 P2-019 | 1,351,161 |
| `assets/ui/final/system/splash/splash_background.png` | Phase 2 P2-008 | 2,096,251 |
| `assets/ui/final/system/splash/splash_logo.png` | Phase 2 P2-010 | 1,312,961 |
| `assets/ui/final/system/splash/splash_scrubby.png` | Phase 2 P2-009 | 1,299,706 |

## Legacy / extra production paths

These files exist in `assets/ui/final/**` but are not canonical targets in the current Phase 1 or Phase 2 master lists. Do not delete them automatically. For new UI binding, prefer the canonical equivalents noted below.

| Existing extra path | Preferred canonical path / note |
|---|---|
| `assets/ui/final/gameplay/buttons/icon_pause.png` | `assets/ui/final/gameplay/controls/button_pause.png` |
| `assets/ui/final/gameplay/buttons/icon_speed_2x.png` | `assets/ui/final/gameplay/controls/button_speed_2x.png` |
| `assets/ui/final/gameplay/buttons/speed_2x_timer_frame.png` | `assets/ui/final/gameplay/controls/button_speed_2x_countdown_frame.png` |
| `assets/ui/final/gameplay/railway/rail_connector.png` | `assets/ui/final/gameplay/railroad/rail_slot_connector.png` |
| `assets/ui/final/gameplay/railway/rail_corner.png` | `assets/ui/final/gameplay/railroad/rail_corner_90.png` |
| `assets/ui/final/gameplay/railway/rail_straight.png` | `Prefer horizontal/vertical canonical pieces under assets/ui/final/gameplay/railroad/` |

## Generated candidates / source visuals (27)

- `assets/ui/generated/gameplay/master_v01/svg/batch_panel.svg`
- `assets/ui/generated/gameplay/master_v01/svg/batch_tile_frame.svg`
- `assets/ui/generated/gameplay/master_v01/svg/booster_extra_slot.svg`
- `assets/ui/generated/gameplay/master_v01/svg/booster_random.svg`
- `assets/ui/generated/gameplay/master_v01/svg/booster_selector.svg`
- `assets/ui/generated/gameplay/master_v01/svg/booster_tornado.svg`
- `assets/ui/generated/gameplay/master_v01/svg/bubble_bucket.svg`
- `assets/ui/generated/gameplay/master_v01/svg/caution_sign.svg`
- `assets/ui/generated/gameplay/master_v01/svg/fx_clean.svg`
- `assets/ui/generated/gameplay/master_v01/svg/fx_sparkle.svg`
- `assets/ui/generated/gameplay/master_v01/svg/gameplay_environment.svg`
- `assets/ui/generated/gameplay/master_v01/svg/pause_button.svg`
- `assets/ui/generated/gameplay/master_v01/svg/profile_panel_frame.svg`
- `assets/ui/generated/gameplay/master_v01/svg/rail_connector.svg`
- `assets/ui/generated/gameplay/master_v01/svg/rail_corner.svg`
- `assets/ui/generated/gameplay/master_v01/svg/rail_end.svg`
- `assets/ui/generated/gameplay/master_v01/svg/rail_intersection.svg`
- `assets/ui/generated/gameplay/master_v01/svg/rail_scrubbot.svg`
- `assets/ui/generated/gameplay/master_v01/svg/rail_straight.svg`
- `assets/ui/generated/gameplay/master_v01/svg/scrubby_gameplay.svg`
- `assets/ui/generated/gameplay/master_v01/svg/scrubby_portrait.svg`
- `assets/ui/generated/gameplay/master_v01/svg/slot_active.svg`
- `assets/ui/generated/gameplay/master_v01/svg/slot_empty.svg`
- `assets/ui/generated/gameplay/master_v01/svg/slot_locked.svg`
- `assets/ui/generated/gameplay/master_v01/svg/speech_bubble.svg`
- `assets/ui/generated/gameplay/master_v01/svg/speed_button_active_frame.svg`
- `assets/ui/generated/gameplay/master_v01/svg/speed_button_frame.svg`

## Owner/reference visuals (51)

- `assets/art/references/_owner_inbox/Additionals/life screens.png`
- `assets/art/references/_owner_inbox/Additionals/need a hand.png`
- `assets/art/references/_owner_inbox/app icon (small).png`
- `assets/art/references/_owner_inbox/app icon.png`
- `assets/art/references/_owner_inbox/Collection Cards/bath time blitz.jpeg`
- `assets/art/references/_owner_inbox/Collection Cards/bathroom mayhem.jpeg`
- `assets/art/references/_owner_inbox/Collection Cards/clean city.jpeg`
- `assets/art/references/_owner_inbox/Collection Cards/cleaning crew 2.jpeg`
- `assets/art/references/_owner_inbox/Collection Cards/cleaning crew.jpeg`
- `assets/art/references/_owner_inbox/Collection Cards/color bots.jpeg`
- `assets/art/references/_owner_inbox/Collection Cards/garage grime.jpeg`
- `assets/art/references/_owner_inbox/Collection Cards/jungle cleanup.jpeg`
- `assets/art/references/_owner_inbox/Collection Cards/kitchen chaos.jpeg`
- `assets/art/references/_owner_inbox/Collection Cards/meet the scrubbots.jpeg`
- `assets/art/references/_owner_inbox/Collection Cards/mess monsters.jpeg`
- `assets/art/references/_owner_inbox/Collection Cards/scrubbot workshop.jpeg`
- `assets/art/references/_owner_inbox/Collection Cards/sewer squad.jpeg`
- `assets/art/references/_owner_inbox/Collection Cards/space cleaners.jpeg`
- `assets/art/references/_owner_inbox/Collection Cards/ultimate cleaners.jpeg`
- `assets/art/references/_owner_inbox/Collection Cards/underwater heroes.jpeg`
- `assets/art/references/_owner_inbox/Colorful logo.png`
- `assets/art/references/_owner_inbox/Game Screens/deneme 3 OK.png`
- `assets/art/references/_owner_inbox/Game Screens/level ekran acilisi.png`
- `assets/art/references/_owner_inbox/Game Screens/main screen.png`
- `assets/art/references/_owner_inbox/Game Screens/scrubbots main screen 001.jpeg`
- `assets/art/references/_owner_inbox/Level Sheets/level sheets 1.jpeg`
- `assets/art/references/_owner_inbox/Level Sheets/level sheets 2.jpeg`
- `assets/art/references/_owner_inbox/Level Sheets/level sheets 3.jpeg`
- `assets/art/references/_owner_inbox/Level Sheets/level sheets 4.jpeg`
- `assets/art/references/_owner_inbox/Level Sheets/pixel art tam gorunum 2.jpeg`
- `assets/art/references/_owner_inbox/Level Sheets/pixel art tam gorunum.jpeg`
- `assets/art/references/_owner_inbox/Levels/level designs 001.jpeg`
- `assets/art/references/_owner_inbox/Levels/level designs 002.jpeg`
- `assets/art/references/_owner_inbox/Levels/level designs 003.jpeg`
- `assets/art/references/_owner_inbox/Levels/level designs 004.jpeg`
- `assets/art/references/_owner_inbox/Levels/level designs 005.jpeg`
- `assets/art/references/_owner_inbox/Levels/level designs 006.jpeg`
- `assets/art/references/_owner_inbox/Levels/level designs 007.jpeg`
- `assets/art/references/_owner_inbox/Levels/level designs 008.jpeg`
- `assets/art/references/_owner_inbox/Levels/level designs 009.jpeg`
- `assets/art/references/_owner_inbox/Levels/level designs 010.jpeg`
- `assets/art/references/_owner_inbox/Levels/level designs 011.jpeg`
- `assets/art/references/_owner_inbox/Levels/level designs 012.jpeg`
- `assets/art/references/_owner_inbox/Levels/level designs 013.jpeg`
- `assets/art/references/_owner_inbox/Levels/level designs 014.jpeg`
- `assets/art/references/_owner_inbox/Levels/level designs 015.jpeg`
- `assets/art/references/_owner_inbox/Levels/level designs 016 made by chatgpt.jpeg`
- `assets/art/references/_owner_inbox/Levels/level designs 017.jpeg`
- `assets/art/references/_owner_inbox/Levels/level designs 018.jpeg`
- `assets/art/references/_owner_inbox/logo simple.png`
- `assets/art/references/_owner_inbox/Playing Motors/game playing motors 001.jpeg`

## Other project art/reference visuals (4)

- `assets/art/levels/previews/m21_level_001_hazard_bot.png`
- `assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png`
- `assets/brand/akilta-wordmark.svg`
- `coordination/sessions/M21-C001/M21_REFERENCE_COMPOSITE.png`

## Integration notes

- `assets/ui/final/**` is the primary discovery root for Claude UI work.
- Robot 2..10 character families are under `assets/ui/final/characters/robots/<robot>/`, with gameplay-profile/help/victory variants in their screen-specific folders.
- Collection contains 15 sets × 9 individual card images under `assets/ui/final/collection/cards/set_01..set_15/`.
- Exactly four boosters are canonical: `extra_slot.png`, `random.png`, `selector.png`, `tornado.png`.
- Railroad routing/geometry truth is runtime-authoritative. PNG railroad files are presentation skins only.
- Store screenshots are intentionally not generated here; final store screenshots should come from the integrated app.
- Production level pixel art is intentionally outside this UI-asset index's canonical generated UI scope and belongs to the level-content pipeline.


## Finalization batch scheduled

The previously recommended Robot perk icons, Collection state art and canonical 10-robot Cleaning Crew group image are now authorized as P2-145..P2-157 in the Phase 2 master list. Until Codex publishes them, treat them as scheduled canonical targets rather than existing assets.

## Recommended future visual backlog

These are not missing from the current canonical Phase 1/Phase 2 contracts. They are additional high-value visuals that would make later UI integration cleaner without introducing World Map, XP, Star currency, weekly progression, event content, or new gameplay rules.

### Robot perk icon family

The 10-robot roster now has distinct meta perks, but the current asset library contains only a generic perk-emblem frame. Recommended dedicated transparent icons:

- first-clear Scrub Bucks bonus
- Gift Bar Scrub Bucks bonus
- paid 2x discount
- Cards Exchange bonus
- booster-purchase discount
- Heart-refill discount
- Win Streak bonus
- Daily-task bonus
- Atlas Master Cleaner combined perk

Suggested root:
`assets/ui/final/robots/perks/`

### Collection state art

Useful additions for unowned/hidden Collection states:

- generic Collection card back
- unknown/uncollected card silhouette
- newly acquired card glow/burst

Suggested root:
`assets/ui/final/collection/states/`

### Cleaning Crew group art

One canonical transparent/wide group composition containing all 10 robots would be useful for:
- Robot Collection header/hero treatment
- store/marketing compositions
- future celebratory screens

Suggested path:
`assets/ui/final/characters/robots/cleaning_crew_group.png`

These items are recommended, not required to consider the current 450 canonical visual targets complete.
