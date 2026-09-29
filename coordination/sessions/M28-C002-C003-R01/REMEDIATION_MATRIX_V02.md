# M28-C002-C003-R01 — Five-Finding Remediation Matrix V02

Date: 2026-09-29
Prompt: `coordination/sessions/M28-C002-C003-R01/CHATGPT_PROMPT_V02.md` (supersedes V01)
Criteria: `coordination/sessions/M28-C002-C003-R01/CHATGPT_AUDIT_CRITERIA_V02.md`
Status: **AWAITING_CHATGPT_AUDIT**. Owner replay is still required (§7).

Focused suite: `tests/m28_c002_c003_r01_remediation.gd` (24 ledger cases).
Rendered-pixel probe: `tests/tools/board_grid_probe.gd` (needs a GPU).
Evidence: `coordination/sessions/M28-C002-C003-R01/evidence/`.

## 1. Timed 2x auto-start

**Root cause** (matches `OWNER_TIMED_2X_CROSS_LEVEL_RUNTIME_V01`):
- `ProductionGameplayHost.build()` created a fresh `GameplaySpeedAuthority`, which starts at 1x.
- `_refresh_hud()` then showed the surviving `SpeedEntitlementService` countdown without applying the live factor.
- The retry path did the same, so timed remaining > 0 with runtime 1x was reachable.

**Fix** (`scripts/gameplay/runtime/production_gameplay_host.gd`):

| Piece | Behaviour |
|---|---|
| `_apply_default_speed()` | Called in `build()` (new level launch or app relaunch) and in `_on_retry_restored()`. If `timed_seconds_remaining() > 0`, it sets the runtime speed authority and the HUD to 2x together; otherwise 1x. |
| `_paid_2x` | Marks a 2x that comes from an entitlement (timed default, purchase, or entitled toggle) as opposed to the free M23 auto-2x. |
| `_drop_expired_paid_2x()` | Runs from the 1 s HUD tick. A paid 2x whose entitlement expired mid-level drops to 1x, unless the supply is exhausted, in which case the free auto-2x owns the speed and is left alone (owner ruling §5). |

Unchanged:
- The current-level 200 SB entitlement is level-scoped and manual; it never auto-starts a level.
- `SpeedEntitlementService` (M55 anti-rollback, prices, durations) is untouched.
- `ProductionInputController`'s M23 auto-2x is untouched.

| Prompt test | Case | Where |
|---|---|---|
| timed purchase → next level 2x | `t01` (L1 buy → WON → Results → +200 s → Continue → L2 is live 2x; countdown 700 s = "11:40"; auto-start cost nothing) | suite §1 |
| app relaunch → 2x | `t02` (save flushed, relaunch, +60 s, entitlement persisted and counting, first gameplay live 2x) | suite §1 |
| manual 1x free; next new level 2x | `t03` (routed tap → 1x, no SB, no popup; next level 2x again) | suite §1 |
| expired → 1x | `t04` (new gameplay after expiry is 1x, no timed HUD) | suite §1 |
| mid-level expiry | `t04b` (paid 2x drops to 1x; with supply exhausted the free auto-2x stays and the HUD shows "auto") | suite §1b |
| current-level 2x does not leak | `t05` (bought on L2; WON clears it; L3 is 1x and not entitled) | suite §1b |
| free M23 auto-2x independent | `t06` (no entitlement, exhausted → 2x, no SB, no popup; next level 1x) | suite §1b |
| retry keeps the timed default | `t07` (manual 1x, Retry → 2x) | suite §1 |
| UI countdown and runtime factor cannot disagree | `t07b` + `_speed_ok` on every case (factor and HUD state asserted together) | suite |
| video | Level 2 auto-starts at 2x, caption "live 2x timed 14:53 left" | `motion_r01_v02_timed2x_rail_flow_720x1440.mp4` |
| still | `r01_timed_2x_new_level_L2_frame_1080x2160.png` | evidence |

## 2. WAITING / ACTIVE removed

`scripts/ui/batch_slot_view.gd`:
- Both refresh paths (normal and shell) now write an empty state label.
- The label node is kept and reserves the exact box the two words occupied, measured from the label's real theme font. This keeps every slot origin and anchor identical: the first attempt without the reserve broke `m29_presentation_identity_evidence` and `m52_r02_early_slot_release`, which showed the slot layout matters.
- WAITING gets a muted thin rim and ACTIVE keeps the cyan border, so the two states stay distinct without words.
- The temporary sixth slot uses the same component.

| Case | Proof |
|---|---|
| `s01` | Five occupied slots, and then the sixth: no `WAITING` / `ACTIVE` text in the strip subtree or in any Label or Button on the whole gameplay screen. Every slot view's state label is empty and robot counts are still shown. |
| `s02` | Slot truth is unchanged (state ACTIVE / WAITING, count = remaining − committed). The two states have different border colour and width. |
| Stills | `r01_gameplay_*_grid_slots_no_labels_*.png`, `r01_gameplay_sixth_slot_no_labels_1080x2160.png` |

