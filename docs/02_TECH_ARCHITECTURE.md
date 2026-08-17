# 02 — Technical Architecture

This document defines conceptual module boundaries. It does not mandate a
final class hierarchy. Prompt 01 established the project shell; Prompt 02
implemented Level Data, Level Loader/Validator, and BoardState; Prompt 03
added the official difficulty-band production validator; Prompt 04 (M06)
added `BoardRenderer` and the DIRTY/CLEAN visual prototype layer (see
"LevelData vs. BoardState", "Structural vs. production validation", and
"BoardRenderer and the DIRTY/CLEAN visual layer" below). Everything else in
the module table is still future work.

## Guiding principles

- Data-oriented board state, not one Node per cell (see
  `docs/05_TECH_DECISIONS.md`).
- Gameplay logic separate from presentation.
- Level data separate from scene/script code.
- **Target selection** and **routing** are separate modules — this is the
  single most important seam in the codebase (see below).

## Conceptual modules

| Module | Responsibility | Planned location |
|---|---|---|
| App/Game State | Top-level app flow: boot, menu, in-level, results. | `scripts/app/` |
| Level Loader | Reads level data resources/files into runtime Board State. | `scripts/data/` |
| Level Data | Serialized level definition (grid, palette, metadata). | `data/levels/` |
| Board State | Runtime source of truth for a level's cells' current state (cell count = width × height, level-defined). | `scripts/gameplay/board/` |
| Pixel/Cell State | Per-cell data: index, x, y, color id, cleaned flag, availability. | `scripts/gameplay/cells/` |
| Palette/Color IDs | Maps compact numeric color ids to actual colors. | `scripts/data/`, `data/palettes/` |
| Slot System | Owns the 5 slots, their assigned color, and dispatch eligibility. | `scripts/gameplay/slots/` |
| Scrubbot Dispatcher | Decides when a slot may release a Scrubbot (work must exist). | `scripts/gameplay/slots/` |
| Target Selector | Decides **which** cell a dispatched Scrubbot will clean. | `scripts/gameplay/routing/` |
| Routing System | Decides **how** a Scrubbot visually travels to its assigned target. | `scripts/gameplay/routing/` |
| Scrubbot Agent | Lightweight runtime object representing one active Scrubbot in flight. | `scripts/gameplay/scrubbots/` |
| Board Renderer | Draws current Board State efficiently (batched, not per-cell Nodes). Implemented in Prompt 04 (M06) — see below. | `scripts/gameplay/board/` |
| Cleaning Feedback | Visual/audio response when a cell is cleaned; poolable, toggleable. | `scripts/gameplay/cells/`, later `scenes/components/` |
| UI | HUD, slot UI, menus. | `scripts/ui/`, `scenes/ui/` |
| Save System | Persists progress, streak, currency. Not implemented yet. | `scripts/data/` |
| Debug/Instrumentation | Dev-only overlays, logging, inspection tools. | `scripts/debug/`, `scenes/debug/` |

## TargetSelector vs. RoutingSystem — the critical seam

```
Slot dispatches a Scrubbot
        |
        v
  TargetSelector  --- decides WHAT cell to clean ---> target cell index
        |
        v
  RoutingSystem   --- decides HOW to visually get there ---> path/movement
        |
        v
  Scrubbot Agent moves along the path, then triggers cell cleanup
```

- `TargetSelector` only ever answers "given current Board State and this
  Scrubbot's color, which cell should it go clean?" It has no opinion about
  movement, animation, or timing.
- `RoutingSystem` only ever answers "given a start point and a target cell,
  what path/motion should the Scrubbot follow?" It has no opinion about
  which cell was chosen or why.
- This split means the routing/pathing algorithm (a significant future
  design task) can be swapped or upgraded without touching level data, slot
  logic, cell state, scoring, or rendering. Do not merge these into one
  script, and do not let `RoutingSystem` reach into Board State to pick
  targets itself.

## Performance approach

- Board State (any level size, e.g. 1,600 or 3,481 cells) is stored as
  flat/packed arrays, not one Node per cell. See `docs/05_TECH_DECISIONS.md`
  for the decision record (ADR-004, ADR-008).
- Rendering draws the entire board as one `Image`/`ImageTexture` on a
  single `TextureRect` (ADR-011) — not one Sprite2D/Node per cell, and not
  per-frame immediate-mode draw calls per cell.
- Scrubbots in flight are lightweight active objects, pooled where it makes
  sense, since the number of simultaneously active Scrubbots is small
  (bounded by slot count) even though the board itself is large.

## LevelData vs. BoardState (implemented in Prompt 02)

- `LevelData` (`scripts/data/level_data.gd`) — immutable parsed level
  source: `version`, `id`, `display_name`, `difficulty`, `width`, `height`,
  `palette`, `cells`. Says what a level **is**. Never mutated at runtime.
- `LevelLoader` / `LevelValidator` (`scripts/data/`) — read a Version 1 JSON
  level file and produce either a `LevelData` or a specific list of
  validation errors (`LevelValidationResult`). See
  `docs/03_LEVEL_DATA_SPEC.md`.
