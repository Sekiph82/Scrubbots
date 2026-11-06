STATUS: READY

# Build: SB-UI-VIS-006 + SB-UI-031 pixel-level QA of on-screen assets

## Summary
New offline audit `tools/ui_vis_006_asset_qa.py` (Pillow + numpy + scipy, all already installed) over
every ACTIVE_RUNTIME / DYNAMIC_REF image (641: 568 final/ PNGs, 40 level PNGs, 33 SVGs) from a fresh
m22_027 inventory run, with drawn rects from a fresh run of the 101 measure tool. Report
`docs/UI_VIS_006_ASSET_QA.md`, per-image CSV `docs/ui_vis_006_asset_qa.csv`, regression test
`tests/ui_vis_006_asset_qa.gd` (added to the android-family-first10 suite list). No art and no
`.import` changed: all import settings were already right.

Files: tools/ui_vis_006_asset_qa.py, tests/ui_vis_006_asset_qa.gd, docs/UI_VIS_006_ASSET_QA.md,
docs/ui_vis_006_asset_qa.csv, .github/workflows/android-family-first10.yml (suite list +1), TASKS.md.
Commits: e58f4bbc (tool, report, CSV, test), ff9ec2a2 (TASKS.md).

Findings: 582 PASS, 50 WARN, 9 FAIL.
- FAIL (under-res, drawn larger than the texture, every one already at source size): the owner-locked
  gameplay shells `gameplay_v02_shell_5slot_3col/6slot_3col` (887x1774, 0.76x at 1170x2532),
  `home/background/home_background.png` (0.71x), and 6 video stills that match their videos
  (Home Scrubby and the standard/premium pack opening at 720x1280: 0.55-0.62x; level_start 624x640:
  0.65x on the tablet). Fixing them needs new art or video renders, an owner decision. They are recorded,
  not changed.
- WARN: 27 under 2x, all still at or above 1x (13 card arts at 1.85x, kept on purpose; 3 nine-patch popup
  frames; source-limited 128 px profile icons at 1.23-1.36x ...); 3 RGBA PNGs with an opaque white
  background (`bot_parts_bar_fill`, `rail_straight`, `slot_active`), none of them drawn; 3 Home world
  strips that touch the canvas edge by design; 18 with at least 1 MiB of transparent padding (mostly
  pack-opening frames that share a registration canvas).
- 0 white halos, 0 empty images, level art alpha binary on all 40. The text/watermark heuristic gave
  3 candidates; Claude looked at each (dust, water drops, confetti), and found no text. Claude also
  looked at contact sheets of the bottom-right and bottom-left corners of all 433 non-thumbnail final/
  PNGs: no mark found.

## Acceptance criteria
1. [x] Audit tool over every ACTIVE_RUNTIME/DYNAMIC_REF image: done. `python -I tools/ui_vis_006_asset_qa.py --inventory=<fresh inv> --measure=<measure.json>` printed "641 images: {'PASS': 582, 'WARN': 50, 'FAIL': 9}". Re-running without --measure gives a byte-identical CSV (`diff -q` IDENTICAL).
2. [x] Alpha-edge checks (fringe/halo, matte bleed): 0 white-matte silhouette halos. The first rule was too broad (it flagged the cards' inner glass line), so I narrowed it to the silhouette after a pixel look. The report explains why dark edge pixels are excluded.
3. [x] Hard-cut alpha at the canvas border: 3 WARN, all Home world strips that run off-screen by design.
4. [x] Transparent padding waste: 18 WARN at 1 MiB or more, with the MiB per image in the CSV. 132.68 MiB in total if everything were resident at once.
5. [x] Text/watermark heuristics as candidates, with no auto-fail: 3 candidates, each looked at, no text. The bottom-corner contact sheets were also looked at. The top corners were checked by the heuristic only (stated in the report).
6. [x] Resolution against the measured drawn size: fresh `m22_026_texture_measure.gd` run "M22-026 MEASURE: DONE (84 scenarios, 189 textures)", 0 SCRIPT ERROR. Below 1x FAIL: 9. Below 2x WARN: 27. 401 unmeasured, with the reasons from M22_029.
7. [x] Import settings consistent: 641/641 have compress/mode=0, mipmaps off, fix_alpha_border on and premult off. size_limit counts are in the report. Filtering is Linear for the UI and Nearest for the board and teaser. 243 runtime images have untracked .import files (Godot defaults, same parameters), noted. Nothing was clearly wrong, so nothing was changed.
8. [x] Memory per texture: resident_mib column. 1479.43 MiB for all final/ PNGs, 386.61 MiB for the 167 with a drawn rect.
9. [x] Report plus CSV with concrete defects and paths: docs/UI_VIS_006_ASSET_QA.md, docs/ui_vis_006_asset_qa.csv.
10. [x] No art modified: commit e58f4bbc touches no image or .import.
11. [x] Regression test: tests/ui_vis_006_asset_qa.gd LOCAL_PASS (exit 0, "UI-VIS-006 ASSET QA: PASS": 608 PNG rows, 167 with a drawn rect, imports ok, 0 under-res, 9 known rows held at or above their recorded ratio). Negative check: setting card_01 size_limit to 256 and turning icon_lock mipmaps on gave "FAIL (2)" with exit 1, and both changes were then reverted.
12. [x] Visual-only judgements are not claimed: the "Owner phone review" section lists softness of the stills and shell, readability of the 128 px icons, and identity consistency.
13. [x] TASKS.md: both queue lines are DONE with a findings summary, and both checklist items are [x], noting that owner-visual review is pending.

## Validation
- `godot --headless --path . --import` once (exit 0). project.godot was rewritten by the import and restored with git checkout. The CRLF-only .import churn and the generated untracked .import/.uid/.translation files were removed, so `git status --porcelain` is empty.
- `godot --headless -s res://tests/tools/m22_026_texture_measure.gd -- --out=<scratch>`: DONE (84 scenarios, 189 textures), 0 SCRIPT ERROR (throw-away saves).
- `python -I tools/m22_027_image_inventory.py --csv <scratch>`: fresh inventory, 641 runtime images (scratch only, committed inventory not touched).
- `python -I tools/ui_vis_006_asset_qa.py ...`: exit 0, and a re-run is reproducible.
- `godot --headless -s res://tests/ui_vis_006_asset_qa.gd`: LOCAL_PASS, exit 0, no SCRIPT ERROR. The negative variant FAILs as expected.
- `git diff --cached --check`: clean.
- No CI run, no phone build (as instructed). No runtime code touched, so no other suites were needed.

## Log
### Round 1
Built the tool, the report, the CSV and the test. I calibrated the heuristics on real hits:
- Halo: restricted to silhouette pixels and to white matte only, after the card glass line and pack-frame shadows came out as false positives.
- Glyph islands: merged pieces within 2 px of each other (rounded-corner tips), and skipped opaque art smaller than 128 px.
- Resolution: compared on the fitting axis using visible draws only, because max-side against max-side flagged keep-aspect stills that are not upscaled.
- Added an opaque-white-background check after the contact sheets showed white boxes.
I used a fresh inventory because the committed m22_027 CSV predates the 141 thumbnails and stills. Peer review has not happened yet (factory review pending).
