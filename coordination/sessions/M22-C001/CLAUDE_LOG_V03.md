# M22-C001 V03 — Railroad V1 Strict-Finding Reconciliation — Claude Log

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude (implementer/test runner)
Engine: Godot `4.7.2.stable.official.ed1daf0bf` (unchanged; not installed/upgraded)
Owner contract: `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`
Audit closed: `coordination/sessions/M22-C001/CHATGPT_AUDIT_V02.md`
Handoff state: `AWAITING_AUDIT`

ChatGPT owns the independent V03 audit and any root `TASKS.md` changes. This log
authors no verdict and claims no PASS.

## 1. Exact commit identities

- **Starting `origin/main` SHA (pre-work):** `51fdc62649177d46a6facf4513c041cfa52e508b`
  (`prompt(M22-C001 V03): reconcile Railroad V1 strict findings`).
- **V03 implementation commit SHA:** `8ded3580a8eacee1c64364e530142e23d6f115db`
  (`fix(M22-C001 V03): close frozen Railroad V1 strict findings`) — pushed to
  `origin/main` BEFORE this log was written (non-circular; F-M22-V02-EVIDENCE-002).
- This log is added in a separate evidence commit on top of the implementation SHA.

Sync: fast-forward `34d3bdf..51fdc62`; clean tree; no force/reset/clean; work only
in `Sekiph82/Scrubbots` on `main`. Root `TASKS.md` read-only and unchanged
(absent from the implementation diff).

## 2. Exact changed files (implementation commit 8ded358)

- `scripts/gameplay/routing/production_routing_system.gd` — outside-start routing
  supersession (all outside starts → Railroad V1; exterior ring removed from the
  interior BFS; `_is_below_board_start` → `_is_outside_start`; `_is_ring` deleted).
- `tests/run_tests.gd` — migrated M17/M18 lab/stress + edge-access regressions off
  outside adjacent-ring injection; strengthened Railroad routing tests
  (segment-domain classifier, far-right/top case, 20..59 tie-break/rectangular);
  migrated the V07 root top-origin case to a below-board multi-side rail route.
- `tests/m22_v03_connector_evidence.gd` — NEW frame-driven post-layout SlotCell
  connector evidence test.

Root `TASKS.md`: not modified. Accepted V01/V02 sources (ScrubRailGeometry,
ScrubRailView, ColorSelectionPanel, GameplaySlotDemo, docs) unchanged this pass.

## 3. F-M22-V02-STRICT-001 — production exterior-ring supersession

Final outside-start routing policy in `ProductionRoutingSystem.compute_route()`:

- **Any OUTSIDE start** (cell outside `[0,W)×[0,H)` — below/top/left/right) routes
  through `_railroad_route()` (Railroad V1): exact start → BOTTOM connector →
  rail-only travel (corners only) → aligned exit → assigned target.
- The obsolete M21 adjacent one-cell ring (`x=-1 / x=W / y=-1 / y=H`) is **no longer
  constructed or searched anywhere**. The ring seeding block and the `_is_ring`
  helper were deleted; the interior BFS neighbour expansion is now inside-board only.
- The interior grid planner is reachable **only by a genuine inside-board start**
  (debug/test), per M22-V03-013 — an outside owner-facing start can never reach it.
- No TargetSelector call/retarget added to routing; ProductionAccessQuery /
  RouteValidator truth not weakened; generic shortcut/rounding still never applied
  to rail routes.

Source-level proof: `grep` for `_is_ring` / ring seeding in
`production_routing_system.gd` returns nothing after V03; `-1 / W / H` exterior
band is absent from current production routing.

Migrated current regressions that had injected outside adjacent-ring starts
(historical M21 V07–V10 files left untouched as historical evidence):

- M17-C002 59x59 (S7) and rectangular VH (S8) lab scenarios: outside slot origins
  now exercise Railroad V1. Current invariants asserted: every successful route is
  RouteValidator-clean and strictly orthogonal (zero diagonal segments); every
  failure is a clean `NO_ROUTE` retaining the same target (interior lattice targets
  are legitimately unreachable when dispatched simultaneously — they open as
  clearing proceeds, proven by the real-art full clear).
