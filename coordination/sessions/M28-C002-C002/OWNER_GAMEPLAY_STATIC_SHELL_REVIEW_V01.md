# M28-C002-C002 — OWNER GAMEPLAY STATIC SHELL REVIEW V01

Date: 2026-09-28
Status: **CANDIDATE, awaiting owner visual review.** No owner acceptance is claimed.
Authority: `coordination/OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01.md`

Compare each image directly against its master:

- `assets/ui/final/gameplay/master/gameplay_v02_shell_5slot_3col.png`
- `assets/ui/final/gameplay/master/gameplay_v02_shell_5slot_4col.png`
- `assets/ui/final/gameplay/master/gameplay_v02_shell_5slot_5col.png`
- `assets/ui/final/gameplay/master/gameplay_v02_shell_6slot_3col.png`
- `assets/ui/final/gameplay/master/gameplay_v02_shell_6slot_4col.png`
- `assets/ui/final/gameplay/master/gameplay_v02_shell_6slot_5col.png`

## How the images were made

`tests/tools/gameplay_v02_snapshot.gd` uses two production paths:
- **3-column shots:** the real app root on real First 10 content, driven with your owner click plans.
- **4/5-column shots:** a real gameplay host with the M23 generator set to 4 or 5 columns on Level 1 content. No First 10 level uses 4 or 5 columns today; no content or plan was changed.

A shot is refused unless the running screen selected exactly the expected shell. All 12 were accepted.

```bash
godot --path . -s res://tests/tools/gameplay_v02_snapshot.gd -- coordination/sessions/M28-C002-C002/evidence
```

## Screens

All images are in `coordination/sessions/M28-C002-C002/evidence/`.

| # | File | Shell | State | Viewport |
|---|---|---|---|---|
| 1 | `c002_5slot_3col_L2_fresh_1080x2160.png` | 5slot_3col | Level 2 (Apple) fresh | 1080×2160 |
| 2 | `c002_5slot_4col_L1gen_fresh_1080x2160.png` | 5slot_4col | Level 1, 4-column generated supply | 1080×2160 |
| 3 | `c002_5slot_5col_L1gen_fresh_1080x2160.png` | 5slot_5col | Level 1, 5-column generated supply | 1080×2160 |
| 4 | `c002_6slot_3col_L2_plus_one_1080x2160.png` | 6slot_3col | +1 Slot used; all six slots filled | 1080×2160 |
| 5 | `c002_6slot_4col_L1gen_plus_one_1080x2160.png` | 6slot_4col | +1 Slot, 4 columns, six slots filled | 1080×2160 |
| 6 | `c002_6slot_5col_L1gen_plus_one_1080x2160.png` | 6slot_5col | +1 Slot, 5 columns, six slots filled | 1080×2160 |
| 7 | `c002_5slot_3col_L2_active_cleaning_1080x2160.png` | 5slot_3col | Scrubbots moving along the baked bottom rail and connectors | 1080×2160 |
| 8 | `c002_5slot_3col_L2_five_slots_occupied_1080x2160.png` | 5slot_3col | all five slots occupied | 1080×2160 |
| 9 | `c002_5slot_3col_L2_timed_2x_1080x2160.png` | 5slot_3col | timed 2x bought; **2x / 14:58** after 2 s of real wall clock; cleaning at 2x | 1080×2160 |
| 10 | `c002_5slot_3col_L3_tall_phone_1290x2796.png` | 5slot_3col | Level 3 (Palm) tall phone, cleaning | 1290×2796 |
| 11 | `c002_5slot_3col_L3_short_phone_1080x1920.png` | 5slot_3col | Level 3 short 16:9 phone, cleaning | 1080×1920 |
| 12 | `c002_5slot_3col_L1_tablet_1536x2048.png` | 5slot_3col | Level 1 tablet portrait | 1536×2048 |

What to look at:
1. **The master is the whole screen.** Environment, rail, board frame, slot frames and connectors, supply cells, profile frame, Pause/2x frames, Scrubby, bubble and props all come from your master. Godot draws none of them a second time.
2. **Board fit.** The level art sits inside the baked board field, and the runtime rail matches the baked rail to within about 5 px (#7, #9–#11).
3. **Scrubbots follow the baked rail and connectors** (#7, #9, #10, #11).
4. **Live slots and supply** fill the baked frames and cells. On the supply, the front row is bright with a cyan edge; preview rows are dimmed.
5. **+1 Slot switches to the matching 6-slot master** (#4–#6); Retry switches back. There is no extra drawn slot or connector.
6. **Top bar:** Scrubby portrait, live Level and Bot Parts sit in the baked profile frame. Pause bars and the 2x text or countdown sit in the baked boxes.
7. **Speech bubble** is kept and blank. The old "Tap on a group of same colored tiles…" sentence is masked.
8. **Bottom:** four boosters, and the reserved AD band below them.
9. **Non-1:2 devices:** the master scales uniformly. The tall phone letterboxes top and bottom; the tablet pillarboxes the sides in a dark fill.

## Remaining visual-only items (owner choice; no gameplay impact)

- **S1 — Surround fill on non-1:2 devices.** A flat dark navy fills outside the master (#10, #12). Keep this, or supply an approved extension or backdrop.
- **S2 — Supply and slot cell size on short 16:9 phones.** The baked cells render at about 83 px on 1080×1920, below the 88 px touch token. Hitboxes match the baked cells exactly, as the decision requires. Accept, or allow hitboxes a few px larger than the cells.
- **S3 — Reserved AD band.** A faint dark bar with a small "AD" label. Keep it visible while there is no ad, or make it invisible until M57.
- **S4 — Pause / 2x glyphs.** The pause bars, play triangle and "2x" text are native. Two approved icon files were unsuitable: `icon_pause.png` is a broken PNG and `icon_speed_2x.png` has its own button frame. The selected 2x state is a translucent cyan fill inside the box; free auto-2x is green.
- **S5 — State colours on live cells.** A batch-colour fill with a white count. The front supply row has a cyan edge, preview rows are dimmed, and ACTIVE slots have a cyan edge.
- **S6 — Non-square boards (future content only).** Every current level is square. A non-square board would stay inside the baked rail, but the runtime rail could then match the baked rail on only one axis.

## Not part of this cycle

The canonical Pause popup, BoosterAcquire, final 2x Acquire popup and modal stack remain M43 dependencies, unchanged from C001. Tutorial copy for the bubble is M44.
