# OWNER DECISION — Scrubbot Railroad V1

Date: 2026-09-14
Status: **OWNER-LOCKED**
Repository: `Sekiph82/Scrubbots`
Applies to: production gameplay routing/presentation beginning with M22-C001 V02

## 1. Purpose

Scrubbots must have a clear, branded, readable movement infrastructure around every pixel-art level. The owner approved a consistent **robotic cleaning railroad** surrounding the artwork. Scrubbots travel on this railroad and leave it only for the final orthogonal approach to their already-assigned target pixel.

This decision takes the useful perimeter-travel principle from observed reference behavior but defines an original SCRUBBOTS visual/movement language. External reference art/composition is not copied.

## 2. Canonical visual language

The production railroad is the **same core visual system for every level**. V1 does not theme or redesign the railroad per level artwork.

Visual direction:

- dark slate / metallic robotic cleaning rail;
- rounded mechanical corners;
- subtle cyan/electric guide lights or energy nodes;
- visually subordinate to the pixel art, not a competing illustration;
- modular/parametric so rectangular and variable-size boards use the same design language;
- optional local glow/trail under a moving Scrubbot may be added later as presentation polish without changing route truth;
- no level-specific railroad skin in V1 unless the owner later changes this decision.

The railroad is not part of C01..C16 pixel artwork and never changes LevelData palette counts or difficulty.

## 3. Canonical geometry

Board logical coordinates use boundaries `x=0..W`, `y=0..H`; board cell centres remain `x+0.5`, `y+0.5`.

Owner-locked V1 geometry:

- **minimum artwork-to-rail visual clearance: 2.0 logical cells**;
- V1 baseline clearance is exactly `2.0` logical cells;
- **rail visual width: 1.0 logical cell**;
- therefore the canonical rail centreline is `2.5` logical cells outside the board boundary.

Centreline coordinates for board `W × H`:

- TOP rail: `y = -2.5`, horizontal from `x = -2.5` to `x = W + 2.5`;
- BOTTOM rail: `y = H + 2.5`, horizontal from `x = -2.5` to `x = W + 2.5`;
- LEFT rail: `x = -2.5`, vertical from `y = -2.5` to `y = H + 2.5`;
- RIGHT rail: `x = W + 2.5`, vertical from `y = -2.5` to `y = H + 2.5`.

Corners are the four rail-centre intersections:

- `(-2.5, -2.5)`
- `(W+2.5, -2.5)`
- `(-2.5, H+2.5)`
- `(W+2.5, H+2.5)`

Rounded visual corners are allowed, but their motion path must remain inside the railroad envelope and may not cut diagonally through the artwork-clearance zone.

## 4. Slot connector law

The five production slots remain below the board/rail system.

For every clicked slot:

1. The Scrubbot starts from that exact SlotCell spawn anchor.
2. A presentation/routing connector joins the slot to the **BOTTOM railroad**.
3. The connector terminates at the bottom-rail centreline at the slot's mapped board-local `x`, clamped to the legal bottom-rail horizontal span only if necessary.
4. The connector is part of visible Scrubbot travel. There is no hidden teleport from slot to rail.
5. Slot connectors may not become target-selection logic.

The slot panel may be repositioned in the M22 integration harness so it sits below the railroad rather than inside the 2-cell artwork clearance.

## 5. Railroad travel law

After joining the railroad, the Scrubbot remains on the railroad during exterior travel.

It may:

- travel left/right on TOP or BOTTOM rail;
- travel up/down on LEFT or RIGHT rail;
- turn only through legal railroad corners;
- traverse multiple rail sides when needed.

It may **not**:

- leave the railroad early and cross exterior free space diagonally;
- use a straight diagonal shortcut from a slot to a distant rail location;
- cut across the two-cell artwork clearance to save distance;
- retarget based on route geometry;
- pass through a non-target ACTIVE board cell.

## 6. Exit / target-approach law

The target is selected first by TargetSelector. Routing then decides HOW to reach that already-selected target.

A Scrubbot may leave the railroad only at a rail point exactly aligned with the target:

- from TOP or BOTTOM rail, the exit point must share the target centre's **x / column**;
- from LEFT or RIGHT rail, the exit point must share the target centre's **y / row**.

The final approach from railroad to target is a straight **orthogonal** segment.

No diagonal final approach is legal.

