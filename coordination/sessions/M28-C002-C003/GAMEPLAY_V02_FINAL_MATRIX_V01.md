# M28-C002-C003 — Gameplay V02 Final Popup-Inclusive Matrix V01

Date: 2026-09-28
Prompt: `coordination/sessions/M28-C002-C003/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/M28-C002-C003/CHATGPT_AUDIT_CRITERIA_V01.md`
Status: **AWAITING_CHATGPT_AUDIT** (owner playtest gate for SB-M28-C002-020 stays open)

## 0. Validation-first outcome

The M43-C003 implementation (audited `cb3b871`, owner-approved `1e7e716`) already routes the real Gameplay V02 controls correctly. **No shipping behaviour was changed.** The only production edit is a comment. The doc comment on `ProductionGameplayHost.request_booster()` still said the Booster Acquire popup and the target picker were "not implemented"; that was documentation drift and is now corrected.

What this cycle adds:
- `tests/m28_c002_c003_final_gate.gd`: a focused suite that drives every flow through the **visible** controls, using routed pointer input via `SubViewport.push_input`.
- `tests/tools/gameplay_v02_final_snapshot.gd`: the final screenshot pack.
- `tests/tools/gameplay_v02_motion_capture.gd`: a real Godot Movie Maker gameplay video.
- The evidence under `evidence/`.

## 1. Code path (unchanged, verified)

| Visible control | Signal → host | Zero charge / unentitled | Owned / entitled |
|---|---|---|---|
| Booster row `Booster_<id>` (`GameplayScreen._make_booster`) | `booster_pressed(id)` → `request_booster(id)` | `reason=acquire_required`, `booster_acquire_requested(id)`, `AcquisitionFlow.open_booster(host, id)` on the app ModalStack | +1 Slot / Random → `ProductionActionFacade` charge-first; Selector / Tornado → same popup in USE mode |
| Booster Acquire `use` / `sb` | `AcquisitionFlow._on_booster_action` → `host.execute_booster(id, target)` | Facade → BoosterService: legality pre-check, SB reservation, refund on failure | — |
| Picker chips | `host.booster_legality()`: Selector from `eligible_safe_batches()`, Tornado from `present_colors()` (same adapter as the transaction) | — | — |
| 2x box | `pressed` → `_on_speed_pressed()` | not entitled → `_open_speed_acquisition()` → `SpeedAcquisitionPopup` (`speed_acquire`) | entitled → `runtime.toggle_speed()`, no charge |
| 2x offer | `offer_chosen` → `ProductionActionFacade.buy_current_level_2x / buy_timed_2x` | success → 2x on, popup closed; insufficient → Insufficient SB → Shop handoff | — |
| Pause box | `pressed` → `open_pause()` | canonical Pause popup, same ModalStack | — |
| Any popup open | `ModalStack.modal_changed(true)` → `_input.set_modal_blocked(true)` + runtime user pause | `request_booster` → `modal_open`; `_on_speed_pressed` ignored; full-rect scrim `MOUSE_FILTER_STOP` | — |

## 2. Row mapping

### SB-M28-C002-012 — zero-charge booster → canonical Booster Acquire

| Prompt §B item | Proof (`tests/m28_c002_c003_final_gate.gd`) | Evidence |
|---|---|---|
| 1. Exactly four canonical boosters | g01: `get_booster_ids() == [plus_one_slot, random, selector, tornado]` | all `final_*` shots |
| 2. No silent failure, no immediate debit | g01: routed tap → `acquire_required` + seam emitted once; `_truth()` identical (full `EconomyServices.snapshot()`, wallet, supply, slots, board revision / cleared count, capacity, speed) | `final_booster_acquire_open_1080x2160.png` |
| 3. Canonical popup on shared ModalStack | g01: `host.get_modal_stack() == root.get_modal_stack()`, top = `booster_plus_one_slot` BasePopup | same |
| 4. Popup matches tapped booster + live charge / price / legality | g01 (+1 Slot: owned 0, 500 SB, balance 5,000, legal); g02 (Selector / Tornado / Random titles, 350 SB); g07 (+1 Slot already active → safety line, CTA disabled) | `final_booster_acquire_open`, `final_sixth_slot_booster_acquire_open` |
| 5. Selector / Tornado popup picker (B1-POPUP) | g02: chip count = min(targets, 12), every key in the adapter's solver-safe proof, CTA disabled until a routed chip tap | `final_selector_or_tornado_picker_open` (Selector, 12 chips), `final_tornado_picker_open` (5 colours) |
| 6. Owned charge stays charge-first | charge_first: owned Selector → USE mode, no purchase CTA, not consumed; owned +1 Slot → direct use, no popup, SB untouched | `final_sixth_slot_active` (owned charge path) |
| 7. Background input blocked | g05 / g06: every supply front (mouse + touch), all 4 boosters, 2x, Pause, board centre → zero effect; runtime held; input gate closed | video 11.0–16.4 s |
| 8. Close / cancel mutates nothing | g02, g04: X (routed), Android Back, Escape (`ui_cancel`) for all four boosters → identical truth, runtime released | video 14.8 s |
| 9. SB / rewarded commit via canonical solver-safe authority | sb_commit_canonical: +1 Slot SB tap −500 once, capacity 6; Tornado chip + SB tap −750 once, that colour removed via BoosterService. Rewarded path unchanged (M43-C003 c18–c21 re-run PASS) | video 16.4–21.9 s |

