# M22-C001 V02 — Scrubbot Railroad V1 + Slot Connector Integration — Claude Log

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude (implementer/test runner)
Engine: Godot `4.7.2.stable.official.ed1daf0bf` (unchanged; not installed/upgraded)
Owner contract: `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`
Handoff state: `AWAITING_AUDIT`

ChatGPT owns audit closure and root `TASKS.md`. This log authors no audit verdict.

---

## 1. Starting / ending commit identities & safe-sync / owner-work preservation

- **Working-checkout loss + recovery.** Between the V02 session start and this run the
  local checkout at `C:\Users\sekip\Desktop\ScrubBots` was reported **empty** (no
  working tree, no `.git`) by an external event. Under explicit owner authorization
  (option 1) the checkout was rebuilt by cloning the authoritative
  `https://github.com/Sekiph82/Scrubbots.git`. GitHub `origin/main` is the source of
  truth; nothing on the remote was lost. The single uncommitted V02 file from the
  interrupted session (`scrub_rail_geometry.gd`) was **not** recovered — it was
  rebuilt cleanly from the V02 specification, as instructed.
- **Starting commit (clone HEAD == current origin/main):** `889039b`
  (`coordination: record LF CP tracker migration boundary`). This is a few
  ChatGPT tracker/LF-CP commits ahead of the V02 base `ff9067e`; all V02
  prompt/criteria/owner-decision docs and the accepted M22 V01 implementation
  (`670200d`) are present in this history.
- **Ending commit:** the M22-C001 V02 implementation commit whose parent is
  `889039b` (hash recorded on `main` after push; see §12 verification).
- No `reset --hard`, `clean`, destructive restore, stash loss or force-push. The
  fresh clone is a clean tree; no owner-local untracked sidecars existed to disturb.
  Work was confined to `Sekiph82/Scrubbots` on `main`.
- Root `TASKS.md` was read and **not modified**.

---

## 2. Exact changed files

New:

- `scripts/gameplay/routing/scrub_rail_geometry.gd` — single-source Railroad V1 geometry (`ScrubRailGeometry`).
- `scripts/ui/scrub_rail_view.gd` + `scenes/components/ui/gameplay/scrub_rail_view.tscn` — reusable procedural railroad presentation.
- `tests/m22_railroad_responsive_smoke.gd` — Railroad V1 responsive / visual-layout / reset-cleanup smoke.

Modified:

- `scripts/gameplay/routing/production_routing_system.gd` — Railroad V1 routing branch for below-board/slot starts (HOW); ring retained only for non-below debug/test starts.
- `scripts/ui/color_selection_panel.gd` — V01 hardening: `bind_colors` fails closed on malformed/undersized snapshot (no fabricated magenta), returns bool.
- `scripts/ui/gameplay_slot_demo.gd` — hosts `ScrubRailView`; slot panel repositioned below the bottom rail.
- `tests/run_tests.gd` — added `_run_m22_railroad_geometry_tests`, `_run_m22_railroad_routing_tests`, `_run_m22_railroad_integration_tests` (registered); marked the M21 V07 root test as safety-intent-only under Railroad V1 supersession.
- `docs/01_GAMEPLAY_SPEC.md`, `docs/02_TECH_ARCHITECTURE.md`, `docs/05_TECH_DECISIONS.md` (ADR-028), `docs/MASTER_UI_SYSTEM.md` — railroad supersession/spacing/ownership documentation.

New evidence doc: `coordination/sessions/M22-C001/CLAUDE_LOG_V02.md` (this file).

A temporary evidence script (`tests/_m22_evidence_tmp.gd`) was used to capture the
route points in §5 and then deleted; it is not committed.

Preserved unchanged (accepted authority): TargetSelector, ReservationState,
ScrubbotDispatcher, ScrubbotAgent, CompleteClearingLoop, BoardPresentation,
BoardState, ProductionAccessQuery, RouteValidator, and the accepted M22 V01
`SlotCell`/`ColorSelectionPanel`/demo component architecture (only the two
documented V02 changes above touch V01).

---

## 3. Railroad geometry constants — single-source proof

All numbers live only in `ScrubRailGeometry` (criteria M22-V02-033/047):

