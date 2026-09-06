# Level Factory Architecture

## Layers

\`\`\`text
Editor / Human Review
        ↓
Batch Orchestrator
        ↓
Generator ── Mutation (V2)
        ↓
Simulation Adapter
        ↓
Solver
        ↓
Difficulty Analyzer
        ↓
Validator / QA
        ↓
Exporter
        ↓
Content Pipeline handoff
\`\`\`

Core generator/solver/analyzer/validator code should be headless-testable.
Editor scenes are presentation only.

## Reproducibility

Every procedural candidate carries at least:

- candidate ID
- generation mode
- generator version
- config version/config
- seed
- source-art provenance when art-first
- mutation lineage when applicable
- solver/analyzer versions and metrics
- acceptance/rejection report

## Data boundary

Factory output must conform to the root game's declared Level Data contract.
M09's audited importer/reconstruction invariants remain authoritative for
pixel-exact art-first conversion.

## Solver boundary

Solver search owns algorithms, not gameplay design. Legal moves come from a
versioned simulation/legal-move adapter whose semantics are tied to canonical
SCRUBBOTS gameplay milestones. Those semantics are now the ACTIVE/CLEARED
model (ADR-019): cells start ACTIVE and block access; a legal move clears one
reachable matching-color ACTIVE cell to CLEARED (open space); a fully enclosed
matching-color ACTIVE cell is not targetable until access is opened (AL-028).
The adapter is the single shared source of these rules — the solver must not
re-invent them.

## Difficulty boundary

Board-size bands remain production legality, not proof of puzzle difficulty.
Difficulty intelligence may add metrics, but metric coefficients stay
versioned/provisional until calibrated and owner-approved.


## Canonical Visual Contract (palette boundary) [OWNER-LOCKED, META-C005]

Authoritative sources: `docs/08_PIXEL_ART_PALETTE_RULES.md` +
`data/palettes/scrubbots_palette_v1.json` (root), with Factory-facing
machine-readable non-palette metadata in
`level_factory/data/canonical_visual_contract_v1.json`. The descriptor
references the root palette and is never an independent palette authority; the
root palette JSON wins on any conflict.

- **Palette:** root game's owner-locked **C01..C15** is authoritative. Factory
  production output uses only a used subset in ascending global C-ID order. No
  C16, no off-palette RGB.
- **Distinct used-color bands (hard legality):** EASY 3–5, MEDIUM 6–7,
  HARD 8–9, VERY_HARD 10–12 — distinct canonical logical cell colors actually
  used by artwork cells.
- **BG01 Midnight Slate `#202533` / RGB(32,37,51):** production gameplay
  background, visible through CLEARED alpha-0 cells; not C16, not a logical
  color, never a LevelData cell color, excluded from the color count.
- **ACTIVE/CLEARED:** ACTIVE = opaque canonical source color; CLEARED = alpha 0
  (BG01 shows through).
- **Cell rendering:** every square is a real gameplay cell rendered as one flat
  solid canonical color with visible square-cell separation — no gloss,
  highlight, bevel, drop shadow, 3D bulge, plastic-bead look, or interpolation;
  presentation grid/border overlays add no logical color and are excluded from
  the count.

Art-first mapping from arbitrary source colors must be deterministic and
auditable; never silently create C16+ or retain off-palette RGB values, never
treat BG01 as a palette color, and never count grid/border overlays toward
difficulty.
