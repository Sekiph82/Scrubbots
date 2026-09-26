# OWNER M52-C001 FIRST 10 LEVEL PACK DECISION

Date: 2026-09-26
Authority: OWNER
Repository: Sekiph82/Scrubbots

## Goal

Make the first 10 campaign levels playable in Godot.

Level 1 remains the existing production Hazard Bot exactly as-is.

Levels 2-10 use the owner-selected/canonicalized source PNGs already committed under `assets/art/levels/source/`.

## Locked campaign mapping

| Campaign Level | Difficulty | Source |
|---:|---|---|
| 1 | EASY | existing `m21_level_001_hazard_bot` |
| 2 | EASY | `assets/art/levels/source/easy/level_002_apple_32x32.png` |
| 3 | MEDIUM | `assets/art/levels/source/medium/level_003_palm_tree_38x38.png` |
| 4 | EASY | `assets/art/levels/source/easy/level_004_orange_cat_32x32.png` |
| 5 | HARD | `assets/art/levels/source/hard/level_005_party_toucan_33x33.png` |
| 6 | EASY | `assets/art/levels/source/easy/level_006_chicken_32x32.png` |
| 7 | EASY | `assets/art/levels/source/easy/level_007_pigeon_32x32.png` |
| 8 | MEDIUM | `assets/art/levels/source/medium/level_008_butterfly_32x32.png` |
| 9 | EASY | `assets/art/levels/source/easy/level_009_frog_32x32.png` |
| 10 | VERY_HARD | `assets/art/levels/source/very_hard/level_010_ice_cube_32x32.png` |

This matches the owner-locked ten-slot cadence:
`EASY, EASY, MEDIUM, EASY, HARD, EASY, EASY, MEDIUM, EASY, VERY_HARD`.

## Source rules

The nine new PNGs are immutable content sources for this task.

For each source:
- one source pixel = one logical cell;
- no resize;
- no interpolation;
- no crop/pad;
- no recolor;
- no nearest-color approximation;
- alpha must be 255 for every logical cell;
- every color must be an exact canonical C01..C16 RGB value;
- used-color count must remain inside the current production 3..12 envelope.

The production LevelData/preview must reconstruct the source exactly.

## Production IDs

Use stable IDs:

- `level_002_apple`
- `level_003_palm_tree`
- `level_004_orange_cat`
- `level_005_party_toucan`
- `level_006_chicken`
- `level_007_pigeon`
- `level_008_butterfly`
- `level_009_frog`
- `level_010_ice_cube`

## Difficulty truth

The class token for each campaign slot is owner-locked above.

Do not revive the obsolete class=dimension or class=color-count rules.

Do not fabricate Challenge Score / Session Load / Frustration metrics if the repository does not yet contain a canonical real-level analyzer for those values. M53 owns full per-level Difficulty/QA evidence. M52-C001 must still enforce all currently implemented production legality, palette, source-reconstruction, catalog and authoritative-solvability gates.

## Supply columns / visible rows / hidden depth

For this first-10 production pack, use **3 independent FIFO supply columns**.

The player-facing supply panel shows exactly **3 visible rows per column**:
- Row 1 = front/selectable batch;
- Row 2 = preview only;
- Row 3 = preview only.

**This is NOT a total queue-depth limit.** Each column may contain any deeper number of hidden batches required by the generated candidate. A column may therefore be 4, 8, 20 or more batches deep; only the first 3 rows are visible to the player. Hidden rows remain real FIFO gameplay state and become visible only as earlier rows are consumed.

In the current engine/API, `preview_depth = 3` means **visible preview depth only**. It must never be interpreted as "three batches total per column".

The authoritative solver must receive and reason over the **entire per-column FIFO queue, including all hidden depth**, exactly as `ProofState.from_level_and_supply()` does from the non-player-facing supply snapshot.

Normal slot capacity remains **5**. The player chooses a front batch from one of the 3 supply columns; a successful selection goes automatically to the rightmost empty slot. Supply column depth and five-slot capacity are separate concepts.

## Solver rule

Each admitted level must be proven solvable under the current canonical gameplay/supply/routing semantics using the existing authoritative solver/generation gate.

Do not:
- weaken the solver;
- change gameplay semantics to make a candidate pass;
- relabel a solver failure as pass;
- treat UNKNOWN_BOUND as solved.

If a source cannot be admitted under the existing rules, stop and report the exact blocking evidence rather than silently mutating the owner source.

## Catalog / progression

On success, production catalog orders 1..10 must resolve uniquely to the ten real levels.

Level 11 remains CONTENT_MISSING until later content is authored.

Home/Play must therefore launch Levels 1..10 through the real catalog frontier without level-number spoofing or fallback-to-Level-1 behavior.
