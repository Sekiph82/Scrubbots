# SCRUBBOTS Global Pixel-Art Palette V1

Status: **OWNER-LOCKED — 2026-09-06**

Machine-readable source of truth:
`data/palettes/scrubbots_palette_v1.json`

No production SCRUBBOTS logical pixel may use a color outside this table
unless the owner explicitly changes the rule and versions the palette.

| ID | Name | HEX | RGB |
| --- | --- | --- | --- |
| C01 | Coral Red | `#E94B4B` | 233, 75, 75 |
| C02 | Tangerine Orange | `#F28C3C` | 242, 140, 60 |
| C03 | Sunny Yellow | `#F2C94C` | 242, 201, 76 |
| C04 | Leaf Green | `#55B85A` | 85, 184, 90 |
| C05 | Mint Green | `#63D6A3` | 99, 214, 163 |
| C06 | Cyan | `#42C7D9` | 66, 199, 217 |
| C07 | Ocean Blue | `#3E7EDB` | 62, 126, 219 |
| C08 | Deep Blue | `#3451A3` | 52, 81, 163 |
| C09 | Purple | `#845EC2` | 132, 94, 194 |
| C10 | Candy Pink | `#E66FA5` | 230, 111, 165 |
| C11 | Earth Brown | `#956447` | 149, 100, 71 |
| C12 | Sand / Cream | `#E8CFA0` | 232, 207, 160 |
| C13 | Light Gray | `#B8C2CC` | 184, 194, 204 |
| C14 | Charcoal | `#3D4652` | 61, 70, 82 |
| C15 | Pure White | `#FFFFFF` | 255, 255, 255 |

## Production distinct-color bands

Count the number of **distinct canonical logical cell colors actually used by
the artwork**.

| Difficulty | Required distinct used colors |
| --- | ---: |
| EASY | **3–5** |
| MEDIUM | **6–7** |
| HARD | **8–9** |
| VERY_HARD | **10–12** |

These are hard production-content bands, not approximate guidance.

## Locked semantics

- Every ACTIVE logical cell uses exactly one of C01..C16.
- No sixteenth production logical color may be introduced silently.
- A production level's local LevelData palette is a subset of C01..C16,
  contains only canonical colors actually used by its logical cells, and is
  ordered by ascending global C-ID.
- `#RRGGBBFF` is serialization-equivalent to the corresponding canonical
  opaque `#RRGGBB`. Other artwork alpha values are not production logical
  colors.
- **CLEARED transparency is runtime state, not a palette color.**
  It is alpha 0 and is not a palette color.
- Gameplay background is not a level palette color.
- Visible square-cell boundaries/grid/border presentation may exist, but it is
  presentation-only and does not add logical cell colors or count toward the
  level's color total.
- External/reference artwork may have arbitrary source colors, but any
  production conversion must explicitly map/reject them against C01..C16.
  Never silently expand the SCRUBBOTS palette.
- AI-generated production pixel artwork must use this same palette contract.

## Art conversion / Level Factory format

The canonical data shape remains:

```text
width × height logical grid
+ local palette subset of global C01..C16
+ row-major color-ID array (index = y * width + x)
```

Each source artwork gets its own true logical dimensions. Do not force every
artwork to a single size such as 48×49.

## Existing M09 importer note

The audited M09 importer predates this owner lock and intentionally preserves
source pixels exactly. Its historical round-trip guarantees remain valid, but
an arbitrary raw import is **not automatically production-legal** under this
new palette contract. Production mapping/validation belongs in the open
content-audit / Level Factory / M48 QA gates before shipping.


## Production gameplay background

The gameplay surface behind the logical pixel artwork is owner-locked:

| ID | Name | HEX | RGB | Counts as pixel-art color? |
| --- | --- | --- | --- | --- |
| BG01 | Midnight Slate | `#202533` | 32, 37, 51 | **No** |

Locked behavior:

- BG01 is the production gameplay background exposed through CLEARED alpha-0 cells.
- BG01 is not part of C01..C16 and is not a logical pixel-art palette color.
- BG01 never counts toward a level's distinct-color total.
- ACTIVE logical cells still use only C01..C16.
- Do not substitute BG01 into LevelData cell color IDs.
- Debug backgrounds may use conspicuous colors (for example magenta) solely to prove transparency; those debug colors are not production palette/background colors.
