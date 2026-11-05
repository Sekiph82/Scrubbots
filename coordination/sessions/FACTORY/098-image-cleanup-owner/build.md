STATUS: READY

# Build: SB-M22-030 owner image cleanup (owner 2026-11-05)

## Summary
Branch `factory/098-image-cleanup-owner` permanently `git rm`s 1442 tracked images (1,850,547,400 bytes, about 1.72 GiB). There is no archive; git history is the only copy.
- 990 coordination test/review evidence captures (commit 7ee3bda9).
- 427 drafts whose selection is finished, plus 21 owner references whose thing is finished (d77e094b): 270 M43-C005-C003 card drafts, 63 home-animation V02 candidates, 63 V03 tool outputs (byte-identical to the approved finals), 27 gameplay master_v01 SVG candidates (with their manifest.json and README), 4 promoted raw crops, 16 Collection Cards sheets, app icon x2, logo x2, and Playing Motors.
- 4 superseded legacy final duplicates (80898c79).
- Docs and TASKS (5c55551f).

Files changed besides the deletions: `ASSET_GENERATION_MANIFEST.json` (deleted raw paths/SVG pack marked `*_deleted` / `DELETED_SB_M22_030`, valid JSON), `assets/art/references/inventory.json` (deleted records get `deletedRepositoryPath` + `deleted`, valid JSON), `assets/ui/VISUAL_ASSET_INDEX.md` (rows dropped, counts, notes), `docs/LEVEL_ART_INVENTORY.md`, `docs/M22_027_IMAGE_INVENTORY.md`, `docs/m22_027_image_inventory.csv` (rerun), new `docs/M22_030_IMAGE_CLEANUP.md` and `docs/m22_030_deleted_images.csv` (path, bytes, sha256, group, reason for every deleted image), `TASKS.md` (queue row + checklist line only).

## Acceptance criteria
1. [x] Every test/review evidence screenshot deleted, keeping images that code reads. I grepped tests/, tools/, .github/, scripts/, scenes/, data/, addons/, level_factory/, content_pipeline/ and project.godot for each path, basename and folder. The only coordination images that code reads are `coordination/sessions/M43-C005-C002/references/*` (9 files, read by `tools/validate_m43_c005_pack_assets.py`, `remediate_m43_c005_pack_assets_v04.py`, `rebuild_m43_c005_card_emergence.py`). They are kept. Every other code hit is a capture tool writing its own output. Result: 990 deleted, 9 kept.
2. [x] Drafts deleted only where selection is finished. Cards: 135/135 final. Home animation: set `home_scrubby_gestures_v03` APPROVED, with the V03 outputs byte-identical to the finals. Gameplay SVG slots: Phase 1 targets 306/306 present. The 4 crops are `PROMOTED_BY_CLAUDE_DELEGATED`, and their targets exist. Result: 427 deleted.
   Kept:
   - `assets/ui/candidates/m43_c005/**` (27): SHA256-checked by the m43_c005_c006/c007 tests.
   - `home_animation/source_v02` (63): owner-original source frames from a ZIP that is not in the repo, and input to `home_scrubby_prepare_assets.py --v03`. Unclear.
   - `generated/masters` (4): their surfaces are MASTER_OWNER_APPROVED, not yet OWNER_ACCEPTED. Unclear.
3. [x] Owner references deleted only where finished: 16 card sheets, 2 app icons (the launcher icons are live in project.godot), 2 logos (approved finals) and Playing Motors (gameplay is built). Result: 21 deleted.
   Kept:
   - Additionals (2): life/need_a_hand are still REFERENCE_SELECTED in `PLAYER_EXPERIENCE_ASSET_MANIFEST.json`. Unclear.
   - Game Screens (4): canonical authorities in the UI docs; level intro is not built. Unclear.
   - `master - actual differences.png`: Home convergence is not closed. Unclear.
   - `world_01`: worlds/regions are planned.
   - Levels and Level Sheets (24): level design references.
   - Level art was not touched.
