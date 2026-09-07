# 01 — Gameplay Specification

Status tags used below:

- `[LOCKED]` — specified by the project owner. Do not reinterpret or change
  silently. Changes require explicit owner sign-off (see `CLAUDE.md` rule 3).
- `[TO BE DESIGNED]` — intentionally undefined. Do not invent a final design;
  propose options instead when the milestone requires it.

## Board `[LOCKED, corrected in Prompt 02 (ADR-008), refined in Prompt 03 (ADR-010)]`

- Logical grid is **variable-size**: width and height are defined per level
  in level data, and cell count is always `width * height` (derived, never a
  fixed engine constant). The engine must not assume `width == height`.
- **Official production difficulty/board-dimension bands** (width and height
  each checked independently against the same band — rectangular boards are
  valid):

  | Difficulty | Width range | Height range | Min cells | Max cells |
  |---|---|---|---|---|
  | EASY | 20–29 | 20–29 | 400 | 841 |
  | MEDIUM | 30–39 | 30–39 | 900 | 1521 |
  | HARD | 40–49 | 40–49 | 1600 | 2401 |
  | VERY_HARD | 50–59 | 50–59 | 2500 | **3481** |

  `40×40` and `50×50` are valid *example* sizes (within Hard and Very Hard
  respectively) — they are not the only supported sizes, and the current
  production maximum is **59×59 = 3,481 cells**.
- `TEST`/development fixtures (e.g. the 3×2 generic-size engine-proof
  fixture) may exist outside every production band — they prove the
  underlying board engine is genuinely dimension-generic and must never be
  exposed as production content. See ADR-010.
- Grid is logical/data, independent of physical screen size or zoom.
- Each cell has (at minimum): index, x, y, color id, and lifecycle state
  (`ACTIVE` or `CLEARED` — see below).

> **Correction note (Prompt 02):** Prompt 01 incorrectly locked this section
> to a fixed 40×40/1,600-cell board. That was a documentation error, not an
> owner-specified rule change — the owner's actual requirement is a
> variable-size board engine. See `docs/05_TECH_DECISIONS.md` ADR-008.
>
> **Refinement note (Prompt 03):** Prompt 02's own correction under-specified
> the requirement as "40×40 standard / 50×50 required for Very Hard" — the
> actual rule is the full difficulty-band table above, with a 59×59 maximum.
> See ADR-010.

## Global production pixel-art palette `[LOCKED — owner decision 2026-09-06]`

Only C01..C16 from `data/palettes/scrubbots_palette_v2.json` are legal
production logical artwork colors. C16 is Pure Black `#000000` and is a normal
logical artwork color. See
`docs/08_PIXEL_ART_PALETTE_RULES.md` for the exact HEX/RGB table.

Distinct canonical logical colors actually used by production artwork:

| Difficulty | Distinct used colors |
| --- | ---: |
| EASY | **3–5** |
| MEDIUM | **6–7** |
| HARD | **8–9** |
| VERY_HARD | **10–12** |

CLEARED transparency is runtime state and is not a logical palette color. Gameplay
background and presentation-only square-grid/border overlays also do not count.

## ACTIVE / CLEARED cell lifecycle `[LOCKED — owner decision 2026-09-05, META-C004; ADR-019]`

Every logical artwork pixel begins **ACTIVE** and can become **CLEARED**.
This owner decision supersedes the earlier DIRTY/CLEAN/grime/reveal prototype
model entirely (see `docs/05_TECH_DECISIONS.md` ADR-019; the superseded
history is preserved, not erased).

**ACTIVE** cell:

- still present on the board;
- displays its **original source palette color, unmodified**;
- is opaque;
- participates in color matching (a color candidate);
- occupies/blocks board space for access/path semantics.

**CLEARED** cell (after a Scrubbot successfully cleans it):

- no longer visually present;
- renders with **alpha = 0** (fully transparent);
- reveals the gameplay background underneath *through the transparent hole*
  (this is the only sense in which anything is "revealed" — there is no
  hidden clean artwork layer);
- is no longer a color candidate;
- becomes open/free space for access/path semantics.

The production gameplay background revealed through CLEARED cells is **BG01
Midnight Slate `#202533` / RGB(32,37,51)**. BG01 is presentation/background
state, not a logical pixel-art palette color, not C16, and is excluded from
difficulty color counts.

There is no gameplay-semantic DIRTY state, no CLEAN-colored transform state,
no grime transform, no A/B/C dirty preset, and no hidden second artwork layer.
The visible pixel artwork itself is what is progressively cleared away.

## Color candidate vs. reachable target `[LOCKED — owner decision, META-C004; AL-028]`

A matching color alone does **NOT** make an ACTIVE cell a valid final target.

- A **raw color candidate** is: valid index AND ACTIVE AND matching
  Scrubbot/palette color AND not caller-excluded/reserved.
- A **reachable/targetable final target** must *additionally* be currently
  reachable under canonical board-access semantics:
  - non-target ACTIVE cells **block** access/traversal;
  - CLEARED cells are **open** space;
  - gameplay background / outside-board free space is open;
  - the assigned ACTIVE target may be the route endpoint.
- A fully enclosed/blocked matching-color ACTIVE cell is **not targetable**
  until prior clears create legal access.

**Locked regression:** a fully enclosed matching-color ACTIVE cell must not
cause dispatch and must not be treated as a targetable final target. Example
(center red is matching but blocked by surrounding ACTIVE cells):

```text
R R B G Y
B G R Y P
G R Y B P
```

