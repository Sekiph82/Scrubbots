# SCRUBBOTS Level Factory

This directory is a **separate Godot 4.7.1 project inside the SCRUBBOTS
repository**. Open \`level_factory/project.godot\` directly when working on
the Factory.

It is not a gameplay module and is never loaded by the mobile game's root
Godot project.

## Mission

Build an offline production machine that can:

\`\`\`text
generate/import candidate
      ↓
validate
      ↓
simulate / solve
      ↓
analyze difficulty and quality
      ↓
human review/edit/revalidate
      ↓
batch accept/reject
      ↓
export declarative production artifacts
      ↓
handoff to Content Pipeline
\`\`\`

The Factory is constraint-based and reproducible, not a blind random-board
generator. Every procedural candidate must be reproducible from versioned
configuration + seed.

## Modes

- **ART_FIRST**: owner-supplied pixel art/mask is the immutable visual source;
  Factory builds/validates puzzle data around it and reuses the audited M09
  exact-pixel contract.
- **PUZZLE_FIRST**: Factory constructs puzzle/geometry candidates first, then
  produces previewable candidate art/data. Generated art is never labeled as
  owner-original.

## Current gameplay-design gates

Dependency locking, stack quantities/order, deadlock semantics, bait/safe
moves, reachability, slot-pressure scoring, exact legal moves, exact
win/solution semantics and campaign progression are not yet canonical.
Factory adapters for them stay experimental until the matching mobile-game
milestones define them.

## Canonical board rules

- EASY: 20–29 per dimension
- MEDIUM: 30–39
- HARD: 40–49
- VERY_HARD: 50–59
- rectangular boards allowed
- max current production workload: 59×59 = 3,481 cells
- TEST fixtures remain non-production

## Integration boundary

\`\`\`text
level_factory/
  -> exported declarative artifacts
  -> audited M09/M30/M47/M48 contracts
  -> root SCRUBBOTS game

root game NEVER -> preload level_factory scripts
\`\`\`

## Task truth

Canonical backlog is the repository-root \`tasks.md\`, using task IDs
\`SB-LFxx-xxx\`.

## Coordination

See \`coordination/README.md\` and \`coordination/SESSION_INDEX.md\`.
ChatGPT writes prompts/audits to GitHub. Claude reads them from GitHub,
implements/tests, appends to the cycle implementation log, pushes, and stops
at \`AWAITING_AUDIT\`. ChatGPT independently audits the repository state.
