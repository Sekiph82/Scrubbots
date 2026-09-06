# Level Factory Vision & Scope

## Product idea

The Level Factory is a **project inside the SCRUBBOTS repository**, but a
separate Godot application. Its job is to manufacture, inspect and approve
level content. The mobile game only plays exported Level Data.

The production philosophy is:

> Not a random board generator. A reproducible, constraint-based,
> solver/validator-backed puzzle production machine.

## Target flow

\`\`\`text
TARGET DIFFICULTY / ART INPUT
        ↓
VERSIONED GENERATION CONFIG + SEED
        ↓
PUZZLE-FIRST or ART-FIRST CANDIDATE
        ↓
SHAPE / COLOR-REGION GENERATION
        ↓
OPTIONAL GAMEPLAY-SEMANTIC ADAPTERS
        ↓
STRUCTURAL + PRODUCTION VALIDATION
        ↓
SIMULATION / SOLVER
        ↓
SOLVED?
   NO ──┘ └── YES
 reject       ↓
         DIFFICULTY / QUALITY ANALYSIS
               ↓
          target match?
          NO       YES
          ↓         ↓
        mutate     HUMAN REVIEW
          │         ↓
          └────→ REVALIDATE
                    ↓
                  ACCEPT
                    ↓
                  EXPORT
                    ↓
             CONTENT PIPELINE
\`\`\`

## Puzzle-first

Puzzle-first begins from mathematical/puzzle structure, then generates
geometry/color regions and previewable candidate content.

Candidate shape primitives may include blob, ring, corridor, pocket, island,
snake, branch, chamber, spiral, nested and multi-island forms. These are tools,
not difficulty rules.

## Art-first

Art-first begins from owner-supplied original pixel art/masks. One logical
artwork square remains one logical cell. Owner source bytes are immutable.
The Factory must reuse the audited M09 exact-pixel Level Data/reconstruction
contract rather than inventing a second incompatible importer.

## Reproducibility

Same versioned config + same seed must reproduce the same candidate. QA and
bug reports reference candidate ID, seed, config and generator version.

## Solver

The baseline planned search is deterministic DFS + visited-state memoization +
state hashing, later extensible with safe pruning, heuristic ordering, IDA* or
beam-search research if needed.

The solver records solution path, states visited, dead ends, max/search depth,
branching and timing diagnostics.

The solver does **not** invent SCRUBBOTS mechanics. Legal moves, reachability,
deadlocks and completion semantics come from versioned gameplay adapters only
after those rules are canonical.

Now-canonical gameplay law the solver/generator must consume via a shared
adapter (owner decision META-C004, ADR-019 / AL-027 / AL-028 — never a
re-invented Colony Flow rule):

- Board cells start **ACTIVE** (present, source palette color, opaque, color
  candidate, block access).
- A legal cleaning move clears **one ACTIVE matching-color target**, turning it
  **CLEARED** (transparent, no longer a candidate, opens access space).
- CLEARED cells and background/outside-board space are **open**; non-target
  ACTIVE cells **block** access/traversal.
- A matching-color ACTIVE cell that is fully enclosed/blocked is **not
  currently targetable** until prior clears create legal access — matching
  color alone is not sufficient.

## Canonical Visual Contract [OWNER-LOCKED, META-C005]

This is the single authoritative visual contract every Factory generation,
mutation, validation, preview and export step must obey. Sources of truth:
`docs/08_PIXEL_ART_PALETTE_RULES.md` + `data/palettes/scrubbots_palette_v2.json`
(root, authoritative), mirrored as machine-readable non-palette metadata in
`level_factory/data/canonical_visual_contract_v1.json` (references the root;
never a second palette authority — root wins on any conflict).

**Palette (source of truth):** production Factory outputs use only root-game
palette **C01..C16** from `data/palettes/scrubbots_palette_v2.json`. No C17, no
off-palette logical artwork RGB. A level's local palette is an ascending-C-ID
subset of the colors actually used.

**Difficulty distinct-used-color bands (hard legality):** count only distinct
canonical logical cell colors actually used by artwork cells —
EASY 3–5, MEDIUM 6–7, HARD 8–9, VERY_HARD 10–12.

**Gameplay background BG01:**

| ID | Name | HEX | RGB | Logical color? |
| --- | --- | --- | --- | --- |
| BG01 | Midnight Slate | `#202533` | 32, 37, 51 | **No** |

BG01 is the production surface behind the artwork, visible through CLEARED
alpha-0 cells. BG01 is **not** C16, **not** a logical artwork color, never a
LevelData cell color, and never counts toward distinct-used-color totals.

**Cell state semantics:** ACTIVE = original canonical source color, opaque;
CLEARED = fully transparent (alpha 0) with BG01 showing through.

**Cell rendering / generation rules:** every logical square is a real gameplay
cell rendered as **one flat solid canonical palette color** with visible
square-cell separation — **no** gloss, highlight, bevel, drop shadow, 3D
bulge/embossing, plastic-bead appearance, or interpolation. Visible cell
boundaries/grid are presentation-only and create no logical color and never
count toward difficulty totals.

Art-first arbitrary source colors must be deterministically mapped/rejected
against C01..C16 and reported; they never become new game colors.

## Difficulty intelligence

Potential metrics include:

- solution depth/move count
- states visited
- dead ends
- branching factor
- forced moves
- dependency depth
- slot pressure
- bait/false-move ratio
- color switches
- remaining-state volatility
- bounded solution count / solution entropy

Metrics that depend on undefined mechanics stay disabled/design-gated.
Difficulty-score coefficients are versioned and provisional until playtest or
future telemetry calibration proves them.

Canonical Easy/Medium/Hard/Very Hard **dimension bands remain production
legality**, not proof of puzzle difficulty.

## Human-in-the-loop editor

A future Godot @tool/editor workspace provides:

- difficulty/dimensions/seed/mode controls
- Generate
- Solve
- Analyze
- Validate
- Reproduce
- Mutate
- Export
- crisp board/art preview
- metrics and rejection reasons
- manual paint/erase/color/config editing where safe
- REVALIDATE after every manual change

Generated candidates never auto-promote to production.

## Batch Factory

A weekly job may request, for example:

\`\`\`text
20 Easy
35 Medium
30 Hard
15 Very Hard
= 100 accepted levels
\`\`\`

The Factory may generate thousands of candidates and reject most of them.
Success is the requested count of reviewed, valid candidates, not a high
acceptance percentage.

Batch output records generated/rejected/accepted counts, rejection reasons,
provenance, previews, Level Data, QA reports and Content Pipeline handoff.

## V1 / V2 / V3

### V1
- deterministic config/seeds
- constraint candidate generator
- puzzle-first/art-first modes
- shape/color regions
- simulation adapter
- baseline solver
- validator
- difficulty metrics framework
- human editor
- export

### V2
- mutation engine
- automatic difficulty targeting
- resumable batch generation
- bounded solution-count analysis
- campaign/sequencing adapter after progression rules exist

### V3 / experimental
- evolutionary/genetic candidate selection
- procedural art-mask research
- telemetry-calibrated difficulty after analytics/privacy approval
- live generation remains disabled unless separately approved

## Historical compatibility warning

Old planning references to 16×16, 18×18, fixed 40×40, Extra Hard, or a
2,500-cell maximum are obsolete. Current canonical production rules are:

- Easy 20–29
- Medium 30–39
- Hard 40–49
- Very Hard 50–59
- width/height validated independently
- rectangular allowed
- maximum 59×59 = 3,481 cells
