# M28-C001 V01 — CLAUDE IMPLEMENTATION LOG

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Milestone: `M28 — Gameplay Screen Layout`
Cycle: `M28-C001 V01` (one continuous full-milestone pass)
Engine: Godot **4.7.2** (`4.7.2.stable.official.ed1daf0bf`), GDScript
Status: **AWAITING_AUDIT**

Session start `origin/main`: `b722f9e` (M28 opened). Rebased onto the newer
`origin/main` `48522db` after the owner landed the locked 1x/2x speed-control
decision mid-cycle (`OWNER_GAMEPLAY_BOTTOM_ROW_SPEED_DECISION_V01` /
`OWNER_GAMEPLAY_SPEED_RULE_V01`), which this implementation reflects.
Implementation SHA: `4fd03587a9a19d38104834b51ec418f68e5af7d9`
Log commit SHA: `(this commit)` (separate final commit)

## 0. Governance / scope confirmation

- Repo/branch verified; synchronized with `origin/main` via fast-forward then a clean
  rebase of the single implementation commit (no `reset --hard` / `clean` / force /
  destructive restore). Owner-local `project.godot` edit and untracked owner assets
  preserved (never staged).
- Root `TASKS.md` modified by Claude: **NO** (absent from every commit).
- M29 touch/input implemented: **NO** — no gameplay input wired; five slots are not
  clickable destinations; the speed control wires no timing/toggle.
- M30+ progression/win/economy implemented: **NO**.
- Image-generation credits spent: **0** (no image tool invoked).
- Owner reference images preserved byte-for-byte: **YES** (no reference file modified;
  none cropped/promoted).
- Implementation commit precedes this separate `CLAUDE_LOG_V01.md` commit.

## 1. What was built

Production responsive gameplay-screen **layout/presentation** around the closed
M23–M27 engine. Composition (owner-locked, reflects the mid-cycle speed decision):

```
GameplayScreen (Control)  scenes/gameplay/gameplay_screen.tscn + scripts/ui/gameplay_screen.gd
└── SafeAreaRoot (reused scene + synthetic-inset test seam)
    └── ScreenContent
        ├── TopRegion            # minimal spacer — NO Goal/Moves, NO Level/lock rail
        ├── BoardRegion          # DOMINANT, aspect-correct
        │   └── BoardPresentation (reused): BoardRenderer(single Image) + ScrubRailView + AgentLayer
        ├── BatchRegion
        │   ├── FiveSlotStrip        # exactly 5 READ-ONLY BatchSlotView (not Buttons)
        │   ├── ScrubbySpeechAnchor  # above Scrubby
        │   ├── ScrubbyDecorationAnchor  # low-left
        │   ├── BatchSupplyPanel     # 3/4/5 columns, exactly 3 visible rows
        │   └── CleaningPropsAnchor  # right, lower priority
        ├── BoosterRow           # 4 compact presentation-only controls
        └── BottomActionRow      # pause | ad placeholder | speed-up (1x/2x states)
```

New source:
- `scripts/ui/gameplay_screen.gd` — controller: SafeAreaRoot + ResponsiveLayout
  COMPACT/NORMAL/TALL band layout; fits the board+rail envelope preserving true W:H
  (rectangular never squared); centers it leaving exactly the ScrubRailGeometry
  clearance; exposes read-only rect/state accessors + coordinate mapping.
- `scripts/ui/five_slot_strip.gd` — exactly five READ-ONLY `BatchSlotView`; no Button,
  no `slot_activated`; binds detached M24 `snapshot()` dicts.
- `scripts/ui/batch_slot_view.gd` — one read-only slot view (PanelContainer): EMPTY /
  batch color / remaining / committed(in-flight) / ACTIVE·WAITING; detached snapshot.
- `scripts/ui/batch_supply_panel.gd` — 3/4/5 columns, exactly 3 visible rows (front
  primary, rows 2/3 secondary), hidden queue depth never rendered; detached M23
  `player_snapshot()`; protected minimum width.

Modified source:
- `scripts/ui/ui_tokens.gd` — M28 layout tokens (batch slot / supply / region minimums).
- `scripts/ui/safe_area_root.gd` — narrow synthetic-inset **test seam**
  (`set_synthetic_insets` / `clear_synthetic_insets`), presentation-only, never gameplay truth.

## 2. Boundaries honored

- Production input is supply-front batch selection, NOT destination slots. M28 revives
  no `ColorSelectionPanel.slot_activated`; `FiveSlotStrip`/`BatchSlotView` are not
  Buttons and emit no activation. Rightmost-empty placement remains M24 truth
  (unchanged). M29 owns touch.
- No UI component owns BoardState/M23/M24/M25/M26/M27 mutable truth — every batch
  binding is a `.duplicate(true)` scalar snapshot; the board is read-only for
  size/pixels via the reused BoardRenderer/BoardPresentation.
