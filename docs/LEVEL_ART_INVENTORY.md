# Level Art Inventory (M07)

As of 2026-10-22. Scope: SB-M07-011..013. Read-only inventory; no art moved or modified.
The visual reference library inventory (UI/gameplay/collection references) is separate:
`assets/art/references/inventory.json`.

## Level source images (`assets/art/levels/source/**`)

All are RGBA 8-bit PNGs, owner-original. "Colors" is the LevelData palette size
(`data/levels/<id>.json`). Previews are in `assets/art/levels/previews/`.

| Path | Size | Colors | Theme | Owner-original |
| --- | --- | --- | --- | --- |
| easy/scrubbots_m21_level_001_hazard_bot_20x20.png (M21 source, baseline) | 20x20 | n/a | robot | yes |
| easy/level_002_apple_32x32.png | 32x32 | 5 | fruit | yes |
| medium/level_003_palm_tree_38x38.png | 38x38 | 6 | nature/tropical | yes |
| easy/level_004_orange_cat_32x32.png | 32x32 | 7 | animal | yes |
| hard/level_005_party_toucan_33x33.png | 33x33 | 10 | animal/tropical | yes |
| easy/level_006_chicken_32x32.png | 32x32 | 8 | animal | yes |
| easy/level_007_pigeon_32x32.png | 32x32 | 8 | animal | yes |
| medium/level_008_butterfly_32x32.png | 32x32 | 8 | animal/insect | yes |
| easy/level_009_frog_32x32.png | 32x32 | 7 | animal | yes |
| very_hard/level_010_ice_cube_32x32.png | 32x32 | 10 | object | yes |

Beyond the M21 source: 9 images (levels 002..010). Folder names are legacy bands, not difficulty truth (CLAUDE.md §6).
`data/levels/test_*.json` are TEST fixtures without source art.

## Underwater artwork

None supplied as of 2026-10-22. The only underwater-named item is the collection card
`assets/art/references/_owner_inbox/Collection Cards/underwater heroes.jpeg`, a UI reference, not level art. It was
deleted by SB-M22-030 (owner 2026-11-05, card set finished; git history keeps it).

### World 10 Sunken Harbor production manifest (SB-M07-014)

Planning data only; the art itself is not supplied yet and the game loads nothing from it.
`data/art_manifests/world10_sunken_harbor_v1.json` lists the 150 distinct standalone level PNG slots L1351-1500
(15 batches of 10, `level_<NNNN>_<subject>_<W>x<H>.png`, grid 20..59 per side, palette V3 C01..C16 with 3..12
colours, alpha 255 or VOID 0 only), 8 world UI, 8 decor, 4 FX and 3 marketing PNG slots (size, aspect, alpha,
use) and 3 optional videos (intro 6-8 s, complete 5-7 s, teaser 10-15 s). The support PNG and video sizes are
planning values chosen by the factory builder (`supportPngSizeSource`), not owner-specified; the owner may change
them when the art is commissioned. Every entry starts `PLANNED` with
empty sha256/provenance/license/sign-off; no collages, atlases, sprite sheets, cropping or automatic slicing.
`python tools/validate_world_art_manifest.py` checks the schema, counts, range and batching, and for supplied
files the hash, size/alpha and (levels) the `tools/audit_level_art.py` palette/grid/VOID rules; `--self-test`
runs it against synthetic PNGs in a temp dir. SB-M07-012 stays conditional until approved level PNGs arrive.

## Other original theme artwork

Owner-supplied theme references (collection cards, level sheets, level designs 001..016, game screens, icons, logo)
live under `assets/art/references/_owner_inbox/` and are catalogued per file (SHA-256, dimensions, category,
provenance) in `assets/art/references/inventory.json`. No further level or theme art exists in the repo.

Future supplies: add a row here when new level art is approved (standing rule).
