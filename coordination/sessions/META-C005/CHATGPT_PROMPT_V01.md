# META-C005 — Propagate Canonical Visual Contract to Level Factory / Pixel-Art Generation Rules (V01)

Status: **ISSUED**

Purpose: persist the already owner-locked SCRUBBOTS visual contract everywhere future pixel-art generation/Level Factory work must read it, without starting the Level Factory implementation itself.

## First action

Work in `C:\Users\sekip\Desktop\ScrubBots`.

Safely sync local `main` with `origin/main` while preserving all owner changes. Never use `reset --hard`, `clean -fd`, destructive restore, or force push.

Then read:
- https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md
- https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
- https://github.com/Sekiph82/Scrubbots/blob/main/docs/08_PIXEL_ART_PALETTE_RULES.md
- https://github.com/Sekiph82/Scrubbots/blob/main/data/palettes/scrubbots_palette_v1.json
- https://github.com/Sekiph82/Scrubbots/blob/main/level_factory/CLAUDE.md
- https://github.com/Sekiph82/Scrubbots/blob/main/level_factory/README.md
- https://github.com/Sekiph82/Scrubbots/blob/main/level_factory/docs/00_VISION_AND_SCOPE.md
- https://github.com/Sekiph82/Scrubbots/blob/main/level_factory/docs/01_ARCHITECTURE.md
- https://github.com/Sekiph82/Scrubbots/blob/main/level_factory/docs/02_ROADMAP.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

## What is already canonical

Do not change these values. Propagate them exactly.

### Global logical palette
Exactly C01..C15 from:
`data/palettes/scrubbots_palette_v1.json`

No C16. No off-palette logical artwork RGB values.

### Difficulty distinct-used-color bands
- EASY: 3–5
- MEDIUM: 6–7
- HARD: 8–9
- VERY_HARD: 10–12

Count only distinct canonical logical cell colors actually used by artwork cells.

Exclude:
- CLEARED transparency
- gameplay background
- presentation-only grid/cell borders

### Gameplay background
`BG01 Midnight Slate = #202533 = RGB(32,37,51)`

Rules:
- BG01 is the production gameplay surface behind the artwork.
- BG01 is visible through CLEARED alpha-0 cells.
- BG01 is NOT C16.
- BG01 is NOT a logical artwork palette color.
- BG01 never appears as a LevelData cell color.
- BG01 never counts toward distinct-used-color totals.

### Cell rendering / pixel-art generation contract
Every generated logical artwork square is a real gameplay cell.

Production/candidate visual intent:
- keep the square-cell structure readable;
- cell interiors are one flat solid canonical palette color;
- no plastic-bead look;
- no gloss/highlight;
- no bevel;
- no drop shadow;
- no 3D bulge/embossing;
- no interpolation;
- visible cell boundaries/grid separation are presentation-only and do not create logical colors.

Runtime:
- ACTIVE = original canonical source color, opaque;
- CLEARED = fully transparent alpha 0;
- BG01 shows through CLEARED cells.

## Required work

This is a rules/governance propagation task, not Level Factory implementation.

1. Update `level_factory/CLAUDE.md` so every future Level Factory/Pixel-Art generation session is explicitly required to read and obey the root canonical visual contract before generating, mutating, validating, previewing, or exporting artwork.

2. Update `level_factory/README.md` so the Factory mission and both ART_FIRST / PUZZLE_FIRST modes explicitly state:
   - logical artwork colors must come only from C01..C15;
   - difficulty color-count bands are hard legality;
   - BG01 is the fixed production background and is not a logical color;
   - generated/puzzle-first art uses flat square cells, not glossy/beveled/3D bead styling.

3. Update `level_factory/docs/00_VISION_AND_SCOPE.md` and `01_ARCHITECTURE.md` with one authoritative section named something like **Canonical Visual Contract** or equivalent that records:
   - C01..C15 source of truth;
   - difficulty color-count bands;
   - BG01 exact ID/name/HEX/RGB and semantics;
   - ACTIVE/CLEARED semantics;
   - square-cell/flat-fill/no-bead/no-interpolation generation rules;
   - presentation grid/border does not count as logical color.

4. Update `level_factory/docs/02_ROADMAP.md` so LF02 candidate generation and LF05 validation explicitly consume/enforce this contract when those phases are implemented.

5. Add a small machine-readable Level Factory visual-contract descriptor under `level_factory/data/`, for example:
   `level_factory/data/canonical_visual_contract_v1.json`

   IMPORTANT: do not create a second independent palette table that can drift. The descriptor should reference the root canonical source:
   `../data/palettes/scrubbots_palette_v1.json`
   (or an equivalent repository-relative reference appropriate to the chosen schema)
   and may redundantly store only locked non-palette metadata needed by Factory governance, such as BG01 ID/HEX/RGB, difficulty bands, ACTIVE/CLEARED semantics, and flat-cell render flags.

   Make it explicit that the root palette JSON remains authoritative if any duplication ever conflicts.

6. Add validation/documentation guards as practical so future Factory generator code cannot silently use an off-palette color, treat BG01 as C16, or count BG01/grid borders toward difficulty colors.

7. Do NOT implement LF00/LF01/LF02 generator code in this task. The Level Factory `scripts/` directory is currently only scaffolded. Preserve that state unless a tiny non-runtime schema validation helper is strictly necessary, and prefer no implementation code.

8. Do NOT change the locked palette values, BG01, difficulty bands, ACTIVE/CLEARED semantics, board-size bands, or production gameplay rules.

9. Do NOT change task completion counts merely for documenting these already-locked rules unless an existing task explicitly becomes genuinely validated by this work. Do not invent new SB task IDs.

## Verification

Before commit:
- verify all 15 C-IDs and HEX values in root palette remain byte-for-byte unchanged;
- verify BG01 remains exactly `#202533` / RGB(32,37,51);
- verify Level Factory docs no longer omit the exact BG01 contract;
- verify Level Factory docs explicitly contain the flat square-cell/no-bead/no-interpolation generation rule;
- verify the new machine-readable descriptor points back to the root palette source rather than becoming an independent palette authority;
- search for contradictory Level Factory language such as arbitrary/off-palette production colors or a background treated as a palette color;
- inspect `git diff`.

Run the normal repository checks appropriate for docs/data-only changes. Do not claim generator runtime tests because the generator is not implemented yet.

## Coordination

Use:
`coordination/sessions/META-C005/CLAUDE_LOG_V01.md`

Before ending:
- update `coordination/SESSION_INDEX.md`;
- update required H!veAI tracking files/dashboard;
- push safely;
- set state to `AWAITING_AUDIT`;
- stop;
- do not self-audit.

## Success condition

After this task, any future Claude/agent working on the SCRUBBOTS Level Factory or pixel-art generation engine encounters the same owner-locked contract before writing generator code:

`C01..C15 only + exact difficulty color-count bands + BG01 #202533 + ACTIVE opaque / CLEARED alpha-0 + flat square gameplay cells with visible separation and no plastic/gloss/bevel/shadow/3D styling.`

The root palette JSON remains the single palette authority.
