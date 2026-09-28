# M28-C002-C003 — Owner Gameplay V02 Final Review V01

Date: 2026-09-28
Status: **OWNER DECISION REQUIRED**. Nothing below is self-approved.
Technical matrix: `GAMEPLAY_V02_FINAL_MATRIX_V01.md`
Evidence: `coordination/sessions/M28-C002-C003/evidence/`

## How to review

1. Watch `evidence/motion_gameplay_v02_popup_flow_720x1440.mp4` (33.6 s, real runtime capture, step captions under the game). `motion_contact_sheet_1fps.png` gives a one-image overview.
2. Look at the `final_*` screenshots listed per item.
3. **Hands-on playtest (required).** The video is recorded evidence, not your own interactive playtest. Please also play Level 2 yourself, in the editor or on a device, and try the items marked ▶.

```bash
godot --path .
```

To reproduce the evidence:

```bash
godot --path . -s res://tests/tools/gameplay_v02_final_snapshot.gd -- coordination/sessions/M28-C002-C003/evidence
```

```bash
godot --path . --write-movie out.avi --fixed-fps 30 --resolution 720x1440 -s res://tests/tools/gameplay_v02_motion_capture.gd
```

## Checklist — mark PASS / FAIL (+ note)

| # | Item | Where to look | PASS / FAIL |
|---|---|---|---|
| 1 | Fresh Gameplay V02 composition is accepted | `final_fresh_level_1080x2160.png`, video 0–1.8 s | ☐ |
| 2 | Active cleaning is readable | `final_active_cleaning_1080x2160.png`, video 1.8–6.7 s ▶ | ☐ |
| 3 | Five occupied slots are readable | `final_five_slots_occupied_1080x2160.png` | ☐ |
| 4 | Sixth slot is readable | `final_sixth_slot_active_1080x2160.png`, video 18–22 s ▶ | ☐ |
| 5 | A zero-charge booster tap opens the correct Acquire popup | `final_booster_acquire_open_1080x2160.png`, video 11 s / 16.4 s ▶ | ☐ |
| 6 | The Selector / Tornado target picker feels clear | `final_selector_or_tornado_picker_open_1080x2160.png` (Selector, 12 chips), `final_tornado_picker_open_1080x2160.png`, video 13.1 s ▶ | ☐ |
| 7 | A popup blocks accidental gameplay taps | ▶ Try tapping supply, boosters, 2x and Pause behind any popup: nothing should happen | ☐ |
| 8 | Pause opens and closes correctly, and its visual hierarchy is accepted | `final_pause_open_1080x2160.png`, video 6.7–9 s ▶ | ☐ |
| 9 | Unentitled 2x opens 2x Acquire | `final_2x_acquire_open_1080x2160.png`, video 21.9 s ▶ | ☐ |
| 10 | 2x purchase and the timed countdown are presented clearly | `final_timed_2x_active_1080x2160.png` (14:13), video 24.4 s+ (15:00 counting down) ▶ | ☐ |
| 11 | Popup stacking and Back behave correctly | ▶ Pause → Restart → Keep playing; Tornado with low SB → Insufficient SB → Back | ☐ |
| 12 | No visual jump or corruption when a popup closes | video 9 s, 14.8 s, 24.4 s ▶ | ☐ |
| 13 | Short phone is readable | `final_short_phone_booster_acquire_open_1080x1920.png`, `final_short_phone_2x_acquire_open_1080x1920.png` | ☐ |
| 14 | Tablet is readable | `final_tablet_2x_acquire_open_1536x2048.png`, `final_tablet_booster_acquire_open_1536x2048.png` | ☐ |
| 15 | **Overall Gameplay V02 shipping visual acceptance** | all of the above | ☐ |

**Additional context shots:**
- `final_sixth_slot_booster_acquire_open_1080x2160.png`: the popup is over the 6-slot state. The centred popup covers the slot strip; the strip is unchanged underneath.
- `final_tall_phone_*_1290x2796.png`
- `matrix_*`: 1170×2532, 1080×2400, 1440×3200.

## Notes for the owner (no action unless you disagree)

- **No design changes this cycle.** Everything shown is the accepted Gameplay V02 static shell plus the already approved M43-C002 and M43-C003 popups:
  - A1-KEEP, B1-POPUP (12-chip cap), C1-KEEP, D1-OK, E1-OK, F1-GATE.
- **The bubble copy stays as approved** ("LET'S CLEAN THIS MESS! / Tap a batch below to send the Scrubbots."). A popup partially covers the bubble while it is open, as in the M43 evidence.

## Owner verdict

- [ ] **ACCEPT**: SB-M28-C002-020 may close after the ChatGPT audit.
- [ ] **REMEDIATE**: list the item numbers and notes.
