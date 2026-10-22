# Level Art Technical Audit (M08)

As of 2026-10-22 (factory 030). Scope: SB-M08-001..010, 013, 014. Read-only: no source art was
modified, resized or moved (standing rules SB-M08-011..012).

Images: every owner level source in `assets/art/levels/source/**` (M21 hazard bot + levels 002..010,
see `docs/LEVEL_ART_INVENTORY.md`). Folder names are legacy bands, not difficulty truth.

Regenerate (deterministic, stdlib Python, exit 1 on any FAIL):

    python tools/audit_level_art.py              # audit table + mapping below
    python tools/audit_level_art.py --self-test  # decoder/grid/AA/D2 checks

## Method

- **Alpha/VOID**: alpha 0 = VOID pixel, alpha 255 = artwork, anything else = semi-transparent (fail).
- **Colours**: distinct opaque RGB values; must be 3..12 (palette V3 `usedColorEnvelopeV1`).
- **Anti-aliasing**: semi-transparent pixels, or off-palette colours touching a different colour (blend at an edge).
- **Interpolation / logical grid**: block size = GCD of all same-colour run lengths per axis; a block above 1
  means an integer upscale, logical grid = size / block. Off-palette or semi-transparent pixels mark
  interpolation (smooth resampling). Ceiling: an exact nearest-neighbour *fractional* upscale that keeps
  palette colours would read as block 1.
- **Envelope**: logical width and height 20..59 (CLAUDE.md §6); with any VOID, D2 needs >= 200 non-VOID
  cells and >= 25% of W*H (ADR-030).
- **Palette mapping**: each source colour maps to C01..C16 of `data/palettes/scrubbots_palette_v3.json` by
  exact RGB match, else REJECTED (the nearest C-ID is printed for information only). Never C17+.

## Results

| File | Size | VOID px | Semi-alpha px | Colours | Anti-aliasing | Block | Interpolation | Logical grid | Non-VOID cells | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| assets/art/levels/source/easy/level_002_apple_32x32.png | 32x32 | 0 | 0 | 5 | none | 1x1 | none | 32x32 | 1024 | PASS |
| assets/art/levels/source/easy/level_004_orange_cat_32x32.png | 32x32 | 0 | 0 | 7 | none | 1x1 | none | 32x32 | 1024 | PASS |
| assets/art/levels/source/easy/level_006_chicken_32x32.png | 32x32 | 0 | 0 | 8 | none | 1x1 | none | 32x32 | 1024 | PASS |
| assets/art/levels/source/easy/level_007_pigeon_32x32.png | 32x32 | 0 | 0 | 8 | none | 1x1 | none | 32x32 | 1024 | PASS |
| assets/art/levels/source/easy/level_009_frog_32x32.png | 32x32 | 0 | 0 | 7 | none | 1x1 | none | 32x32 | 1024 | PASS |
| assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png | 20x20 | 0 | 0 | 5 | none | 1x1 | none | 20x20 | 400 | PASS |
| assets/art/levels/source/hard/level_005_party_toucan_33x33.png | 33x33 | 0 | 0 | 10 | none | 1x1 | none | 33x33 | 1089 | PASS |
| assets/art/levels/source/medium/level_003_palm_tree_38x38.png | 38x38 | 0 | 0 | 6 | none | 1x1 | none | 38x38 | 1444 | PASS |
| assets/art/levels/source/medium/level_008_butterfly_32x32.png | 32x32 | 0 | 0 | 8 | none | 1x1 | none | 32x32 | 1024 | PASS |
| assets/art/levels/source/very_hard/level_010_ice_cube_32x32.png | 32x32 | 0 | 0 | 10 | none | 1x1 | none | 32x32 | 1024 | PASS |

**assets/art/levels/source/easy/level_002_apple_32x32.png**: #FF4500 x296 -> C01, #00CC78 x23 -> C04, #2450A4 x639 -> C08, #9C6926 x56 -> C11, #FFF8B8 x10 -> C12

**assets/art/levels/source/easy/level_004_orange_cat_32x32.png**: #FFA800 x167 -> C02, #00CC78 x2 -> C04, #2450A4 x639 -> C08, #9C6926 x13 -> C11, #FFF8B8 x68 -> C12, #D4D7D9 x5 -> C13, #000000 x130 -> C16

**assets/art/levels/source/easy/level_006_chicken_32x32.png**: #FF4500 x12 -> C01, #FFA800 x5 -> C02, #FFD635 x41 -> C03, #2450A4 x702 -> C08, #9C6926 x58 -> C11, #FFF8B8 x133 -> C12, #515252 x71 -> C14, #000000 x2 -> C16

**assets/art/levels/source/easy/level_007_pigeon_32x32.png**: #FF4500 x9 -> C01, #2450A4 x666 -> C08, #FF3881 x2 -> C10, #9C6926 x9 -> C11, #D4D7D9 x43 -> C13, #515252 x126 -> C14, #FFFFFF x58 -> C15, #000000 x111 -> C16

**assets/art/levels/source/easy/level_009_frog_32x32.png**: #51E9F4 x15 -> C06, #3690EA x318 -> C07, #2450A4 x497 -> C08, #FFF8B8 x40 -> C12, #D4D7D9 x12 -> C13, #FFFFFF x2 -> C15, #000000 x140 -> C16

**assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png**: #FF4500 x30 -> C01, #FFD635 x5 -> C03, #2450A4 x298 -> C08, #9C6926 x11 -> C11, #000000 x56 -> C16

**assets/art/levels/source/hard/level_005_party_toucan_33x33.png**: #FF4500 x7 -> C01, #FFA800 x26 -> C02, #FFD635 x106 -> C03, #51E9F4 x9 -> C06, #3690EA x8 -> C07, #2450A4 x611 -> C08, #FF3881 x15 -> C10, #9C6926 x52 -> C11, #515252 x78 -> C14, #000000 x177 -> C16

**assets/art/levels/source/medium/level_003_palm_tree_38x38.png**: #FFA800 x28 -> C02, #00CC78 x452 -> C04, #00CCC0 x88 -> C05, #2450A4 x601 -> C08, #9C6926 x72 -> C11, #000000 x203 -> C16

**assets/art/levels/source/medium/level_008_butterfly_32x32.png**: #FF4500 x55 -> C01, #FFA800 x150 -> C02, #FFD635 x47 -> C03, #2450A4 x482 -> C08, #9C6926 x7 -> C11, #515252 x15 -> C14, #FFFFFF x28 -> C15, #000000 x240 -> C16

**assets/art/levels/source/very_hard/level_010_ice_cube_32x32.png**: #FFA800 x6 -> C02, #FFD635 x14 -> C03, #00CCC0 x93 -> C05, #51E9F4 x16 -> C06, #3690EA x2 -> C07, #2450A4 x259 -> C08, #D4D7D9 x270 -> C13, #515252 x78 -> C14, #FFFFFF x70 -> C15, #000000 x216 -> C16

SUMMARY: 10 images, 10 PASS, 0 FAIL

## Verdict

All 10 images PASS. Every image is native 1:1 pixel art (block 1x1, logical grid = file size), fully opaque
(no VOID, no semi-transparent pixels), with no anti-aliasing or interpolation, a grid of 20..38 per
dimension (inside 20..59), 5..10 colours (inside 3..12), and every source colour an exact palette V3
match. No colour was rejected. The dark blue background (C08 `#2450A4`) is opaque artwork in every
image, so it counts as an ACTIVE colour; none of the sources uses VOID cells.

New level art: run the script on it before import and add its row here.
