# M22-C001 V07 — Post-Rail Interior-Turn Routing Correction — Claude Log

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude (implementer/test runner)
Engine: Godot `4.7.2.stable.official.ed1daf0bf` (unchanged)
Owner contract: `coordination/OWNER_SCRUBBOT_RAILROAD_INTERIOR_PATH_DECISION_V01.md`
(supersedes only the straight-only target-approach in §6–8 of the original Railroad decision)
Handoff state: `AWAITING_AUDIT`

This is a narrow production routing correction (owner F6 rejection of straight-only
post-rail targetability). No `TASKS.md`, historical M21 evidence, or M23 work.

## 1. Commit identities

- **Starting `origin/main` SHA:** `84837cc43dde414707f2c9aff61c406bea7a833c`.
- **V07 implementation SHA:** `b2ba61b0acc4c992ab9774f69c1249ac4fd146b7`
  (`feat(M22-C001 V07): post-rail interior orthogonal turning`) — pushed before this log.
- **This log** is a separate evidence commit on top of the implementation SHA.

Sync: fast-forward `10adfad..84837cc`; owner-local `project.godot` + untracked
`.import`/`.uid` sidecars preserved (left unstaged); no force/reset/clean.

## 2. Changed files (implementation commit b2ba61b)

- `scripts/gameplay/routing/production_routing_system.gd` — `_railroad_route`
  rewritten for post-rail interior turning; added `_rank_lt` + a small binary
  min-heap (`_heap_less/_heap_push/_heap_pop`); enclosed-target fast-fail.
- `tests/run_tests.gd` — added `_run_m22_v07_interior_turn_tests` (+ helpers
  `_v07_dirs/_v07_has_seq/_v07_turn_count/_v07_clear`), registered in `_initialize`.

Root `TASKS.md` absent from the diff. Owner-local `project.godot` NOT staged.
`.uid` files are engine-generated and untracked (never committed in this repo).

## 3. Owner-observed defect

F6 review rejected the behavior where a matching target was targetable only if a
single straight orthogonal rail-to-target segment existed. A side-offset target
reachable by leaving the BOTTOM rail, moving up through cleared cells, then turning
left/right through cleared cells was wrongly classified untargetable.

## 4. Algorithm (HOW-only; TargetSelector WHAT unchanged)

For the already-assigned target:

```text
clicked slot anchor
  -> BOTTOM connector (start -> bottom_entry(start.x))
  -> rail-only exterior travel on canonical ScrubRailGeometry (corners only)
  -> a LEGAL rail ingress: an orthogonal rail->cell bridge into an OPEN/CLEARED
     (or the target) perimeter cell, on any side
  -> interior orthogonal path: four-neighbour Dijkstra through OPEN/CLEARED cells,
     90-degree turns allowed, target enterable only as final arrival
  -> assigned ACTIVE target
```

A single deterministic Dijkstra seeds every legal ingress perimeter cell with its
rail cost0 = connector + rail_path(entry→ingress rail point) + ingress bridge;
interior edges cost 1.0. It minimises the **total** legal route. Every edge is
validated by the authoritative `ProductionAccessQuery` seam (`_seg_true`,
`_classify`); the returned route is `RouteValidator`-clean. Interior movement is
inside-board only; exterior stays rail-only (the superseded M21 adjacent ring is
never revived). Collinear points are collapsed (never a diagonal-introducing
shortcut), so straight runs stay compact and every segment is axis-aligned.

**Deterministic tie-break** (exactly-equal total length): side priority
`BOTTOM → LEFT → RIGHT → TOP`, then ascending same-side ingress scan index
(bottom/top by x, left/right by y), then the fixed 4-neighbour expansion order
`[up,right,down,left]` — propagated through the Dijkstra as a secondary key.

**Enclosed-target fast-fail:** if the target has no OPEN orthogonal neighbour with
a traversable edge into it AND is not a directly rail-ingressable perimeter cell,
return `NO_ROUTE` without running the Dijkstra (perf + correctness).

No retarget: routing computes HOW only; `is_targetable()` naturally becomes true
whenever this revised routing can build a valid route.

## 5. Route examples (runtime-observed)

Owner-observed side-offset class (derived state, printed by the suite):

```text
V07_OWNER_CLASS target_idx=241 coord=(1,12)
  corridor = col7[y12..19] cleared + row12[x2..7] cleared
  route = [(10.0,21.0), (10.0,22.5), (7.5,22.5), (7.5,12.5), (1.5,12.5)]
```

That is: connector down to the bottom rail, rail travel left to the column-7
ingress, ingress + up the cleared column to row 12, then a LEFT turn along the
cleared row to target (1,12). The straight BOTTOM approach to (1,12) is
access-blocked (asserted), so the interior turn is load-bearing.

