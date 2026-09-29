# OWNER DECISION — SCRUBBOT RAILWAY-FIRST ROUTING V02

Date: 2026-09-29
Status: **OWNER-LOCKED CURRENT**
Repository: `Sekiph82/Scrubbots`
Applies to: production Scrubbot Railroad V1 route choice
Authority source: M28-C002-C003-R01 V02 owner remediation

## Supersession

This decision supersedes only the **route-choice preference** in:

- `coordination/OWNER_SCRUBBOT_RAILROAD_INTERIOR_PATH_DECISION_V01.md` §5 where it required the shortest total legal route;
- the matching "shortest total legal route" wording in `CLAUDE.md` §8.10B.

All other Railroad V1 geometry, legal-access, target-selection, reservation, claim, clearing and no-retarget rules remain in force.

## Current runtime rule

For an already-assigned target, production Scrubbot travel is **railway-first**.

Required route behavior:

1. start at the exact owning SlotCell anchor;
2. join the canonical bottom rail through the slot connector;
3. remain on the canonical perimeter rail as long as possible;
4. choose a legal rail exit / ingress that minimises the required board-interior travel to the assigned target;
5. only then enter the board for the shortest legal final interior approach;
6. if the aligned/nearest ingress is blocked, use the nearest legal ingress measured by legal orthogonal interior path distance;
7. interior movement remains four-neighbour orthogonal through OPEN/CLEARED cells; 90-degree turns are allowed when obstacles require them;
8. non-target ACTIVE cells remain blockers and the assigned ACTIVE target is enterable only as the final endpoint;
9. no diagonal, corner cut, teleport, free-space exterior shortcut or retarget.

On an open board, this means the Scrubbot follows the rail to the side/point nearest the target and then makes only the short aligned final approach.

## Deterministic route ranking

Runtime route preference is lexicographic:

1. least board-interior travel;
2. then least connector + rail + ingress travel;
3. then canonical side priority `BOTTOM -> LEFT -> RIGHT -> TOP`;
4. then stable same-side perimeter scan order;
5. then deterministic interior neighbour order.

Implementation may use a mathematically equivalent weighted-cost representation while the supported board envelope guarantees the first term dominates the second.

## WHAT vs HOW remains unchanged

This decision changes **HOW** only.

It must not change:

- TargetSelector WHAT-order;
- bottom-most / left-most target priority;
- target eligibility;
- claim identity;
- ReservationState ownership;
- batch FIFO/conservation;
- authenticated clearing identity/order guarantees;
- completion truth;
- economy.

## Solver / analysis relationship

Solver and difficulty-analysis tooling may retain an equal-weight legal-route metric for previously accepted proof/measurement evidence **only if**:

- it searches the exact same legal graph/access truth;
- positive route weights cannot change reachability/targetability;
- production target/claim/clear truth is proven identical;
- the analysis route metric is never presented as the live Scrubbot's visual runtime path.

Runtime gameplay uses the railway-first preference in this V02 decision.

## Validation

The production implementation must cover representative:

- left;
- right;
- top;
- bottom;
- deep interior;
- corner/corner-adjacent;
- blocked nearest/aligned ingress

targets and prove:
- nearest legal exit behavior;
- no diagonal exterior/interior shortcut;
- same assigned targets/claims/clears;
- exactly-once full-board completion on representative real production content.

Independent audit:
`coordination/sessions/M28-C002-C003-R01/CHATGPT_AUDIT_V02.md`

Verdict:
`AUDITED_PASS / OWNER FINAL REPLAY REQUIRED`