- M18 agent-lifecycle stress + M17 F-003 edge-access (route-around / sole-edge
  NO_ROUTE): migrated to **inside-board origins**, exercising the retained interior
  debug/test planner (its safety intent — edge-access truth, NO_ROUTE on a sole
  blocked edge — preserved).
- V07 root corridor top case: migrated from an above-board origin to a below-board
  slot-style start reaching the far-right/top target (multi-side rail travel).

## 4. F-M22-V02-STRICT-002 — independent post-layout connector evidence

`tests/m22_v03_connector_evidence.gd` (real `SubViewport`, layout frames awaited):

Five real post-layout SlotCell mapped board-local starts (viewport 1080×2160),
independently measured from each Button's laid-out top-center global anchor via
`BoardPresentation.global_to_board_local()`:

```text
slot 0 -> (1.666667, 24.0)
slot 1 -> (5.444445, 24.0)
slot 2 -> (9.222222, 24.0)
slot 3 -> (13.0, 24.0)
slot 4 -> (16.77778, 24.0)
```

All five are distinct, one-to-one with slot ids, and below the board (genuine
railroad starts). Real C08 (slot 2) Button, fresh scene:

```text
mapped slot-2 anchor : (9.222222, 24.0)   [independently measured, NOT (0,24)]
route point 0        : (9.222222, 24.0)   == independently mapped anchor (non-circular)
route point 1        : (9.222222, 22.5)   == ScrubRailGeometry.bottom_entry(mapped.x)
route                : (9.222222,24.0) -> (9.222222,22.5) -> (0.5,22.5) -> (0.5,19.5)
target               : 380 / (0,19)   (naturally selected by TargetSelector)
```

Route point 0 is compared to the independently measured anchor (not to
`agent.spawn_origin`), closing the circular-evidence gap. Connector is a real
segment (point0 ≠ point1). Per-slot: every successful Button route starts at that
slot's own mapped anchor and enters `bottom_entry(mapped.x)`.

Second re-layout case (viewport 1290×2796, panel moved +（53,41）):

```text
slot-2 anchor before move : (9.222222, 24.0)
slot-2 anchor after move  : (10.69444, 25.13889)
route after move          : (10.69444,25.13889) -> (10.69444,22.5) -> (0.5,22.5) -> (0.5,19.5)
route point 0 == after-move anchor (dynamic); != before-move anchor (no stale cache)
C08 still naturally selects 380
```

## 5. F-M22-V02-EVIDENCE-001 — direct Railroad-domain tests

`_run_m22_railroad_routing_tests` now classifies each successful route via
`_assert_rail_domain`: connector (p0→bottom entry, orthogonal) + canonical rail
travel + one final orthogonal aligned approach. Every rail-travel segment must lie
exactly on a canonical TOP/BOTTOM/LEFT/RIGHT centreline (`_rail_seg_side`, not mere
axis-alignment), side changes only at exact corners (`_rail_is_corner`), no rail
segment in the 2-cell clearance free-space, no diagonal final approach.

Cases (all on 20..59 boards):

- far-left/bottom (20×20): BOTTOM entry + aligned bottom exit → (0.5,19.5).
- true far-right/top (20×20, target (19,0)): BOTTOM entry → corner(s) → aligned
  RIGHT/TOP exit → (19.5,0.5); domain-clean.
- two rail sides via exact BL corner (left-edge interior target (0,5)); also proves
  blocked-preferred-exit fallback to LEFT for the SAME target.
- all aligned exits blocked (enclosed interior (10,10)) → `NO_ROUTE`, same target,
  zero BoardState mutation.
- shortest legal route (right-side start → BOTTOM exit chosen).
- deterministic tie-break `BOTTOM → LEFT → RIGHT → TOP` on a **21×21** board (odd
  width puts col-10 centre on the loop midpoint → LEFT/RIGHT exactly equal → LEFT).