## 3. Railway-first routing

**Root cause:** the railroad Dijkstra (V07) gave one rail unit and one interior unit the same cost, so an equal-length staircase through the artwork tied with "follow the rail". The BOTTOM-first tie-break always chose the early exit.

**Fix** (`scripts/gameplay/routing/production_routing_system.gd`):
- `INTERIOR_STEP_COST = 1000.0`, larger than the longest rail loop (256 cells). This makes the search lexicographic:
  1. fewest interior steps, which means the perimeter point nearest the target and an aligned straight final leg whenever the column or row is open;
  2. shortest rail distance;
  3. the unchanged BOTTOM → LEFT → RIGHT → TOP and scan-order tie-break.
- `interior_step_cost` is an instance variable, so tests can reproduce the old behaviour with `1.0`.
- Unchanged:
  - the access truth (`ProductionAccessQuery`);
  - the RouteValidator gate;
  - the connector and rail geometry (`ScrubRailGeometry`);
  - the `TargetSelector`, claim and reservation code, and `ScrubbotAgent`.

| Prompt test | Case | Proof |
|---|---|---|
| hugs the rail, exits at the nearest valid point, left/right/top/bottom | `r01`, `r02` | 3 slot positions × 7 targets (left, right, top, bottom, deep left/top/bottom) on a 40×40 board. Independent oracle: expected exit = lexicographic (distance, rail distance, side) over the four aligned exits. Every route is valid, ends on the target, enters the board at exactly the expected crossing point, has board travel = 0.5 + nearest-edge distance, and is axis-aligned. |
| vs the old cut-through | `r03` | Board travel over the 21 routes: 134 vs 568 cells (18 of 21 strictly shorter, none longer). |
| blocked aligned exit | `r04` | Cells (0,15) and (1,15) blocked: route stays valid, and board travel = 0.5 + 4 (independent BFS oracle). |
| corner-adjacent | `r05` | 8 corner / corner-adjacent targets × 2 slots: exit ≤ 1 cell from the target, axis-aligned, no cut-through. |
| identity | `r06` | Real Level 2 host, run twice (cost 1.0 vs default). The first 25 spawned Scrubbots are assigned the same target cells in the same order. Both runs finish WON with all 1024 cells cleared exactly once. Identical (target, colour) clear sets. Zero reservations left. Wave board travel is never more than before. |
| diagrams | `route_compare_open_40x40_slot_left/right.png`, `route_compare_blocked_exit_30x30.png` | Green railway-first vs red previous. Board travel: 37 vs 300 (left slot) and 37 vs 182 (right slot) cells. |
| motion | `motion_r01_v02_rail_frames_L2.png` (6 consecutive frames), the video | Scrubbots stay on the rail and enter at the perimeter |

**Solver and difficulty truth pinned:** the railway-first cost applies only to the live gameplay host's travel path. `ProofKernel` (the M27 solver) and both difficulty analyzers (V1, V2 candidate) set `interior_step_cost = TOTAL_TRAVEL_COST` (1.0), which is the audited equal-weight behaviour.

Why this matters: my first full regression run showed `m53_first10_difficulty` and `m53_c002_difficulty_calibration` failing "fresh run == committed raw evidence". The route-length metrics (`lastWaveMaxRoute`, `routes/*`) had changed, because the analyzer measures through the kernel's routing. After pinning, both pass again and the committed Difficulty V1 evidence is byte-identical.

Reachability is the same under both costs: the same legal graph is searched, and only the choice among legal paths differs. The `r06` case additionally proves identical target, claim and clear sets in the live host.

**Coordination note:** `OWNER_SCRUBBOT_RAILROAD_INTERIOR_PATH_DECISION_V01` describes the Dijkstra as minimising total legal route cost. Owner finding 3 asks for railway-first, so only the interior weight changed. ChatGPT / owner should record that in the decision file if wanted; I did not edit coordination decisions.

## 4. Dynamic pixel grid / bevel

**Implementation:**
- `scripts/gameplay/board/board_pixel_grid.gdshader`: one canvas-item shader on the existing `BoardRenderer` TextureRect (one texel per cell).
  - `grid_size` = real width × height.
  - Each fragment samples its own cell's texel centre, so the palette colour and the ACTIVE / CLEARED verdict come from that cell.
  - CLEARED (alpha 0) emits fully transparent.
  - A thin dark gutter, a rounded-corner tile and a light-top-left / dark-bottom-right bevel are measured in screen pixels (`fwidth`) and clamped.
