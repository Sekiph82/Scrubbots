# M28-C002-C003 — CLAUDE LOG V01

Date: 2026-09-28
Prompt: `coordination/sessions/M28-C002-C003/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/M28-C002-C003/CHATGPT_AUDIT_CRITERIA_V01.md`
Scope: SB-M28-C002-012 / 013 / 019 and the SB-M28-C002-020 prerequisites
Status: **AWAITING_CHATGPT_AUDIT**

## Sync / governance

- Repo `Sekiph82/Scrubbots`, branch `main`.
- **Starting commit:** `c931f63`, fast-forwarded from `cb3b871` with no conflict.
- **Final commit:** the commit that adds this log. Its SHA is reported in the hand-off message, because a file cannot contain its own id.
- **Preserved and not committed:**
  - the pre-existing local `project.godot` modification (property reorder + removed `[audio]` default bus line; the path is Godot's default anyway);
  - all untracked owner media and `.uid` / `.import` caches;
  - `tests/_m55_diag_tmp.gd`.
- Root `TASKS.md` was read only. **It was not edited.**
- **Required reading done:**
  - `CLAUDE.md`, `TASKS.md`;
  - the M43-C003 audit + owner gate (A1-KEEP, B1-POPUP incl. 12-chip cap, C1-KEEP, D1-OK, E1-OK, F1-GATE);
  - the M43-C003 log;
  - the M28 C001 / C002 static-shell / R01 tests;
  - `tests/tools/gameplay_v02_snapshot.gd`, `acquisition_snapshot.gd`, `popup_pause_snapshot.gd`;
  - the host, AcquisitionFlow, BasePopup, ModalStack, SpeedAcquisitionPopup and GameplayScreen code.

## Validation-first result

The shipping implementation from M43-C003 already satisfies §B and §C through the real visible controls:
- `GameplayScreen.booster_pressed` → `request_booster()` → `AcquisitionFlow.open_booster()` on the app ModalStack;
- 2x `pressed` → `_on_speed_pressed()` → `SpeedAcquisitionPopup`.

The one gap found: all earlier proof drove `host.request_booster(id)` or `acq.open_booster()` directly. None tapped the visible booster button through routed input. This cycle closes that gap with tests and evidence, not with code.

**Shipping code change: comment only** (`scripts/gameplay/runtime/production_gameplay_host.gd`, `request_booster()` doc). It still said the Booster Acquire popup and the target picker were "not implemented / does not exist yet", which is documentation drift. There is no behaviour, visual, price, rule, solver or routing change.

## Files

**New:**
- `tests/m28_c002_c003_final_gate.gd`: focused suite, 22 ledger cases, routed mouse / touch input on visible controls.
- `tests/tools/gameplay_v02_final_snapshot.gd`: the final screenshot pack. Every popup is opened by a routed tap on the visible control. A shot is rejected if the wrong popup is on top, if `text_fits()` fails, if the level is terminal, or if the picker is empty.
- `tests/tools/gameplay_v02_motion_capture.gd`: Godot Movie Maker session with routed taps; the economy clock is the movie clock.
- `coordination/sessions/M28-C002-C003/evidence/`:
  - 21 PNG, the MP4, the contact sheet and the timeline;
  - `.gdignore`, so Godot does not import the evidence.
- `GAMEPLAY_V02_FINAL_MATRIX_V01.md`, `OWNER_GAMEPLAY_V02_FINAL_REVIEW_V01.md`, this log.

**Modified:** `scripts/gameplay/runtime/production_gameplay_host.gd` (comment only).

## Focused proof — `tests/m28_c002_c003_final_gate.gd`

**PASS, 22/22 cases, 0 fail** (full mapping in matrix §2).

"Truth" below means a full `EconomyServices.snapshot()`, wallet, supply snapshot, slot snapshot, board revision / cleared count, slot capacity and speed.

| §G | Case | Result |
|---|---|---|
| 1 | g01: zero-charge +1 Slot routed tap → `booster_plus_one_slot`; `acquire_required` + seam once; owned 0 / 500 SB / balance / legal | PASS |
| 2 | g02: Selector (12 chips) / Tornado (5 colours) / Random → matching popup. Chip keys ⊆ adapter solver-safe proof; CTA arms only after a routed chip tap | PASS |
| 3 | g01 / g03: opening leaves the full truth identical | PASS |
| 4 | g04: X / Android Back / Escape on all four boosters (target picked) → identical truth, runtime released | PASS |
| 5 | g05: every supply front, mouse **and touch**, under Booster Acquire → 0. Positive control: after close the same touch activates | PASS |
| 6 | g06: all 4 boosters, 2x, Pause and board behind the modal → no request, no second modal; programmatic `modal_open` | PASS |
| 7 | g07: 6 slots (6 occupied). Capacity, slot truth and slot-view rects are identical under Tornado / +1 Slot / 2x / Pause; +1 Slot shows the safety state | PASS |
| 8 | g08: unentitled 2x routed tap → `speed_acquire`, no free 2x | PASS |
| 9 | g08 / g09: no debit on open; exactly 200 / 300 / 500 / 750 SB; no rewarded 2x | PASS |
| 10 | g10: routed current-level tap → −200 once, 2x on, popup closed | PASS |
| 11 | g11: 6 entitled taps alternate 1x / 2x at 0 SB, no popup | PASS |
| 12 | g12: 15m → 15:00. +75 s → the real `HudTimer` redraws 13:45 (no manual refresh). A −400 s rollback is frozen. Free timed toggling | PASS |
| 13 | g13: routed Pause tap → Pause popup, runtime held; RESUME resumes | PASS |
| 14 | g14: Pause + Restart confirm — lower Pause controls and scrim taps do nothing. Booster Acquire + Insufficient SB — the lower X is unreachable, Back pops only the top | PASS |
| 15 | g15: X release + an immediate same-point tap → no side effect; RESUME tap does not leak | PASS |
| 16 | g16: 5 same-frame taps each → one booster popup / one 2x popup / one 300 SB purchase / one Pause / one 500 SB +1 Slot; touch behind a modal → 0 | PASS |
| 17 | g17: board / strip / slot views / fronts / booster row / Pause / 2x / connectors identical while each popup is open and after close | PASS |
| 18 | g18: 40 routed open / close cycles. Nodes 309 → 309, Timers 2 → 2; ModalStack / booster / 2x / Pause / rewarded connections stable | PASS |
| B6 | charge_first: owned Selector → USE mode, not consumed; owned +1 Slot → direct, no popup, SB untouched | PASS |
| B9 | sb_commit_canonical: +1 Slot −500 once; Tornado chip + SB −750 once, colour removed via BoosterService | PASS |
| C8 | auto_2x_independent: no popup, spend or entitlement change during free auto-2x | PASS |
| H | responsive_matrix: 7 sizes × (base + Booster Acquire + Selector picker + Pause + 2x Acquire + sixth slot + Tornado popup). Fit, no clipping or overlap, all targets ≥ 88 px, geometry unchanged | PASS |

## Regression gate

Run on Godot 4.7.2 headless, 12-way parallel, **all 112 suites** (every `tests/*.gd` except the untracked `_m55_diag_tmp.gd`).

**Result: 109 exit 0, 3 non-zero.**

**Root suite:** `tests/run_tests.gd` — **Total checks 5323, RESULT: ALL PASS.**

**Required suites (all PASS):**
- M28:
  - `c002_c001` 14/14;
  - `c002_c002_static_shell` 16/16;
  - `c002_c002_r01` 10/10;
  - `m28_gameplay_layout_smoke`.
- M29: all 7 suites, including `m29_input_gate_evidence`.
- M30: `completion_authority`, `transaction_safe_retry`, `manual_playtest_smoke`.
- M39: A–E, V02 (atomicity / capacity / integration), V03 (full surface / integration), V04 tornado in-flight.
- M40: save / V02 / V03 / V04.
- M43: C002 23/23, C003 34/34.
- M52: owner supply plans, R01, R02.
- M55: long session, core chaos, economy release, Heart 900, C002 timed-2x anti-rollback.

**Non-zero exits:**
1. `m21_v08_corridor_validation`: C/043, C/047.
2. `m21_v09_direct_evidence_reconciliation`: B.

   These are **identical** to the historical pre-Railroad-V1 baseline recorded in the M43-C003 log. No routing was touched.
3. `m39_v04_integration`: one assertion, `strip/sb: economy (charge/SB) exact`. **This is a pre-existing clock-boundary flake, unrelated to this cycle.**
   - Isolated serial reruns: PASS, FAIL (`engine/charge`, a different sub-case), PASS.
   - Root cause: the test compares `econ.snapshot()` before and after with `==` on the **real** wall clock. `HeartService.snapshot()` sets `anchor = now` when Hearts are full, and `SpeedEntitlementService.snapshot()` includes `clock_high_water = now`. Crossing a one-second boundary between the two snapshots breaks equality, even though charges and SB are exact.
   - This cycle changes no economy code and no M39 test.
   - I did not modify the M39 suite, because that is out of scope. A separate follow-up task was flagged to the owner: make the comparison clock-deterministic.

**Other checks:**
- `SCRIPT ERROR` appears only in the `m20_v04/v05/v07/v08_lifecycle_smoke` assertion-name baseline.
- The "ObjectDB leaked / resources still in use at exit" warnings match M43-C003 exactly (teardown noise).
- `git diff --check`: clean.

## Evidence

The directory is `coordination/sessions/M28-C002-C003/evidence/`. All nine required 1080×2160 files are present with the exact names from prompt §D. Also included:
- short-phone shots with a popup;
- tall 1290×2796;
- tablet with a popup;
- the sixth slot with a popup at 1080×2160 and 1080×2400;
- 1170 / 1440 matrix shots;
- the video, contact sheet and timeline.

**Screenshots:**
- Every popup screenshot was opened by a routed tap on the visible control; none is a composite.
- Picker shots use 2 occupied slots so that Selector is legal. With 5 slots full, Selector correctly shows its safety state.

**Motion — a real video was captured:**
- File: `motion_gameplay_v02_popup_flow_720x1440.mp4` (33.6 s, 1,008 frames, 30 fps).
- Recorded with **Godot's built-in Movie Maker**.
- Local `ffmpeg` was used only to transcode the AVI and tile the contact sheet. It is not a project dependency.
- Capture notes:
  - The window must be 720×1440 (exactly 1:2). On this 2560×1600 display a 1080×2160 window is clamped, and Movie Maker then records a centre crop.
  - Inside the video the real 1080×2160 render is scaled to 95 % so the caption strip fits.
- The video is recorded evidence. **The owner's own hands-on interactive playtest remains required** (SB-M28-C002-020, `OWNER_GAMEPLAY_V02_FINAL_REVIEW_V01.md`).

## Deviations / notes

1. **Sixth slot + popup.** The centred popup covers the slot strip, so the 6-slot state is not visible in that screenshot. It is proven by g07 (truth and rects unchanged), by shell id `6slot_3col`, and by the +1 Slot selected state. The unobstructed sixth slot is in `final_sixth_slot_active`.
2. **Supply setup.** Supply progress in the still screenshots is driven by `ProductionInputController.activate_front()` in owner-plan order, the same driver as the accepted R01 harness. The video and focused tests use routed taps on the supply hit areas.
3. **No owner item is self-approved.**

## Reproduce

Focused suite:

```bash
godot --headless --path . -s res://tests/m28_c002_c003_final_gate.gd
```

Screenshots:

```bash
godot --path . -s res://tests/tools/gameplay_v02_final_snapshot.gd -- coordination/sessions/M28-C002-C003/evidence
```

Video capture (AVI):

```bash
godot --path . --write-movie out.avi --fixed-fps 30 --resolution 720x1440 -s res://tests/tools/gameplay_v02_motion_capture.gd
```

Transcode to MP4:

```bash
ffmpeg -i out.avi -an -vf scale=720:-2 -c:v libx264 -pix_fmt yuv420p -crf 23 -movflags +faststart motion.mp4
```

`AWAITING_CHATGPT_AUDIT / M28-C002-C003 GAMEPLAY V02 FINAL POPUP-INCLUSIVE GATE`
