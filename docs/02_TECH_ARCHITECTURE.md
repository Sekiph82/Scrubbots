# 02 — Technical Architecture

This document defines conceptual module boundaries. It does not mandate a
final class hierarchy. Prompt 01 established the project shell; Prompt 02
implemented Level Data, Level Loader/Validator, and BoardState; Prompt 03
added the official difficulty-band production validator; Prompt 04 (M06)
added `BoardRenderer`; META-C004 replaced the DIRTY/CLEAN prototype with the
owner-locked ACTIVE/CLEARED model (see "LevelData vs. BoardState",
"Structural vs. production validation", and "BoardRenderer and the
ACTIVE/CLEARED visual model" below; ADR-019). Everything else in the module
table is still future work.

## Guiding principles

- Data-oriented board state, not one Node per cell (see
  `docs/05_TECH_DECISIONS.md`).
- Gameplay logic separate from presentation.
- Level data separate from scene/script code.
- **Target selection** and **routing** are separate modules — this is the
  single most important seam in the codebase (see below).
- Production UI is responsive Godot composition, not flattened screen art.
- Owner-approved/reference art guides visual direction; generated art never
  replaces gameplay truth or responsive layout logic.

## Conceptual modules

| Module | Responsibility | Planned location |
|---|---|---|
| App/Game State | Top-level app flow: boot, menu, in-level, results. | `scripts/app/` |
| Level Loader | Reads level data resources/files into runtime Board State. | `scripts/data/` |
| Level Data | Serialized level definition (grid, palette, metadata). | `data/levels/` |
| Board State | Runtime source of truth for a level's cells' current state (cell count = width × height, level-defined). | `scripts/gameplay/board/` |
| Pixel/Cell State | Per-cell data: index, x, y, color id, lifecycle state (ACTIVE/CLEARED). | `scripts/gameplay/cells/` |
| Palette/Color IDs | Maps compact numeric color ids to actual colors. | `scripts/data/`, `data/palettes/` |
| Slot System | Owns the 5 slots, their assigned color, and dispatch eligibility. | `scripts/gameplay/slots/` |
| Scrubbot Dispatcher | Decides when a slot may release a Scrubbot (a reachable target must exist). | `scripts/gameplay/slots/` |
| Color Candidate Index | Groups raw ACTIVE matching-color candidates by color (cached; M13). Does NOT prove reachability. | `scripts/gameplay/targeting/` |
| Reachability/Access truth | Filters candidates that are currently blocked/unreachable under access semantics (future; M15/M16). | `scripts/gameplay/targeting/` or a narrow query seam |
| Target Selector | Decides **which** reachable/targetable candidate a dispatched Scrubbot will clean. | `scripts/gameplay/targeting/` |
| Routing System | Decides **how** a Scrubbot visually travels to its assigned target. | `scripts/gameplay/routing/` |
| Scrubbot Agent | Lightweight runtime object representing one active Scrubbot in flight. | `scripts/gameplay/scrubbots/` |
| Board Renderer | Draws current Board State efficiently (batched, not per-cell Nodes). Implemented in Prompt 04 (M06) — see below. | `scripts/gameplay/board/` |
| Cleaning Feedback | Visual/audio response when a cell is cleaned; poolable, toggleable. | `scripts/gameplay/cells/`, later `scenes/components/` |
| UI | HUD, slot UI, menus, safe areas, responsive composition, reusable controls. | `scripts/ui/`, `scenes/components/ui/`, later screen scenes |
| Visual Asset Pipeline | Owner-reference intake, Magnific-only generated illustration assets, raw/final separation. | `assets/art/references/`, `assets/ui/`, `ASSET_GENERATION_MANIFEST.json` |
| Save System | Persists progress, streak, currency. Not implemented yet. | `scripts/data/` |
| Debug/Instrumentation | Dev-only overlays, logging, inspection tools. | `scripts/debug/`, `scenes/debug/` |

## Candidate → reachability → TargetSelector → RoutingSystem — the critical seam

```
ColorCandidateIndex  --- raw ACTIVE matching-color candidates (M13) --->
        |
        v
Reachability/access  --- filters blocked/unreachable candidates --->
        |
        v
  TargetSelector     --- chooses WHAT target among reachable candidates --->
        |
        v
  RoutingSystem      --- decides HOW to travel to the selected target --->
        |
        v
  Scrubbot Agent moves along the path, then clears the target cell (CLEARED)
```

- `ColorCandidateIndex` (M13, implemented) answers only "which currently
  ACTIVE cells match this color?" as **raw color candidates**. It does **not**
  prove reachability, choose a target, generate a route, or own reservations
  (AL-028).
- **Reachability/access truth** (future) filters candidates that are
  currently blocked/unreachable: non-target ACTIVE cells block access, CLEARED
  and background space is open. A fully enclosed matching-color ACTIVE cell is
  not targetable.
- `TargetSelector` (M15, future) chooses which *reachable/targetable*
  candidate a Scrubbot cleans. It has no opinion about movement/animation and
  **never generates routes**.
- `RoutingSystem` (M16+, future) answers "given a start point and the already
  selected target, what path/motion should the Scrubbot follow?" It has no
  opinion about which cell was chosen and **must never silently retarget** if
  the assigned target has no route — no route is a failure, not a re-pick.
- This split means the routing/pathing algorithm can be swapped or upgraded
  without touching level data, slot logic, cell state, scoring, or rendering.
  Do not merge `TargetSelector` and `RoutingSystem` into one script, and do
  not let `RoutingSystem` reach into Board State to pick targets itself.

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
- Responsive UI may resize/reposition the `BoardRenderer` container but may
  not change its data-oriented rendering architecture.

## LevelData vs. BoardState (implemented in Prompt 02)

- `LevelData` (`scripts/data/level_data.gd`) — immutable parsed level
  source: `version`, `id`, `display_name`, `difficulty`, `width`, `height`,
  `palette`, `cells`. Says what a level **is**. Never mutated at runtime.
- `LevelLoader` / `LevelValidator` (`scripts/data/`) — read a Version 1 JSON
  level file and produce either a `LevelData` or a specific list of
  validation errors (`LevelValidationResult`). See
  `docs/03_LEVEL_DATA_SPEC.md`.
- `BoardState` (`scripts/gameplay/board/board_state.gd`) — runtime cell
  state (`ACTIVE`/`CLEARED` per cell; all cells start ACTIVE), built fresh
  from a `LevelData` via
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

## BoardRenderer and the ACTIVE/CLEARED visual model (M06 renderer; ACTIVE/CLEARED locked in META-C004 / ADR-019)

- `BoardRenderer` (`scripts/gameplay/board/board_renderer.gd`, extends
  `TextureRect`) — draws a `BoardState` as one `Image`/`ImageTexture` (one
  texel per logical cell, nearest-neighbor filtered for crisp pixel-art
  edges). Exactly one Node regardless of board size — see ADR-011. Reads
  `BoardState`/palette; never mutates gameplay state, never chooses
  targets, never dispatches. Public surface: `configure(board, palette,
  available_size)`, `refresh_all()`, `update_cells(indices)`,
  `get_cell_size()`, `get_board_pixel_size()`, `get_pixel_color(x, y)`,
  `get_cell_center_local(x, y)` / `get_cell_center_global(x, y)` (the
  geometry seam a future `RoutingSystem` will target — no movement is
  implemented against it yet).
- **Color law (ADR-019):** an ACTIVE cell renders its exact source palette
  color, opaque (subject only to 8-bit RGBA quantization); a CLEARED cell
  renders `Color(0,0,0,0)` — fully transparent — so the gameplay background
  behind the board shows through. Never a black/gray/palette substitute for
  CLEARED. There is no dirty transform and no preset.
- Geometry: `cell_size = floor(min(available.x/width, available.y/height))`
  — fits any width×height (including rectangular boards) inside a given
  display rect without stretching or distorting aspect ratio, and without
  fractional/drifting cell boundaries.
- `PaletteColors` (`scripts/data/palette_colors.gd`) — the one conversion
  path from `LevelData.palette` hex strings to Godot `Color`, used by
  `BoardRenderer`. Malformed entries are reported, not silently ignored
  (`PaletteParseResult`).
- `scenes/debug/board_renderer_debug.tscn` +
  `scripts/debug/board_renderer_debug.gd` — dev-only tool to compare every
  official board-size boundary against ACTIVE/CLEARED patterns (All ACTIVE,
  All CLEARED, Half, Checker) at native gameplay scale, via dropdowns, no
  code changes needed. A visible debug background sits behind the board so
  transparent CLEARED cells reveal it. Not production UI.

## ColorCandidateIndex (M13, `scripts/gameplay/targeting/`)

- `ColorCandidateIndex` (`scripts/gameplay/targeting/color_candidate_index.gd`,
  extends `RefCounted`) — the color-grouped query/cache layer that answers a
  single narrow question: which currently ACTIVE cells match a given color, as
  **raw color candidates**. Contract: `valid + ACTIVE + matching color + not
  caller-excluded`. API: `create()`, `bind(board)`, `rebind(board)`,
  `rebuild()`, `sync_cell(index)`, `get_candidates(color, excluded=[])`,
  `has_candidates(...)`, `count_candidates(...)`, `get_color_ids()`.
- It groups by color into cached buckets (row-major, deterministic), removes
  CLEARED cells, and supports a caller-supplied exclusion/reservation set —
  but it does **not** decide reachability, choose a final target, generate a
  route, or own reservations (M14/M15/M16 remain separate). A matching-color
  candidate is not automatically reachable (AL-028).

## Gameplay Session Core (implemented in M11)

- `GameplaySession` (`scripts/gameplay/session/gameplay_session.gd`, extends
  `RefCounted`) — headless-testable lifecycle owner. Holds the immutable
  `LevelData` reference and the current `BoardState` instance. Does not
  depend on UI, renderer, slots, routing, or scene hierarchy.
- Lifecycle states: `UNINITIALIZED → READY → ACTIVE ↔ PAUSED → COMPLETED`.
  Reset from any non-UNINITIALIZED state returns to `READY` with a fresh
  `BoardState`. All transitions are explicit method calls; invalid
  transitions return an actionable error without mutating state.
- `load_level(path)` — uses existing `LevelLoader`; on success creates a
  fresh `BoardState` via `BoardState.from_level_data()` and enters `READY`.
  A failed load preserves any previously valid session (failed-load
  atomicity). Replacement semantics: a new level replaces the prior
  session only after full validation and fresh `BoardState` creation succeed.
- `complete()` — explicit external lifecycle transition only. No automatic
  win/lose/timer/move detection. The eventual win-condition system will
  call this method.
- `bind_renderer(renderer, available_size)` — optional presentation
  binding. Configures a `BoardRenderer` through its existing
  `configure(board, palette, size)` contract. Renderer is refreshed on
  load and reset. Renderer does not own lifecycle, does not load levels,
  and does not decide completion.
- Uses the explicit `preload()` convention (ADR-009).

## Master UI System (owner-approved foundation)

Canonical specification: `docs/MASTER_UI_SYSTEM.md`.

### Display/root contract

- baseline reference viewport: 1080×2160 portrait;
- stretch: `canvas_items` + `expand`;
- reusable safe-area root: `scenes/components/ui/common/safe_area_root.tscn`;
- centralized tokens: `scripts/ui/ui_tokens.gd`;
- breakpoint helper: `scripts/ui/responsive_layout.gd`;
- required phone-class viewport matrix is defined in `MASTER_UI_SYSTEM.md`.

### Gameplay layout priority

The board is the primary visual region and grows before decorative regions.
The color-selection panel keeps a protected usable width. In the approved
composition: Goal/Moves is removed; Scrubby sits low left of the selection
region with speech above; cleaning props stay to the right; boosters form a
compact horizontal lower row; pause sits left of the bottom/ad region and
settings right of it.

### Production component rule

UI interaction/state uses live Godot controls, themes and containers. Normal
labels, quantities, slots, progress bars, popup bodies and counters are not
baked into AI images. Full-screen concept renders are art direction only.

### Visual generation boundary

`ASSET_GENERATION_MANIFEST.json` is the generation queue. Magnific MCP is the
only owner-approved AI image provider for this UI pipeline unless explicitly
changed. Generated files are presentation assets only and never carry
canonical game state.

Owner reference intake starts from the confirmed local source:
`C:\Users\sekip\Desktop\ScrubBots Gorselleri` using
`tools/import_desktop_visual_refs.ps1`; originals are copied/preserved and
classified before production promotion.

## Cross-script referencing convention (ADR-009)

Scripts under `scripts/data/` and `scripts/gameplay/board/` reference each
other via explicit `const Foo = preload("res://path/to/foo.gd")` rather than
bare `class_name` lookups, and do not declare `class_name` themselves. See
ADR-009 in `docs/05_TECH_DECISIONS.md` for why — headless Godot runs (no
prior editor session) do not have a global script class cache, so bare
`class_name` references fail to parse. Follow this same pattern for new
gameplay scripts that need to run correctly under `godot --headless`.

## What is explicitly NOT built yet

Slot System is implemented at its current M12 data-model boundary; the M13
`ColorCandidateIndex` supplies raw color candidates only. Reachability/access
truth, reservation (M14), TargetSelector (M15), RoutingSystem (M16+), Scrubbot
Agent, Cleaning Feedback and Save System remain future milestones (see
`docs/04_ROADMAP.md` / `tasks.md`). `BoardRenderer` is implemented with the
owner-locked ACTIVE/CLEARED model (ADR-019); owner manual QA of the
transparent model is still pending (`tasks.md` SB-M10-005..011). The Master UI
foundation now defines responsive architecture and primitives, but production
Gameplay/Home/Popup screens are still milestone work and must not be marked
complete until implemented and validated.


## Level Platform sidecars

### Level Factory

`level_factory/` is a second Godot project inside the repository, with its
own `project.godot`. It is an offline authoring/analysis application, not a
runtime gameplay module.

Boundary:

```text
LEVEL FACTORY
  generate / import / solve / analyze / QA
        |
        | declarative Level Data / previews / reports
        v
M09/M30/M47/M48 production contracts
        |
        v
SCRUBBOTS MOBILE GAME
```

The root game may consume exported Level Data but must never preload Factory
GDScript. Factory editor scenes may depend on Factory core; solver/generator
core should remain headless-testable and scene-independent.

### Content Pipeline

`content_pipeline/` packages accepted content, creates versioned manifests,
publishes first to staging, verifies remote objects, promotes to production,
and supports rollback/disable/scheduling.

Shipping runtime eventually receives only the minimal remote-content client
needed to fetch declarative content over HTTPS, verify it, cache it under
`user://`, and expose verified levels to the existing catalog/loader seam.
Publisher credentials and Factory code never ship in the app.
