# M21-C001 Owner Asset Approval V01

Status: **OWNER_APPROVED**

Approved by project owner: Şekip

Approved source artwork for M21 First Real-Art Vertical Slice:
- Repository target path: `assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png`
- Logical dimensions: `20 x 20`
- Candidate production difficulty: `EASY`
- Logical cell count: `400`
- Canonical logical colors used: `C01`, `C03`, `C08`, `C11`, `C16`
- Distinct logical color count: `5` (valid for EASY 3-5)
- All production logical cells: alpha 255
- Off-palette logical pixels: 0
- Semi-transparent logical pixels: 0
- Transparent source background cells were deliberately replaced with canonical `C08` before owner approval so the production source begins fully ACTIVE/opaque.
- No interpolation or antialiasing was introduced during this conversion.

Owner decision:
This exact 20x20 source is approved as the canonical M21 real-art input. Claude must not regenerate, resize, recolor, smooth, reinterpret, or replace it. Any derived Level Data / preview must be reproducibly generated from this source through the audited importer pipeline and must preserve exact logical-cell identity.

The earlier transparent sprite is historical input only. It is not the M21 production source.