```text
CLEARANCE      = 2.0   (artwork-to-rail inner-edge clearance, logical cells)
RAIL_WIDTH     = 1.0   (logical cell)
CENTER_OFFSET  = 2.5   (= CLEARANCE + RAIL_WIDTH/2, outside each boundary)
For board W×H:
  TOP    centreline y = -2.5,    x ∈ [-2.5, W+2.5]
  BOTTOM centreline y = H+2.5,   x ∈ [-2.5, W+2.5]
  LEFT   centreline x = -2.5,    y ∈ [-2.5, H+2.5]
  RIGHT  centreline x = W+2.5,   y ∈ [-2.5, H+2.5]
  Corners: (-2.5,-2.5) (W+2.5,-2.5) (W+2.5,H+2.5) (-2.5,H+2.5)
Equal-distance route tie-break: BOTTOM → LEFT → RIGHT → TOP
```

Consumers reference this helper, never literals: `ProductionRoutingSystem`
(`_railroad_route`), `ScrubRailView` (`_draw`), and `GameplaySlotDemo` (panel
placement uses `ScrubRailGeometry.CENTER_OFFSET`/`RAIL_WIDTH`). Unit tests validate
the constants/centrelines/corners for `20×20, 24×38, 30×12, 59×59` and fail-closed
on invalid input (`_run_m22_railroad_geometry_tests`).

---

## 4. Movement model & interaction chain

Below-board (slot-style, `start.y >= H`) starts — the owner-facing production path,
because real `SlotCell`s sit below the board — route on the railroad:

```text
clicked SlotCell (Button) → SlotView.slot_activated → ColorSelectionPanel re-emit
 → GameplaySlotDemo.request_slot → CompleteClearingLoop.activate_slot
 → TargetSelector (bottom-most/left-most; targetability via the SAME rail routing)
 → ProductionRoutingSystem._railroad_route:
      start → BOTTOM-rail connector entry (mapped slot x) → rail centreline travel
      (corners only) → aligned exit (TOP/BOTTOM share target x; LEFT/RIGHT share
      target y) → strictly orthogonal final approach → assigned target
 → ScrubbotDispatcher → ScrubbotAgent → authenticated arrival → M20 clear
```

Non-below (left/right/above/inside) debug/test injection starts retain the
compatible exterior path (the owner slot-connector law does not cover them). No
SPACE/keyboard gameplay path exists. The generic collinear/shortcut/rounding
post-process is **not** applied to rail routes, so it can never turn a legal rail
route into a diagonal free-space shortcut (M22-V02-074/075).

---

## 5. Representative exact route points

Real production demo, first fresh Hazard Bot C08 (slot 2) click →
**target index 380, coordinate (0,19)** arising naturally from TargetSelector:

```text
C08 route: (0.0, 24.0) → (0.0, 22.5) → (0.5, 22.5) → (0.5, 19.5)
           start(below)   bottom entry  bottom-rail    orthogonal
                          (connector)   aligned exit   approach → target centre
```

Connector-before-rail and aligned-exit are explicit; every segment is orthogonal.

Synthetic 20×20 all-ACTIVE evidence (slot-style start (10.0, 21.0)):

```text
far-left bottom target (0,19):
  (10.0,21.0) → (10.0,22.5) → (0.5,22.5) → (0.5,19.5)          [BOTTOM exit]

two rail sides via BL corner — left-edge interior target (0,5):
  (10.0,21.0) → (10.0,22.5) → (-2.5,22.5) → (-2.5,5.5) → (0.5,5.5)
  connector      bottom rail    BL corner     LEFT rail     orthogonal approach
```

The two-sides route proves genuine corner traversal (bottom **and** left sides via
the exact BL corner `(-2.5,22.5)`), stronger than a single ambiguous corner point.

---

## 6. No-shortcut / no-early-exit evidence

- Every route segment is axis-aligned (dx==0 or dy==0) in all geometry/routing/
  integration tests (`_rail_axis_aligned`), and on the real agent path
  (`agent.get_route_points()`), proving no diagonal exterior shortcut and no
  diagonal final approach (M22-V02-072/073/081/135/136/142).
