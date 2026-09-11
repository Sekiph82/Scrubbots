# M21-C001 Owner Asset Approval V01

Status: **OWNER_APPROVED**

Approved by project owner: Şekip

Approved source artwork for M21 First Real-Art Vertical Slice:
- Repository path: `assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png`
- Git blob SHA: `b565743ba52699899007882b750b7c8e7cdd00f9`
- SHA-256: `ede1e02a9096c4c7ba040b91ed7db2d2c2af3b2e20d5c8774068c8d08ad59899`
- File size: `297` bytes
- Logical dimensions: `20 x 20`
- Candidate production difficulty: `EASY`
- Logical cell count: `400`
- Canonical logical colors used: `C01`, `C03`, `C08`, `C11`, `C16`
- Exact pixel counts: `C01=30`, `C03=5`, `C08=298`, `C11=11`, `C16=56`
- Distinct logical color count: `5` (valid for EASY 3-5)
- All production logical cells: alpha 255
- Off-palette logical pixels: 0
- Semi-transparent logical pixels: 0
- Transparent source background cells were deliberately replaced with canonical `C08` before owner approval so the production source begins fully ACTIVE/opaque.
- No interpolation or antialiasing was introduced during this conversion.

Owner decision:
This exact 20x20 source is approved as the canonical M21 real-art input. Claude must not regenerate, resize, recolor, smooth, reinterpret, or replace it. Any derived Level Data / preview must be reproducibly generated from this source through the audited importer/content-validation pipeline and must preserve exact logical-cell identity.

The earlier transparent sprite is historical input only. It is not the M21 production source.
