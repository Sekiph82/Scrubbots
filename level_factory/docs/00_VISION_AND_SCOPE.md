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
