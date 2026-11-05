# SB-M22-027 tracked-image inventory and orphan cleanup

Factory job 096 (2026-11-05). Tool: `tools/m22_027_image_inventory.py` (stdlib, `--selftest`).
Per-image table (path, SHA256, bytes, class, reason, tracked .import/.uid, first source refs):
`docs/m22_027_image_inventory.csv`. Re-run from the repo root after `godot --headless --import`
(so every image has its .import uid on disk):
`python tools/m22_027_image_inventory.py --csv docs/m22_027_image_inventory.csv --md <summary.md>`.

## Method

Every tracked image (`git ls-files`: png, jpg, jpeg, webp, svg, bmp, tga, gif, exr, hdr, ico,
icns, ktx, dds) is searched for in every tracked text file except image `.import` files, the
tool and this report. A reference is any of:

- **res** / **path**: the `res://` path / the repo path (also backslash and `%20` forms);
- **uid**: the `uid://` from its `.import` (scene/resource ext_resource by uid);
- **base**: the file name with extension (relative tails such as `F + "common/icons/x.png"`,
  JSON icon fields, slug maps that store names);
- **stem**: the file name without extension, as a substring (slug maps, `name + ".png"`);
  deliberately loose, so a collision keeps a file (e.g. `railway/rail_straight.png` is held by
  `rail_straight_horizontal`);
- **pat**: a code string literal with a format placeholder (`"rewards/%s.png"`,
  `"set_%02d/card_%02d.png"`) or a `"_tail.png"` fragment, matched as a regex against the end of
  the path; a pattern needs 4+ literal folder/name characters (`"%s/%s.png"` names nothing);
- **dir**: a code string literal naming the image's folder (`FRAME_DIR + f`,
  `VIDEO_DIR + name + "_" + kind + ".png"`); the bare roots `res://`, `res://assets/` and
  `res://assets/ui/final/` are not folders, their tails are caught by base/pat.

The only runtime folder listings (`DirAccess`) are in `addons/game_feel_flow` (presets, effect
types), `scripts/tools/level_batch_importer.gd` (level catalog) and the user:// pack store of
`remote_content_manager.gd`; no runtime code lists a res:// art folder.

Source kinds: **runtime** = scripts/, scenes/, data/, addons/, .tres/.tscn/.gdshader under
assets/, project.godot (boot splash, icons), plus any asset manifest that runtime code loads by
`res://` path (`assets/ui/HOME_ASSET_MANIFEST.json`, read by `home_art_binder.gd`); **test** =
tests/; **tool** = tools/, .github/ (workflows, export presets), level_factory/,
content_pipeline/; **manifest** = `ASSET_GENERATION_MANIFEST.json` and text beside the art
(`assets/**` manifests, PROVENANCE.md, `VISUAL_ASSET_INDEX.md`, `references/inventory.json`);
**doc** = everything else (docs/, coordination/, factory/, TASKS.md).

The Android export preset (`.github/android/export_presets_family_first10.cfg`) excludes
coordination/, assets/art/references/, assets/ui/generated/ and assets/ui/candidates/ from the
pack, so for those images only a code `res://` or uid reference counts as runtime; runtime data
that names them (the HOME manifest's source fields), bare names in code (the shipped final twin,
e.g. `frame_01_closed.png`) and plain paths in code comments (the pack-opening storyboard master
in `standard_pack_ceremony.gd`) count as provenance.

Classes, first match wins:

| class | rule |
|---|---|
| ACTIVE_RUNTIME | runtime res://, path or uid reference |
| DYNAMIC_REF | runtime base/stem/pat/dir reference |
| PROVENANCE_MASTER | owner references/_owner_inbox, level art, plugin, masters/, coordination/factory audit evidence, or a generated/candidate image named by a manifest, tool or doc |
| FUTURE_NEEDED | assets/ui/final image named by an asset manifest/index but by no runtime file |
| TEST_ONLY | referenced by tests only |
| UNKNOWN | any other reference (tool/doc only): ambiguous, kept |
| CONFIRMED_ORPHAN | no reference of any kind anywhere, or an undecodable PNG under assets/ that no code/scene/data/test file loads |

CONFIRMED_ORPHAN is then deleted only with runtime proof (below).

## Before (origin/main ebf70299)

| class | images | bytes |
|---|---:|---:|
| ACTIVE_RUNTIME | 426 | 399217989 |
| DYNAMIC_REF | 74 | 61507569 |
| PROVENANCE_MASTER | 1573 | 1942805818 |
| FUTURE_NEEDED | 145 | 174921839 |
| TEST_ONLY | 0 | 0 |
| UNKNOWN | 0 | 0 |
| CONFIRMED_ORPHAN | 1 | 7531 |
| **total** | 2219 | 2578460746 |

2219 tracked images, 1871 distinct SHA256.