- Intermediate travel points lie on rail centrelines / corners; the only non-rail
  segments are the slot connector and the final aligned orthogonal approach.
- The direct straight shot from slot to a far target remains access-blocked, so
  success genuinely requires rail travel (preserved from V07 safety intent).

---

## 7. Blocked-exit fallback & all-blocked failure

- **Fallback to another aligned side for the SAME target:** left-edge interior target
  (0,5) on an all-ACTIVE board has its BOTTOM/RIGHT/TOP aligned approaches blocked by
  non-target ACTIVE cells; routing falls back to the LEFT aligned side for the same
  target and succeeds (route ends exactly at the target centre). No retarget
  (M22-V02-086/133/137).
- **All aligned sides blocked:** enclosed interior target (10,10) → `success=false`,
  `failure_reason=NO_ROUTE`, `target_index` retained (=210, no retarget), and the
  BoardState ACTIVE count is unchanged (no side effect) (M22-V02-087/099/101/138).

---

## 8. Rapid / reset ReservationState & AgentLayer cleanup

- Three rapid real-Button C08 activations yield three **unique** target indices
  (first = 380) and three **unique** reservation owners; the slot shows the active
  visual with concurrent rail-routed agents (M22-V02-094/098/109/111).
- Reset while **≥2** agents are still travelling on the connector/rail clears the
  in-flight bookkeeping and active visuals, releases reservations via the accepted
  `CompleteClearingLoop.reset`, and does **not** clear the unarrived targets
  (CLEARED count unchanged) (M22-V02-112). After deferred free the AgentLayer holds
  **zero** orphan Scrubbots (M22-V02-113, verified with real frames in the railroad
  responsive smoke). Fresh post-reset activation again naturally selects target 380
  (M22-V02-114).

---

## 9. Responsive board / rail / slot matrix

`tests/m22_railroad_responsive_smoke.gd` hosts the demo in real SubViewports, awaits
layout, and measures post-layout geometry. Every case: rail view present with valid
single-source geometry; five slots BELOW the bottom rail (never inside the 2-cell
clearance); touch ≥ 88; deterministic order; no overlap; slots inside viewport
bounds; board aspect undistorted; ≥ 2 logical-cell artwork-to-rail gap.

| Viewport | cell size | rail outer y (screen) | cell0 | cell4 | below rail | touch≥88 | overlap |
|----------|-----------|-----------------------|-------|-------|-----------|----------|---------|
| 1080×2160 | 36 | 948 | (60,984) 120² | (604,984) 120² | yes | yes | none |
| 1170×2532 | 36 | 948 | (60,984) | (604,984) | yes | yes | none |
| 1290×2796 | 36 | 948 | (60,984) | (604,984) | yes | yes | none |
| 1080×2400 | 36 | 948 | (60,984) | (604,984) | yes | yes | none |
| 1440×3200 | 36 | 948 | (60,984) | (604,984) | yes | yes | none |
| 1080×1920 (16:9) | 36 | 948 | (60,984) | (604,984) | yes | yes | none |
| 1536×2048 (tablet) | 36 | 948 | (60,984) | (604,984) | yes | yes | none |

Logical 2-cell clearance invariant (`clearance()==2.0`) and centrelines tracking
`W/H` validated for `20×20, 30×12 (rectangular), 59×59` (M22-V02-122/123/124).
Routing validated on rectangular `30×12` and `59×59` all-ACTIVE boards.

---

## 10. Documentation supersession summary

- `docs/05_TECH_DECISIONS.md` — **ADR-028**: Railroad V1 supersedes the M21 adjacent
  one-cell ring as future production geometry; single-source geometry + ownership
  boundaries; M21 V07–V10 remain valid historical evidence for their commits.
- `docs/01_GAMEPLAY_SPEC.md` — railroad travel + orthogonal aligned-exit law, tie-break.
- `docs/02_TECH_ARCHITECTURE.md` — single-source `ScrubRailGeometry` + consumers + preserved authority.
- `docs/MASTER_UI_SYSTEM.md` — reusable railroad presentation/spacing contract; slots below rail.

