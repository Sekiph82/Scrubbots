# SCRUBBOTS Level Factory — CLAUDE Governance

This file applies when an implementation prompt targets \`level_factory/\`.

## Project identity

- Nested Godot project: \`level_factory/project.godot\`
- Engine: Godot 4.7.1-stable
- Language: GDScript unless a later audited decision approves otherwise
- Canonical tasks: repository-root \`tasks.md\`, \`SB-LFxx-xxx\`
- Main-game governance: repository-root \`CLAUDE.md\`

## Isolation

The Factory is development tooling. Do not make the root mobile game preload
or depend on Factory GDScript. Export only documented declarative artifacts.

Do not duplicate or rewrite audited M09 importer behavior. Reuse/bridge its
data contract deliberately.

## Design gates

Do not invent dependency, stack, deadlock, reachability, slot-pressure,
win/solution or progression semantics. Implement adapters/interfaces and
wait for canonical gameplay decisions where needed.

## Canonical visual contract [MUST READ before any artwork work]

Before generating, mutating, validating, previewing or exporting any pixel
artwork — in either ART_FIRST or PUZZLE_FIRST mode — every Level Factory /
pixel-art-generation session MUST read and obey the owner-locked root visual
contract (META-C005):

- Root palette rules: `docs/08_PIXEL_ART_PALETTE_RULES.md`
- Root palette (single authority): `data/palettes/scrubbots_palette_v1.json`
- Factory descriptor (references the root, never redefines it):
  `level_factory/data/canonical_visual_contract_v1.json`

Locked rules the Factory must enforce, never weaken:

- Logical artwork colors are **C01..C16 only** (root palette). No C17, no
  off-palette RGB.
- Difficulty distinct-used-color bands are hard legality:
  EASY 3–5, MEDIUM 6–7, HARD 8–9, VERY_HARD 10–12. Count only distinct
  canonical logical cell colors actually used by artwork cells.
- `BG01 Midnight Slate #202533 = RGB(32,37,51)` is the production gameplay
  background: visible through CLEARED alpha-0 cells, **not** C16, **not** a
  logical artwork color, never a LevelData cell color, and never counted
  toward distinct-used-color totals.
- ACTIVE = opaque canonical source color; CLEARED = alpha 0 with BG01 showing
  through.
- Every logical square is a real gameplay cell rendered as one flat solid
  canonical color with visible square-cell separation — **no** gloss,
  highlight, bevel, drop shadow, 3D/plastic-bead appearance or interpolation.
  Grid/border separation is presentation-only and creates no logical color.

If the descriptor ever conflicts with the root palette JSON, the root palette
JSON wins. Do not create a second independent palette table that can drift.

## GitHub coordination

1. Safely sync \`origin/main\`.
2. Read the active cycle's \`CHATGPT_PROMPT_VNN.md\`,
   \`CHATGPT_AUDIT_CRITERIA_VNN.md\`, prior ChatGPT audit(s), root
   \`coordination/AUDIT_INDEX.md\`, root \`tasks.md\`, this file and relevant
   Factory docs.
3. Implement/test/log only.
4. Maintain exactly one append-only
   \`CLAUDE_IMPLEMENTATION_LOG.md\` per cycle.
5. Update root \`tasks.md\`, Factory \`coordination/SESSION_INDEX.md\` and
   root \`.hiveai/PROJECT_DASHBOARD.md\` with validated truth.
6. Push safely to \`origin/main\`; never force.
7. Return \`AWAITING_AUDIT\` and stop.
8. Never create audit/self-audit files and never assign audit verdicts.

ChatGPT alone creates \`CHATGPT_AUDIT_VNN.md\` and correction prompt versions.


## Coordination v4 owner override — version-matched Claude logs [LOCKED]

This section supersedes older references in this file to a single
`CLAUDE_IMPLEMENTATION_LOG.md` per cycle.

For every material ChatGPT prompt version:

```text
CHATGPT_PROMPT_VNN.md
CHATGPT_AUDIT_CRITERIA_VNN.md
CLAUDE_LOG_VNN.md
CHATGPT_AUDIT_VNN.md
```

The prompt version and Claude log version must match exactly. Work performed
under VNN is recorded in `CLAUDE_LOG_VNN.md` in the same cycle directory.
If V02 and V03 are intentionally delivered/executed together, Claude still
creates both logs and identifies shared commits/tests explicitly.

Historical `CLAUDE_IMPLEMENTATION_LOG.md` files are legacy evidence only.
Do not delete them, but do not use that naming pattern for new prompt work.

Before ending a material session, update these derived H!veAI sources:

- `.hiveai/ACTIVE_CYCLES.md`
- `.hiveai/ARTIFACT_MAP.md`
- `.hiveai/PROGRESS_SNAPSHOT.md`

Then materialize the latest state into
`.hiveai/PROJECT_DASHBOARD.md`. H!veAI actively watches only the dashboard.
`tasks.md` remains the only canonical task ledger.

Canonical policy:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/VERSIONED_LOG_POLICY.md
