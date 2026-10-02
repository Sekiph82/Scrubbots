# M43-C001R-C001 — Momentum Matrix V01

Date: 2026-10-02
Scope: SB-M43-R01-001..008
Focused suite: `tests/m43_c001r_c001_results_momentum.gd` (34 cases)

## 1. Ownership map

| Concern | Owner | Writes state? |
|---|---|---|
| Next frontier → content | `GameplayLaunchResolver.resolve` (same call Continue / CLEAN NEXT uses); now also returns the entry's `preview_path` | No |
| Journey + Next Cleanup read model | `scripts/progression/results_momentum.gd` (`ResultsMomentum`, static, RefCounted) | No |
| Presentation config | `data/config/results_momentum_v1.json` (`scrubbots.results_momentum.v1`), validated fail-closed by `ResultsMomentum.load_config` | No |
| Results model assembly | `main._results_model`: WON only, `ResultsMomentum.results_model(app_state, won_level, launch, cfg)` | No |
| Results presentation | `ResultsScreen` momentum section + `set_ceremony_barrier(id, active)` seam | No |
| Home presentation | `HomeScreen._render_journey` → `ResultsMomentum.home_journey` | No |
| Journey drawing | `scripts/ui/components/journey_strip.gd`: one Control, drawn nodes, `MOUSE_FILTER_IGNORE`, `FOCUS_NONE`, no children | No |
| CLEAN NEXT | Existing `ResultsScreen.continue_requested(attempt)` → `main.continue_from_results` | Navigation only (unchanged) |

`ResultsMomentum` reads only:

- `LevelProgressionService.current_level()` / `class_for()`;
- the resolved catalog entry;
- that entry's `LevelData` palette;
- that entry's own preview texture.

It has no grant, unlock, save or difficulty path.

## 2. Config (`results_momentum_v1.json`)

| Key | V1 | Validation |
|---|---|---|
| `journey.cycle_length` | 10 | Must equal the owner lock (10) |
| `journey.mini_boss_slot` | 5 | Must equal 5 |
| `journey.boss_slot` | 10 | Must equal 10 |
| `teaser.reveal_mode` | `cropped_detail` | Must equal it |
| `teaser.visible_area_fraction` | 0.20 | Must be within [min, max] |
| `teaser.visible_area_fraction_min/max` | 0.15 / 0.25 | May only narrow the owner envelope 0.15..0.25 |
| `teaser.reveal_delay_s` | 0.2 | Must be 0..1 (presentation delay after the reward rows) |

A malformed or missing config (`ok: false`) means:

- Results show no momentum section;
- Home shows no strip;
- CLEAN NEXT / PLAY / Continue are unaffected (t35).

## 3. Journey semantics

| Context | Anchor | Complete | Highlight |
|---|---|---|---|
| Home | Current frontier `n` | Slots `< slot(n)` | `slot(n)` = current (gold) |
| Results (WON) | Just-completed level `n` | Slots `<= slot(n)` | `slot(n) + 1` = next (white), if it is in the same cycle |

The cycle math is `cycle = floor((n-1)/10) + 1` and `slot = ((n-1) % 10) + 1`. Node classes come from `progression.class_for(level)`.

| Case | Result | Test |
|---|---|---|
| Home frontier 1 | Slot 1 current, 0 complete | t16 |
| Home frontier 6 | Slots 1..5 complete, slot 6 current | t17 |
| Results Level 9 | 9/10, slot 10 next; teaser Level 10 | t18 |
| Results Level 10 | 10/10 | t19 |
| Home frontier 11 | Cycle 2, slot 1 (Level 11) current, nodes 11..20 | t20 |
| Results L10 → injected L11 → Home 11 | 10/10 → teaser L11 available → cycle 2 slot 1 | t21 (test-only catalog stub; production still has no L11) |
| Save / relaunch | Same journey; the save file contains no journey/momentum key | t23 |