- rectangular **40×24** (both axes in 20..59) far-left bottom, domain-clean.
- **59×59** far-left bottom, domain-clean.

## 6. F-M22-V02-EVIDENCE-002 — exact commit identities

Two-step, non-circular: the implementation was committed and pushed
(`8ded3580a8eacee1c64364e530142e23d6f115db`) BEFORE this log existed; both the
starting SHA (`51fdc62…`) and the exact implementation SHA are recorded above. This
log is a separate evidence commit; it is not called the implementation SHA.

## 7. Concurrency / lifecycle / UI non-regression (root suite)

Green in the full suite: rapid three real C08 activations → unique targets/owners +
active visual; reset with ≥2 agents on rail travel → assignments/reservations
released, no false clears, zero orphan agents after deferred cleanup (railroad
responsive smoke); no-work slot → no side effect; `bind_colors` fail-closed on
malformed/undersized/non-Color, valid five-Color still works; five-slot/touch/
responsive V01 behavior intact; single-source geometry; procedural theme-independent
rail; zero generated-art.

## 8. Validation commands / results

Engine: `godot --version` → `4.7.2.stable.official.ed1daf0bf`.

| Command | Result |
|---------|--------|
| `-s tests/run_tests.gd` (full root suite) | **Total checks: 4798, Failures: 0, ALL PASS, exit 0** |
| Railroad geometry/routing/integration (in root suite) | included in 4798, PASS |
| `-s tests/m22_v03_connector_evidence.gd` (2 viewport/layout cases) | PASS, exit 0 |
| `-s tests/m22_railroad_responsive_smoke.gd` | PASS, exit 0 |
| `-s tests/m22_responsive_smoke.gd` (V01 responsive/component) | PASS, exit 0 |
| `-s tests/m21_real_art_smoke.gd` (full 400-cell clear, current routing) | PASS, exit 0 |
| `-s tests/m21_v10_final_reservation_evidence.gd` | PASS, exit 0 |
| `-s tests/m20_queue_free_smoke.gd`, `m20_v10_lifecycle_smoke.gd`, `m20_v08_lifecycle_smoke.gd` | PASS, exit 0 |
| TargetSelector / reservation / dispatcher / ScrubbotAgent strict (in root suite) | PASS |
| Headless M22 demo boot (connector-evidence + responsive smokes load+build the demo) | zero SCRIPT/Parse errors |
| `git diff --check` | clean |

Godot prints benign teardown warnings (leaked CanvasItem RID / ObjectDB at exit) as
before; exit code 0 / ALL PASS.

## 9. Historical-only failures (classified; not current acceptance)

Standalone historical M21 scripts (owner ADR-028 superseded geometry; left
unmodified per M22-V03-007/106):

- `tests/m21_v08_corridor_validation.gd` — FAIL(2): `C/043: above -> far-right top`
  and `C/047: corner route uses BOTH left and top exterior sides`. Both assert the
  superseded above-board exterior-ring behavior; an above-board start now correctly
  fails closed on the rail (its bottom connector cannot cross the board).
- `tests/m21_v09_direct_evidence_reconciliation.gd` — FAIL(1): `B: route crosses a
  distinct adjacent vertical-side NON-corner ring cell (left x=-1 or right x=20)` —
  asserts the exact `x=-1/x=W` ring, deliberately superseded.
- `tests/m21_v07_corridor_smoke.gd` — PASS.

These failing assertions encode only the deliberately superseded exact adjacent
ring; their safety intent is re-proven by the current Railroad V1 tests. They were
not edited to falsify M21 history and did not drive the production router back to
old geometry.

## 10. Statements

- `Magnific/image-generation credits spent = 0`.
- Root `TASKS.md` was not modified (absent from the implementation diff).
- No audit verdict authored; no `TASKS.md`/status change; no M23 work.