All four state the railroad is presentation/routing space only (not
LevelData/BoardState, not a C01..C16 artwork layer, no Difficulty V1 change), that
V1 uses one consistent visual language across levels (no per-level theme), and that
no external reference title's assets/composition are copied. Historical M21
audit/log evidence was **not** rewritten.

---

## 11. Test migration / historical classification

- The root suite's M21 V07 corridor test is annotated as **safety-intent-only** under
  Railroad V1: its checks assert surviving invariants (exterior travel load-bearing,
  direct diagonal shot blocked, exact start/target endpoints, four-side/corner +
  rectangular + 59×59 coverage, enclosed-interior unreachable). Below-board cases now
  exercise Railroad V1; it is not cited as current exact-geometry acceptance. The
  full root suite passes with these preserved.
- Fresh Railroad V1 tests carry the current exact-geometry acceptance.
- **Historical standalone scripts (not current acceptance, not rewritten):**
  - `tests/m21_v08_corridor_validation.gd` — FAILs one check `C/047: corner route
    uses BOTH left and top exterior sides` (asserts the superseded exact adjacent
    ring). Classified historical/superseded (owner ADR-028); safety intent re-proven
    by `_run_m22_railroad_routing_tests` (two-sides/corner, blocked fallback,
    all-blocked no-route).
  - `tests/m21_v09_direct_evidence_reconciliation.gd` — FAILs one check `B: route
    crosses a distinct adjacent vertical-side NON-corner ring cell (left x=-1 or
    right x=20)` (asserts exact `x=-1/x=W` ring). Classified historical/superseded.
  These two are the only regressions that depend on the superseded exact ring
  geometry; per prompt they are not run as current acceptance and their history is
  preserved unmodified. `m21_v07_corridor_smoke` and `m21_v10` standalone PASS.

---

## 12. Exact commands / results / check counts

Engine: `godot --version` → `4.7.2.stable.official.ed1daf0bf` (unchanged).

| Command | Result |
|---------|--------|
| `-s tests/run_tests.gd` (full root suite) | **Total checks: 4769, Failures: 0, RESULT: ALL PASS, exit 0** |
| Railroad V1 geometry/routing/integration (in root suite) | included in 4769, PASS |
| `-s tests/m22_railroad_responsive_smoke.gd` | PASS, exit 0 (matrix + rectangular/59×59 geom + reset cleanup) |
| `-s tests/m22_responsive_smoke.gd` (V01 slot/responsive regression) | PASS, exit 0 |
| `-s tests/m21_real_art_smoke.gd` (full 400-cell clear under current routing) | PASS, exit 0 |
| `-s tests/m21_v10_final_reservation_evidence.gd` | PASS, exit 0 |
| `-s tests/m20_queue_free_smoke.gd` | PASS, exit 0 |
| `-s tests/m20_v10_lifecycle_smoke.gd` | PASS, exit 0 |
| `-s tests/m20_v08_lifecycle_smoke.gd` | PASS, exit 0 |
| `-s tests/m21_v05_playtest_smoke.gd`, `m21_v06_tall_layout_smoke.gd`, `m21_v07_corridor_smoke.gd` | PASS, exit 0 |
| `-s tests/m21_v08_corridor_validation.gd` / `m21_v09_direct_evidence_reconciliation.gd` | FAIL(1) each — superseded exact-ring assertions only, classified historical (§11) |
| Headless M22 railroad demo boot | zero SCRIPT/Parse errors (demo loads+builds in responsive smoke + integration) |
| `git diff --check` | clean |

TargetSelector / reservation / dispatcher / ScrubbotAgent strict regressions run
inside the full root suite (all PASS). Godot prints benign teardown warnings
(leaked CanvasItem RID / ObjectDB "at exit") as before; exit code is 0 / ALL PASS.

---

## 13. Magnific / AI generation

**Magnific / image-generation credits spent = 0.** No image-generation provider was
called. The railroad is native/procedural Godot 2D (`ScrubRailView._draw`); no
booster/Scrubby/rail/tile/decorative asset was generated.

---

## 14. Tracker statement

Root `TASKS.md` was **not modified**. ChatGPT owns tracker updates and audit
closure. No audit verdict/file was authored by Claude.
