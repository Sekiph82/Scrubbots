# 02 — Technical Architecture

This document defines conceptual module boundaries. It does not mandate a
final class hierarchy, and most modules below are **not implemented yet** —
Prompt 01 only establishes the project shell they will live in.

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
| Board State | Runtime source of truth for all 1,600 cells' current state. | `scripts/gameplay/board/` |
| Pixel/Cell State | Per-cell data: index, x, y, color id, cleaned flag, availability. | `scripts/gameplay/cells/` |
| Palette/Color IDs | Maps compact numeric color ids to actual colors. | `scripts/data/`, `data/palettes/` |
| Slot System | Owns the 5 slots, their assigned color, and dispatch eligibility. | `scripts/gameplay/slots/` |
| Scrubbot Dispatcher | Decides when a slot may release a Scrubbot (work must exist). | `scripts/gameplay/slots/` |
| Target Selector | Decides **which** cell a dispatched Scrubbot will clean. | `scripts/gameplay/routing/` |
| Routing System | Decides **how** a Scrubbot visually travels to its assigned target. | `scripts/gameplay/routing/` |
| Scrubbot Agent | Lightweight runtime object representing one active Scrubbot in flight. | `scripts/gameplay/scrubbots/` |
| Board Renderer | Draws current Board State efficiently (batched, not per-cell Nodes). | `scripts/gameplay/board/`, `scenes/gameplay/` |
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

- Board State for all 1,600 cells is stored as flat/packed arrays, not 1,600
  Node instances. See `docs/05_TECH_DECISIONS.md` for the decision record.
- Rendering draws the board from that data (e.g. a single custom-drawn
  surface or batched draw calls / texture generated from state), not one
  Sprite2D per cell.
- Scrubbots in flight are lightweight active objects, pooled where it makes
  sense, since the number of simultaneously active Scrubbots is small
  (bounded by slot count) even though the board itself is large.

## What is explicitly NOT built yet

Board State, Level Loader, Slot System, TargetSelector, RoutingSystem,
Scrubbot Agent, Board Renderer, Cleaning Feedback, Save System are all
future milestones (see `docs/04_ROADMAP.md`). Prompt 01 delivers only the
project shell, docs, and a bootstrap scene.
