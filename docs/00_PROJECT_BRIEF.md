# 00 — Project Brief

## What SCRUBBOTS is

SCRUBBOTS is an original mobile puzzle game. Each level is a piece of
pixel-art whose cells start **ACTIVE** — visible at their original source
palette color. The player dispatches tiny cleaning robots — **Scrubbots** —
from a limited set of color slots to clear away the visible pixel artwork one
logical pixel at a time. A cleared cell becomes **CLEARED**: fully transparent,
so the gameplay background shows through the hole it leaves. There is no
grime layer and no hidden second artwork — the visible artwork itself is what
is progressively cleared away (see `docs/05_TECH_DECISIONS.md` ADR-019).

This is a from-scratch SCRUBBOTS implementation: own architecture, own
visuals, own terminology, own rules. No code, assets, characters, UI, levels,
or exact visual presentation are copied from any other title. Games about
"many small agents moving through a board" may be discussed internally only
as a feel reference, never as a source to copy from.

## Mobile puzzle-game objective

Each level presents the player with an obscured pixel-art image and a small
number of active color slots. The player's job is to clear the board by
routing the right Scrubbots to the right cells, working within the
constraints of how many slots and Scrubbots are available at once. The
puzzle tension comes from managing limited dispatch resources, not from
twitch reflexes — this is a puzzle game, not an action game.

## The Scrubbots universe (original)

Scrubbots are small robots, each tied to a color/slot. They are simple,
purposeful machines: they leave their slot, travel to a cell they can clean,
clean it, and disappear. No story or lore beyond this functional identity is
specified yet — none should be invented. See `CLAUDE.md` rule 2.

## High-level player experience

1. Player opens a level and sees a pixel-art image — all cells ACTIVE at
   their source palette color — on a logical grid whose width and height are
   defined by that level (40×40 and 50×50 are both real, supported sizes —
   see below).
2. Player sees 5 slots, each representing a color/robot type.
3. Player selects/activates slots to dispatch Scrubbots.
4. Scrubbots travel from their slot to a reachable matching-color ACTIVE cell
   and clear it (the cell becomes CLEARED — transparent).
5. As cells become CLEARED, transparent holes open across the artwork and the
   gameplay background shows through.
6. The level is won when the board reaches its win condition (exact
   condition detail: see `docs/01_GAMEPLAY_SPEC.md`).
7. Consecutive wins build a streak that pays out according to the locked
   reward mapping.

## The variable-size logical board concept

Every puzzle image is defined on a **logical grid whose width and height come
from that level's data**, not from a fixed engine constant. Official
production difficulty bands (Prompt 03) tie board dimensions to difficulty:
Easy 20–29×20–29, Medium 30–39×30–39, Hard 40–49×40–49, Very Hard
50–59×50–59 — see `docs/01_GAMEPLAY_SPEC.md` for the full table. `40×40`
and `50×50` are valid example sizes within the Hard and Very Hard bands
respectively, not the only sizes the engine supports — the current maximum
production requirement is 59×59 (3,481 cells). Cell count is always
`width * height` — it is derived, never hard-coded. This is game data, not
a screen-pixel measurement: a logical board of any supported size can be
displayed at any physical size the device screen allows. See
`docs/03_LEVEL_DATA_SPEC.md` for how this is represented and
`docs/05_TECH_DECISIONS.md` (ADR-008, ADR-010) for why the engine is
variable-size and how the official difficulty bands work.

## The 5-slot concept

The player currently works with **5** color/robot slots at a time. Slots are
the player's only means of introducing new Scrubbots onto the board.

## Tiny robot cleaning concept

A Scrubbot leaves its slot only when there is a valid, reachable cell for it
to clean — never speculatively. It travels to that one target, cleans it,
and disappears. It does not carry color, and it does not return home.

## Why robot movement matters

Watching Scrubbots move across the board is the core visual identity of the
game — it is not incidental animation. The architecture must keep this
system replaceable and improvable independent of the rest of the game (see
the TargetSelector/RoutingSystem split in `docs/02_TECH_ARCHITECTURE.md`),
because this is where the game's feel will be iterated on the most.
