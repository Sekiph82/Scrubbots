# M21-C001 V07 — Owner Playtest Findings and Locked Routing Decision

Date: 2026-09-13
Owner: Şekip
Repository: `Sekiph82/Scrubbots`
Cycle: `M21-C001`
Status: **OWNER PLAYTEST FAILED FINAL M21 CLOSURE — V07 REQUIRED**

## 1. What the owner confirmed working

The owner manually ran `scenes/debug/m21_real_art_vertical_slice.tscn` in Godot after the V06 engineering audit and confirmed that the following are materially working:

- the real Hazard Bot artwork renders correctly;
- exactly five visible color slots are present;
- clicking a visible color slot dispatches a real Scrubbot from that slot's visible spawn anchor;
- the real targetability/clearing chain avoids arbitrary interior clears;
- the real clearing loop clears valid artwork cells to transparency over BG01;
- the V05/V06 visible slot/agent transform correction is working.

These accepted observations remain protected in V07.

## 2. F-M21-OWNER-001 — remove SPACE dispatch completely

The current owner-playable debug controller still contains a developer keyboard fallback:

- `step_one_clear()`;
- `_unhandled_input(KEY_SPACE)`;
- synthetic off-board origins.

The owner observed that SPACE-dispatched Scrubbots emerge from a board/screen side rather than from a visible color slot. That creates a second interaction/origin law and is no longer desired.

### Owner-locked rule

**Remove SPACE gameplay dispatch entirely from the M21 owner-playable scene.**

There must be one owner-facing gameplay activation path only:

```text
visible color slot click
→ real SlotView signal
→ real CompleteClearingLoop activation
→ real Scrubbot starts at the clicked SlotView spawn anchor
```

Do not replace SPACE with another hidden keyboard shortcut that dispatches gameplay work.

Headless tests may invoke narrow controller/test seams where needed, but owner-visible gameplay work must originate from the visible slot UI.

## 3. F-M21-OWNER-002 — current reachability defeats the intended bottom-left order

The current `TargetSelector` ordering itself is correct and must be preserved:

1. larger board-local `y` first (bottom-most);
2. smaller board-local `x` next (left-most);
3. deterministic index tie-break.

However, TargetSelector chooses only among candidates that the production routing/access layer reports as targetable.

On the fresh Hazard Bot board, the C08 bottom row is ACTIVE. A Scrubbot starting from a slot below the board cannot currently move laterally through a modeled outside walkway before entering a far-left perimeter target. A direct diagonal/straight approach toward the far-left target crosses intervening ACTIVE bottom-row cells and is correctly rejected. Therefore a nearer bottom target under/in front of the slot is reported targetable first. After that clear opens space, later bots visibly progress leftward.

That runtime behavior does not match the owner intention.

## 4. Owner-locked exterior walking corridor

Production routing must explicitly model a **one logical-cell-wide exterior walking corridor** around all four sides of every board.

### 4.1 Geometry

For board width `W` and height `H`, the real board cells occupy:

```text
x = 0 .. W-1
y = 0 .. H-1
```

The canonical exterior routing ring is exactly one logical cell thick:

```text
top:    y = -1, x = -1 .. W
bottom: y =  H, x = -1 .. W
left:   x = -1, y =  0 .. H-1
right:  x =  W, y =  0 .. H-1
```

The four corner corridor cells are included:

```text
(-1,-1), (W,-1), (-1,H), (W,H)
```

Route nodes may use each corridor cell centre:

```text
Vector2(cx + 0.5, cy + 0.5)
```

The exterior corridor is routing space only. It is not LevelData, not artwork, not BoardState, does not increase board dimensions, and never counts as a logical palette cell.

### 4.2 Start connector

A visible SlotView spawn anchor may lie farther than one cell outside the board. The route may use one access-valid connector segment from that exact slot origin to the one-cell exterior ring. After joining the ring, generated exterior traversal must stay on the ring until it legally enters a target/open board cell.

### 4.3 Required movement semantics

A Scrubbot may:

1. leave the clicked slot's exact spawn anchor;
2. connect to the exterior ring through outside/background space;
3. walk left/right/up/down around the ring, including corners;
4. enter an ordinary CLEARED perimeter cell where legal;
5. enter the assigned ACTIVE perimeter target only as final arrival;
6. continue through already-CLEARED/open board space under existing audited rules.

Non-target ACTIVE cells remain blockers. The ring must never make an enclosed interior ACTIVE cell reachable through solid ACTIVE artwork.

### 4.4 Width decision

V07 locks the corridor to **one logical cell**. The current agent is a lightweight point agent, so a second lane has no correctness value yet and would enlarge the routing search surface. Any future two-cell/multi-lane presentation is a separate owner decision.

## 5. Target-selection law remains unchanged

Do not weaken targetability and do not bypass ProductionTargetAccess merely to force a coordinate preference.

The law remains:

```text
among matching ACTIVE, unreserved, currently targetable candidates:
    choose highest y
    then lowest x
```

The fix belongs in production routing reachability/path construction.

## 6. Exact Hazard Bot acceptance

The fresh Hazard Bot is 20×20. Its entire bottom row is C08. Therefore after the exterior-corridor correction, clicking the visible C08 slot on a fresh board must make the first successful target:

```text
coordinate = (0,19)
index = 380
palette = C08 / local palette id 2
```

The owner must visibly see the Scrubbot leave the C08 slot, connect to the bottom exterior corridor, travel left outside the artwork to the far-left bottom cell, and enter that target without tunnelling through ACTIVE artwork.

If multiple C08 activations are accepted concurrently, reservations must make the subsequent bottom-row targets advance deterministically left-to-right (`381`, `382`, ... where still targetable), without duplicate assignment.

## 7. Protected behavior

V07 must preserve:

- the owner-approved Hazard Bot source bytes;
- V05/V06 visible SlotView anchor → agent spawn mapping;
- exactly five visible functional slots;
- per-assignment concurrency/active-slot bookkeeping;
- M15 strict selector safety, reservation and coherence rules;
- M19 dispatcher strict safety;
- M20 authenticated-arrival clearing authority;
- ACTIVE blocks / CLEARED opens semantics;
- no retarget inside RoutingSystem;
- rectangular boards and up-to-59×59 support.

M21 remains open until V07 is independently audited and the owner repeats the manual playtest successfully.