- Railroad preserved: `ScrubRailView` consumes canonical `ScrubRailGeometry`
  (2-cell artwork clearance, 1-cell rail width, closed loop) unchanged; responsive
  scaling changes physical pixels only (cell size), never routing geometry.
- Single-Image `BoardRenderer` reused; no per-cell Control/Node introduced.
- Speed control is presentation-only: distinct/readable 1x·2x states, new session
  defaults 1x; M28 wires no timing/toggle. Per `OWNER_GAMEPLAY_SPEED_RULE_V01` the
  automatic `M23 supply exhausted -> 2x` transition must consume authoritative M23
  exhaustion (never inferred from visible preview rows / five-slot occupancy) — that
  is future runtime integration, explicitly out of M28 scope.
- Ads: presentation placeholder only, no logic; monetization design-gated (M57).

## 3. Asset approval gate

`assets/art/references/inventory.json` has **zero** `PRODUCTION_APPROVED`/`APPROVED`
gameplay illustration (only `CANONICAL_SELECTED` references, `SUPPLIED_NOT_APPROVED`,
`OWNER_REQUIRED`, `NOT_APPLICABLE`). Therefore M28 binds **no** illustration and uses
neutral native placeholder anchors (Scrubby / speech / props), production-ready for a
later approved asset. No screenshot used as background; nothing cropped/promoted;
untracked owner files under `assets/ui/final/**` preserved and not bound. See
`evidence/asset_gate_report.md` and `evidence/reference_audit.md`.

## 4. Tests / evidence

- `tests/run_tests.gd` — `_run_m28_layout_tests()` (+34 frameless structural checks):
  five read-only slots; 3/4/5 column clamp; exactly 3 visible rows / hidden depth not
  exposed; detached-snapshot copy; no Button/`slot_activated`; composition (no
  Goal/Moves, no Level rail, 4 boosters); reuse of BoardPresentation + ScrubRailView;
  speed control 1x/2x states. **Full suite: 5346 checks / 0 failures.**
- `tests/m28_gameplay_layout_smoke.gd` — standalone viewport harness (**239 checks / 0
  failures**): single SubViewport resized across the required matrix (+ short 16:9 +
  tablet) and reconfigured across the board-size matrix, proving resize/re-layout
  re-derives geometry (criteria L). Emits `evidence/viewport_metrics.{json,md}`.
  Headless has no GPU, so PNG capture returns false (documented; deterministic metrics
  are the geometry proof).
  - Viewport matrix: 1080×2160 (NORMAL), 1170×2532, 1290×2796, 1080×2400, 1440×3200
    (TALL), 1080×1920 (COMPACT short 16:9), 1536×2048 (COMPACT tablet). Each: board
    region dominant, board aspect 0.6 preserved, five read-only slots, 4 columns × 3
    rows, no Goal/Moves, no Level rail, pause<ad<speed, pause/speed ≥ TOUCH_MIN, speed
    1x/2x states, no clipping, coord round-trip max err ≤ 5e-6.
  - Board-size matrix (layout fixtures only): 20×20, 40×40, 50×50, 59×59, 40×53, 24×40 —
    aspect preserved (rectangular not squared), board inside region, region dominant,
    batch region ≥ 605px (protected min), supply ≥ protected width, coord err ≤ 4e-6.
  - Synthetic safe-area insets {48,96,48,132}: all essential regions inside the inner
    safe rect (no notch/gesture overlap).
- Evidence: `coordination/sessions/M28-C001/evidence/{reference_audit.md,
  asset_gate_report.md, viewport_metrics.json, viewport_metrics.md}`.

### Regression floor (all PASS; no new failures outside recorded baseline)

```
godot --headless --path . -s res://tests/run_tests.gd            -> ALL PASS
godot --headless --path . -s res://tests/m28_gameplay_layout_smoke.gd -> 239/0
godot --headless --path . -s res://tests/m27_hazard_bot_solve.gd  -> PASS
godot --headless --path . -s res://tests/m27_scale_59.gd          -> PASS
godot --headless --path . -s res://tests/m27_generation_retry.gd  -> PASS
godot --headless --path . -s res://tests/m26_hazard_bot_integration.gd -> PASS
godot --headless --path . -s res://tests/m26_scale_59_sanity.gd   -> PASS
godot --headless --path . -s res://tests/m25_v03_exact_work_binding_evidence.gd -> PASS
godot --headless --path . -s res://tests/m24_v02_transaction_hardening_evidence.gd -> PASS
godot --headless --path . -s res://tests/m23_v03_transaction_identity_evidence.gd -> PASS
godot --headless --path . -s res://tests/m22_v03_connector_evidence.gd -> PASS
godot --headless --path . -s res://tests/m22_v06_real_demo_state_evidence.gd -> PASS
godot --headless --path . -s res://tests/m22_railroad_responsive_smoke.gd -> PASS
godot --headless --path . -s res://tests/m22_responsive_smoke.gd -> PASS
godot --headless --path . -s res://tests/m21_v06_tall_layout_smoke.gd -> PASS
git diff --check -> clean
```

