# SB-M22-030 owner image cleanup

Factory job 098 (2026-11-05). Owner decision 2026-11-05 (chat): delete production drafts whose
selection is finished, every test/review evidence screenshot, owner references whose thing is
finished, and the approved-but-unused final images with no plausible future use; keep the rest.
Permanent `git rm`, no archive: git history is the only copy. Starting point: the SB-M22-027
inventory (`docs/M22_027_IMAGE_INVENTORY.md`, `docs/m22_027_image_inventory.csv`).
Per-file list with bytes, SHA256 and reason: `docs/m22_030_deleted_images.csv`.

## Deleted

| group | images | bytes | what |
|---|---:|---:|---|
| evidence | 990 | 1403833730 | every coordination/ capture, contact sheet, QA crop and montage (M21..M43, FACTORY 076..090 evidence) |
| drafts | 427 | 437940113 | M43-C005-C003 card drafts (132 production_art, 130 production_cards, 8 pilots); home Scrubby animation V02 candidates (63) and V03 tool output (63, byte-identical to the approved finals); 27 gameplay master_v01 SVG candidates (+ their manifest.json, README); 4 promoted raw crops (3 profile/achievement icons, weekly event hero) |
| references | 21 | 8620872 | `_owner_inbox/Collection Cards/` (16), `app icon.png`, `app icon (small).png`, `Colorful logo.png`, `logo simple.png`, `Playing Motors/game playing motors 001.jpeg` |
| final | 4 | 152685 | superseded legacy duplicates `gameplay/buttons/icon_speed_2x.png`, `gameplay/buttons/speed_2x_timer_frame.png`, `gameplay/railway/rail_connector.png`, `gameplay/railway/rail_corner.png` |
| **total** | **1442** | **1850547400** | plus 4 tracked `.import` files and the 2 SVG-pack text files |

Rules applied:

- **Evidence**: an image counts as evidence only if no test, tool, CI workflow or runtime file reads
  it. Checked by grep of tests/, tools/, .github/, scripts/, scenes/, data/, addons/,
  level_factory/, content_pipeline/ and project.godot for each path, file name and folder. The
  capture tools (`tests/tools/*_snapshot.gd`, `c005f_*_capture.gd`, `build_m21_reference_composite.gd`,
  `web_export_runtime_probe.py`) only write their images; they regenerate them on demand.
- **Drafts**: deleted only where the slot has an approved final in `assets/ui/final/` (cards 135/135,
  home animation set `home_scrubby_gestures_v03` APPROVED, Phase 1 gameplay targets 306/306,
  the four crops `PROMOTED_BY_CLAUDE_DELEGATED`).
- **References**: deleted only where the thing they were for is finished: the 135-card set, the
  live app icon (`project.godot` launcher icons) and approved logos, the built gameplay mechanic.
- **Final**: deleted only the four `VISUAL_ASSET_INDEX` "Legacy / extra" duplicates whose canonical
  replacement exists; no code, test, tool or manifest names them.

## Kept

| kept | images | why |
|---|---:|---|
| `coordination/sessions/M43-C005-C002/references/` | 9 | read by `tools/validate_m43_c005_pack_assets.py`, `remediate_m43_c005_pack_assets_v04.py`, `rebuild_m43_c005_card_emergence.py` |
| `assets/ui/candidates/m43_c005/pack_opening/**` | 27 | SHA256-checked by `tests/m43_c005_c006_*`, `m43_c005_c007_*` and read by the pack tools |
| `assets/ui/generated/characters/home_animation/source_v02/` | 63 | owner-original source frames from the owner's Home_Main_Hero_Assets.zip (not in the repo); input of `tools/home_scrubby_prepare_assets.py --v03`; owner-original art (unclear) |
| `assets/ui/generated/masters/` | 4 | approved Profile/Achievements/Events/Pack-opening masters; `PLAYER_EXPERIENCE_ASSET_MANIFEST.json` surfaces are MASTER_OWNER_APPROVED, not yet OWNER_ACCEPTED; pack master is the storyboard named in `standard_pack_ceremony.gd` (unclear) |
| `_owner_inbox/Additionals/` | 2 | life / need-a-hand surfaces are still REFERENCE_SELECTED in `PLAYER_EXPERIENCE_ASSET_MANIFEST.json` (unclear) |
| `_owner_inbox/Game Screens/` | 4 | canonical Home / gameplay / level-intro authorities cited by the UI docs; level intro is not built (unclear) |
| `_owner_inbox/master - actual differences.png` | 1 | owner's Home master-vs-actual comparison; Home convergence not closed (unclear) |
| `_owner_inbox/world_01_whispering_park_1080x2160.png` | 1 | worlds/regions are planned |
| `_owner_inbox/Levels/`, `Level Sheets/` | 24 | level design references; campaign content still being produced |
| FUTURE_NEEDED finals | 141 | plausible future use: branding/app icons (launcher icons are live), marketing/store art, robots stage/animation layers, collection frames, cards exchange, shop, popups (failure, help, level intro, victory), difficulty emblems, loading/splash/placeholders, settings/system icons, gameplay controls/decorative/effects/railroad/slots/batch, booster tutorial pointer |

## Proof (LOCAL_PASS 2026-11-05, Godot 4.7.2)

- **Inventory rerun** (`tools/m22_027_image_inventory.py`, selftest PASS; CSV rewritten): 2218 ->
  776 tracked images, 2578453215 -> 727905815 bytes (1850547400 freed). ACTIVE_RUNTIME 426 and
  DYNAMIC_REF 74 are the identical path sets before and after; no image changed class; the CSV
  diff is 1442 pure row deletions. After: PROVENANCE_MASTER 135, FUTURE_NEEDED 141,
  CONFIRMED_ORPHAN 0.
- **Import**: `godot --headless --import` before and after, exit 0, no error / missing-resource line.
- **Runtime**: `tests/tools/m22_026_texture_measure.gd` (real main.tscn, throw-away saves, 52
  scenarios) before, after and after again: no "Failed loading resource", "Cannot open file",
  "Resource file not found", "Error loading" or SCRIPT ERROR line; the same 168 textures and
  identical per-scenario loaded MiB. Merged max-side px differ by 1-2 px only for animated
  pieces (victory emblem/poses, collection-complete emblem); two runs of the same after tree
  differ the same way, so that is tween timing, not the cleanup.
- **Suites** (exit 0, no SCRIPT ERROR / Parse Error): m21_real_art_smoke PASS,
  m22_026_texture_budget PASS, maint_home_export_asset_gate_c001 11/11, m42_c003_scrubby_animation
  25/25, m43_c005_c006_standard_pack_presentation 28/28, m43_c005_c007_premium_pack_presentation
  20/20, m42_home 19/19. Pre-existing failures that read no deleted file (not in the CI suite
  list): m42_assets FAIL(2) counts 54 HOME manifest ART entries against a stale 53 (manifest
  unchanged by this job, SB-POLISH-009 added HOME-123); m43_c001b_won_results_visual 3 fails
  expect still-texture robots that 93a02ced replaced with Flow videos.