| folder | ACTIVE_RUNTIME | DYNAMIC_REF | PROVENANCE_MASTER | FUTURE_NEEDED | TEST_ONLY | UNKNOWN | CONFIRMED_ORPHAN |
|---|---:|---:|---:|---:|---:|---:|---:|
| addons | 1 | 30 | 0 | 0 | 0 | 0 | 0 |
| assets/art/levels | 40 | 0 | 0 | 0 | 0 | 0 | 0 |
| assets/art/references | 0 | 0 | 53 | 0 | 0 | 0 | 0 |
| assets/brand (2 svg) | 2 | 0 | 0 | 0 | 0 | 0 | 0 |
| assets/ui/candidates | 0 | 0 | 27 | 0 | 0 | 0 | 0 |
| assets/ui/final | 383 | 44 | 0 | 145 | 0 | 0 | 1 |
| assets/ui/generated | 0 | 0 | 224 | 0 | 0 | 0 | 0 |
| coordination | 0 | 0 | 1269 | 0 | 0 | 0 | 0 |

## Findings

- **One CONFIRMED_ORPHAN**: `assets/ui/final/gameplay/buttons/icon_pause.png`.
- Every other assets/ image has at least one reference. No assets/ image is unreferenced.
- The 145 FUTURE_NEEDED final images have no runtime reference but are listed by
  `ASSET_GENERATION_MANIFEST.json`, `HOME_ASSET_MANIFEST.json` or `assets/ui/VISUAL_ASSET_INDEX.md`
  as approved production art (Phase 1/2 canonical targets). Kept by rule; SB-M22-029 measures
  the remaining reachable screens. Five of them are the `VISUAL_ASSET_INDEX` "Legacy / extra
  production paths" (`gameplay/buttons/icon_speed_2x.png`, `gameplay/buttons/speed_2x_timer_frame.png`,
  `gameplay/railway/rail_connector.png`, `rail_corner.png`; `rail_straight.png` is DYNAMIC_REF by
  stem collision). They decode, the index says "Do not delete them automatically", and owner
  review M28-C002-C002 S4 calls `icon_speed_2x.png` approved but unsuitable: kept.
- 301 coordination/ audit-evidence captures (419991770 bytes, mostly M43 evidence folders)
  have no individual path/name reference; their session logs cite the evidence folder. They are
  review evidence, not game graphics, and are kept as PROVENANCE_MASTER (location rule).
- 348 tracked images are byte-identical copies of another tracked image (2219 files,
  1871 SHA256), e.g. generated sources promoted to final. Duplicates are not orphans; each copy
  is classified by its own path.

## Deleted (permanent `git rm`, no archive or backup)

| path | bytes | sha256 | tracked meta |
|---|---:|---|---|
| `assets/ui/final/gameplay/buttons/icon_pause.png` | 7531 | `d917ec37efdafda1fdd6d21f0c6da6a390a65eeb6413cf2e04c54e4b3b30e782` | none (its .import was never tracked) |

Proof:

- **Undecodable**: the IHDR says 256x250 RGBA, the single IDAT chunk declares 32768 bytes but
  the file ends after 7531; zlib stops with "invalid distance too far back". Godot's import
  fails (`ERR_FILE_CORRUPT`, "Error importing ...icon_pause.png"; the only 3 import errors of
  the project), so no load of it can ever return a texture. Truncated since its only commit
  fbda9e71.
- **Negative references**: no res:// path, repo path, uid, file name, stem, pattern or folder
  literal in any scripts/, scenes/, data/, addons/, tests/, tools/, project.godot or export
  preset. The remaining mentions were descriptions of the broken file: owner review
  M28-C002-C002 S4 ("icon_pause.png is a broken PNG", pause glyph drawn natively),
  `VISUAL_ASSET_INDEX.md` "LEGACY / EXTRA", the M47 R02 audit trail, and the iOS workflow that
  skipped it in its sparse checkout and exclude_filter.
- **Runtime**: `tests/tools/m22_026_texture_measure.gd` (real main.tscn, throw-away saves,
  52 scenarios at 1080x2400 and 1536x2048: Home, Gameplay 5/6-slot, Results, Shop, Collection,
  Robots, ceremonies, packs, popups, coachmarks) before and after: no "Failed loading resource",
  "Cannot open file", "Resource file not found" or "Error loading" line in either log; merged
  per-texture sizes (168 textures) and per-scenario loaded MiB identical.

Doc/CI follow-ups in the same commit: the iOS workflow no longer special-cases the file
(sparse-checkout line, absence guard, exclude_filter entry, pack grep), `docs/IOS_TOOLCHAIN.md`
and `VISUAL_ASSET_INDEX.md` no longer list it.

## After

| class | images | bytes |
|---|---:|---:|
| ACTIVE_RUNTIME | 426 | 399217989 |
| DYNAMIC_REF | 74 | 61507569 |
| PROVENANCE_MASTER | 1573 | 1942805818 |
| FUTURE_NEEDED | 145 | 174921839 |
| TEST_ONLY | 0 | 0 |
| UNKNOWN | 0 | 0 |
| CONFIRMED_ORPHAN | 0 | 0 |
| **total** | 2218 | 2578453215 |

Before -> after: 2219 -> 2218 tracked images, 1871 -> 1870 distinct SHA256, 7531 bytes freed.
The CSV is the after state.