4. [x] FUTURE_NEEDED: 4 of 145 deleted, `gameplay/buttons/icon_speed_2x.png`, `gameplay/buttons/speed_2x_timer_frame.png`, `gameplay/railway/rail_connector.png` and `gameplay/railway/rail_corner.png`. These are the VISUAL_ASSET_INDEX legacy duplicates. Each has a canonical replacement in place, and nothing names them in code, tests, tools or manifests. 141 are kept as plausible future use: branding (the app icons are actually live as launcher icons), marketing, robot animation layers, collection, exchange, shop, popups, difficulty emblems, loading/splash, settings icons and gameplay skins. Reasons are in `docs/M22_030_IMAGE_CLEANUP.md` and `docs/m22_030_deleted_images.csv`.
5. [x] Nothing ACTIVE_RUNTIME/DYNAMIC_REF, loaded by code/tests, untracked, or level art was deleted. After the inventory rerun, the ACTIVE_RUNTIME (426) and DYNAMIC_REF (74) path sets are identical to before. Zero class changes. The CSV diff is 1442 pure deletions.
6. [x] .import/.uid removed and refs fixed. The 4 tracked .import files of deleted images were removed (no deleted image had a tracked .uid). Runtime/test-read manifests contain no deleted path: HOME_ASSET_MANIFEST, PLAYER_EXPERIENCE_ASSET_MANIFEST, and the M43 pack manifests read by tests. The one exception is the historical `coordination/sessions/M42-C003/evidence_v03/normalization_measurements.json` record. It lists V03 tool-output paths, but its test reads only the sha256 fields, which equal the promoted finals. Asset manifest/index rows were marked or dropped, and json.loads passes on both edited JSON files.
7. [x] Proof: import, texture measure before/after, static suites (see Validation).
8. [x] TASKS.md: queue row `- DONE SB-M22-030 ...` added after SB-M22-027, and a checklist line added after the SB-M22-027 checklist line. No other lines touched.

## Validation (LOCAL_PASS, Godot 4.7.2 console, worktree)
- `python tools/m22_027_image_inventory.py --selftest`: PASS. Rerun: 2218 -> 776 images, 2578453215 -> 727905815 bytes.
- `godot --headless --path . --import` before and after: exit 0, no error lines. project.godot restored after each run, and import churn reverted.
- `tests/tools/m22_026_texture_measure.gd` before / after / after again (throw-away saves): 52 scenarios, 0 missing-resource / SCRIPT ERROR lines. Same 168 textures and identical loaded MiB per scenario. 1-2 px max-side jitter on animated victory/collection emblems and poses also shows between the two after runs of the same tree, so it comes from tween timing.
- m21_real_art_smoke: PASS.
- m22_026_texture_budget: PASS.
- maint_home_export_asset_gate_c001: 11/11.
- m42_c003_scrubby_animation: 25/25.
- m43_c005_c006_standard_pack_presentation: 28/28.
- m43_c005_c007_premium_pack_presentation: 20/20.
- m42_home: 19/19.
- m42_assets: FAIL(2), pre-existing. It counts 54 HOME_ASSET_MANIFEST ART entries against a stale 53. The manifest is unchanged by this branch (SB-POLISH-009 added HOME-123), and this suite is not in the CI suite list.
- m43_c001b_won_results_visual: 3 fails, pre-existing. The suite expects still-texture robots on Results, which 93a02ced replaced with Flow videos. It reads no deleted file and is not in the CI suite list.
- `git diff --check`: clean. `git status --porcelain`: empty.
- No CI run, no phone build, not pushed.

## Log
### Round 1
I built the deletion lists from the 096 inventory, with grep checks against all code roots and manifest/status checks for each group. I ran the baseline import and texture measure, then made 3 deletion commits and 1 docs/tasks commit. Afterwards I re-imported, reran the inventory, ran the measure twice, and ran the asset/manifest guard suites plus the suites for the touched manifests. Two items for owner/peer attention:
- The 096 inventory classes the 3 launcher icons in project.godot as FUTURE_NEEDED, so its class is not reliable for those. They are kept.
- m42_assets and m43_c001b are stale, pre-existing failures outside this job.
