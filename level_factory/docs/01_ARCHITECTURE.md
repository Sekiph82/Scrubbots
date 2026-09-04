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
SCRUBBOTS gameplay milestones.

## Difficulty boundary

Board-size bands remain production legality, not proof of puzzle difficulty.
Difficulty intelligence may add metrics, but metric coefficients stay
versioned/provisional until calibrated and owner-approved.
