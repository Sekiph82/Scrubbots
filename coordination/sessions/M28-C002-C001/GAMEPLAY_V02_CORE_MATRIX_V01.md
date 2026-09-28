# M28-C002-C001 — GAMEPLAY V02 CORE MATRIX V01

Date: 2026-09-28
Actor: Claude (implementer). No audit verdict or owner acceptance is claimed.
Prompt: `coordination/sessions/M28-C002-C001/task_prompts/SB-M28-C002-C001_GAMEPLAY_V02_CORE.md`

Authority:
- `coordination/OWNER_GAMEPLAY_SCREEN_COMPOSITION_V02.md`
- `coordination/OWNER_GAMEPLAY_MASTER_VISUAL_V01.md` (master = reference only)
- Railroad V1 decisions
- speed/economy owner rules

Focused evidence: `tests/m28_c002_c001_gameplay_v02.gd` (14/14 cases, 109 ok)
Owner review pack: `coordination/sessions/M28-C002-C001/OWNER_GAMEPLAY_V02_REVIEW_V01.md`

## 1. What changed (real production screen)

`ProductionGameplayHost` still builds exactly one `GameplayScreen` (`scripts/ui/gameplay_screen.gd`). That screen is now the V02 composition. No mockup and no flattened master image is used.

```text
TOP      ProfileChip (Scrubby portrait, live Level N, live Bot Parts parts/cost)   PAUSE | 2x
BOARD    BoardRenderer (single Image) + ScrubRailView: full four-sided Railroad V1 skin
         + five permanent slot->bottom-rail connectors (sixth only with the +1 Slot slot)
SLOTS    execution slots (5 baseline / 6 with +1 Slot) on a navy tray
SUPPLY   BatchSupplyPanel (3/4/5 columns x 3 visible rows) — Scrubby low-left, props right
BOOSTERS +1 Slot / Random / Selector / Tornado (live charges / price / state)
```

Removed from the gameplay screen:
- the bottom `BottomActionRow` (Pause | AdPlaceholder | speed);
- native placeholder anchors;
- the empty top spacer.

There are no Settings, Heart HUD, Goal/Moves/Time or Level-rail nodes.

Gameplay truth is untouched:
- no change to BoardState, M23–M27 engines, routing (`ScrubRailGeometry`, `ProductionRoutingSystem`), input controller logic, completion/retry, or economy services/prices;
- `SlotOriginProvider` is unchanged; the screen reuses it for connectors.

## 2. Row status (implementer view; audit decides)

