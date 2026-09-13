# M21-C001 V07 — Claude Implementation Log

Cycle: `M21-C001` V07 — exterior corridor + slot-only owner correction.
Actor: Claude (implementer/test runner). Auditor: ChatGPT (independent).
Repository: `Sekiph82/Scrubbots`, branch `main`. Handoff: `AWAITING_AUDIT`.
Engine: Godot `4.7.2.stable.official.ed1daf0bf` (the machine Godot was upgraded from 4.7.1 to 4.7.2 during this run; all V07 evidence below ran on 4.7.2 and passed).

Frozen correction of the two owner findings after the V06 owner playtest:
F-M21-OWNER-001 (remove SPACE gameplay dispatch — slot-click only) and
F-M21-OWNER-002 (add the owner-locked one-cell exterior routing corridor so the
bottom-most/left-most reachable target is genuinely reachable). TargetSelector,
M19/M20, ProductionAccessQuery, agent, presentation and SlotView are unchanged.
Runtime results are Claude E1/E2 evidence; owner manual visual PASS is still pending.

## 0. Safe sync + preserved owner/local work

- Synchronized starting head: local `8586a09…` fast-forwarded to `origin/main`
  `fd84520…` via `git rebase --autostash origin/main` (0 ahead / 5 behind; incoming
  = V06 audit/owner-gate, V07 prompt/criteria/owner-findings). Confirmed the incoming
  set did not touch the owner's locally-modified files before syncing.
- Preserved owner/local work (autostash reapplied, never dropped/reset/restored):
  `project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
  `scenes/debug/scrubbot_agent_debug.tscn` (unstaged), plus untracked owner inbox
  `.import` sidecars, `docs/logs/`, `*.uid`. None staged.
- No `.hiveai` tracker recreated. GitHub-only logging.

## 1. Tracker note (owner instruction)

Per the owner's explicit instruction for this run — **"Do not modify root
TASKS.md"** — no tracker-only V07 start commit and no tracker lifecycle handoff edit
were made. This intentionally deviates from CHATGPT_PROMPT_V07 §2/§13 tracker steps;
all other V07 scope is executed. Only implementation/test/log/guide changes are
committed.

## 2. Frozen finding A — SPACE gameplay dispatch removed

`scripts/debug/m21_real_art_vertical_slice.gd`: removed `_unhandled_input`
(KEY_SPACE handler), `step_one_clear()`, and the `SLOT_ORDER` constant + synthetic
off-board origin array that existed only for that fallback. The owner-playable scene
now has exactly ONE player-facing gameplay activation path:

```
visible SlotView click → slot_activated → scene handler → CompleteClearingLoop.activate_slot → real dispatcher/target/route/agent/authenticated clear
```

`request_slot()` remains only as a narrow programmatic/test seam. No replacement
hidden keyboard dispatch was added. The V01 debug-scene root smoke was updated to
drive via `request_slot(2)` (visible-slot path) instead of the removed
`step_one_clear()`.

## 3. Frozen finding B — one-cell exterior routing corridor

`scripts/gameplay/routing/production_routing_system.gd` (pre-V07 blob
`0900e9554d0e64dcfbb28667e1ce1062eadba73f`): the deterministic BFS planning domain
was extended from board cells to `board + one-cell exterior ring`.

- New `_is_ring(c, w, h)`: the border band exactly one cell outside the board — the
  bounding box `[-1..W]×[-1..H]` minus inside-board cells (top y=-1 x=-1..W, bottom
  y=H x=-1..W, left x=-1 y=0..H-1, right x=W y=0..H-1, corners included).
- Ring cells are seeded as BFS entries (nearest-first) via one access-valid connector
  segment from the exact slot origin; BFS neighbour expansion now traverses inside
  board cells AND ring cells; nothing beyond the one-cell ring is ever searched.
- Ring nodes classify OPEN through the EXISTING `ProductionAccessQuery`
  (outside-board → OPEN); its production semantics were NOT changed (blob unchanged).
  Every traversed edge is still `is_segment_traversable()`-validated, the final
  ACTIVE-target arrival law is unchanged, and every returned route is still
  RouteValidator-clean (including organized/curved post-processing).
- Movement/route truth stays board-local; LevelData/BoardState dimensions are never
  extended.

### Root cause reproduced (red-before / green-after)

Pre-V07, from a slot below the board the planner had no modelled outside walkway: a
straight approach to the far-left bottom target crossed intervening ACTIVE bottom-row
cells (correctly rejected), so a nearer bottom target was reported targetable first
and TargetSelector cleared it — exactly the owner's observation. The V07 corridor
makes the whole bottom row reachable via the exterior ring, so TargetSelector's
unchanged bottom-most/left-most rule now yields `(0,19)`. The V07 corridor smoke
asserts first target index `380 / (0,19)`, which fails on the pre-V07 routing and
passes after the ring is added; the pure-routing corridor tests include a
load-bearing case (`direct straight shot blocked` + `routed success` + route has an
exterior-ring point) that fails if the ring expansion is removed.

## 4. Exact Hazard Bot correction (real owner scene, `tests/m21_v07_corridor_smoke.gd`)

Slot-click (real Button `pressed`→`slot_activated`→handler) on fresh Hazard Bot:

```
anchor global      = (400.0, 880.0)
mapped board-local = (9.444445, 21.11111) == agent.spawn_origin == route[0]
first target index = 380 ; coord = (0,19) ; color local palette id = 2 (C08)
route points       = [(9.444445,21.11111), (0.749418,20.517), (0.640298,20.494),
                      (0.562355,20.442), (0.515589,20.360), (0.5,20.25), (0.5,19.5)]
