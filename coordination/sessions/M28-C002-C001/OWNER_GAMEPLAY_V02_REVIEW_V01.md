# M28-C002-C001 — OWNER GAMEPLAY V02 REVIEW V01

Date: 2026-09-28
Status: **CANDIDATE, awaiting owner visual review.** No owner acceptance is claimed.
Reference: `assets/ui/final/gameplay/master/scrubbots_gameplay_master.png`. The master is a composition reference only; the screen is native Godot plus BoardRenderer.

## How the images were made

`tests/tools/gameplay_v02_snapshot.gd` renders the real app root (`scenes/app/main.tscn`) on a temporary save. It launches the real frontier level and drives it with the owner-approved supply-plan clicks (`intendedColumnClicks`, the same driver as `m55_long_session`). Nothing is solved or invented.

State setup goes through the real services on the temporary save:
- one granted +1 Slot charge;
- 1000 SB credited before buying timed 2x.

Re-create the images (needs a display, not `--headless`):

```bash
godot --path . -s res://tests/tools/gameplay_v02_snapshot.gd -- coordination/sessions/M28-C002-C001/evidence
```

Or play live: Home → PLAY.

## A. Core V02: ready for your visual review

All images are in `coordination/sessions/M28-C002-C001/evidence/`.

| # | File | State | Viewport |
|---|---|---|---|
| 1 | `v02_L2_fresh_1080x2160.png` | Level 2 (Apple) fresh: five empty slots with all five connectors visible, 3×3 supply, four boosters with prices | 1080×2160 |
| 2 | `v02_L2_active_cleaning_1080x2160.png` | 5 owner clicks; Scrubbots on connectors, bottom rail and interior path | 1080×2160 |
| 3 | `v02_L2_five_slots_occupied_1080x2160.png` | all five slots occupied (live counts, ACTIVE) | 1080×2160 |
| 4 | `v02_L2_sixth_slot_1080x2160.png` | +1 Slot used: six slots, sixth connector, +1 Slot ring shown as selected | 1080×2160 |
| 5 | `v02_L2_timed_2x_countdown_1080x2160.png` | timed 2x bought (15 min); after 2 s of real wall clock the button reads **14:58**; cleaning at 2x | 1080×2160 |
| 6 | `v02_L3_tall_phone_1290x2796.png` | Level 3 (Palm) tall phone, active cleaning | 1290×2796 |
| 7 | `v02_L3_short_phone_1080x1920.png` | Level 3 short 16:9 phone, active cleaning | 1080×1920 |
| 8 | `v02_L1_fresh_tablet_1536x2048.png` | Level 1 tablet portrait: 3-column supply with real colours | 1536×2048 |

What to look at:
1. **Hierarchy vs the master.** Profile top-left, PAUSE | 2x top-right, board dominant, slots right under the board, supply below, Scrubby low-left, props right, four boosters at the bottom.
2. **Railroad V1 skin.** Chained approved rail segments, blue energy nodes at the corners. Rail is 1 cell wide and visually subordinate to the pixel art.
3. **Connectors.** Five always visible, even when the slots are empty (#1). A sixth appears only with +1 Slot (#4). Each one starts at the exact point a Scrubbot really departs from.
4. **Supply tiles.** Batch-coloured, live counts. The front row has a bright cyan rim; preview rows are dimmed and cannot be tapped.
5. **2x states.** Plain "2x" (#1), live countdown (#5). Current-level and free-auto states are covered by tests; they use the active art, and free-auto adds a green tint.
6. **Boosters.** Four; price badge when no charge is owned, count badge when one is.

## B. Deferred by dependency (not claimed in this cycle)

| Row | What exists now | Final owner |
|---|---|---|
| SB-M28-C002-012 BoosterAcquire popup routing | Tapping a booster with no charge spends nothing and emits `booster_acquire_requested(id)`. Selector/Tornado target selection is not built. | M43 booster acquisition flow |
| SB-M28-C002-013 final 2x Acquire popup | The existing functional `SpeedAcquisitionPopup` (unchanged) | M43-C003 |
| SB-M28-C002-014 canonical Pause popup | Pause toggles the existing runtime pause; the button dims while paused | M43-C002 |
| SB-M28-C002-015 final modal-stack input suppression | Existing input safety unchanged | M43 modal stack |
| SB-M28-C002-019 full review pack incl. popups | This core pack only | after 012–015 |

## C. Genuine visual-only choices for the owner

These need no new design policy; each is an owner choice.

- **V1 — Background.** No approved portrait gameplay backdrop exists. The master's industrial jungle scene is not an asset, and `gameplay_environment.png` is an isometric arena prop. The screen currently uses a native midnight-blue gradient. Options: produce and approve a backdrop, or accept the gradient.
- **V2 — Profile chip / slot art.** The approved `profile_panel_frame.png`, `bot_parts_bar_fill.png` and `slots/slot_*.png` have opaque white backgrounds, so native look-alike panels are used instead. Options: accept the native versions, or supply transparent re-exports.
- **V3 — Profile content.** The master shows a title ("The Leader"), an XP-like number and a large progress figure. No authority exists for these, so the chip shows only Scrubby, the live Level N and live Bot Parts parts/cost.
- **V4 — Speech bubble.** Hidden because no tutorial copy is authorised (FTUE/tutorial copy belongs to M44).
- **V5 — Spare height on tall phones (#6).** Extra height is split above the board and between supply and boosters. The alternative is to let the board grow larger, which is width-limited on tall phones.
- **V6 — Rail segment density.** Straight runs are made of whole approved segments; the end flanges read as couplings. Choose whether you want longer or shorter segments.