### SB-M28-C002-013 — unentitled 2x → canonical 2x Acquire

| Prompt §C item | Proof | Evidence |
|---|---|---|
| 1. Unentitled tap → `speed_acquire` | g08: routed tap on the 2x box | `final_2x_acquire_open_1080x2160.png` |
| 2. No free manual 2x | g08: `is_2x()==false`, mode `off` | same |
| 3. No debit on open | g08 / g09: `_truth()` identical | same |
| 4. Exactly 200 / 300 / 500 / 750 SB | g08: keys `[level, timed_900, timed_1800, timed_3600]` + prices, no `watch` | same, `final_short_phone_2x_acquire_open`, `final_tablet_2x_acquire_open` |
| 5. Purchase immediately enables 2x | g10: routed offer tap −200 once, 2x on, mode `level`, popup closed | video 24.4 s |
| 6. Entitled switching is free | g11: 6 routed taps alternate 1x / 2x at 0 SB; g12: timed entitlement toggles free | video 28.8–33.6 s |
| 7. Timed countdown live | g12: after the 15m tap the box reads 15:00; +75 s → real `HudTimer` redraws 13:45 (no manual refresh); a 400 s rollback is frozen by the M55 high-water | `final_timed_2x_active` (14:13), video 24.4 s+ (15:00 → 14:52) |
| 8. Free M23 auto-2x independent | auto_2x_independent: tap during auto-2x → no popup, no spend, entitlement untouched (M52 / M29 real exhausted path re-run PASS) | — |
| 9. Popup-open input isolated | g08: supply / booster / Pause behind 2x Acquire blocked; CANCEL leaves identical truth | video 21.9–24.4 s |

### SB-M28-C002-019 — owner-review screenshots / video incl. popup-open states

All shots come from the real runtime and are **not composites**. The tool rejects a shot when the expected popup is not on top, when `text_fits()` fails, or when the level is terminal.

| Required | File |
|---|---|
| 1 fresh level | `evidence/final_fresh_level_1080x2160.png` |
| 2 active cleaning | `evidence/final_active_cleaning_1080x2160.png` |
| 3 five slots occupied | `evidence/final_five_slots_occupied_1080x2160.png` |
| 4 sixth slot active | `evidence/final_sixth_slot_active_1080x2160.png` |
| 5 Booster Acquire open | `evidence/final_booster_acquire_open_1080x2160.png` |
| 6 Selector / Tornado picker open | `evidence/final_selector_or_tornado_picker_open_1080x2160.png` (Selector) + `final_tornado_picker_open_1080x2160.png` |
| 7 Pause open | `evidence/final_pause_open_1080x2160.png` |
| 8 2x Acquire open | `evidence/final_2x_acquire_open_1080x2160.png` |
| 9 timed 2x active | `evidence/final_timed_2x_active_1080x2160.png` |
| 10 short phone + popup | `final_short_phone_booster_acquire_open_1080x1920.png`, `final_short_phone_2x_acquire_open_1080x1920.png` |
| 11 tall phone 1290×2796 | `final_tall_phone_cleaning_1290x2796.png`, `final_tall_phone_pause_open_1290x2796.png` |
| 12 tablet + popup | `final_tablet_2x_acquire_open_1536x2048.png`, `final_tablet_booster_acquire_open_1536x2048.png` |
| 13 sixth slot + popup | `final_sixth_slot_booster_acquire_open_1080x2160.png`, `matrix_1080x2400_sixth_slot_popup_1080x2400.png`. The centred popup covers the slot strip; the state underneath is proven by g07 (capacity, slot truth and slot-view rects unchanged under Booster / 2x / Pause), by shell id `6slot_3col`, and by the +1 Slot button in the selected state. |
| extra matrix | `matrix_1170_booster_acquire_open_1170x2532.png`, `matrix_1440_2x_acquire_open_1440x3200.png`, `matrix_1440_pause_open_1440x3200.png` |
| **video** | `evidence/motion_gameplay_v02_popup_flow_720x1440.mp4`: 33.6 s, 1,008 frames, 30 fps, real runtime (see §4) |
| video index | `evidence/motion_contact_sheet_1fps.png` (1 frame per second, ordered), `evidence/motion_timeline.txt` (step start times) |

