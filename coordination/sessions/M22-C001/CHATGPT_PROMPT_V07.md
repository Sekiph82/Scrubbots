# M22-C001 V07 - Implement Post-Rail Interior-Turn Routing + Godot F5 Playable Entry Correction

Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Goal

Fix the owner-rejected targetability behavior discovered during F6 review and fix the obsolete Godot Run Project entry discovered during the same owner review.

There are two owner-observed defects in this V07 cycle:

1. **Routing / targetability:** current production routing is too restrictive after leaving Railroad V1. A target can be visually reachable through OPEN/CLEARED space after one or more 90-degree turns, yet the current straight-only post-rail model rejects it.
2. **Godot editor launch:** pressing **F5 / Run Project** opens the obsolete `SCRUBBOTS / Project Foundation OK` bootstrap instead of the current M22 Railroad playable experience. The Railroad demo works only when launched directly.

This is a focused production correction. Preserve accepted Railroad geometry, slot connector, TargetSelector WHAT-order, reservations, dispatcher and authenticated clearing architecture. Do not begin M23.

## Authoritative inputs

Read before editing:

- `TASKS.md` - read-only
- `CLAUDE.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`
- `coordination/OWNER_SCRUBBOT_RAILROAD_INTERIOR_PATH_DECISION_V01.md` - newest owner rule for post-rail movement
- `coordination/OWNER_CURRENT_PLAYABLE_ENTRY_DECISION_V01.md` - newest owner rule for Godot F5 / Run Project
- `coordination/sessions/M22-C001/OWNER_F6_REVIEW_V01.md`
- `coordination/sessions/M22-C001/CHATGPT_AUDIT_V06.md`
- `coordination/sessions/M22-C001/CHATGPT_AUDIT_CRITERIA_V07.md`

## 1. Safe start

1. Confirm repo exactly `Sekiph82/Scrubbots`, branch `main`.
2. Safely synchronize with current `origin/main`; no force push, destructive reset or clean.
3. Record exact start SHA.
4. Read all authoritative files above.
5. Inspect current `ProductionRoutingSystem`, `ProductionAccessQuery`, `ProductionTargetAccess`, `ScrubRailGeometry`, `RouteValidator`, TargetSelector and current Railroad tests.
6. Inspect `project.godot`, `scenes/app/main.tscn`, `scripts/app/main.gd`, and `scenes/demo/m22_slot_demo.tscn` before changing app entry behavior.
7. Do not modify root `TASKS.md`.
8. Do not begin M23 or unrelated UI/content work.
9. Spend zero Magnific/image-generation credits.

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
- `ProductionTargetAccess.is_targetable()` must naturally become true for a candidate whenever revised production routing can build a valid route;
- TargetSelector still chooses bottom-most then left-most among matching ACTIVE valid unreserved targetable cells.

Prefer reusing/adapting the existing deterministic interior BFS rather than introducing another access truth. `ProductionAccessQuery` and the shared `RouteValidator` remain authoritative.

For an already-selected target, evaluate legal rail-ingress + interior-route combinations and choose the shortest total legal route including the real slot connector and rail travel. Preserve `BOTTOM -> LEFT -> RIGHT -> TOP` as equal-total side tie-break. Make same-side ingress ties deterministic and document/test the rule.

## 3. Required routing tests

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

## 4. Fix Godot Editor / F5 Run Project behavior

Owner observed that normal Godot **F5 / Run Project** still launches the obsolete foundation/bootstrap screen from `scenes/app/main.tscn`, while direct PowerShell launch of `res://scenes/demo/m22_slot_demo.tscn` correctly opens Railroad V1.

Required correction:

- preserve the stable application entry path `res://scenes/app/main.tscn` unless there is a compelling, documented reason not to;
- make `main.tscn` a thin current-playable bootstrap/wrapper for the M22 Railroad experience;
- normal **F5 / Run Project** must show the same current M22 Hazard Bot + Railroad + five-slot experience used for owner acceptance;
- the obsolete `SCRUBBOTS / Project Foundation OK` diagnostics screen must no longer be the normal F5 result;
- direct launch of `res://scenes/demo/m22_slot_demo.tscn` must still work;
- opening `m22_slot_demo.tscn` and using **F6 / Run Current Scene** must still work;
- do not implement M23 screen architecture as part of this fix;
- prefer simple scene composition/forwarding rather than duplicating M22 gameplay construction inside app/main.

The old `scripts/app/main.gd` bootstrap code may remain unreferenced if deleting it is unnecessary. Do not keep obsolete diagnostics in the active owner-facing startup path merely for historical reasons.

Add automated/headless evidence that the project main scene reaches the M22 playable composition and exposes, at minimum:

- real Hazard Bot board;
- Railroad V1 presentation;
- exactly five SlotCell/Button instances.

Also run the project main scene headlessly long enough to prove no parse/script/runtime startup failure.

## 5. Preserve all accepted systems

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

## 6. Validation

Run and record literal commands/results/exits:

- `godot --version`
- `godot --headless --path . -s res://tests/run_tests.gd`
- new V07 focused routing evidence test(s)
- new V07 app-entry/F5-equivalent smoke test
- a literal headless project-main launch command proving `run/main_scene` boots into current M22 playable content without parse/script errors
- direct `m22_slot_demo.tscn` headless launch/smoke proving the explicit scene path still works
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

## 7. Commit / handoff

1. Review diff and confirm scope is limited to the routing correction, current app-entry/bootstrap correction, focused tests/evidence, and any directly required current docs.
2. Confirm root `TASKS.md` absent from diff.
3. Commit/push implementation first.
4. Record implementation SHA.
5. Create `coordination/sessions/M22-C001/CLAUDE_LOG_V07.md` afterward.
6. Log exact changed files, owner-observed routing defect, algorithm, deterministic tie behavior, route examples, Hazard Bot reproduction, app-entry change, F5-equivalent evidence, and all literal commands/results/exits.
7. State zero image-generation spend.
8. Push log separately and verify both commits visible on GitHub main.
9. Return only:

`AWAITING_AUDIT`

`https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M22-C001/CLAUDE_LOG_V07.md`

Do not claim PASS. ChatGPT audits. Owner F6 must be repeated after engineering acceptance, including a manual F5 / Run Project check from Godot.
