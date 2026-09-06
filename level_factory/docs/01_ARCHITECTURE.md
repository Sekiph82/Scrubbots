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


## Palette boundary

The root game's owner-locked C01..C15 global palette is authoritative.
Factory production output may use only a used subset in ascending global C-ID
order.

Distinct used-color bands:
EASY 3–5, MEDIUM 6–7, HARD 8–9, VERY_HARD 10–12.

CLEARED transparency/background/presentation grid overlays are excluded from
the count. Art-first mapping from arbitrary source colors must be deterministic
and auditable; never silently create C16+ or retain off-palette RGB values.
