# OWNER M52-C001 — FIRST 10 LEVEL PACK V01

Date: 2026-09-26
Authority: OWNER
Repositories:
- Main game: `Sekiph82/Scrubbots`
- Analysis/mutation support: `Sekiph82/ScrubBots-Level-Factory`

## Goal

Build the first playable 10-level production pack.

Level 1 remains the existing production Hazard Bot already in the main game.
Levels 2–10 use the owner-selected canonical pixel-art sources below.

The campaign cadence is owner-locked and must remain:

`EASY, EASY, MEDIUM, EASY, HARD, EASY, EASY, MEDIUM, EASY, VERY_HARD`

Therefore the new slots are:

| Level | Visual | Required class | First-cycle target Challenge | Canonical source | SHA-256 |
|---:|---|---|---:|---|---|
| 2 | Apple | EASY | 22.0 | `assets/art/levels/source/easy/level_002_apple_32x32.png` | `b1dd3b414738cf0557cf9baabb5d3a12208df3c3a57d3ab3184e990df1dcf580` |
| 3 | Palm Tree | MEDIUM | 40.0 | `assets/art/levels/source/medium/level_003_palm_tree_38x38.png` | `84960199759b1c3a1e130a24149c14fff9a5ee6ffb53db4ec6f138e34c6116cc` |
| 4 | Orange Cat | EASY | 19.0 | `assets/art/levels/source/easy/level_004_orange_cat_32x32.png` | `0b8cbc068d1d070cc5c68ee439ccb908a09cc99180f6a068ba4475339f41c926` |
| 5 | Party Toucan | HARD | 58.0 | `assets/art/levels/source/hard/level_005_party_toucan_33x33.png` | `c95c0fd4021bb90eacd78dbc2279809f26fe0ed435cca260881ee6961eb9874f` |
| 6 | Chicken | EASY | 18.0 | `assets/art/levels/source/easy/level_006_chicken_32x32.png` | `9e15e570a7b8d5a31f4cd0eb37e4f6e48e18e71f66b7c56e08510738412ff790` |
| 7 | Pigeon | EASY | 21.0 | `assets/art/levels/source/easy/level_007_pigeon_32x32.png` | `ca6004936d2ab9f4a8faef3215f9887157a407a7b63743ec07cc0a922530158a` |
| 8 | Butterfly | MEDIUM | 42.0 | `assets/art/levels/source/medium/level_008_butterfly_32x32.png` | `9a623fece67690862ba73b737e5e52d9acfbe1e46b160c411eee5714ea01b2fc` |
| 9 | Frog | EASY | 19.0 | `assets/art/levels/source/easy/level_009_frog_32x32.png` | `b0bd1638961cd69e64f2bd174df117d3c75520be0804a114362efc96663d036f` |
| 10 | Ice Cube | VERY_HARD | 76.0 | `assets/art/levels/source/very_hard/level_010_ice_cube_32x32.png` | `a39b54c0adc05ca4778536cd9f0b5bccaa7cfde786fb8c72efa4be91029d3d61` |

Source-art commit:
`1ec599bfef82568f92413ac7dd24f558aa7bf53f`

## Source-art rules

The nine source PNGs above are immutable provenance anchors.

- Never overwrite or repaint those exact source paths.
- Never resize/resample/interpolate/crop/pad those sources.
- Every source is already intended to use the canonical Alpix-aligned C01..C16 palette and full opacity.
- Verify this from bytes; do not trust the description.

If a source does not fit its required campaign slot, a derivative candidate may be created in a separate generated/candidate path only. The source remains untouched.

Derivative work is allowed because these nine are generated level-art candidates rather than irreplaceable owner-original artwork. However every derivative must:
- preserve the recognizable subject/silhouette;
- keep the same logical dimensions unless there is an explicit, evidence-backed reason to change them;
- use only C01..C16;
- stay fully opaque;
- remain within 3..12 used canonical colors;
- record parent/source hash + mutation lineage;
- be re-imported, re-solved and re-analyzed from scratch.

No manual editing of a difficulty score or label is allowed.

## Difficulty truth

The campaign class is a target slot, not permission to mislabel art.

Use `data/config/level_progression_v1.json` and Difficulty V1.

For levels 2–10 first-cycle targets are exactly:

- L2 22
- L3 40
- L4 19
- L5 58
- L6 18
- L7 21
- L8 42
- L9 19
- L10 76

Default fit tolerance: ±3.5.
Preferred fit when feasible: ±2.0.
Never force a class/slot when Challenge error exceeds ±5.0.

Actual measured recovery must also satisfy:
- L3 -> L4: at least 15 Challenge drop
- L5 -> L6: at least 20 Challenge drop
- L8 -> L9: at least 15 Challenge drop

If canonical analysis is unavailable or inconclusive, do not invent a Challenge Score and do not claim the affected level is production-admitted.

## Main-game admission

A level enters `data/levels/catalog/production_catalog_v1.json` only after:

1. exact source/candidate provenance verified;
2. exact-pixel import + canonical palette normalization;
3. structural LevelData validation;
4. production 20..59 envelope validation;
5. exact source reconstruction equality;
6. authoritative solver returns SOLVED, never UNKNOWN_BOUND/INCONCLUSIVE;
7. Difficulty V1 Challenge evidence satisfies its slot target/tolerance;
8. recovery guard relationships pass;
9. generated preview corresponds exactly to final LevelData;
10. metadata binds source/candidate hash, LevelData hash, solver evidence and analysis provenance;
11. catalog revalidates all entries;
12. gameplay launch resolver resolves orders 1..10 with no fallback.

Level 1 remains unchanged.

## Cross-repository rule

The Level Factory may be used for canonical analysis/mutation assistance, but its current cross-repo handoff must not be blindly trusted.

Final admission authority remains the current main-game repository and its validators/solver/catalog.

Do not directly overwrite the main-game catalog from an unverified Factory handoff.

## Completion truth

Success means:
- exactly 10 production catalog entries in orders 1..10;
- Level 1 unchanged;
- Levels 2..10 use the owner-selected visual concepts;
- all nine new entries pass main-game import/validation/solver/difficulty/recovery/catalog gates;
- progression can launch Level 2 after Level 1, through Level 10 in order.

If any slot cannot honestly pass, stop that slot as BLOCKED/NOT_ADMITTED with exact evidence instead of fabricating completion.
