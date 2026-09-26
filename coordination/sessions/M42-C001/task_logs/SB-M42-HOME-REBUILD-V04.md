# SB-M42 HOME REBUILD V04 — Claude implementation log

Status: **AWAITING_CHATGPT_AUDIT** (implementer log; no self-audit; owner visual acceptance NOT claimed)

Prompt: `coordination/sessions/M42-C001/task_prompts/SB-M42-HOME-REBUILD_V04.md`
Criteria: `coordination/sessions/M42-C001/audit_criteria/SB-M42-HOME-REBUILD_V04.md`
Owner decision: `coordination/OWNER_M42_HOME_REBUILD_V04_SINGLE_WORLD_BACKGROUND.md`

## Commits

| Role | SHA |
|---|---|
| Baseline (synced `origin/main`) | `a61cfd9` |
| Owner World 01 source committed unchanged (see note) | `390ea44` |
| Implementation + manifest + tests + harness (final implementation SHA) | `a8b953e` |
| Evidence + ledger + this log | follow-up commit |

Note: `390ea44` also carries the removal of `tests/m42_home_v03.gd` (it was already staged by `git rm` when the
reference commit was made). The removal is intentional: that suite asserted the V03 composition (3+3 panels,
SHOP|PLAY|CARDS row, layered city), which V04 supersedes. Its still-valid properties are covered by
`m42_home_v04.gd` (modal hiding, no visible Home buttons behind modals, retired-asset presentation) and
`m42_home_composition.gd` (OWNER_DISABLED idle overlays have no node).

## Mandatory gate — World 01 asset

- Source `assets/art/references/_owner_inbox/world_01_whispering_park_1080x2160.png`: **1080 x 2160**, RGBA,
  4,887,142 B, SHA-256 **`8e04eda668aabd9f96172c0e82fd7dd47e61083cb691402a313120443a525e5b`** — matches. Gate passed.
- Promoted with a byte copy (`cp -p`) to `assets/ui/final/home/worlds/world_01_whispering_park_1080x2160.png`;
  `cmp` identical; both Git blobs `208795e92533844065110a644ecf2c87184aca82`. No regeneration/recompression/resizing.

## Manifest change

Appended one entry (no other line changed; old statuses/hashes untouched):
`HOME-120 / world_01_whispering_park_background`, group `world`, kind `ART`, `generation_required: true`,
provider `chatgpt_image_generation` (+ `magnific` fallback per schema), status `APPROVED`,
`approved_sha256` = `8e04eda6…5e5b`, `approval_authority` = the V04 owner decision, `source_path` = owner inbox file.
The validator passes; HomeArtBinder state `APPROVED_BOUND`. The historical `layer_order` key (V01 layered pipeline)
was left unchanged; V04 Home layers are `WorldBackground`, `characters` (asserted by `m42_home` layered_art_regions).

## Retirement accounting (presentation map)

51 manifest ART entries: **24 STATIC / 18 WORLD_BAKED_RETIRED / 7 OWNER_RETIRED / 2 OWNER_DISABLED**.
- WORLD_BAKED_RETIRED (baked into HOME-120): HOME-001, 002, 003, 004, 006, 007, 010, 013, 014, 015, 016, 018, 019, 020, 021, 022, 023, 024.
- OWNER_RETIRED: HOME-011 (V03), 062 / 063 / 066 / 069 (V04: Win Streak / Gifts / No Ads / Cards Exchange panels removed), 078, 087.
- OWNER_DISABLED: HOME-031, 032.
- New STATIC: HOME-120 → `WorldBackground`; shortcut icons HOME-064/065/067/068 → `ShortcutIcon_<id>` TextureRects.
Inactive rows have no node and a reason; all 27 keep APPROVED + sha pins.

## Scrubby anchor geometry (canonical 1080x2160)

- Contract (data/config/home_worlds_v1.json): feet anchor (540, 1297); safe box 353..727 x 779..1297.
- HOME-026 facts (1158x1358): alpha>128 visible bbox (27, 7, 1130, 1327); soles line y = 1318 (brush bristles end at 1334).
- Fit k = min(374/1130, 518/1311) = 0.33097 (width-bound). Visible rect → x 353.0..727.0, y 863.1..1302.3;
  centre X = 540.00; soles Y = 1297.00; only the bristles (+5.3 px) pass the soles line.
- Scrubby does not intersect the baked sign rect (351,653,383,92) or the four measured helper-bot rects.
- Screen mapping: uniform s + offset (`world_to_screen`). Scale rule: cover the canvas; keep the platform-top region
  (≤ y 1345) above PLAY; keep the sign below the Gift Meter when that forces a smaller scale. Measured transforms:

| Viewport | s | offset |
|---|---|---|
| 1080x2160 | 1.0000 | (0, 0) |
| 1170x2532 | 1.0889 | (-3, 0) |
| 1290x2796 | 1.2111 | (-9, 0) |
| 1080x2400 | 1.0329 | (-17.8, 0) |
| 1440x3200 | 1.3981 | (-35, 0) |
| 1080x1920 | 1.0000 | (0, -79) |
| 1536x2048 | 1.4118 | (5.6, -515.9) — side bands filled with a mirrored continuation |

## Other V04 implementation

- **Panels:** 2+2 light panels 210x156 (alpha 0.30 tint, 2 px cyan outline), 26 px edge margin, icons standing on
  the label band and popping above it; SHOP/COLLECTION icon box 1.2 x V03 (206x164), TASKS/DAILY exactly V03.
  `_avoid_helper_bots()` tightens a column's gap, then shifts the column inward, so no panel covers a baked bot
  (asserted at 7 viewports x 2 inset sets).
