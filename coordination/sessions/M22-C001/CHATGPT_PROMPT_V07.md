# M22-C001 V07 — Implement Post-Rail Interior-Turn Routing Correction

Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Goal

Fix the owner-rejected targetability behavior discovered during F6 review. The current production route considers a target reachable mainly when the final post-rail approach can be one straight orthogonal rail-to-target segment. The owner clarified that this is too restrictive.

After a Scrubbot leaves Railroad V1 at a legal ingress into OPEN/CLEARED gameplay space, it must be able to continue through that open corridor with orthogonal four-neighbour movement and one or more 90-degree turns before reaching the already-assigned ACTIVE target.

This is a narrow production routing correction. Preserve the accepted Railroad geometry, slot connector, TargetSelector WHAT-order, reservations, dispatcher and authenticated clearing architecture.

## Authoritative inputs

Read before editing:

- `TASKS.md` — read-only
- `CLAUDE.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`
- `coordination/OWNER_SCRUBBOT_RAILROAD_INTERIOR_PATH_DECISION_V01.md` — newest owner rule for post-rail movement
- `coordination/sessions/M22-C001/OWNER_F6_REVIEW_V01.md`
- `coordination/sessions/M22-C001/CHATGPT_AUDIT_V06.md`
- `coordination/sessions/M22-C001/CHATGPT_AUDIT_CRITERIA_V07.md`

## 1. Safe start

1. Confirm repo exactly `Sekiph82/Scrubbots`, branch `main`.
2. Safely synchronize with current `origin/main`; no force push, destructive reset or clean.
3. Record exact start SHA.
4. Read the authoritative files above and inspect current `ProductionRoutingSystem`, `ProductionAccessQuery`, `ProductionTargetAccess`, `ScrubRailGeometry`, `RouteValidator`, TargetSelector and current Railroad tests.
5. Do not modify root `TASKS.md`.
6. Do not begin M23 or unrelated UI/content work.
7. Spend zero Magnific/image-generation credits.

## 2. Correct the routing model

The current owner-approved movement model is now:

`clicked SlotCell anchor -> visible BOTTOM connector -> Railroad V1 exterior travel -> legal rail ingress -> orthogonal OPEN/CLEARED interior corridor, turns allowed -> assigned target`

Required invariants:

- exact clicked slot anchor remains the route start;
- connector still joins BOTTOM rail visibly;
- exterior movement stays on canonical rail sides/corners only;
- rail exit no longer has to be directly aligned with the final target;
- a legal rail exit/ingress may connect to OPEN/CLEARED perimeter gameplay space;
- after ingress, use grid-aware four-neighbour orthogonal routing through OPEN/CLEARED cells;
- 90-degree turns are allowed after ingress;
- non-target ACTIVE cells remain hard blockers;
- assigned ACTIVE target may be entered only as final arrival;
- no diagonal, corner cut, teleport or free-space shortcut;
- no retargeting;
- `ProductionTargetAccess.is_targetable()` must naturally become true for a candidate whenever this revised production routing can build a valid route;
- TargetSelector still chooses bottom-most then left-most among matching ACTIVE valid unreserved targetable cells.

Prefer reusing/adapting the existing deterministic interior BFS rather than introducing another access truth. `ProductionAccessQuery` and shared `RouteValidator` remain authoritative.

For an already-selected target, evaluate legal rail ingress + interior route combinations and choose the shortest total legal route including real slot connector and rail travel. Preserve `BOTTOM -> LEFT -> RIGHT -> TOP` as equal-total side tie-break. Make same-side ingress ties deterministic and document/test the rule.

## 3. Required tests

Add focused tests that reproduce the actual missing behavior, not merely helper-unit behavior.

At minimum prove:

1. existing straight BOTTOM-to-target route still works;
2. BOTTOM rail -> ingress -> up -> LEFT turn -> target works;
3. mirrored RIGHT turn works;
4. at least one path with two interior 90-degree turns works;
5. making one required corridor cell ACTIVE makes that target untargetable/no-route;
6. diagonal-only apparent gap remains blocked;
7. no alternate target is substituted when the assigned target cannot route;
8. route trace proves exterior travel stays rail-only and every interior segment is orthogonal;
9. rectangular board works;
10. 59x59 works.

Also add a deterministic real Hazard Bot or derived-state regression for the owner-observed class: a side-offset matching cell that the old straight-only rule rejected but which is reachable after rail ingress and a 90-degree turn through cleared/open cells. Persist exact target index/coordinate, corridor cells and route points.

Fresh-level C08 should remain natural target `380/(0,19)` under unchanged WHAT-order unless the new reachability legitimately exposes a higher-priority candidate. If that changes, do not silently rewrite the expected target. Log the exact newly targetable candidate set/order and stop for audit.

## 4. Preserve all accepted systems

Do not weaken or bypass:

- `ScrubRailGeometry` canonical 2.0 clearance / 1.0 width / 2.5 centerline geometry;
- exact slot-to-BOTTOM connector law;
- rail-only exterior movement;
- ReservationState ownership;
- TargetSelector color/state/reservation/order rules;
- Dispatcher one-assignment semantics;
- CompleteClearingLoop authenticated clear;
- reset/rapid-input cleanup;
- rectangular / 59x59 support.

Do not revive the old M21 adjacent-ring exterior lane. Interior BFS after a legal Railroad ingress is not permission to use the superseded exterior ring.

## 5. Validation

Run and record literal commands/results/exits:

- `godot --version`
- `godot --headless --path . -s res://tests/run_tests.gd`
- new V07 focused routing evidence test(s)
- V06 real-demo state evidence
- V05 final state evidence
- V04 final evidence
- V03 connector evidence
- Railroad responsive smoke
- V01 responsive/component smoke
- M21 real-art full-clear smoke
- M21 V10 reservation evidence
- required M20 lifecycle/clearing smokes
- `git diff --check`

Any old test whose only assertion is the now-superseded straight-target-aligned post-rail rule may be updated, but identify it explicitly in the log and preserve its safety intent.

## 6. Commit / handoff

1. Review diff and confirm scope is routing/access-related production code plus focused tests/evidence only.
2. Confirm root `TASKS.md` absent from diff.
3. Commit/push implementation first.
4. Record implementation SHA.
5. Create `coordination/sessions/M22-C001/CLAUDE_LOG_V07.md` afterward.
6. Log exact changed files, owner-observed defect, algorithm, deterministic tie behavior, route examples, Hazard Bot reproduction, all literal commands/results/exits, zero image-generation spend.
7. Push log separately and verify both commits visible on GitHub main.
8. Return only:

`AWAITING_AUDIT`

`https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M22-C001/CLAUDE_LOG_V07.md`

Do not claim PASS. ChatGPT audits. Owner F6 must be repeated after engineering acceptance.
