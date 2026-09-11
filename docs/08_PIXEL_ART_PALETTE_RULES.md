# SCRUBBOTS Global Pixel-Art Palette V2

Status: **OWNER-LOCKED — palette 2026-09-06; difficulty semantics updated 2026-09-12**

Machine-readable palette source of truth:
`data/palettes/scrubbots_palette_v2.json`

Difficulty/progression owner decision:
`coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`

No production SCRUBBOTS logical pixel may use a color outside this table unless the owner explicitly changes the rule and versions the palette.

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
| C16 | Pure Black | `#000000` | 0, 0, 0 |

## Production used-color rule

Under Difficulty / Progression V1, production artwork normally uses **3..12 distinct canonical logical colors actually referenced by cells**.

The historical mapping:

```text
EASY 3-5
MEDIUM 6-7
HARD 8-9
VERY_HARD 10-12
```

is **superseded as a difficulty-class legality rule**.

Distinct color count and color-distribution entropy now contribute to mathematical Color Complexity `C`, which is one component of Challenge Score. They do not determine the player-facing class on their own.

This permits, for example:

- a compact/high-unlock-depth VERY_HARD level with relatively few colors;
- a visually rich EASY level with more colors when accessibility, bottleneck, route, slot and workload metrics keep total challenge in the EASY target envelope.

Production content still must stay within the global 3..12 used-color envelope unless a later versioned owner decision changes that limit.

## Locked semantics

- Every ACTIVE logical cell uses exactly one of C01..C16.
- No seventeenth production logical color may be introduced silently.
- A production level's local LevelData palette is a subset of C01..C16.
- The local palette contains only canonical colors actually used by logical cells.
- Local palette order is ascending global C-ID.
- `#RRGGBBFF` is serialization-equivalent to canonical opaque `#RRGGBB`; other ACTIVE artwork alpha values are illegal.
- CLEARED transparency is runtime state, not a palette color.
- Gameplay background is not a level palette color.
- Presentation grid/border overlays do not count as logical colors.
- External/reference artwork may contain arbitrary source colors only before explicit production mapping/rejection. Never silently expand the SCRUBBOTS palette.
- AI-generated production pixel artwork follows the same contract.

## Difficulty-analysis relationship

Color Complexity is measured from both count and distribution.

V1 concept:

```text
count_norm = clamp((distinct_used - 3) / 9, 0, 1)
H = normalized Shannon entropy of used-color frequencies
C = 0.50 * count_norm + 0.50 * H
```

See `docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md` and `data/config/difficulty_score_model_v1.json`.

Changing palette membership and changing difficulty coefficients are separate versioned decisions.

## Art conversion / Level Factory format

Canonical data shape:

```text
width × height logical grid
+ local palette subset of global C01..C16
+ row-major color-ID array (index = y * width + x)
```

Each source artwork keeps its own true logical dimensions. Do not resize artwork merely to manufacture a difficulty class.

The Level Factory may request approximate color complexity as a generation constraint, but the final difficulty class is decided by campaign target fit across the full Challenge vector, Session Load and Frustration gates.

Owner-original source artwork may not be recolored silently to force a target score.

## Existing M09 importer note

The audited M09 importer predates the palette lock and Difficulty V1. It intentionally preserves source pixels exactly and historically orders imported palette entries by first-seen source order.

An arbitrary raw import is therefore **not automatically production-legal** under the newer contract. Production normalization/validation must prove:

- every logical color maps exactly to C01..C16;
- local palette is used-only and ascending C-ID;
- ACTIVE alpha is 255;
- used-color count is within current production envelope;
- exact logical cell identity is preserved while remapping local palette IDs.

M21 may use the audited legacy importer as a compatibility stage for the approved 20x20 Hazard Bot, but its production artifact must obey the canonical palette contract.

## Production gameplay background

| ID | Name | HEX | RGB | Counts as pixel-art color? |
| --- | --- | --- | --- | --- |
| BG01 | Midnight Slate | `#202533` | 32, 37, 51 | **No** |

Locked behavior:

- BG01 is visible through CLEARED alpha-0 cells.
- BG01 is not C01..C16.
- BG01 never counts toward color complexity or used-color total.
- ACTIVE logical cells still use only C01..C16.
- Never substitute BG01 into LevelData cell IDs.
- Debug backgrounds may differ solely to prove transparency; those debug colors are not production palette/background colors.