Focused fixtures (all on all-ACTIVE boards with carved CLEARED corridors, start
`(10,21)` unless noted), each asserted success + fully orthogonal (no diagonal):

- straight BOTTOM→(0,19) still succeeds;
- `BOTTOM → ingress → up → LEFT turn → (3,15)` (dirs contain U,L);
- mirrored `up → RIGHT turn → (16,15)` (dirs contain U,R);
- two interior 90° turns `up → right → up → (8,10)` (dirs contain U,R and R,U);
- blocking one corridor cell (5,17) ACTIVE → `NO_ROUTE`, same target, zero BoardState mutation;
- diagonal-only gap to (3,15) (all orthogonal neighbours ACTIVE) stays unreachable;
- rectangular `40×24` interior-turn route succeeds, orthogonal;
- `59×59` interior-turn route succeeds, orthogonal.

## 6. Preserved invariants

`ScrubRailGeometry` 2.0/1.0/2.5 geometry, slot→BOTTOM connector, rail-only exterior
travel + corners-only side changes, no exterior diagonal shortcut, ReservationState
ownership, TargetSelector color/state/reservation/bottom-most-left-most order,
dispatcher one-assignment, CompleteClearingLoop authenticated clear, reset/rapid
cleanup, rectangular/59×59 support — all unchanged and green in the root suite.

**Fresh-level C08 remains natural target `380 / (0,19)`** (asserted in the root
suite M22 integration/V03–V06 evidence and the real-art clear). The revised
reachability exposes no higher-priority C08 candidate: `(0,19)` is the absolute
bottom-left cell and remains directly rail-reachable, so TargetSelector's
bottom-most/left-most order is unchanged. No target-order change to report.

## 7. Validation commands / results / exits

Run from repo root `C:\Users\sekip\Desktop\ScrubBots`.

| # | Literal command | Result | Exit |
|---|-----------------|--------|------|
| 1 | `godot --version` | `4.7.2.stable.official.ed1daf0bf` | 0 |
| 2 | `godot --headless --path . -s res://tests/run_tests.gd` | **Total checks: 4823, Failures: 0, ALL PASS** | 0 |
| 3 | `godot --headless --path . -s res://tests/m22_v06_real_demo_state_evidence.gd` | PASS | 0 |
| 4 | `godot --headless --path . -s res://tests/m22_v05_final_state_evidence.gd` | PASS | 0 |
| 5 | `godot --headless --path . -s res://tests/m22_v04_final_evidence.gd` | PASS | 0 |
| 6 | `godot --headless --path . -s res://tests/m22_v03_connector_evidence.gd` | PASS | 0 |
| 7 | `godot --headless --path . -s res://tests/m22_railroad_responsive_smoke.gd` | PASS | 0 |
| 8 | `godot --headless --path . -s res://tests/m22_responsive_smoke.gd` | PASS | 0 |
| 9 | `godot --headless --path . -s res://tests/m21_real_art_smoke.gd` | PASS (full 400-cell clear under revised routing) | 0 |
| 10 | `godot --headless --path . -s res://tests/m21_v10_final_reservation_evidence.gd` | PASS | 0 |
| 11 | `godot --headless --path . -s res://tests/m20_queue_free_smoke.gd` | PASS | 0 |
| 12 | `godot --headless --path . -s res://tests/m20_v04_lifecycle_smoke.gd` | PASS | 0 |
| 13 | `godot --headless --path . -s res://tests/m20_v05_lifecycle_smoke.gd` | PASS | 0 |
| 14 | `godot --headless --path . -s res://tests/m20_v07_lifecycle_smoke.gd` | PASS | 0 |
| 15 | `godot --headless --path . -s res://tests/m20_v08_lifecycle_smoke.gd` | PASS | 0 |
| 16 | `godot --headless --path . -s res://tests/m20_v09_lifecycle_smoke.gd` | PASS | 0 |
| 17 | `godot --headless --path . -s res://tests/m20_v10_lifecycle_smoke.gd` | PASS | 0 |
| 18 | `git diff --check` | clean | 0 |

The V03/V04/V05/V06 Railroad evidence scripts remain green **without modification**:
on all-ACTIVE / straight-corridor fixtures the revised routing (after collinear
collapse) yields identical route arrays to the prior straight-aligned approach; the
new interior-turn behavior only activates where a cleared corridor requires a turn.
No existing test encoded a superseded straight-only rule that needed changing.
Historical M21 V08/V09 exact-ring-only failures remain classified/untouched.

## 8. Statements

- `Magnific/image-generation credits spent = 0`.
- Root `TASKS.md` not modified (absent from the V07 diff).
- No audit verdict authored; no PASS claimed; no M23 work. Owner F6 must be repeated
  after engineering acceptance.
