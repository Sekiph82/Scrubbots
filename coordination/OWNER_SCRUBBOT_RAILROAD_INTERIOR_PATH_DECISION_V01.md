# OWNER DECISION — Scrubbot Railroad Interior Path Revision V01

Date: 2026-09-17
Status: **OWNER-LOCKED**
Repository: `Sekiph82/Scrubbots`
Applies to: M22 Railroad V1 production routing after owner F6 review
Supersedes: only the target-approach restrictions in sections 6–8 of `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md` where they required rail departure to be directly target-aligned and the entire post-rail approach to be one straight segment.

## 1. Owner clarification from F6 review

The owner rejected the behavior where a matching target is considered targetable only when a Scrubbot can leave the railroad and travel in one straight orthogonal segment directly to that target.

Required behavior:

- the Scrubbot still starts from the exact clicked SlotCell anchor;
- it still joins the BOTTOM railroad through the visible slot connector;
- exterior travel still stays on the Railroad V1 loop and turns only at railroad corners;
- however, after leaving the railroad at a legal ingress into currently open gameplay space, the Scrubbot may continue through OPEN/CLEARED board space using an orthogonal path with one or more 90-degree turns;
- the path may turn left/right/up/down inside the open corridor before reaching the already-selected target;
- no diagonal movement or corner cutting is allowed;
- non-target ACTIVE cells remain blockers;
- the assigned ACTIVE target is enterable only as the final cell/endpoint;
- no retarget is allowed.

Concrete F6 example: if a red target cannot be reached by a straight BOTTOM-rail-to-target segment but can be reached by leaving the BOTTOM rail, moving upward through cleared/open cells, then turning left or right through cleared/open cells, that target MUST be considered targetable.

## 2. Revised targetability law

A matching ACTIVE candidate is targetable when there exists at least one legal route from the clicked slot origin satisfying all of the following:

1. exact slot anchor -> BOTTOM rail connector;
2. rail-only exterior travel on the canonical Railroad V1 geometry;
3. a legal rail-to-board ingress into OPEN/CLEARED space;
4. an orthogonal interior path through OPEN/CLEARED cells, with 90-degree turns allowed;
5. final arrival into the assigned ACTIVE target;
6. no traversal through any other ACTIVE cell;
7. no diagonal shortcut, corner cut, teleport, or retarget.

TargetSelector WHAT-order remains unchanged: requested matching color, ACTIVE, valid, unreserved, targetable; then bottom-most, left-most.

## 3. Rail ingress law

Rail departure is no longer restricted to a point directly aligned with the final target.

A legal ingress may occur from any Railroad V1 side when it connects orthogonally into an OPEN/CLEARED perimeter cell/corridor under authoritative access truth. The route may then turn inside the board/open corridor.

The rail itself remains exterior-only movement infrastructure. Interior movement begins only after a legal ingress.

## 4. Interior path law

Interior post-rail movement is grid-aware and orthogonal:

- four-neighbour movement only;
- 90-degree turns allowed;
- OPEN/CLEARED cells traversable;
- outside-board free space remains open only where used by the connector/rail/ingress geometry;
- non-target ACTIVE cells blocked;
- target ACTIVE cell permitted only for final arrival;
- no diagonal edge or corner squeeze through blockers.

The implementation should reuse authoritative `ProductionAccessQuery` truth and existing route validation rather than create a second contradictory access model.

## 5. Route choice

Routing remains HOW-only after TargetSelector has chosen the target.

For that assigned target, routing should evaluate legal railroad ingress + interior path combinations and choose the shortest legal total route measured from the real clicked-slot start:

`slot connector + railroad travel + ingress bridge + interior orthogonal path + final target arrival`.

Equal-distance routing must remain deterministic. Preserve the existing side priority `BOTTOM -> LEFT -> RIGHT -> TOP` as the first tie-break dimension. Within the same side, use a stable deterministic ingress ordering documented by the implementation/tests.

## 6. Preserved Railroad V1 rules

Unchanged:

- 2.0 logical-cell artwork-to-rail clearance;
- 1.0 logical-cell rail width;
- 2.5 logical-cell rail centerline offset;
- same reusable four-side robotic rail;
- exact clicked-slot connector to BOTTOM rail;
- exterior travel rail-only;
- side changes on the rail only at canonical corners;
- no exterior free-space diagonal shortcut;
- no retarget;
- ReservationState / dispatcher / authenticated clearing authority unchanged;
- rectangular boards / 20..59 / 59x59 support;
- zero dependence on generated-image credits.

## 7. F6 consequence

Owner F6 is **REJECTED / CHANGES REQUIRED** for the current production behavior because side-offset targets that are reachable through a cleared orthogonal corridor after rail ingress are incorrectly classified as untargetable.

A new M22 production correction cycle must implement and prove this revised route/targetability behavior before owner F6 is repeated.