- `BoardState` (`scripts/gameplay/board/board_state.gd`) — runtime cell
  state (`DIRTY`/`CLEAN` per cell), built fresh from a `LevelData` via
  `BoardState.from_level_data(level)`. Says what is **currently happening**
  to that level. Two `BoardState` instances built from the same `LevelData`
  never share mutable state.
- Storage: flat `PackedInt32Array` (palette ids) and `PackedByteArray` (cell
  states), sized to `width * height` — no per-cell Node/object, and no
  assumption about board size anywhere in these classes (see ADR-008).
- Indexing rule (centralized in `BoardState`, must not be re-derived
  elsewhere): `index = y * width + x`; reverse `x = index % width`,
  `y = index / width` (integer division).

## Structural vs. production validation (implemented in Prompt 03)

- `DifficultyRules` (`scripts/data/difficulty_rules.gd`) — single source of
  truth for the official difficulty→dimension bands (Easy/Medium/Hard/
  Very_Hard, each `{min, max}` applied to both width and height
  independently) and the `TEST` non-production identifier. See
  `docs/05_TECH_DECISIONS.md` ADR-010.
- `ProductionLevelValidator` / `ProductionValidationResult`
  (`scripts/data/`) — take an already-structurally-valid `LevelData` and
  decide whether it is legal as *production* content: known production
  difficulty (never `TEST`), width/height within that difficulty's band.
  This is deliberately a **separate** class from `LevelValidator` — the
  generic engine (`LevelData`, `LevelLoader`, `LevelValidator`,
  `BoardState`) stays fully dimension-agnostic and never rejects a
  structurally valid level (e.g. the 3×2 fixture) for being "too small" or
  "not a real difficulty." Only code that specifically cares about
  production legality calls `ProductionLevelValidator`.
- Board dimensions are never a `TargetSelector`/`RoutingSystem`/renderer
  concern either — those future systems read `BoardState.get_width()`/
  `get_height()` like everything else and have no reason to know about
  difficulty bands at all.

## BoardRenderer and the DIRTY/CLEAN visual layer (implemented in Prompt 04 / M06)

- `BoardRenderer` (`scripts/gameplay/board/board_renderer.gd`, extends
  `TextureRect`) — draws a `BoardState` as one `Image`/`ImageTexture` (one
  texel per logical cell, nearest-neighbor filtered for crisp pixel-art
  edges). Exactly one Node regardless of board size — see ADR-011. Reads
  `BoardState`/palette; never mutates gameplay state, never chooses
  targets, never dispatches. Public surface: `configure(board, palette,
  available_size)`, `refresh_all()`, `update_cells(indices)`,
  `set_dirty_preset(name)`, `get_cell_size()`, `get_board_pixel_size()`,
  `get_cell_center_local(x, y)` / `get_cell_center_global(x, y)` (the
  geometry seam a future `RoutingSystem` will target — no movement is
  implemented against it yet).
- Geometry: `cell_size = floor(min(available.x/width, available.y/height))`
  — fits any width×height (including rectangular boards) inside a given
  display rect without stretching or distorting aspect ratio, and without
  fractional/drifting cell boundaries.
- `PaletteColors` (`scripts/data/palette_colors.gd`) — the one conversion
  path from `LevelData.palette` hex strings to Godot `Color`, used by
  `BoardRenderer`. Malformed entries are reported, not silently ignored
  (`PaletteParseResult`).
- `DirtyCleanPresets` (`scripts/gameplay/board/dirty_clean_presets.gd`) —
  centralized DIRTY color transform (HSV saturation *and* value reduction,
  never saturation alone — see `docs/01_GAMEPLAY_SPEC.md`). CLEAN always
  displays the unmodified source palette color. Three named presets
  (`A`/`B`/`C`) exist for owner comparison; **none is approved yet** — this
  is an open `[DESIGN GATE]`, tracked in `tasks.md` M10.
- `scenes/debug/board_renderer_debug.tscn` +
  `scripts/debug/board_renderer_debug.gd` — dev-only tool to compare every
  official board-size boundary and all three DIRTY presets at native
  gameplay scale, via dropdowns, no code changes needed. Not production UI.

## Cross-script referencing convention (ADR-009)

Scripts under `scripts/data/` and `scripts/gameplay/board/` reference each
other via explicit `const Foo = preload("res://path/to/foo.gd")` rather than
bare `class_name` lookups, and do not declare `class_name` themselves. See
ADR-009 in `docs/05_TECH_DECISIONS.md` for why — headless Godot runs (no
prior editor session) do not have a global script class cache, so bare
`class_name` references fail to parse. Follow this same pattern for new
gameplay scripts that need to run correctly under `godot --headless`.

## What is explicitly NOT built yet

Slot System, TargetSelector, RoutingSystem, Scrubbot Agent, Cleaning
Feedback, Save System are all future milestones (see `docs/04_ROADMAP.md`).
`BoardRenderer` is now implemented (Prompt 04/M06), but the *final* DIRTY
visual language is not — that remains an open design gate (see above and
`tasks.md` M10).
