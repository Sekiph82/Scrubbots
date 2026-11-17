STATUS: READY

# Build: 176-aab-size (SB-AAB-SIZE-2026-11-17)

## Summary
Cuts the exported pack from 348-368 MB to ~122 MB. Pixel-art level data, gameplay and economy are unchanged, and no source PNG or master was changed or deleted.

- **Textures:** every PNG under `assets/ui/final/` whose source is >= 100 KiB now imports as Godot Lossy (WebP, `compress/lossy_quality=0.8`, alpha kept). The exceptions are `boosters/` and `gameplay/effects/` (their alpha gradients band, per the earlier UI-ADR) and `branding/`. Everything smaller and all pixel art (`assets/art/levels/`) stays lossless. Size limits and mipmaps are unchanged. That is 583 `.import` files: 434 edited and 149 newly tracked (these PNGs had only the Godot default `.import` before). The tool is `tools/sb_aab_size_lossy.py [--write]`.
- **Videos:** the keyed Flow videos (results win/lose, level start, gift small/big, set complete, welcome back, new region, need a hand, 10 robot unlocks) were re-encoded from the owner masters in `flow_videos/` (read only) at Theora `-q:v 5` instead of 8. This uses `tools/build_result_scrubby_videos.py`, which now has a `THEORA_Q` constant. The opening cinematic was re-encoded from its committed MP4 master at q5. The stills are byte-identical (not in the diff). Each `PROVENANCE.md` records the new sha256, size and command.
- **Not changed:** the Home videos (already q4 and sha-pinned by the Home manifest/tests) and the pack openings (q6, already shown below their resolution per UI-VIS-006). The audio is only 2.8 MB (one ogg) and was left alone.
- **Tests and docs:** `tests/ui_vis_006_asset_qa.gd` (CI) now enforces the lossy/lossless split in both directions, plus the quality and the lossy count (> 500). `tests/m22_029_texture_cold_warm.gd` uses the same rule. `tools/ui_vis_006_asset_qa.py` imports the rule. `tests/m42_opening.gd` has the new hash and q5. The decision is in `docs/07_UI_ASSET_PIPELINE_DECISIONS.md` (UI-ADR-009) and `docs/UI_VIS_006_ASSET_QA.md`.
- **Capture tool:** `tests/tools/store_screens_capture.gd` gained `--level N`, used for the L11 captures.
- **Evidence:** the before/after sheets are in `coordination/sessions/FACTORY/176-aab-size/evidence/`.

Commits: `82ed3b2f` textures, `890011f5` videos, `42306ef8` capture --level, `92f8248e` evidence. The branch is rebased on origin/main `cae0ab61`, which includes job 168.

## Size table

### Measured: what is in the PCK (local `--export-pack` of the Android preset, before vs after)
| category | before MB | after MB |
|---|---|---|
| PNG (imported ctex) | 268.5 | 59.8 |
| Theora .ogv | 88.4 | 52.1 |
| JSON (levels/config) | 6.3 | 6.3 |
| ogg music | 2.8 | 2.8 |
| **PCK total** | **368.4** (local file) | **123.4** (local file) |

PNG by folder (MB, imported):
| folder | before | after |
|---|---|---|
| final/collection | 78.3 | 15.7 |
| final/characters | 44.4 | 9.7 |
| final/rewards | 28.2 | 6.0 |
| final/events | 24.6 | 3.9 |
| final/gameplay | 22.3 | 5.1 |
| final/popups | 20.3 | 3.9 |
| final/home | 12.2 | 2.1 |
| final/common | 8.7 | 1.2 |
| final/robots | 7.2 | 1.4 |
| final/marketing | 5.9 | 1.1 |
| final/branding (lossless on purpose) | 5.8 | 5.8 |
| final/system | 4.0 | 1.0 |
| final/daily | 2.3 | 0.3 |
| final/boosters (lossless on purpose) | 2.2 | 2.2 |
| final/shop | 1.6 | 0.3 |
| assets/art (pixel art, lossless) | 0.1 | 0.1 |

Biggest single files before: the opening .ogv 16.04, premium_pack_opening.ogv 5.53, gift_big_opening.ogv 3.94, world_01_whispering_park png 3.64, standard_pack_opening.ogv 3.59, home_scrubby_wave_keyed.ogv 3.58, set_complete_badge.ogv 3.57 MB. Keyed videos: 63.2 MB down to 26.9 MB (opening 16.04 to 7.28 MB).

### Packages
| artifact | before | after | source |
|---|---|---|---|
| CI PCK | 347.8 MB (run 44105591683, release) | **122.7 MB** (run 44121919624, debug apk_only on this branch) | CI `sizes.txt` |
| Universal APK (both ABIs) | 513.6 MB (run 44108551008, debug b99) | **178.1 MB** (run 44121919624, b104) | CI `sizes.txt` |
| Release AAB (both ABIs) | 396.1 MB (run 44105591683) | **~173 MB est.** (396.1 − 225.1 PCK delta) | estimate |
| Play base-module download, arm64 device | ~372 MB est. | **~150 MB est.** (PCK 122.7 + arm64 `libgodot_android.so` 24.0 + libc++ 0.5 + dex 1.8 compressed, from the 4.7.2 release template) | estimate |
| iOS IPA | 369.6 MB (run 44077148479) | **~145 MB est.** (369.6 − 225 PCK delta) | estimate |

The AAB and IPA "after" values are estimates. The aab_release dispatch on this branch was denied by the session permission layer, and iOS was not dispatched. The base module is now well under Play's 200 MB limit and at the 150 MB target.

