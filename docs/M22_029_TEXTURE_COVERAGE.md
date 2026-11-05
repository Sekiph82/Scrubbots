# SB-M22-029 texture measurement coverage and caps

Factory job 101 (2026-11-05). Continues UI-ADR-008 steps 1-4 (`docs/07_UI_ASSET_PIPELINE_DECISIONS.md`)
after the SB-M22-027 inventory and the SB-M22-030 cleanup (776 tracked images, 570 PNGs under
`assets/ui/final/`). No atlas, no crop, no PNG changed, nothing deleted; only `process/size_limit`
lines in `.import` files.

## Measurement

`tests/tools/m22_026_texture_measure.gd` (real `main.tscn` in a SubViewport at the m49 logical size,
throw-away `user://` saves only, opening video off) now runs 28 scenarios at **1080x2400, 1170x2532
and 1536x2048** = 84 runs, 173 distinct final/ textures with a drawn size.

New in SB-M22-029:

- the 1170x2532 phone (logical width 1080, so every element draws ~8.3% more px than at 1080x2400);
- `level_intro` (SB-VIDEO-005 overlay forced on: keyed still under the Flow video);
- `ranks` (SB-M43-122 personal ladder, now served; was skipped);
- `late_frontier`: the throw-away save is walked by `record_win` to L30 (last catalog level) with
  starter charges: Home with Robots/Events unlocked, Robots, Events, Ranks, gameplay with all four
  boosters unlocked (fresh-save gameplay covers the locked plates) and the four booster popups;
- `shop_pages` also opens the Home Scrub Bucks popup (`open_scrub_bucks`, the only billing surface);
- the walker also records Button icons (expand_icon: button rect, else icon size), StyleBoxTexture
  panels (control rect) and CheckButton/slider theme icon overrides (1:1); this found the Daily
  day-card frames, drawn as StyleBoxTexture and never measured before;
- `--only=a,b` runs a subset.