| Row | Status this cycle | Evidence |
|---|---|---|
| 001 native V02 scene/layout | implemented | `composition_no_obsolete`, `responsive_matrix`; evidence #1 |
| 002 BoardRenderer dominant / rectangular | implemented | board area > slots + supply and > 4× boosters at all 7 sizes; aspect error < 0.01 (32×32, 38×38, 20×20, 24×40) |
| 003 four-sided Railroad V1 production skin | implemented | `ScrubRailView` uses approved `rail_straight_horizontal.png` (tube = exactly 1.0 cell) and `rail_energy_node.png` corners on the unchanged `ScrubRailGeometry` centrelines (clearance 2.0, width 1.0, centreline 2.5). Procedural fallback retained. |
| 004 five permanent connectors aligned with real movement | implemented | `connectors_truthful`: each connector is `[SlotOriginProvider.origin_for_slot(i), ScrubRailGeometry.bottom_entry(origin.x)]`, the two points `ProductionRoutingSystem` uses; drawn while slots are EMPTY; origin = visible slot top-centre |
| 005 five baseline + temporary sixth | implemented | `sixth_connector_conditional`: +1 Slot → 6 slots and 6 connectors (6th = `origin_for_slot(5)`); Retry → back to 5 / 5 |
| 006 5×3 supply, 3/4/5 truth | implemented | `supply_columns_rows` (3×3, 4×3, 5×3); tiles are batch-coloured with a live count |
| 007 only fronts interactive | implemented (M29 logic unchanged) | `preview_non_interactive`: preview rows IGNORE with no `gui_input` connection and are dimmed; a synthetic preview press/release places nothing |
| 008 Pause + 2x top-right, live states | implemented | `pause_top_right`, `speed_modes`, `timed_2x_wallclock` |
| 009 robot/profile, no Heart HUD / Settings | implemented | Scrubby portrait; level = host frontier; Bot Parts = `RobotUnlockService.next_robot_progress()`. No XP/player-level invented. |
| 010 four canonical booster controls | implemented | exact ids and order; `BoosterInventory.BOOSTERS` |
| 011 live booster overlays | implemented | `four_boosters_live`: badge = charges; price = `EconomyConfig.booster_price`; states available / purchasable / unavailable / selected. `locked` exists but is never shown, because no booster unlock authority exists. |
| 012 BoosterAcquire popup routing | **DEFERRED (dependency)** | only a request seam exists: `ProductionGameplayHost.booster_acquire_requested(id)`, emitted on a no-charge tap; nothing is spent |
| 013 final 2x Acquire popup | **DEFERRED (dependency)** | the existing functional `SpeedAcquisitionPopup` is unchanged and still used |
| 014 canonical Pause popup | **DEFERRED (dependency)** | Pause keeps the existing runtime pause toggle plus a dimmed pressed visual |
| 015 final modal-stack input suppression | **DEFERRED (dependency)** | existing input safety is unchanged |
| 016 background / Scrubby / decorative hierarchy | implemented with owner items | Scrubby `scrubby_gameplay.png` low-left; `bubble_bucket.png` + `caution_wet_floor_sign.png` right; decoration hides below 96 px side width. No approved portrait gameplay backdrop exists, so a native BG01 gradient is used (review item V1). |
| 017 responsive viewport matrix | implemented | `responsive_matrix`, `safe_area_insets`, `tests/m28_gameplay_layout_smoke.gd` (253 checks) |
| 018 mouse/touch, rapid taps, sixth-slot readability | implemented (M29 input unchanged) | `front_click_mapping`; M29 input/rapid-tap suites; six slots ≥ 120 px |
| 019 full owner-review pack incl. popups | **partial** | core pack delivered; popup views deferred with 012–015 |
| 020 audit + owner playtest acceptance | not claimed | |

## 3. Connector truth (row 004)

The screen computes connectors after every layout pass and after every strip re-sort (capacity 5 ↔ 6, responsive resize):

```text
origin = SlotOriginProvider.new(presentation, strip, board).origin_for_slot(i)   # runtime route start
entry  = ScrubRailGeometry.bottom_entry(origin.x)                                # runtime bottom-rail entry
```

`ScrubRailView.set_connectors()` draws exactly those segments using the approved `rail_slot_connector.png`, 0.9 cell wide, chevrons pointing slot → rail.

- The slot row is kept inside the rail span, so connectors are vertical.
- If a narrow board ever forces the row wider, the outer connector bends to the clamped entry, exactly as the route does.
- A slot with no finite mapping gets no connector (fails closed, like the route).

## 4. 2x presentation (row 008) — Economy truth untouched

| Mode | Condition (from services) | Presentation |
|---|---|---|
| off | no manual entitlement, 1x | approved `button_speed_2x.png` ("2x") |
| level | 2x on + `is_manual_2x_entitled(level)`, no timed | approved `button_speed_2x_active.png` (selected) |
| timed | `timed_seconds_remaining() > 0` | approved `button_speed_2x_countdown_frame.png` + live "2x" + live `MM:SS` (`H:MM:SS` ≥ 1 h). Selected when 2x is on; dimmed when toggled to 1x, since the entitlement keeps counting. |
| auto | 2x on without manual entitlement (free M23-exhausted path) | active art, green tint; a tap only toggles 1x and never opens purchase UI or spends |

The label is refreshed by a 1 s host `HudTimer` (`ignore_time_scale = true`). The timer only schedules a redraw; the value is always `SpeedEntitlementService.timed_seconds_remaining()` (wall clock plus the M55-C002 high-water mark).

Test (`timed_2x_wallclock`):
- 15:00 → +62 s wall clock at `Engine.time_scale = 4` → 13:58;
- clock rolled back 600 s → still 13:58;
- after expiry → "2x".

Purchase flow, prices and `_on_speed_pressed` gating are unchanged.

## 5. Booster control semantics (rows 010/011; 012 deferred)

`request_booster(id)`:

