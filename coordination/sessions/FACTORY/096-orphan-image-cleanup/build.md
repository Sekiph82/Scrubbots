STATUS: READY

# Build: SB-M22-027 tracked-image inventory and proven-orphan cleanup

## Summary
Branch `factory/096-orphan-image-cleanup` (4 commits on ebf70299, not pushed):

- `66a848d3` tools/docs: `tools/m22_027_image_inventory.py` (stdlib, `--selftest`) classifies every
  tracked image by SHA256 and references; `docs/M22_027_IMAGE_INVENTORY.md` (method, classes,
  findings) + `docs/m22_027_image_inventory.csv` (one row per image: path, sha256, bytes, class,
  reason, tracked .import/.uid, first source refs).
- `db318453` tools: the inventory skips its own source (its selftest literals had matched 2
  coordination captures).
- `15f5716e` assets: `git rm assets/ui/final/gameplay/buttons/icon_pause.png` (the only
  CONFIRMED_ORPHAN); `.github/workflows/ios-ipa.yml`, `docs/IOS_TOOLCHAIN.md`,
  `assets/ui/VISUAL_ASSET_INDEX.md` no longer special-case it; report gains Deleted + After;
  CSV is the after state.
- `ab2cd36c` docs/tasks: SB-M22-027 queue row DONE and checklist row `[x]` with evidence.

Files changed: `tools/m22_027_image_inventory.py` (new), `docs/M22_027_IMAGE_INVENTORY.md` (new),
`docs/m22_027_image_inventory.csv` (new), `assets/ui/final/gameplay/buttons/icon_pause.png`
(deleted), `.github/workflows/ios-ipa.yml`, `docs/IOS_TOOLCHAIN.md`,
`assets/ui/VISUAL_ASSET_INDEX.md`, `TASKS.md`.

### Inventory report

How references are found: every tracked text file except image `.import` files, the tool itself
and its report. For each image the tool looks for its res:// path, repo path (also backslash and
%20 forms), the uid:// from its .import, its file name, its stem (as a substring, which is loose
on purpose), code format patterns that need at least 4 literal characters (`"rewards/%s.png"`,
`"set_%02d/card_%02d.png"`, `"_portrait.png"`) and code folder literals (`FRAME_DIR + f`,
`VIDEO_DIR + name + "_" + kind + ".png"`). Runtime sources are scripts/, scenes/, data/, addons/,
.tres/.tscn/.gdshader under assets/, project.godot (boot splash), and any manifest that runtime
code loads by res:// (HOME_ASSET_MANIFEST.json, read by home_art_binder). The only runtime
DirAccess listings are the game_feel_flow presets, the level catalog importer and the user://
pack store, so no res:// art folder is listed at runtime. Images that the Android export preset
excludes (generated/, candidates/, art/references/, coordination/) count as runtime only when
code loads them by res:// or uid. Runtime data that names them (HOME manifest source fields),
the shipped final file with the same name, and plain paths in code comments count as
provenance.

| class | before | after | bytes after |
|---|---:|---:|---:|
| ACTIVE_RUNTIME | 426 | 426 | 399217989 |
| DYNAMIC_REF | 74 | 74 | 61507569 |
| PROVENANCE_MASTER | 1573 | 1573 | 1942805818 |
| FUTURE_NEEDED | 145 | 145 | 174921839 |
| TEST_ONLY | 0 | 0 | 0 |
| UNKNOWN | 0 | 0 | 0 |
| CONFIRMED_ORPHAN | 1 | 0 | 0 |
| **total** | 2219 (1871 SHA256) | 2218 (1870 SHA256) | 2578453215 |

PROVENANCE_MASTER covers 1269 coordination evidence captures, 224 generated, 53 owner references
and 27 candidates. Of the 145 FUTURE_NEEDED, all are under assets/ui/final. Runtime does not
reference them, but ASSET_GENERATION_MANIFEST, the HOME manifest or VISUAL_ASSET_INDEX lists
them as approved art.

Deleted: `assets/ui/final/gameplay/buttons/icon_pause.png`, 7531 bytes, sha256
d917ec37efdafda1fdd6d21f0c6da6a390a65eeb6413cf2e04c54e4b3b30e782, no tracked .import/.uid.
- Proof it can't be decoded: the IDAT chunk declares 32768 bytes but the file ends at byte 7531,
  and zlib fails with "invalid distance too far back". Godot import fails with
  ERR_FILE_CORRUPT. Those were the project's only 3 import errors; there are 0 after the
  deletion.
- Proof nothing references it: no code, scene, data, test, tool or export preset reference
  of any kind. The only mentions were descriptions of the broken file: owner review
  M28-C002-C002 S4 ("icon_pause.png is a broken PNG", native glyph used), VISUAL_ASSET_INDEX
  LEGACY / EXTRA, the M47 R02 audit trail and the iOS workflow workaround.
- Runtime proof: see AC 4.
- Freed: 7531 bytes. It was permanently `git rm`'d, with no archive or backup.