- **Play:** centred standalone 470x155, native triangle, live subtitle, compact status pill as a child of the CTA.
- **Profile:** 540 px card; portrait 195 px in front of the 150 px frame, visible bottom on the ring's inner bottom
  (0.83), popping above; Bot Parts bar 42 px (V03 24) with the centred `N/250`; level badge on the same row.
- **HUD:** SB/heart icons drawn 98 px (footprint 70, overhanging left/up/down in front of the chip); `+` buttons 88x88
  emitting `scrub_bucks_purchase_requested` / `hearts_purchase_requested` only.
- **Gift Meter / track / nav:** V03 compact forms preserved; emblem/crate 112 px.
- **Modal:** one `HomeActionLayer` (panels, PLAY, track, nav) + HUD `+` buttons hidden while any Home popup or the
  Settings panel is open; `ActionHost` keeps the layout slot; back closes the top modal first.
- **AdBannerSlot:** below BottomNav, height = width·50/320 clamped 100..180 (reservation only), dark panel with an
  empty `AdMount` child (SDK seam), `set_ad_slot_enabled(false)` collapses it (nav drops to the bottom). The world
  canvas is clipped at the ad slot top.
- **World seam:** `data/config/home_worlds_v1.json` + `HomeWorldCatalog` (world_id → background slug + anchor
  contract); world_01 default only; no level ranges, no World 02+.

## 83-item ledger

`coordination/sessions/M42-C001/task_logs/SB-M42-HOME-V04-83-COMPLETION-LEDGER.md` — 83 rows:
**70 FIXED / 11 PRESERVED_CURRENT / 2 DEFERRED_BY_OWNER_ARCHITECTURE / 0 BLOCKED_WITH_PROOF**
(deferred: 74 Cards Exchange inside Collection, 75 No Ads inside Shop — seams kept, flows are later milestones).

## Visual evidence (vision inspected)

`coordination/sessions/M42-C001/runtime_evidence/home_v04/`: `home_1080x2160.png`, `home_1290x2796.png`,
`home_1080x1920.png`, `home_1536x2048.png`, `home_adslot_collapsed_1080x2160.png`, `modal_daily_1080x2160.png`,
`modal_settings_1080x2160.png`, plus iterations `iter1_home_1080x2160.png` (first pass) and
`iter2_tablet_mirrored_edges_1536x2048.png`.
Checked: no duplicate portal/platform/helper art; Scrubby's soles on the baked platform top; the four baked helper
bots visible and uncovered; 2+2 panels clear of Scrubby and bots; portrait seated in its frame; city/world reads as
one scene; PLAY centred; ad slot below the nav; action UI absent behind Daily and Settings.
Iteration fixes: icons reaching the Gift Meter after an early top-margin cut (reverted to fixed clearance), DAILY over
the upper-right bot on 16:9/tablet (gap tighten + inward shift), BG01 side bars on tablet (mirrored fill),
currency icons overlapping values (left-only overhang).
Honest residuals: on 1290x2796 a wide band of street separates the platform from PLAY; on 1080x1920 the top 79 px of
sky sit behind the HUD; on tablet the mirrored side bands are narrow but visible at the far edges.

## Tests (headless, tree = `a8b953e`)

| Suite | Result | SCRIPT ERROR | engine ERROR* |
|---|---|---|---|
| `tests/m42_assets.gd` | 4/4 PASS, exit 0 | 0 | 0 |
| `tests/m42_home.gd` | 19/19 PASS, exit 0 | 0 | 0 |
| `tests/m42_home_composition.gd` | 9/9, 0 failures, exit 0 | 0 | 0 |
| `tests/m42_home_v04.gd` | 18/18, 0 failures, exit 0 | 0 | 0 |
| `tests/m42_navigation.gd` | 12/12 PASS, exit 0 | 0 | 0 |
| `tests/m42_opening.gd` | 8/8 PASS, exit 0 | 0 | 0 |
| `tests/run_tests.gd` | 5322 checks, ALL PASS, exit 0 | 0 | 8 (pre-existing intentional corrupt-PNG fixtures = baseline) |

\* excluding exit-time "resources still in use"/RID teardown notices. `git diff --check` clean. Headless
`project.godot` churn restored (not committed).

Prompt test list → `m42_home_v04.gd` cases: 1 world_asset_identity; 2 world_binds_through_lifecycle; 3–6
no_duplicate_world_art; 7–9 scrubby_anchor_contract; 10–11 four_panels; 12–15 panel_icons; 16–17
panel_style_and_margin; 18 play_standalone; 19–22 profile; 23–24 currency_hud; 25–26 gift_and_track; 27 nav_and_ad_slot;
28 ad_slot_collapse; 29 daily_modal; 30 settings_modal (real `main.tscn`); 31 responsive_matrix; 32 historical_assets_intact.

## Asset integrity

Pre-implementation record: all 456 PNG blobs under `assets/ui/final` at `a61cfd9`. After implementation: **0
mismatches** (every previously approved PNG unchanged). New world image SHA verified; source bytes == final bytes.
No candidate generated; nothing under `assets/ui/generated/` added.

Untouched: root `TASKS.md`, owner decision files, ChatGPT prompt/criteria/audit files.

Final handoff: `AWAITING_CHATGPT_AUDIT / M42 HOME REBUILD V04`