## Acceptance criteria
1. [x] **Measure and table:** done (see above). Local import + `--export-pack "Android Family First10"` before/after, with each stored file mapped back to its source by its `.import` dest.
2. [x] **Shrink, in the spec's order of preference:**
   - **Textures:** lossy WebP 0.8 for big UI art. Pixel art, boosters/effects and branding stay lossless. Mipmaps are still off and the size limits are untouched. Oversized sources were already capped by UI-ADR-008 (cards 1080 etc.).
   - **Videos:** re-encoded from the masters at q5 at their existing crop sizes. These sizes are at or below their drawn size on 1170x2532 per UI-VIS-006 (several are recorded under-res), so downscaling would hurt.
   - **Key check:** a frame-by-frame key-edge metric on all 19 keyed videos with the shader's key. The semi-transparent band grows from 0.56 to 0.65 % of frame pixels (win), and similarly for the others. Keyed comparison sheets (q8 left, q5 right) over BG01 for win, atlas (magenta), bubbles, gift (green) and clippy (blue) show no magenta, green or blue fringe: `evidence/before_after_key_sheet_a.jpg` and `_b.jpg`.
   - **Audio:** already one 2.8 MB ogg, unchanged.
   - **Unused files:** a literal-reference scan finds ~321 exported files without a literal `res://` path. They are almost all dynamically built paths (card thumbs, robot videos, home animation frames). The only unreferenced static weight is `branding/` (~5.7 MB of app-icon/logo ctex). Removing them would mean editing the export preset's exclude_filter, which is a workflow-owned file I was told not to edit. Left as a follow-up note.
3. [x] **Visual check:** real-app GPU captures with a throw-away save. `store_screens_capture.gd --size 1080x2340 --level 11` covers Home, Collection, Robots, gameplay L11 after the real intro video, and the end of the real win video. `ev02_events_capture.gd` covers the Events page at 1170x2532 (its fixed size). Before = a temporary worktree at origin/main `cae0ab61` (removed afterwards); after = this branch.
   - Mean abs diff per screen: Home 1.10/255, Collection 0.55, Robots 0.58, gameplay 2.18 (bots are in motion), win 1.17, Events 1.03.
   - The side-by-side sheets `evidence/before_after_sheet_1.jpg` / `_2.jpg` and the 1:1 crops (`_crop_1_home.jpg`, `_crop_3_robots.jpg`) show no visible change to art or text.
4. [x] **Prove the size:** CI run 44121919624 (apk_only on `factory/176-aab-size`) measured APK 178,131,202 and PCK 122,735,716 bytes. AAB and IPA are estimated (see table). The run itself ends red at its last step, "APK signature / metadata / hash". The cause is the summary line `cat out/aab_cert.txt out/aab_manifest.txt 2>/dev/null` added on main by job 168: on a debug apk_only build those files do not exist, so `cat` exits 2 under `bash -e`. This happens after the sizes are printed and the artifact is built. It is not from this branch, and the workflow is not mine to edit.
5. [x] **Suites:** see Validation.

## Validation
- `tests/ui_vis_006_asset_qa.gd`: `UI-VIS-006 ASSET QA: PASS` (exit 0, 0 script errors) — LOCAL_PASS
- `tests/m22_026_texture_budget.gd`: `M22-026 TEXTURE BUDGET: PASS` — LOCAL_PASS
- `tests/m42_opening.gd`: `M42 opening evidence: PASS` — LOCAL_PASS
- `tests/m22_025_booster_texture_budget.gd`: `FAIL (1)` "9 booster PNGs (expected 10)". It fails identically on origin/main `cae0ab61`, so it is pre-existing, unrelated to this job, and not in the CI list.
- `tests/m22_029_texture_cold_warm.gd`: `M22-029 TEXTURE COLD/WARM: PASS`, with "627 final/ imports follow the lossy/lossless split without mipmaps" — LOCAL_PASS
- Full CI list (98 suites, `python tools/run_suites.py`, CI PASS/FAIL rule): **97 PASS, 1 FAIL**. I ran suites 1-49 sequentially and 50-74 and 75-98 as two parallel shards (`aggregate=PASS (25/25)` and `aggregate=PASS (24/24)`). All PASS have exit 0 and diag 0. These include ui_vis_006_asset_qa, m42_home, m43_master_c005_meta_ceremonies, m43_master_c007_collection, m43_master_c008_robots, m43_c005_c074_c077_celebrations, m46_performance, m49_responsive_matrix, ev02_events_ui, ev02_events_v02, board_bg01_backdrop, sb_phone_2026_11_12_e_win_home and real_play_levels.
  - The one FAIL is `m43_c001a_results_foundation`, on "economy/progression untouched". The economy snapshot it compares includes the EV02 wall-clock high-water mark, which moves with real time. It is unrelated to textures and videos and is the flake job 175 fixes (its branch commit `9c48fa0c`: "EV02 reads never write the high-water clock (flaky m43_c001a economy-untouched in CI)").
- `git diff --check`: clean on the changed text files.

## Log
### Round 0
Measured, applied lossy WebP to the big UI art, re-encoded the keyed videos and the opening from their masters at q5, updated the tests and docs, made GPU before/after captures and key sheets, and measured the CI APK/PCK.

Notes for the merger:
- 149 new tracked `.import` files sit under `assets/ui/final/` (characters, common, gameplay, rewards ...). The owner's Desktop checkout has Godot-generated untracked `.import` files at many of the same paths, so `git pull --ff-only` there will refuse with "untracked working tree files would be overwritten". Those untracked files are regenerable Godot defaults (lossless). Deleting exactly the colliding ones lets the pull through, but that needs the owner's or orchestrator's call.
- Not done: the Desktop owner-side deletion; removing `branding/` from the export (needs a preset edit); the aab_release / iOS runs (the aab dispatch was denied by the permission layer).
