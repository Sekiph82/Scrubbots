# M22-C001 V07 - Post-Rail Interior-Turn Routing + Godot F5 Playable Entry Correction Criteria

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Purpose: correct owner-rejected straight-only post-rail targetability and obsolete Godot Run Project startup while preserving accepted Railroad V1 geometry, reservations and clearing behavior.

Authoritative owner revisions:

- `coordination/OWNER_SCRUBBOT_RAILROAD_INTERIOR_PATH_DECISION_V01.md`
- `coordination/OWNER_CURRENT_PLAYABLE_ENTRY_DECISION_V01.md`

## A. Governance

- **M22-V07-001** Work only in `Sekiph82/Scrubbots` on `main`.
- **M22-V07-002** Safe fast-forward/sync only; no destructive reset/clean/force-push.
- **M22-V07-003** Root `TASKS.md` is read-only for Claude.
- **M22-V07-004** Read the V06 audit, F6 review, original Railroad V1 owner decision, interior-path owner revision and current-playable-entry owner decision before editing.
- **M22-V07-005** No M23 work, no unrelated visual/content generation, zero Magnific/image-generation credits.
- **M22-V07-006** Preserve accepted ReservationState, TargetSelector ordering, dispatcher and CompleteClearingLoop ownership boundaries.

## B. Revised reachability / route semantics

- **M22-V07-010** A target may be targetable even when no single straight rail-to-target segment exists.
- **M22-V07-011** Slot start remains exact laid-out SlotCell spawn anchor -> visible BOTTOM connector -> canonical Railroad V1.
- **M22-V07-012** Exterior travel remains rail-only and side changes occur only at canonical rail corners.
- **M22-V07-013** Rail departure may occur at a legal ingress aligned to OPEN/CLEARED board space, not necessarily aligned with the final target.
- **M22-V07-014** After ingress, the route may traverse OPEN/CLEARED board cells with four-neighbour orthogonal movement and one or more 90-degree turns.
- **M22-V07-015** Non-target ACTIVE cells remain blocked.
- **M22-V07-016** Assigned ACTIVE target is enterable only as final arrival.
- **M22-V07-017** No diagonal segment, corner cut, teleport or free-space shortcut is introduced.
- **M22-V07-018** No retarget. Routing computes HOW only for the already-selected target.
- **M22-V07-019** TargetSelector WHAT ordering remains bottom-most, then left-most among matching ACTIVE valid unreserved targetable cells.

## C. Route construction / choice

- **M22-V07-020** Reuse canonical `ScrubRailGeometry` for rail geometry.
- **M22-V07-021** Reuse authoritative `ProductionAccessQuery` / shared route validation for OPEN/CLEARED/ACTIVE truth.
- **M22-V07-022** Do not create a contradictory second access model.
- **M22-V07-023** For an assigned target, evaluate legal rail-ingress + orthogonal interior-path combinations.
- **M22-V07-024** Total route cost includes connector + rail travel + ingress + interior path + final arrival.
- **M22-V07-025** Choose shortest legal total route.
- **M22-V07-026** Equal total-length side tie preserves `BOTTOM -> LEFT -> RIGHT -> TOP`; same-side ingress ties are deterministic and documented.
- **M22-V07-027** Returned route is fully RouteValidator-clean.

## D. Required routing regression fixtures

- **M22-V07-030** Straight BOTTOM-to-target case still succeeds.
- **M22-V07-031** Target requiring `BOTTOM rail -> ingress -> up -> LEFT turn -> target` succeeds.
- **M22-V07-032** Mirrored `BOTTOM rail -> ingress -> up -> RIGHT turn -> target` succeeds.
- **M22-V07-033** Target requiring at least two interior 90-degree turns through CLEARED cells succeeds.
- **M22-V07-034** Same geometry with one required corridor cell ACTIVE fails targetability / route.
- **M22-V07-035** Diagonal-only apparent opening remains illegal.
- **M22-V07-036** No alternate target is silently substituted when the selected target has no legal route.
- **M22-V07-037** Route point sequence/classification proves exterior segments stay on rail and interior segments are orthogonal.
- **M22-V07-038** Rectangular board coverage.
- **M22-V07-039** 59x59 coverage.