### SB-M28-C002-020 — prerequisites for the audit + owner gate

| Prerequisite | State |
|---|---|
| Focused integration proof | `m28_c002_c003_final_gate` 22/22 cases PASS |
| Full regression | See `CLAUDE_LOG_V01.md` §Tests |
| Fresh popup-inclusive evidence + video | §2 SB-019 |
| Owner playtest checklist (15 PASS/FAIL items) | `OWNER_GAMEPLAY_V02_FINAL_REVIEW_V01.md`. Not self-approved. |
| Owner acceptance | **OWNER_REQUIRED**, not claimed |

## 3. Responsive / touch (§H)

The focused `responsive_matrix` covers every size: 1080×2160, 1170×2532, 1290×2796, 1080×2400, 1440×3200, 1080×1920 and 1536×2048.

**Base gameplay:**
- Pause, 2x and the four boosters sit inside the viewport and are at least 88 px (`UiTokens.TOUCH_MIN`);
- supply hit areas are at least 88 px tall;
- board, slot strip, supply and booster row do not overlap.

**Popups:** the checks run on Booster Acquire (+1 Slot), Booster Acquire (Selector picker), Pause, 2x Acquire, and the sixth slot with the Tornado Acquire open. Each must meet:
- `text_fits()`;
- the frame, hero, every visible action and every target chip lie inside the viewport;
- actions, close X and chips are at least 88 px.

**Stability:**
- gameplay geometry is identical before and after all popup cycles;
- the sixth-slot views stay inside the viewport.

Result: **7/7 sizes PASS, zero findings.**

## 4. Motion evidence

- **Tool:** Godot 4.7.2 **built-in Movie Maker** (`--write-movie`, `--fixed-fps 30`). No new dependency.
- **Encoding:** a locally installed `ffmpeg` only converted the MJPEG AVI to H.264 MP4 and built the contact sheet. The shipping project never depends on it.
- **Session:** one continuous real-runtime session. The runtime processes at the fixed movie step. Every interaction is a routed tap on the visible control, including supply fronts in the owner plan order.
- **Clock:** the economy wall clock is the movie clock, so the timed-2x countdown runs in video time.

| t (s) | Step |
|---|---|
| 0.0 | Fresh Level 2 |
| 1.8 | Supply taps, dispatch + cleaning |
| 6.7 | Pause popup (gameplay held) |
| 9.0 | RESUME |
| 11.0 | Tornado with 0 charges → Booster Acquire |
| 13.1 | Colour chip picked |
| 14.8 | Close X, nothing spent |
| 16.4 | +1 Slot with 0 charges → Booster Acquire |
| 18.3 | USE 500 SB → sixth slot (SB 2,000 → 1,500) |
| 21.9 | Unentitled 2x → 2x Acquire |
| 24.4 | 15 MIN bought (SB 1,500 → 1,200), 2x + countdown |
| 28.8 | Free switch to 1x |
| 30.5 | Back to 2x, no charge |

This is real recorded runtime video. It does **not** replace the owner's own interactive, hands-on playtest on device or in the editor. That playtest remains the SB-M28-C002-020 owner gate.

## 5. Scope locks honoured

- Root `TASKS.md` untouched.
- No static-shell, popup-visual, price, duration, booster-rule, Heart, solver or routing change.
- No ad SDK, no M43-C004+ work, no new art.
- Local `project.godot` modification and untracked owner media / `.import` caches preserved and not committed.