The neighborhood topology, route shape and movement language are now
**owner-selected (M17)**: the production movement language is **Organized/curved
on a deterministic grid-aware backbone** (OWNER_MOVEMENT_DECISION_V01, ADR-025).
A deterministic 4-neighbour grid planner establishes valid reachability + an
orthogonal path; a validity-preserving organized/curved post-process (bounded
shortcuts + controlled corner rounding) is the visual movement language. Direct
straight routing is **rejected** for production and kept only as a debug/baseline
comparison tool. Collision radius remains `[TO BE DESIGNED]` (M18+). This section
locks the semantic law; the production routing implementation is
`scripts/gameplay/routing/production_routing_system.gd`.

`TargetSelector` (M15, implemented) enforces this law at assignment time: it
consumes reachability/access truth as a narrow **injected** query
(`is_targetable(index)`), selects only a valid + ACTIVE + matching + unreserved
+ *targetable* candidate, and reserves it atomically. It fails closed (assigns
nothing) when no access truth is supplied, so a blocked/enclosed candidate is
never dispatched (ADR-023). Who computes that access truth stays M16/M17.

### Small-board readability

ACTIVE-vs-CLEARED must stay readable at native gameplay display size,
especially on 50×50 and 59×59 boards: an ACTIVE cell shows its opaque source
color, a CLEARED cell shows the background through a transparent hole. Owner
manual QA of the transparent model at every band + rectangular + narrow/tall
window (`tasks.md` SB-M10-005..011) is complete.

## Slots `[LOCKED]`

- **5** slots are active during the primary gameplay presentation.
- Each slot corresponds to a color/robot type.
- The player interacts with slots to dispatch Scrubbots.

## Scrubbot behavior `[LOCKED]`

- A Scrubbot leaves its slot **one at a time**, never in a batch burst tied
  to a single player action.
- A Scrubbot must **not** leave its slot unless the system has a target that
  is ALL of: ACTIVE, color-matching, valid, unreserved, and
  reachable/targetable under the access rule above. A raw color candidate
  that is blocked/unreachable is not sufficient.
- Once dispatched, a Scrubbot travels visually from its slot toward a
  specific target cell it has been assigned.
- On reaching its target, the target cell becomes **CLEARED** (transparent;
  background shows through), candidate/index truth updates, and any
  reservation clears.
- The Scrubbot then disappears/finishes its task.
- A Scrubbot does **not** pick up or carry the pixel color.
- A Scrubbot does **not** return to its slot after cleaning.

## Target selection vs. routing `[LOCKED — architectural rule]`

- **Target selection** (which cell a given Scrubbot is assigned to clean) and
  **routing** (the path/movement it takes to get there) are separate
  concerns and must remain separable in code. See
  `docs/02_TECH_ARCHITECTURE.md`.
- `RoutingSystem` (M16, implemented — CONTRACT only, ADR-024) defines HOW a
  routing implementation answers "give me a route to this already-assigned,
  already-reserved target," in a resolution-independent board-local cell
  coordinate space (board top-left `(0,0)`, one cell = 1×1 units, cell center
  `(x+0.5,y+0.5)`; slot origins may lie outside the board). A route starts at
  the slot origin, ends at the assigned target cell center, keeps the same
  target, and is validated segment-by-segment through an **injected** access
  query (`is_segment_traversable(from, to, target_index)`). No route is a
  first-class failure — routing **never** silently retargets and never calls
  TargetSelector.
- The production routing **algorithm** and movement language are
  owner-selected (M17-C002, ADR-025): `ProductionRoutingSystem`
  (`scripts/gameplay/routing/production_routing_system.gd`) subclasses the M16
  `RoutingSystem` contract with a deterministic grid-aware backbone plus a
  validity-preserving organized/curved post-process (conservative bounded
  shortcut + controlled corner rounding). `ProductionAccessQuery`
  (`scripts/gameplay/routing/production_access_query.gd`) is the canonical
  production access truth (ACTIVE blocks, CLEARED/outside open, target only as
  final endpoint). Direct straight routing is debug/baseline only. The M17
  experimental prototypes and the Routing Prototype Lab
  (`scripts/gameplay/routing/prototypes/`, `scenes/debug/`) are retained for
  diagnostics/comparison, not production. Collision radius stays
  `[TO BE DESIGNED]` (M18+).

## Win / lose condition `[TO BE DESIGNED]`

- The general shape (clear the board to win) is implied by the concept, but
  the precise win condition (timer? move limit? full clear only? partial
  clear threshold?) and any lose condition are not yet specified. Do not
  invent these; flag them for owner decision when the relevant milestone
  (M9) is reached.

## Difficulty progression `[TO BE DESIGNED]`

Not yet specified. Do not invent a curve or level-gating scheme.

## Consecutive win-streak reward mapping `[LOCKED]`

Reward depends on the **number of consecutive wins**, not on point
thresholds. The correct mapping is:

| Consecutive wins | Reward |
|---|---|
| 1 | 1 |
| 2 | 5 |
| 3 | 10 |
| 4 | 25 |
| 5 or more | 100 |

In functional form:

```text
reward(streak):
  streak == 1        -> 1
  streak == 2        -> 5
  streak == 3        -> 10
  streak == 4        -> 25
  streak >= 5        -> 100
```

**Do not** implement this incorrect mapping (kept here only as a documented
non-example, to prevent this exact mistake from recurring):

```text
WRONG: 1->1, 5->5, 10->10, 25->25, 5+->100
```

The economy around this reward (currency type, spend sinks, balancing) is
`[TO BE DESIGNED]`. This document only locks the reward *mapping*.

## Detailed economy / shop / monetization `[TO BE DESIGNED]`

Not in scope for this milestone or this document. See `CLAUDE.md` scope
rules — do not implement.
