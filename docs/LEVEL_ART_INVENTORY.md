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
`assets/art/references/_owner_inbox/Collection Cards/underwater heroes.jpeg`, a UI reference, not level art.

## Other original theme artwork

Owner-supplied theme references (collection cards, level sheets, level designs 001..016, game screens, icons, logo)
live under `assets/art/references/_owner_inbox/` and are catalogued per file (SHA-256, dimensions, category,
provenance) in `assets/art/references/inventory.json`. No further level or theme art exists in the repo.

Future supplies: add a row here when new level art is approved (standing rule).