## 4. Next Cleanup teaser

The crop is a `w × h` window with `w = W·√f` and `h = H·√f`, where `f = 0.20`.

- **Detail:** pixels that are not the dominant colour. A window is eligible when it holds at least half of the best window's detail.
- **Choice:** an FNV-1a hash of the stable entry id picks one eligible window.
- **Binding:** UI binds only an `AtlasTexture` whose region is that window. Nearest filter, 132 px frame.

| Level | Preview | Crop | Visible fraction |
|---|---|---|---|
| 1 hazard_bot | 20×20 | 9×9 @ (9,2) | 0.203 |
| 2 apple | 32×32 | 14×14 @ (8,6) | 0.191 |
| 3 palm_tree | 38×38 | 17×17 @ (17,18) | 0.200 |
| 4 orange_cat | 32×32 | 14×14 @ (8,17) | 0.191 |
| 5 party_toucan | 33×33 | 15×15 @ (16,7) | 0.207 |
| 6 chicken | 32×32 | 14×14 @ (11,14) | 0.191 |
| 7 pigeon | 32×32 | 14×14 @ (14,17) | 0.191 |
| 8 butterfly | 32×32 | 14×14 @ (18,11) | 0.191 |
| 9 frog | 32×32 | 14×14 @ (4,10) | 0.191 |
| 10 ice_cube | 32×32 | 14×14 @ (11,2) | 0.191 |

The teaser shows only canonical facts:

- `NEXT CLEANUP`;
- `LEVEL N`;
- the difficulty token (catalog / LevelData, which equals the cadence class);
- the colour count (LevelData local palette, which equals metadata `usedColorCount`).

When content is missing, it shows `LEVEL N` + `Coming soon` + a neutral `?` box. CLEAN NEXT is disabled, and the existing note "Level N is coming soon." stays.

**Non-disclosure:**

- t06 probes every frame of the normal reveal and the Reduced Effects view. No `TextureRect` draws a full preview or a region larger than 25%.
- The probe is sensitivity-checked: a planted full preview and a 30×30 region are both flagged.

## 5. Corridor order (WON Results)

`Header → Level → committed reward rows (C001B order, unchanged) → CLEANING JOURNEY n/10 + strip → Next Cleanup → note → CLEAN NEXT (primary) → HOME (secondary)`

- The momentum section fades in after the row reveal plus `reveal_delay_s` (0.2 s). This is presentation only, and CLEAN NEXT is never gated by it.
- Reduced Effects shows everything immediately (t32).
- **Ceremony barrier (future C005):** `set_ceremony_barrier(id, true)` hides Next Cleanup and disables CLEAN NEXT; the journey and Home stay. Releasing the last barrier restores the same resolved teaser.
  - Barriers clear when Results hides.
  - The barrier writes no economy or progression state (t30/t31).
  - No ceremony is implemented; SB-M43-013 stays open.

## 6. CLEAN NEXT safety (unchanged route)

| Property | Test |
|---|---|
| `continue_requested` → `continue_from_results` | t26 |
| 5 rapid taps → 1 launch | t27 |
| Stale attempt refused | t28 |
| 0 Hearts → Life, no launch | t29 |
| Missing L11 → disabled, `no_next_content` | t11 |
| Receipt / economy / progression identical after rendering | t24 |

## 7. Home placement

`HomeJourneyStrip` (560×58) is a child of `PlayButton`, anchored centre-top 6 px above it, with a translucent navy plate. It is the same pattern as the existing status pill.

- It takes no layout slot, so Play, the Win Streak track, BottomNav, the Gift Meter and the ad slot do not move.
- When the status pill is shown ("Level 11 is coming soon."), it rides above the strip.
- t33 checks, at all five viewports, that the strip is inside the safe area and intersects none of: PlayButton, TrackPanel, BottomNav, GiftMeter, AdBannerSlot, TopCurrencyHUD, or the four shortcut panels.