- `BoardRenderer._apply_grid_style()` derives `gutter_alpha`, `bevel_strength` and `corner_radius` from a density factor over 20..59 cells (bolder on 20×20, fainter on 59×59).
- `set_grid_enabled()` is for tests and evidence.
- No node per cell; the renderer image and `get_pixel_color()` are unchanged.

| Case | Proof |
|---|---|
| `g01` | `grid_size` == real (w, h) for 7 dimensions, including 20×59 and 59×20. The shader has no mask texture. Strength decreases from 20×20 (0.62 / 0.16) to 59×59 (0.40 / 0.09). |
| `g02` | Grid on vs off: identical palette pixels, cell size, board size and every cell centre (local and global). |
| `g03` | A cleared cell is alpha 0 and the shader emits transparent for it. |
| `g04` | 59×59 board (3481 cells): one TextureRect, 0 child nodes. |
| GPU `board_grid_probe` | On 6 dimensions (20×20@30, 24×32@24, 38×38@16, 59×59@12, 20×59@14, 59×20@14): gutters are on the cell boundaries (±1 px), cell cores keep the exact palette colour, gutters are darker than the core, cleared cells equal the background exactly (0 ghost pixels, with the grid ON), and grid on/off differ only inside ACTIVE cells. |
| Stills | `grid_*_cs*.png` + `_zoom.png`; `r01_gameplay_L1/L2/L3_*` at 20×20, 32×32, 38×38 |

Hit-testing, targets and clear truth are unchanged. This is the M28 static-shell coordinate round-trip (M28 static shell 16/16, M28 layout smoke).

## 5. Home background

**Wiring:**
- The file `assets/ui/final/home/background/home_background.png` (940×1672, sha256 `9d5db295…abe2`) is used byte-for-byte. It is added as manifest `HOME-121` `home_background_whispering_park` (APPROVED, sha-pinned, authority = this prompt).
- `data/config/home_worlds_v1.json` `world_01` now points at it (canvas 940×1672).
- The anchors were re-measured for this image:
  - Scrubby feet (470, 1240) and safe box (305, 620, 330, 620);
  - sign rect, platform rect, and two helper-bot rects.
- `HomeScreen` uses new constants `PLATFORM_BOTTOM_Y` and `SIGN_TOP_Y`, and a re-based `HERO_SHADE_RECT`.
- The transform algorithm is unchanged, and it is still uniform and never stretched. The old `world_01_whispering_park_1080x2160.png` (HOME-120) stays byte-identical and is `OWNER_RETIRED`, so it is never loaded.

| Case | Proof |
|---|---|
| `h01` | `WorldBackground.texture.resource_path` == the exact path; 940×1672; sha matches; bound through `HomeArtBinder` (`APPROVED_BOUND`); catalog slug and canvas; drawn at the image's own aspect. |
| `h02` | The new background is drawn exactly once. No `worlds/world_01` or `home_bg_*` texture is visible. It is the bottom-most world layer. |
| `h03` | PLAY, 4 shortcuts, 5 nav buttons, Gift Meter, currency chip and Scrubby remain live native nodes. Nothing is baked into the background. |
| Stills | `r01_home_{1080x2160,1170x2532,1290x2796,1080x1920,1536x2048}.png` |

**Existing tests updated because they froze the old world.** The asserted properties are unchanged; only the frozen numbers moved.
- `m42_assets`: counts 51 → 52 (one new APPROVED entry).
- `m42_home`, `m42_home_composition`: accounted entries 52, 8 OWNER_RETIRED.
- `m42_home_v04`: world path, sha, canvas, anchor, slug.
- `m42_home_v05`, `m42_home_v06`, `m42_home_v07_safe_area`:
  - the frozen world-transform tables were re-baselined for the new image (14 viewports × insets);
  - anchor numbers.

The new transform is checked independently by the same suites: touch targets, PLAY below the platform row, sign below the Gift Meter, uniform scale.

Known visual note: on wide (tablet) and short-phone viewports the existing mirrored side-band mechanism shows. The new image's outer 3–5 px columns are dark, so the mirror seam reads as a thin dark line. This is the established V04 fallback and is not changed.

## 6. Scope

- Root `TASKS.md` untouched.
- No price, duration, Heart, booster or M23 change. No solver, target, claim or reservation change. The popup family and the Gameplay V02 shell are unchanged.
- No unrelated Home features.

## 7. Owner replay still required

1. Timed 2x: buy 15/30/60 min on Level 1 or 2 → win → Continue → the next level must start 2x with the countdown running. Also close and relaunch the app.
2. Slot row: no WAITING / ACTIVE words, on five and six slots.
3. Railway-first motion: watch Scrubbots follow the rail and enter at the nearest point (video / frames).
4. Grid / bevel: readability on small, medium and large / dense levels.
5. Home with the selected background: including the tablet / short-phone mirrored side bands.