Already covered by steps 2 and 4 and re-run here at all three sizes: Home, gameplay 5/6 slots,
Results won/failed and reward/robot variants, Shop, Collection album/sets/cards/Exchange, Robots and
detail, Heart popup, Daily/Tasks/calendar/ScrubBox/Gift Bar, Rewarded Ads, Profile/Achievements/
Events/Comeback/Notifications, Help, Settings, every meta ceremony (set, master, gift milestones,
What's New features, world), robot unlock x10, Standard + Premium pack frames and reveal, Need a Hand,
Insufficient, booster popups, every FTUE coachmark.

Not measured (reason):

| state | reason |
|---|---|
| opening cinematic | a video (`assets/brand/opening/*.ogv`), no final/ texture |
| Home Scrubby frame gestures | Home plays the SB-POLISH-009 Flow videos; the frame fallback refuses `full_turn` and the other gestures leave no drawn frame, so the 63 `home_animation` frames are not drawn |
| gameplay clean FX / pack sparkles | `fx_clean_sparkle`, `fx_clean_puff`, rail art and BoosterVfx burst/glow are drawn by `_draw` / CPUParticles2D / during clears, which the walker cannot size; kept uncapped (beyond earlier steps) |
| marketing / store art, app icons | not runtime screens (store listing, export icons) |
| ranks unlocked on Home | RANKS opens at L40, the catalog ends at L30; its popup is opened directly |

## Observed vs not observed (570 final PNGs)

`python -I tools/m22_026_apply_caps.py <measure.json> --coverage` (class from
`docs/m22_027_image_inventory.csv`):

| state | ACTIVE_RUNTIME | DYNAMIC_REF | FUTURE_NEEDED | not in inventory |
|---|---:|---:|---:|---:|
| measured (drawn > 0) | 144 | 28 | 0 | 1 |
| not observed | 239 | 16 | 141 | 1 |

Not observed, by reason (none is deleted; not seen is not unused):

- 115 catalog card arts: only owned / revealed cards draw (13 owned in the Collection scenario plus
  the pack-fixture reveals); all 135 share the step 3 cap 1080.
- 63 Home Scrubby gesture frames + `scrubby_brush_arm_layer`, `scrubby_face_blink_layer`: Flow-video
  Home (above).
- Robot `*_gameplay`, `*_home_pose`, `gameplay/profile/robots/*_portrait`, `scrubby_gameplay`,
  helper bots: not drawn in any measured state (the measured profiles keep Scrubby equipped and the
  gameplay runtime is paused, so no Scrubbot agents travel); not investigated further.
- Home layered world (`home/background/home_bg_*`, `environment/*`, `platform/*`, `area_banner/*`,
  `play_cta/play_button_frame`, `worlds/world_01_*`): bound through the HOME manifest but not drawn
  in the measured Home (World 01 shows the SB-POLISH-009 still + video).
- `victory_scrubby_pose`, `refill_heart_bundle`, `shop_header_emblem`, `popup_small_frame`,
  `popup_warning_frame`, `gift_big_opening_still`: replaced on screen by Flow videos / not opened by
  any reachable state measured (error/warning popups); earlier caps stay.
- Gameplay shells `5slot_4col/5col`, `6slot_4col/5col`, `scrubbots_gameplay_master`, `slot_active`,
  `rail_straight`, `bot_parts_bar_fill`, the 4 reward bundles, `event_weekly_hero`, `icon_check/info/
  plus`: name/pattern references (DYNAMIC_REF) for layouts or data not active in the 30-level catalog.
- `boot_splash_portrait`: engine boot splash (project.godot), not a scene texture.
- 141 FUTURE_NEEDED: listed by asset manifests only (SB-M22-030 kept them).

## Caps (rule: limit >= 2 x max drawn px over every scenario and size, never below source need)

`tools/m22_026_apply_caps.py` now also flags existing limits under 2x the drawn side. At 1170x2532:

| texture | before | after | drawn max px | resident RGBA8 MiB |
|---|---:|---:|---:|---|
| common/icons/icon_lock.png | 0 | 512 | 60 | 6.00 -> 1.00 |
| home/shortcuts/icon_shortcut_gift_bar.png | 0 | 512 | 94 | 6.00 -> 1.00 |
| home/shortcuts/icon_shortcut_win_streak.png | 0 | 512 | 94 | 6.00 -> 0.67 |
| daily/daily_day_reward_frame.png | 0 | 1024 | 304 | 6.00 -> 3.33 |
| daily/daily_day5_reward_frame.png | 0 | 1024 | 304 | 6.00 -> 2.67 |
| collection/collection_complete_emblem.png | 512 | 1024 | 261 | 1.00 -> 4.00 (was 1.96x) |
| home/shortcuts/icon_shortcut_collection.png | 512 | 1024 | 268 | 0.67 -> 2.67 (was 1.91x) |
| daily/daily_login_calendar.png | 1024 | none | 954 | 3.79 -> 6.00 (was 1.07x; 2x > source) |

5 new caps save 21.33 MiB; the 3 corrections cost 7.21 MiB; net -14.12 MiB. Day-card frames stretch
the whole texture (content margins only, no 9-slice texture margins), so a uniform downscale keeps
the look. Not capped although `apply_caps` proposes it: `fx_clean_sparkle` (94 px on Achievements,
but also gameplay clean sprites and pack CPUParticles2D, not measurable).

Kept under 2x on purpose: the 135 card arts at 1080 draw 585 px at 1170x2532 (1.85x, still above
the drawn size); raising all to 1170 costs ~+70 MiB if all resident; SB-M22-028 (on-demand full art
+ thumbnails, LRU) owns card memory. Done 2026-11-06 (factory 103): 440x660 thumbnails in the grid, full art only in
the card detail, album LRU <= 24 full cards / 96 MiB (UI-ADR-008 step 6).

Per-screen lists re-measured after re-import (`tests/m22_026_texture_budget.gd`): Shop/Collection
42.98 MiB (budget 41 -> 47), Daily/Tasks 36.41 MiB with the day-card frames (32 -> 40), Profile
32.05 MiB (32 -> 35); the rest unchanged.

## Cold / warm loaded textures (2 GB-device proxy)

`tests/m22_029_texture_cold_warm.gd`: real main.tscn at 1080x2400, throw-away save; counts final/
textures in the ResourceLoader cache. Cold Home 93 textures / 133.50 MiB; peak with Shop, Collection
(album + set + card), Daily, Robots, Profile open 145.91 MiB; warm Home after each of two visits 93 /
133.50 MiB (no growth, no card art left). Budgets cold 147, peak 161 MiB. All 570 final imports are
lossless (`compress/mode=0`) with mipmaps off (checked by the same test); alpha is kept on every
capped texture (budget test).
