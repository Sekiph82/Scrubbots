# M21-C001 V04 — Owner Manual-Playtest Decisions

Date: 2026-09-13
Status: **OWNER-LOCKED for V04 implementation/audit**
Repository: `Sekiph82/Scrubbots`

This file records owner decisions produced by manually running `scenes/debug/m21_real_art_vertical_slice.tscn` in Godot after M21-C001 V03 implementation. These decisions supersede the earlier unresolved target-selection heuristic and extend the final M21 owner-playable acceptance surface.

## 1. What the owner manually observed

The current real-art vertical slice successfully demonstrates that:

- the Hazard Bot artwork renders correctly;
- clearing starts from an actually targetable/reachable part of the artwork rather than deleting an arbitrary interior cell;
- target selection and CompleteClearingLoop behavior appear functionally sound;
- ACTIVE cells clear to transparency and BG01 shows through.

The owner also observed three missing/undesired behaviors:

1. target clearing currently begins from the upper part of the artwork;
2. no visibly moving Scrubby/Scrubbot can be seen during the route;
3. the five-slot system exists logically but is not visible in the playable scene.

## 2. Owner-locked TargetSelector priority

Eligibility rules do not change. A target is selectable only when it is:

- a valid board index;
- ACTIVE;
- the requested color;
- not reserved;
- currently targetable/reachable according to the authoritative injected access truth.

Among all candidates that satisfy those requirements, deterministic priority is now:

1. **bottom-most first**: largest board-local `y` coordinate;
2. **left-most within that row**: smallest board-local `x` coordinate;
3. deterministic index tie-break if ever needed.

Canonical BoardState coordinates increase downward, so larger `y` means visually lower on the artwork.

This is a **TargetSelector WHAT-policy**. It must not be implemented as a RoutingSystem heuristic. Routing still receives one already-selected target and decides only HOW the Scrubbot travels there.

A geometrically high-priority candidate that is blocked/unreachable must never be chosen. Selection continues through the deterministic bottom-to-top / left-to-right priority until the first truly targetable candidate is found.

The previous ascending row-major baseline is superseded by this owner decision.

## 3. Visible Scrubbot / presentation transform

ScrubbotAgent movement truth remains in board-local cell coordinates. Do not multiply production route coordinates by screen pixels inside gameplay/routing/agent truth.

The presentation layer must map the agent to screen space using the same board origin and cell scale as the rendered board. A preferred shape is a shared presentation hierarchy such as:

```text
BoardPresentationRoot
├── BoardRenderer
└── AgentLayer
    └── ScrubbotAgent(s)
```

Equivalent architecture is allowed if tests prove exact alignment.

Required result in the Godot owner-playtest scene:

- the debug Scrubbot marker is plainly visible at normal game-window scale;
- it begins from the visible slot/spawn origin or a clearly corresponding presentation origin;
- it traverses the real route toward the selected target;
- its final position visually agrees with the target cell center;
- clearing happens on authenticated arrival as before;
- movement truth remains board-local and independent of physical phone resolution.

The current debug circle is acceptable for this V04 functional proof. Final Scrubbot production art remains the later character-visual milestone unless separately owner-approved.

## 4. Five visible slots now required

The final M21 owner-playable vertical slice must show the existing five logical slots on screen.

Minimum V04 slot presentation requirements:

- exactly five visible slot components;
- each slot is bound to a real SlotSystem slot, not duplicated UI-only state;
- each slot visibly communicates its bound level-palette color;
- owner/dev can activate the intended slot from the visible UI in the desktop Godot playtest;
- activation enters the existing CompleteClearingLoop / dispatcher path, not a parallel debug clear shortcut;
- the slot/spawn presentation supplies a coherent Scrubbot origin for routing/presentation;
- active/in-flight state is visibly distinguishable;
- native Godot controls/components are used, not a flattened screenshot;
- dynamic state/color remains live in Godot;
- the five-slot bar remains readable with the 20x20 M21 board in the current portrait reference viewport.

The SPACE-key debug step may remain as a developer fallback, but it does not replace the visible five-slot interaction proof.

## 5. Scope boundaries

V04 must not use these owner decisions as permission to:

- merge TargetSelector and RoutingSystem;
- change ACTIVE/CLEARED semantics;
- change reservation ownership rules;
- change M19/M20 dispatcher/clearing authority without a proven blocker;
- redesign Difficulty V1;
- implement Level Factory generation;
- implement PixelLab runtime integration;
- invent final Scrubbot character art;
- build unrelated Home/Results/economy/progression UI;
- generate speculative Magnific assets.

## 6. Final owner acceptance target

At the end of V04 the owner should be able to run the real-art Godot scene and visibly confirm this flow:

```text
five visible color slots
→ activate a color slot
→ TargetSelector chooses the bottom-most, then left-most currently reachable matching pixel
→ a visible Scrubbot leaves from the slot/presentation origin
→ it follows the real production route over the board
→ authenticated arrival clears exactly that target to transparency
→ another activation continues from the next bottom/left reachable target
```

That owner-visible flow is required before M21 strict final closure.
