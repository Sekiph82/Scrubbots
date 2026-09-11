# M21-C001 — Owner-Approved Source Audit (M08-style)

Cycle: `M21-C001` V01. Author: Claude (implementer). This audit uses
repository/owner evidence only; it infers no provenance beyond the
owner-approved artifacts.

## 1. Identity

| Field | Value |
| --- | --- |
| Filename | `scrubbots_m21_level_001_hazard_bot_20x20.png` |
| Repository path | `assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png` |
| Git blob SHA | `b565743ba52699899007882b750b7c8e7cdd00f9` |
| SHA-256 | `ede1e02a9096c4c7ba040b91ed7db2d2c2af3b2e20d5c8774068c8d08ad59899` |
| File size | `297` bytes |

Both hashes and the size were recomputed from the committed bytes and match
`OWNER_ASSET_APPROVAL_V01.md` / `OWNER_ASSET_VALIDATION_V01.json` exactly.
The git blob SHA is also recomputed inside the headless suite via
`ProductionArtLevelBuilder._git_blob_sha1_file` and asserted equal.

## 2. Dimensions & grid

| Field | Value |
| --- | --- |
| Width × Height | `20 × 20` |
| Logical pixels / cells | `400` |
| Grid rule | one logical source pixel = one logical cell (`index = y*width + x`) |
| Spatial resize / interpolation | NONE — the importer performs no resize, resample, or antialiasing |

## 3. Alpha / transparency

| Field | Value |
| --- | --- |
| Distinct alpha values observed | `{255}` only |
| Semi-transparent logical pixels | `0` |
| Transparent logical pixels | `0` |

Every logical cell is fully opaque (alpha 255). Per
`OWNER_ASSET_APPROVAL_V01.md`, the owner deliberately replaced the earlier
transparent background cells with canonical `C08` before approval so the
production source begins fully ACTIVE/opaque. CLEARED transparency is a
runtime state, not a source palette color.

## 4. Canonical color set & counts

Mapped against the machine-readable authority
`data/palettes/scrubbots_palette_v2.json` (RGB → C-ID), with no nearest-color
approximation.

| C-ID | Name | HEX | Cell count |
| --- | --- | --- | ---: |
| C01 | Coral Red | `#E94B4B` | 30 |
| C03 | Sunny Yellow | `#F2C94C` | 5 |
| C08 | Deep Blue | `#3451A3` | 298 |
| C11 | Earth Brown | `#956447` | 11 |
| C16 | Pure Black | `#000000` | 56 |
| — | **total** | — | **400** |

- Off-palette logical colors: `0`.
- Distinct used canonical colors: `5`.

## 5. Difficulty legality (legacy compatibility gate + Difficulty V1 note)

| Field | Value |
| --- | --- |
| Dimensions | `20 × 20` (within the legacy EASY dimension band 20..29) |
| Difficulty label used | `EASY` (legacy compatibility, via `ProductionLevelValidator`) |
| Legacy EASY distinct-color compat band | `3–5` |
| Actual distinct used colors | `5` → PASS against the legacy compat band |
| Difficulty V1 used-color envelope | `3–12` → PASS (`data/palettes/scrubbots_palette_v2.json`) |

**Difficulty V1 distinction (per `OWNER_DIFFICULTY_V1_SCOPE_NOTE.md`, 2026-09-12):**
the owner adopted Difficulty/Progression/Retention V1 while M21-C001 V01 was
active. Under V1, color count and dimensions are difficulty **score inputs**, not
class-legality gates; the palette authority replaced the per-difficulty
`difficultyColorCountBands` with a global `usedColorEnvelopeV1` (3–12). This audit
therefore does NOT assert "20×20 ⇒ EASY" or "5 colors ⇒ EASY" as design law. It
asserts only that the approved asset (a) satisfies the currently installed LEGACY
compatibility validator/band, which the scope note explicitly permits as the M21
gate, and (b) sits within the V1 used-color envelope. The approved 20×20 source and
its exact colors remain valid and unchanged.

## 6. Perimeter topology (adversarial AL-028 value)

- Perimeter cell count: `76` (2·20 + 2·20 − 4 corners).
- Every perimeter cell is `C08`.
- Zero `C01/C03/C11/C16` cells on the perimeter.

Consequence: on a fresh board, every non-C08 color is strictly interior and
fully enclosed by C08. Each non-C08 color has raw color candidates but NO
reachable target from the exterior — an exact real-art demonstration of the
AL-028 "raw candidate ≠ reachable target" rule.

## 7. Raw first-seen vs. production-normalized local palette

- Raw M09 importer first-seen row-major order:
  `C08, C16, C01, C03, C11`.
- Production canonical local order (ascending global C-ID):
  `C01, C03, C08, C11, C16`.

The historical generic M09 importer intentionally preserves first-seen order;
the production-art bridge (`scripts/tools/production_art_level_builder.gd`)
normalizes it to ascending C-ID and remaps cell indices deterministically so
the visible pixels are byte-identical.

## 8. Owner approval artifacts referenced

- `coordination/sessions/M21-C001/OWNER_ASSET_APPROVAL_V01.md` (OWNER_APPROVED)
- `coordination/sessions/M21-C001/OWNER_ASSET_VALIDATION_V01.json`

## 9. Immutability

The source PNG is immutable for this milestone: never resized, recolored,
smoothed, regenerated, optimized/re-encoded, or overwritten. The blob SHA and
SHA-256 above are re-verified unchanged at the end of the work (see
`CLAUDE_LOG_V01.md`). The earlier transparent sprite is historical input only
and is NOT the M21 production source.