The approach may pass through outside-board clearance and through board cells only when the accepted access truth says those cells/segments are traversable. A non-target ACTIVE cell remains a blocker. The assigned ACTIVE target may be the final endpoint. A cleared legal corridor may expose an interior target later.

If one side's aligned approach is blocked, routing may evaluate another aligned side for the **same target**. If no aligned side can legally reach that target, routing returns no route. It must never silently choose another target.

## 7. Route choice after target assignment

For the already-assigned target:

1. derive legal aligned exit candidates on TOP/BOTTOM/LEFT/RIGHT rail;
2. reject any candidate whose final orthogonal approach is invalid under authoritative access truth;
3. compute railroad travel distance from the slot's bottom-rail connector entry to each legal exit;
4. choose the shortest legal total rail route;
5. use a deterministic tie-break if distances are equal;
6. never change the assigned target.

V1 deterministic equal-distance tie-break order is:

`BOTTOM → LEFT → RIGHT → TOP`

This tie-break is HOW-only and does not affect TargetSelector's WHAT-order.

## 8. TargetSelector remains unchanged

Owner-locked target selection remains:

- requested matching color;
- ACTIVE;
- valid index;
- unreserved;
- currently targetable under authoritative access/routing truth;
- then positional priority: **bottom-most first, left-most within that row**.

The Railroad V1 change may affect whether a candidate is targetable because HOW has changed, but TargetSelector itself must not absorb railroad geometry or route planning.

## 9. Gameplay-truth boundaries

The railroad:

- is not a LevelData cell layer;
- is not BoardState;
- does not add logical artwork pixels;
- does not affect C01..C16 counts;
- does not change Difficulty V1 directly;
- does not own reservations;
- does not own target selection;
- does not clear cells;
- does not create slot quantities/cooldowns/refill rules.

Routing remains HOW. ReservationState remains assignment truth. CompleteClearingLoop/M20 remains authenticated clearing authority.

## 10. Implementation architecture target

M22 V02 should introduce one canonical geometry source rather than duplicating numbers across routing and UI.

Preferred shape:

- pure/data-oriented railroad geometry helper, e.g. `ScrubRailGeometry`;
- ProductionRoutingSystem consumes that geometry for exterior travel;
- reusable presentation component, e.g. `ScrubRailView`, consumes the same geometry contract;
- slot connector presentation/routing uses the same geometry;
- board/presentation scaling maps logical railroad coordinates through the existing board-local transform.

The names may differ if the implementation documents an equivalent single-source geometry contract.

## 11. Supersession of M21 one-cell adjacent corridor

M21 V07–V10 proved the previous one-cell adjacent exterior-ring solution and remains valid historical audit evidence for those commits.

For **future production behavior after this owner decision**, the exact adjacent ring geometry is superseded by Railroad V1:

- M21's target ordering, reservation, slot-click-only, no-tunnelling and authenticated-clear invariants remain locked;
- the previous exact `x=-1 / x=W / y=-1 / y=H` exterior travel lane is no longer the desired final production movement geometry;
- historical audit files/logs are not rewritten;
- current regression tests that assert obsolete exact ring coordinates must be migrated/versioned deliberately while preserving their safety intent.

## 12. Variable-size / responsive law

Railroad geometry is derived from board `W/H` and logical cell scale. It must support:

- square and rectangular boards;
- 20..59 engine envelope;
- 59×59 maximum;
- the production responsive portrait matrix;
- the same 2-cell logical clearance regardless of physical pixel resolution.

The rail may visually shrink in physical pixels as logical cell size shrinks, but the logical geometry does not change.

## 13. Concurrency / congestion

Multiple Scrubbots may currently occupy/cross the same railroad path. Collision avoidance, queuing, lane separation and congestion styling remain design-gated and are **not** invented by Railroad V1.

Railroad V1 must preserve existing rapid dispatch and reservation correctness.

## 14. V02 visual acceptance target

The M22 demo must visibly show:

- the real pixel artwork;
- at least two logical cells of breathing room around it;
- the same reusable robotic rail on all four sides;
- rounded rail corners;
- exactly five slots below the rail;
- a connector from each clicked slot toward the bottom rail;
- Scrubbot travel from clicked slot → connector → railroad → aligned exit → target;
- no diagonal exterior shortcut;
- no early rail departure;
- first fresh Hazard Bot C08 still resolves naturally to target `380 / (0,19)` and approaches it from a legal aligned rail exit.

Owner visual review follows successful strict engineering audit.