| Situation | Result |
|---|---|
| no economy / terminal | refused, nothing spent |
| 0 charges | `acquire_required` + `booster_acquire_requested(id)`; **no SB debit** |
| charge + +1 Slot | `ProductionActionFacade.plus_one_slot()` (charge-first; host transaction/rollback unchanged) |
| charge + Random | `ProductionActionFacade.random()` (charge-first; a refused effect refunds the charge) |
| charge + Selector / Tornado | `target_selection_required`; no charge consumed (target UI belongs to the booster flow, not built here) |

The UI never mutates the wallet or inventory directly (`booster_requests_no_silent_spend`).

## 6. Responsive matrix (`responsive_matrix`, Level 2 = 32×32 real content)

Checked at 1080×2160, 1170×2532, 1290×2796, 1080×2400, 1440×3200, 1080×1920 and 1536×2048 (tablet). Each size must satisfy:
- board aspect exact;
- board dominant;
- rail envelope, HUD, slots, supply and boosters inside the safe rect;
- strict vertical order HUD → board + rail → slots → supply → boosters;
- Pause/2x ≥ 88 px;
- every supply front ≥ 88 × 88 px and on screen;
- slots ≥ 120 px;
- coordinate round-trip error ≤ 4e-6.

Safe areas (`safe_area_insets`):
- 1170×2532 with a 141 px notch and 102 px gesture bar;
- 1080×2400 with 96 / 132 px insets;
- every essential control lies inside the inner rect.

## 7. Sensitivity (mutated → focused suite → restored)

| Mutation | Result |
|---|---|
| connectors offset 0.7 cell from the runtime origin | exit 1, FAIL 3 |
| `AdPlaceholder` re-added | exit 1, FAIL 1 |
| no-charge booster tap spends through the facade | exit 1, FAIL 1 |
| countdown fed a constant instead of wall clock | exit 1, FAIL 2 |
| preview rows not visually distinct | exit 1, FAIL 1 |

## 8. Assets

Bound (read-only; none written or regenerated):
- `gameplay/railroad/rail_straight_horizontal.png`, `rail_energy_node.png`, `rail_slot_connector.png`;
- `gameplay/controls/button_pause.png`, `button_speed_2x.png`, `button_speed_2x_active.png`, `button_speed_2x_countdown_frame.png`;
- `gameplay/profile/scrubby_portrait.png`;
- `characters/scrubby/scrubby_gameplay.png`;
- `gameplay/decorative/bubble_bucket.png`, `caution_wet_floor_sign.png`;
- `boosters/extra_slot.png`, `random.png`, `selector.png`, `tornado.png`;
- `boosters/states/booster_selected_ring.png`, `booster_unavailable_overlay.png`.

Mipmapped copies of the rail art are built **in memory** at runtime (`Image.generate_mipmaps` on a loaded copy) for smooth downscaling. Source files are untouched.

Not bound, and why (listed for owner review):
- `gameplay/profile/profile_panel_frame.png`, `bot_parts_bar_fill.png`, `gameplay/slots/slot_*.png`: opaque white backgrounds/corners, so they cannot be composited without editing approved art. Native renditions are used instead.
- `gameplay/environment/gameplay_environment.png`: an isometric arena prop, not a portrait backdrop.
- `gameplay/tutorial/speech_bubble.png`: loaded into the anchor but hidden, because there is no authorised tutorial copy (FTUE is M44).

`scrubbots_gameplay_master.png` is not referenced by any runtime code.

## 9. Test migrations (intentional, per prompt)

| File | Change |
|---|---|
| `tests/m28_gameplay_layout_smoke.gd` | The bottom `pause < ad < speed` assertion is replaced by V02 checks: PAUSE \| 2x top-right, profile top-left, no ad/Settings/Heart. `board > bottom row` becomes `board > top HUD`. Every other safety assertion is kept (matrix, aspect, 5 slots, 3/4/5 × 3 supply, safe area, board-size matrix, round-trip). Evidence now goes to `coordination/sessions/M28-C002-C001/layout_smoke/`, so the historical M28-C001 evidence is not overwritten. |
| `tests/m52_r01_parallel_runtime.gd` | The speed-button text checks `"2x"` / `"1x"` become `get_speed_state()`. The V02 inactive label is "2x" (owner §5); the behaviour assertions are unchanged. |
