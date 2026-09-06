# Level Factory Roadmap

- LF00 Bootstrap & isolation
- LF01 Deterministic config/seeds
- LF02 Constraint-based candidate generation — MUST consume the Canonical
  Visual Contract: emit only C01..C16 logical colors on flat solid square
  cells (no gloss/bevel/shadow/3D-bead/interpolation), on BG01 background,
  honoring the difficulty distinct-used-color bands.
- LF03 Simulation/solver/state search
- LF04 Difficulty intelligence
- LF05 Validation/QA — MUST enforce the Canonical Visual Contract as hard
  legality: reject off-palette/C17+ colors, reject BG01 used as a logical
  color, reject grid/border colors counted toward difficulty, and enforce the
  EASY/MEDIUM/HARD/VERY_HARD distinct-used-color bands before accept/export.
- LF06 Human-in-loop Godot editor
- LF07 Mutation/automatic difficulty targeting (V2)
- LF08 Batch weekly production
- LF09 Advanced/evolutionary research (V3)
- LF10 Campaign/sequencing adapter (design-gated)

Canonical task detail lives only in repository-root \`tasks.md\`.


## Owner-locked visual contract gate — 2026-09-06 (META-C005)

Before Factory candidates can be accepted as production content, validation
(LF05) and export must enforce the full Canonical Visual Contract, not just the
palette:

- C01..C16 logical colors only (root `data/palettes/scrubbots_palette_v1.json`;
  Factory descriptor `level_factory/data/canonical_visual_contract_v1.json`).
- Distinct-used-color bands: Easy 3–5, Medium 6–7, Hard 8–9, Very Hard 10–12.
- BG01 `#202533` is the fixed background — outside C01..C16, not a logical color, never
  counted toward difficulty.
- ACTIVE opaque / CLEARED alpha-0 (BG01 through).
- Flat solid square cells with visible separation; no gloss/highlight/bevel/
  drop-shadow/3D-bead/interpolation; grid/border is presentation-only.

This is production legality, not a heuristic score. The root palette JSON is
the single palette authority.