Judgement calls:
1. I classified coordination/** captures by location as audit evidence (PROVENANCE_MASTER), so
   none of them could be deleted. 301 of them (419991770 bytes, mostly M43 evidence folders)
   are not referenced by name anywhere; their session logs cite the evidence folder as a whole.
   They are review evidence, not game graphics, so I kept them. Deleting them would need an
   explicit owner decision.
2. VISUAL_ASSET_INDEX lists 5 decodable "Legacy / extra production paths" with "Do not delete them
   automatically". Owner review calls icon_speed_2x approved but unsuitable. I kept all 5:
   four are FUTURE_NEEDED, and railway/rail_straight.png is DYNAMIC_REF because its stem
   collides with rail_straight_horizontal.
3. Superseded generated sets (home_animation v01 and source_v02, pack-opening candidates) are
   named in audit evidence JSON or in manifests as the provenance chain of the final art, so I
   kept them as PROVENANCE_MASTER.
4. A broken PNG under assets/ that no code, scene, data or test file loads is CONFIRMED_ORPHAN,
   even though docs and CI mention it. Such notes describe the breakage; they are not uses. The
   tool encodes this rule as `png_decodes`.
5. Stem substring matching is deliberately loose: a name collision keeps a file rather than
   deleting it.

## Acceptance criteria
1. [x] Inventory every tracked image (png/jpg/webp/svg/etc and their .import/.uid) by SHA256 into
   the 7 classes: `python tools/m22_027_image_inventory.py --csv ... --md ...` covers 2219 images
   and 14 extensions. The CSV has 2219 rows before and 2218 after, each with a sha256 and its
   tracked meta.
2. [x] The reference scan covers direct load/preload, dynamic paths (format strings, path joins,
   slug maps, manifests, data/config json), .tscn/.tres ext_resource including uid://,
   .import/.uid, tests, docs and provenance (ASSET_GENERATION_MANIFEST, HOME manifest,
   PROVENANCE.md), level_factory/, content_pipeline/, CI workflows, export presets and
   project.godot. It also checks folder-level dynamic loads and stems without the extension, so
   a zero filename grep is never the only evidence. `--selftest`: PASS. It covers PNG decode,
   pattern specificity, folder literals and source kinds.
3. [x] Only CONFIRMED_ORPHAN images were deleted, each with independent negative-reference proof:
   1 file, proof above. Nothing ambiguous was deleted. Referenced owner art, manifest-listed
   final art, level art, provenance masters and untracked files were all kept. Nothing was
   archived and no art was overwritten.
4. [x] Runtime proof after deletion: `tests/tools/m22_026_texture_measure.gd` runs the real
   main.tscn with throw-away saves across 52 scenarios at 1080x2400 and 1536x2048. I ran it
   before (4m06s) and after. Neither log has a "Failed loading resource", "Cannot open file",
   "Resource file not found", "Error loading" or icon_pause line. The 168 merged texture sizes
   and the per-scenario loaded MiB are identical (JSON compare). `--import` after the deletion
   shows 0 errors (3 before).
5. [x] The report gives before/after counts, freed bytes, each deleted path with its proof, and
   the counts per class: `docs/M22_027_IMAGE_INVENTORY.md`, plus the tables above.
6. [x] Static asset guard suites, the texture budget and a cold-boot missing-resource check were
   run. Results under Validation.
7. [x] TASKS.md: the queue row and the checklist row are marked DONE with evidence (ab2cd36c).

## Validation
- `python tools/m22_027_image_inventory.py --selftest`: `selftest PASS`.
- `python tools/m22_027_image_inventory.py --csv/--md` before and after: the tables above.
- `$GODOT --headless --path <wt> --import`: 3 ERROR lines before (all icon_pause), 0 after.
  project.godot was restored after each import, and the import churn on tracked .import files
  was restored, not committed.
- Cold boot / missing resources: m22_026_texture_measure before and after, both exit 0. The only
  ERROR in each log is the usual exit leak line "30 resources still in use".
- Suites after the deletion (scratch runner using run_suites.evaluate, LOCAL_PASS):
  - m22_026_texture_budget: PASS
  - m22_025_booster_texture_budget: PASS
  - m21_real_art_smoke: PASS
  - m42_home: PASS ("M42 home evidence: PASS"; a first run done while the inventory was also
    running printed FAIL(1), the standalone rerun passed)
  - m49_responsive_matrix: 8/8 PASS
  - maint_home_export_asset_gate_c001: 11/11, 0 failures, exit 0. Its summary line has no
    "PASS" word, so evaluate() flags it.
- Pre-existing failures. Both are identical with icon_pause.png restored (I checked out the
  file, re-imported and re-ran both), and neither suite is in the CI list:
  - m42_assets: FAIL(2). HOME_ASSET_MANIFEST has 54 APPROVED_BOUND entries; the test expects 53.
  - m28_c002_c002_r01_visual: 10/10 cases pass, but the log has 15 "SCRIPT ERROR: Left operand
    of 'is' is a previously freed instance" at scripts/ui/feel/booster_vfx.gd:122.
- `git diff --check`: clean for every commit.
- No CI run and no phone build, as instructed. Not pushed.
- The worktree has untracked Godot import output (.import/.uid/.translation) and
  tools/__pycache__ from the selftest. Removing tools/__pycache__ was denied by the
  permissions, and per instructions I didn't delete the untracked generated files. Tracked
  files are clean.

## Log
### Round 1
- Read CLAUDE.md, AGENTS.md, the SB-M22-027 and SB-M22-026 rows, the m22_026 inventory and measure
  tools. There is no spec.md in the job folder; the TASKS.md row is the spec.
- Wrote the inventory tool and refined it in several passes. Each refinement came from real
  false hits: generic `"%s/%s.png"` test patterns matched everything; VISUAL_ASSET_INDEX.md
  under assets/ counted as runtime; generated files named in HOME manifest source fields; a
  storyboard path in a code comment.
- Found icon_pause.png corrupt during the worktree import. The tool now detects undecodable
  PNGs, and this file is the single CONFIRMED_ORPHAN.
- Deleted it, cleaned the iOS workflow workaround and the docs, re-ran the inventory, the measure
  tool and the suites, and established a baseline for the two failing suites.
- Labels: the evidence is LOCAL_PASS and CLAUDE_SELF_REVIEW. Factory peer review is still pending.