```

- route[0] == exact mapped slot origin; final point == centre of `(0,19)`;
- route traverses the bottom exterior ring (points with `y >= 20`), i.e. it walks
  OUTSIDE the artwork rather than crossing ACTIVE bottom-row cells (direct assertion
  `not _crosses_active_bottom_row`);
- authenticated M20 arrival clears exactly index `380`; AgentLayer 0 orphans after
  deferred cleanup;
- deterministic left-to-right progression proven: subsequent C08 clears select
  `381, 382, 383` (emergent from TargetSelector + ProductionTargetAccess + corrected
  corridor + ReservationState; no forced target IDs).

## 5. Four-side / rectangular / 59×59 / enclosed matrix (`_run_m21_v07_corridor_tests`)

Pure `ProductionRoutingSystem` on all-ACTIVE boards (only the exterior ring can reach
a far perimeter target):

- below-origin → far-left bottom target via bottom ring (+ load-bearing: direct shot
  blocked, routed success, exterior point present);
- above-origin → far-right top target via top ring;
- left-origin → far-bottom-left target via left ring;
- right-origin → far-top-right target via right ring;
- below-left origin → top-right target (rounds exterior corners);
- rectangular 30×12 far-left bottom via ring;
- 59×59 far-left bottom reachable via ring (dimension-scaled sanity);
- enclosed INTERIOR ACTIVE target stays unreachable (ring never tunnels through art).

## 6. Superseded strict assertion (narrow update)

The M17-C002 V03 "sole connecting edge blocked → NO_ROUTE" sub-case used a 3×3
perimeter target that is now legitimately reachable via the exterior ring (an
alternate approach the owner corridor intentionally adds). Its original safety
purpose — a genuinely sole blocked connecting edge must still yield NO_ROUTE and the
planner must consult segment access on that edge — is preserved by retargeting it to
a true INTERIOR target reached by a bent L-corridor whose sole connection `(1,2)→(2,2)`
is the blocked edge (no straight exterior shot, ring gives no alternate). It still
asserts NO_ROUTE and `blocked_edge_queried`. No other strict test changed.

## 7. Required commands and actual results

| Command | Result |
| --- | --- |
| `godot --version` | `4.7.2.stable.official.ed1daf0bf` (upgraded from 4.7.1 mid-run) |
| `tests/run_tests.gd` (root) | **4617 checks, 0 failures, ALL PASS** (0 SCRIPT/Parse errors) |
| `tests/m21_v07_corridor_smoke.gd` | PASS |
| `tests/m21_v06_tall_layout_smoke.gd` | PASS |
| `tests/m21_v05_playtest_smoke.gd` | PASS |
| `tests/m21_real_art_smoke.gd` | PASS — 400 clears, exact clean final state (headless CPU diagnostic only, AL-003) |
| M20 queue-free + V04/V05/V07/V08/V09/V10 lifecycle smokes | all PASS |
| owner scene headless boot `--quit-after 5` | boots, 0 SCRIPT/Parse errors |
| `tools/build_m21_level.gd` rerun | LEVEL/PREVIEW/METADATA UNCHANGED |
| `tools/build_m21_reference_composite.gd` | UNCHANGED |
| scan for `SCRIPT ERROR` / `Parse Error` | 0 |
| `git diff --check` | clean (only benign pre-existing owner/local + LF advisories) |

## 8. Exact changed files

Modified (authorized production):
- `scripts/gameplay/routing/production_routing_system.gd` (one-cell exterior corridor: `_is_ring`, ring entries, ring traversal)
- `scripts/debug/m21_real_art_vertical_slice.gd` (removed SPACE dispatch / step_one_clear / SLOT_ORDER)

Modified (tests):
- `tests/run_tests.gd` (V07 corridor matrix `_run_m21_v07_corridor_tests`; retargeted the superseded M17 sole-edge sub-case; V01 debug smoke now uses the visible-slot path)

Added:
- `tests/m21_v07_corridor_smoke.gd` (real-scene (0,19)/380 + left-to-right + ring-travel + slot-only)
- `coordination/sessions/M21-C001/M21_V07_OWNER_PLAYTEST.md` (current owner guide)
- `coordination/sessions/M21-C001/CLAUDE_LOG_V07.md` (this file)

Root `TASKS.md` intentionally NOT modified (owner instruction, §1). No change to
TargetSelector, dispatcher, clearing loop, ProductionAccessQuery, route_request,
route_validator, board_presentation, slot_view, scrubbot_agent, owner source PNG,
LevelData/preview/metadata, or reference composite. `.uid` sidecars not committed;
owner local work never staged.

## 9. Protected blob rechecks after all V07 work

| File | Expected blob | Status |
| --- | --- | --- |
| owner Hazard Bot PNG | `b565743ba52699899007882b750b7c8e7cdd00f9` | unchanged |
| clearing loop | `06391839523cbc27e88a4b3ef12b730012cd45fa` | unchanged |
| dispatcher | `eee10149e4f116af6706beec832042352bf3a6dd` | unchanged |
| TargetSelector | `bb1e48a2a82f6ca4e8962f2a24de60e815c1a945` | unchanged |
| BoardPresentation | `2093df48d367903d332a910dfb3369154831a9ed` | unchanged |
| SlotView | `480dffc0ee135150bd3dd2258f002264273ead10` | unchanged |
| ScrubbotAgent | `48b43b1c8ee1709741fc6ad9c9b1ef436f4d6370` | unchanged |
| ProductionAccessQuery | `7ba9d13556abb0e3a0a6d281449438330a25386d` | unchanged |

Authorized changed production blobs:
- `production_routing_system.gd`: `0900e9554d0e64dcfbb28667e1ce1062eadba73f` → `8a0eea8e91298c852c692bd87ca1d09cd7d7f4a1`
- `m21_real_art_vertical_slice.gd`: `66050fe5ec95498a43c6d4abccf62c4d82744d39` → `153c042a17dc0ef9e83699a0beb2932217057ff4`

## 10. Handoff

Owner manual visual PASS is still PENDING independent audit. Claude closed no
`SB-M21-*` / `SB-M22-*` / `SB-UI-*` checkbox and authored no audit verdict/file. Per
owner instruction, root `TASKS.md` lifecycle was NOT changed by this run. All
authorized implementation/test/log/guide work pushed to `origin/main` without force.
Handoff: **AWAITING_AUDIT**.
