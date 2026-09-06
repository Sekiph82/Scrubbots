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
  exact-pixel contract. Any source color must be deterministically mapped to /
  rejected against C01..C16 — never silently expanded — and the result must
  satisfy the difficulty distinct-used-color bands.
- **PUZZLE_FIRST**: Factory constructs puzzle/geometry candidates first, then
  produces previewable candidate art/data. Generated art is never labeled as
  owner-original. Generated logical colors come only from C01..C16, honor the
  difficulty color-count bands, sit on the fixed BG01 background (not a logical
  color), and render as flat solid square cells — never glossy/beveled/3D/bead
  styling.

## Canonical visual contract (owner-locked, META-C005)

Every Factory mode and phase obeys the root owner-locked visual contract
(`docs/08_PIXEL_ART_PALETTE_RULES.md` + `data/palettes/scrubbots_palette_v1.json`;
Factory descriptor `level_factory/data/canonical_visual_contract_v1.json`):

- **Logical artwork colors are C01..C16 only** — no C17, no off-palette RGB.
- **Difficulty color-count bands are hard legality**, not guidance:
  EASY 3–5, MEDIUM 6–7, HARD 8–9, VERY_HARD 10–12 (distinct canonical logical
  cell colors actually used by artwork cells).
- **BG01 Midnight Slate `#202533` / RGB(32,37,51)** is the fixed production
  background: shown through CLEARED alpha-0 cells, outside C01..C16, not a logical
  color, never a LevelData cell color, never counted toward difficulty totals.
- **ACTIVE** = opaque canonical source color; **CLEARED** = alpha 0 (BG01
  visible).
- Generated/puzzle-first art uses **flat solid square cells** with visible
  square-cell separation — no gloss, highlight, bevel, drop shadow, 3D bulge,
  plastic-bead look, or interpolation. Cell borders are presentation-only and
  add no logical color.

The root palette JSON is the single palette authority; the descriptor only
references it and stores locked non-palette metadata.

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
