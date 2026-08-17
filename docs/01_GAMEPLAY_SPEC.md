# 01 — Gameplay Specification

Status tags used below:

- `[LOCKED]` — specified by the project owner. Do not reinterpret or change
  silently. Changes require explicit owner sign-off (see `CLAUDE.md` rule 3).
- `[TO BE DESIGNED]` — intentionally undefined. Do not invent a final design;
  propose options instead when the milestone requires it.

## Board `[LOCKED]`

- Logical grid: **40 × 40** cells = **1,600 cells** exactly.
- Grid is logical/data, independent of physical screen size or zoom.
- Each cell has (at minimum): index, x, y, color id, cleaned/uncleaned state,
  available/unavailable state.

## Slots `[LOCKED]`

- **5** slots are active during the primary gameplay presentation.
- Each slot corresponds to a color/robot type.
- The player interacts with slots to dispatch Scrubbots.

## Scrubbot behavior `[LOCKED]`

- A Scrubbot leaves its slot **one at a time**, never in a batch burst tied
  to a single player action.
- A Scrubbot must **not** leave its slot if there is no valid cleaning work
  currently available for it (no matching uncleaned/available cell).
- Once dispatched, a Scrubbot travels visually from its slot toward a
  specific target cell it has been assigned.
- On reaching its target, the target cell is cleaned/revealed.
- The Scrubbot then disappears/finishes its task.
- A Scrubbot does **not** pick up or carry the pixel color.
- A Scrubbot does **not** return to its slot after cleaning.

## Target selection vs. routing `[LOCKED — architectural rule]`

- **Target selection** (which cell a given Scrubbot is assigned to clean) and
  **routing** (the path/movement it takes to get there) are separate
  concerns and must remain separable in code. See
  `docs/02_TECH_ARCHITECTURE.md`.
- The actual routing/pathing algorithm is `[TO BE DESIGNED]` in a later task.
  The current milestone only establishes the seam between the two systems.

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