## E. Real Hazard Bot / owner-observed behavior

- **M22-V07-040** Add a deterministic real-level or derived-state regression reproducing the owner-observed side-offset reachability class from Hazard Bot.
- **M22-V07-041** Demonstrate a matching target rejected by the old straight-only rule but reachable after rail ingress + 90-degree turn is now targetable.
- **M22-V07-042** Log exact target index/coordinate, route points and cell-state corridor used.
- **M22-V07-043** Preserve fresh-level C08 natural first target `380 / (0,19)` unless revised targetability legitimately exposes a higher-priority target under unchanged TargetSelector ordering. If target order changes, report exact candidate list/coordinates and stop for audit rather than hiding it.

## F. Godot Editor / F5 current playable entry

- **M22-V07-070** Normal project startup must no longer present the obsolete `SCRUBBOTS / Project Foundation OK` screen as the owner-facing F5 result.
- **M22-V07-071** Preserve `res://scenes/app/main.tscn` as the stable project entry path unless a different solution is explicitly justified in the log.
- **M22-V07-072** `main.tscn` must act as a thin wrapper/composition for the current M22 playable Railroad experience, not duplicate the gameplay construction logic.
- **M22-V07-073** Godot **F5 / Run Project** equivalent startup must expose the real Hazard Bot board, Railroad V1 presentation and exactly five SlotCell/Button instances.
- **M22-V07-074** Direct `res://scenes/demo/m22_slot_demo.tscn` launch remains valid.
- **M22-V07-075** Opening `m22_slot_demo.tscn` and using **F6 / Run Current Scene** remains valid.
- **M22-V07-076** Do not implement M23 gameplay-screen architecture as part of the app-entry correction.
- **M22-V07-077** Add a headless app-entry smoke that proves the project main scene reaches the M22 playable composition.
- **M22-V07-078** Literal headless project-main startup exits cleanly / can be terminated cleanly with no SCRIPT ERROR, parse error or startup failure.
- **M22-V07-079** The old foundation bootstrap may remain as unreferenced historical code, but it must not be the normal Run Project path.

## G. Non-regression

- **M22-V07-050** Full root suite passes with exact check/failure count and exit 0.
- **M22-V07-051** V03/V04/V05/V06 Railroad evidence remains green unless a test encodes the superseded straight-only rule; any changed test must be explicitly identified and justified.
- **M22-V07-052** M21 real-art full clear remains PASS.
- **M22-V07-053** M21 V10 reservation evidence remains PASS except historical exact geometry assertions already classified superseded.
- **M22-V07-054** Required M20 lifecycle smokes remain PASS.
- **M22-V07-055** Rapid dispatch / reservation uniqueness / reset cleanup remain green.
- **M22-V07-056** `git diff --check` clean.
- **M22-V07-057** Direct M22 demo launch and project-main launch both remain free of parse/script errors.

## H. Scope proof / handoff

- **M22-V07-060** Record exact starting SHA and implementation SHA.
- **M22-V07-061** List every changed production/test/app-entry file.
- **M22-V07-062** Root `TASKS.md` absent from Claude diff.
- **M22-V07-063** No image-generation spend.
- **M22-V07-064** Persist literal validation commands/results/exits.
- **M22-V07-065** Explicitly document how `main.tscn` now reaches the M22 playable scene and why this remains a thin temporary/current-playable bootstrap rather than M23 implementation.
- **M22-V07-066** Create `CLAUDE_LOG_V07.md` only after implementation commit exists, push separately, and hand back `AWAITING_AUDIT`.

## I. Closure rule

V07 passes only if both owner-observed problems close together:

1. legal post-rail orthogonal traversal through OPEN/CLEARED corridors with 90-degree turns works while rail, blocker, no-retarget, reservation and authenticated-clear invariants remain intact;
2. normal Godot Run Project/F5 reaches the current M22 Railroad playable experience instead of the obsolete project-foundation screen, while direct demo launch remains valid.

Owner F6 must be repeated after engineering acceptance and must include an actual Godot F5 / Run Project check.