## 5. Task-by-task mapping (SB-M28-001..028)

Code = `scripts/ui/*.gd` + `scenes/gameplay/gameplay_screen.tscn`; Unit =
`_run_m28_layout_tests()` in `tests/run_tests.gd`; Viewport = `tests/m28_gameplay_layout_smoke.gd`
+ `evidence/`.

- SB-M28-001 canonical reference/UI-system audit — `evidence/reference_audit.md`.
- SB-M28-002 dedicated production scene/controller w/ SafeAreaRoot — `gameplay_screen.tscn` + `gameplay_screen.gd`; Unit screen composition.
- SB-M28-003 five read-only slots + batch supply presentation — `five_slot_strip.gd` / `batch_slot_view.gd` / `batch_supply_panel.gd`; Unit + Viewport.
- SB-M28-004 supply-front (not destination-slot) input contract locked — no `slot_activated`/Button; Unit "no Button / slot_activated".
- SB-M28-005 reuse BoardPresentation/BoardRenderer — `gameplay_screen._build_board_presentation`; Unit "reuses BoardPresentation".
- SB-M28-006 board dominant — `_layout_board`/band math; Viewport "board region > batch/booster/bottom".
- SB-M28-007 board aspect-correct / rectangular not squared — envelope fit; Viewport "aspect preserved" (matrix + rectangular fixtures).
- SB-M28-008 required viewport matrix — Viewport matrix (7 sizes) + metrics.
- SB-M28-009 COMPACT/NORMAL/TALL — `ResponsiveLayout.get_layout_mode`; Viewport mode column (all three exercised).
- SB-M28-010 board-size fixtures (small/med/hard/59×59) — Viewport board-size matrix.
- SB-M28-011 rectangular boards — `rect_40x53`, `rect_24x40`; Viewport.
- SB-M28-012 SafeAreaRoot + synthetic-inset seam — `safe_area_root.gd`; Viewport safe-area case.
- SB-M28-013 ScrubRailView on canonical ScrubRailGeometry, clearance/width preserved — `_build_board_presentation`/`_layout_board`; Unit "reuses ScrubRailView".
- SB-M28-014 coordinate round-trip after responsive scaling — `cell_center_to_global`/`global_to_board_local`; Viewport coord err ≤ 5e-6.
- SB-M28-015 no per-cell Control/Node — single-Image BoardRenderer reused; documented + Unit reuse.
- SB-M28-016 Goal/Moves absent — `has_goal_moves_panel()==false`; Unit + Viewport.
- SB-M28-017 Level/lock rail absent — `has_level_lock_rail()==false`; Unit + Viewport.
- SB-M28-018 responsive region priority / protected supply+batch — `relayout`/`_layout_batch_region`; Viewport protected-min checks.
- SB-M28-019 3/4/5 columns, exactly 3 rows, hidden depth hidden, detached snapshots — `batch_supply_panel.gd`; Unit clamp + rows + Viewport.
- SB-M28-020 ScrubbyDecorationAnchor low-left — `_layout_batch_region`; Viewport "Scrubby anchored left/low".
- SB-M28-021 SpeechAnchor above Scrubby — Viewport "speech above Scrubby".
- SB-M28-022 CleaningPropsAnchor right, lower priority — Viewport "props anchored right"; decoration shrinks before supply/slots.
- SB-M28-023 four boosters horizontal — `BoosterRow`; Unit + Viewport "exactly four boosters".
- SB-M28-024 bottom row pause | ad | speed-up (owner override; distinct 1x/2x states) — `BottomActionRow`/`_apply_speed_visual`; Unit + Viewport order + speed states.
- SB-M28-025 ad placeholder only / monetization gated — `AdPlaceholder` (no logic); documented.
- SB-M28-026 asset approval gate — neutral placeholders, zero binds — `evidence/asset_gate_report.md`.
- SB-M28-027 deterministic viewport metrics/captures — `evidence/viewport_metrics.{json,md}` (PNG false in headless, documented).
- SB-M28-028 full-milestone evidence + regression + task mapping — this log + regression floor above.

## 6. Handoff

`AWAITING_AUDIT`. Every `SB-M28-001..028` maps to code + direct evidence above. Root
`TASKS.md` left for ChatGPT to update after independent audit. Root TASKS modified =
**NO**; M29 input = **NO**; image credits = **0**; reference art promoted = **NONE**;
canonical screenshot used as flattened production UI = **NO**.
