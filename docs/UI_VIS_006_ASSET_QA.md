# SB-UI-VIS-006 / SB-UI-031 pixel-level QA of on-screen assets

Factory job 114 (2026-11-06). Tool: `tools/ui_vis_006_asset_qa.py` (Pillow + numpy + scipy, already
installed). Per-image table: `docs/ui_vis_006_asset_qa.csv`. Regression test:
`tests/ui_vis_006_asset_qa.gd` (also in the `android-family-first10.yml` suite list).
No art was changed and no `.import` was changed: every import setting checked is already correct.

## Inputs

- **Which images**: every ACTIVE_RUNTIME / DYNAMIC_REF image of a fresh `tools/m22_027_image_inventory.py`
  run on this branch (the committed `docs/m22_027_image_inventory.csv` predates the 135 SB-M22-028 card
  thumbnails and 6 video stills; the fresh run adds exactly those 141 as DYNAMIC_REF and moves
  `icon_lock` to ACTIVE_RUNTIME). 641 images: 568 PNGs under `assets/ui/final/`, 40 level PNGs under
  `assets/art/levels/`, 2 brand SVGs, 31 `addons/game_feel_flow` SVGs (editor-only plugin icons).
- **Drawn sizes**: `tests/tools/m22_026_texture_measure.gd` re-run on this branch (throw-away saves):
  `M22-026 MEASURE: DONE (84 scenarios, 189 textures)`, 0 SCRIPT ERROR, at 1080x2400, 1170x2532
  and 1536x2048. Only visible draws count; per texture the visible rect with the largest
  magnification is kept (`drawn_w`, `drawn_h` in the CSV). 167 PNGs have a visible drawn rect;
  401 are not observed (reasons in `docs/M22_029_TEXTURE_COVERAGE.md`: card art not owned, Home
  Scrubby gesture frames replaced by Flow video, robot gameplay poses, layered Home world, name /
  stem references for layouts not in the catalog).

Re-run (after `godot --headless --import`):
`python -I tools/ui_vis_006_asset_qa.py --inventory=<fresh m22_027 csv> --measure=<measure.json>`;
without `--measure` it keeps the drawn sizes already in the CSV (re-run gives a byte-identical CSV).

## Checks and thresholds

| check | rule | result |
|---|---|---|
| import | `compress/mode=0`, `mipmaps/generate=false`, `process/fix_alpha_border=true`, `process/premult_alpha=false` | 641 / 641 ok |
| resolution | `max(imp_w / drawn_w, imp_h / drawn_h)` with `size_limit` applied: < 1 FAIL, < 2 WARN | 9 FAIL, 27 WARN, 131 ok |
| white halo | semi-transparent silhouette px (alpha 16..224, opaque and transparent px within 2 px) near-white while the opaque neighbours are > 80 luma darker; WARN > 5 % and >= 50 px | 0 |
| cropped art | opaque px on a canvas edge > 10 % while the art covers < 85 % of the canvas | 3 WARN |
| padding | fully transparent margin outside the alpha bbox >= 1 MiB at the imported size | 18 WARN |
| white background | all four corner px opaque and >= 240 | 3 WARN |
| empty | no pixel with alpha > 0 | 0 |
| level art | alpha strictly 0 / 255 (VOID / ACTIVE) | 40 / 40 ok |
| text / watermark | detached small opaque islands in a corner box (12 % of the short side), or dense edges in an opaque corner; candidates for a look, never a FAIL | 3 candidates, none is text |

Dark edge pixels are not counted as a halo: in this art style they are outlines and drop shadows,
and they disappear on the dark BG01 / UI. Inner semi-transparent bands (the card frames' white glass
line) are not silhouette edges. The first version of the halo rule flagged all 135 card arts on that
glass line; it was narrowed to the silhouette after a pixel look (`set_09/card_08`: a 3 px band of
#F0EFF1 at alpha 154 between the purple frame and the navy inner panel, by design).

## Defects (FAIL: drawn larger than the imported texture)

| texture | imported | largest visible drawn rect | ratio | cause |
|---|---|---|---:|---|
| `gameplay/master/gameplay_v02_shell_5slot_3col.png` | 887x1774 | 1170x2340 (1170x2532 phone) | 0.76 | owner-locked static gameplay master (SHA-256 pinned in `gameplay_shell_geometry.gd`), drawn full screen with `STRETCH_SCALE`: 1.22x upscale on 1080 px wide phones, 1.32x on 1170 |
| `gameplay/master/gameplay_v02_shell_6slot_3col.png` | 887x1774 | 1170x2340 | 0.76 | same |
| `home/background/home_background.png` | 940x1672 | 1321x2349 | 0.71 | Home background drawn as a cover behind the World 01 still / video |
| `home/videos/home_scrubby_still.png` | 720x1280 | 1321x2349 | 0.55 | first-frame still of the Home Flow videos, which are 720x1280 too |
| `rewards/pack_opening/videos/standard_pack_opening_first.png` | 720x1280 | 1170x2532 | 0.62 | still of `standard_pack_opening.ogv` (720x1280) |
| `rewards/pack_opening/videos/standard_pack_opening_peak.png` | 720x1280 | 1170x2532 | 0.62 | same |
| `rewards/pack_opening/videos/premium_pack_opening_first.png` | 720x1280 | 1170x2532 | 0.62 | still of `premium_pack_opening.ogv` (720x1280) |
| `rewards/pack_opening/videos/premium_pack_opening_peak.png` | 720x1280 | 1170x2532 | 0.62 | same |
| `gameplay/videos/level_start_scrubby_still.png` | 624x640 | 953x978 (1536x2048 tablet) | 0.65 | still of `level_start_scrubby.ogv` (624x640); 1.0x or better on the phones |

None of these can be fixed with import settings: every one is at its source size already
(`size_limit` 0). The six video stills match their videos pixel for pixel, so the soft look on a
large phone is the video's own resolution (Theora picture sizes read from the `.ogv` headers). The fix
is new, higher-resolution source art / video renders (the gameplay shells and their geometry are
owner-locked at 887x1774), which is an owner art decision. Recorded, not changed.

## Warnings

**Under 2x the drawn size (27; all >= 1x, so nothing is upscaled):**

- 13 viewed collection card arts at `size_limit=1080`: 720x1080 for a 412x585 draw (1.85x), kept on
  purpose (UI-ADR-008 step 5 / SB-M22-028; the grid draws thumbnails, full art only in the card detail).
- Nine-patch popup frames `common/frames/popup_large_frame.png` (1.20x), `popup_medium_frame.png`
  (1.27x), `popup_reward_frame.png` (1.26x): only the middle stretches, the corners draw at most
  1:1, so this is not a sharpness problem.
- Source-limited art (`size_limit` 0, cannot go higher without new art):
  `profile/profile_trophy_icon.png` 128 px for 104x106 (1.23x),
  `profile/achievement_crown_icon.png` and `profile/profile_no_booster_icon.png` 128 px for 94 px
  (1.36x), `gameplay/tutorial/tutorial_highlight_ring.png` 1.30x, `characters/scrubby/scrubby_home_pose.png`
  1.51x, `popups/videos/result_scrubby_lose_still.png` 1.69x, `rewards/set_complete_video/set_complete_badge_still.png`
  1.71x, `gameplay/tutorial/speech_bubble.png` 1.73x, `gameplay/profile/scrubby_portrait.png` 1.79x,
  `rewards/gift_videos/gift_small_opening_still.png` 1.96x, `collection/states/card_new_glow.png` 1.97x.

**Opaque white background (3):** `gameplay/profile/bot_parts_bar_fill.png` (320x38),
`gameplay/railway/rail_straight.png` (512x128), `gameplay/slots/slot_active.png` (220x220) are RGBA
without a single transparent pixel and white corners. None is drawn: they are DYNAMIC_REF only through
loose stem matches (`profile_bot_parts_bar_fill` manifest key, `set_slot_active`), not observed in any
measured scenario. If one is ever wired as a sprite it shows a white box on the dark UI; it would need
its background removed first.

**Art on the canvas edge (3):** `home/background/home_bg_city_far.png` (97 % of one edge opaque),
`home_bg_city_mid.png` (85 %), `home_bg_street_foreground.png` (56 %): the layered Home world strips
are meant to run off the screen sides; not drawn in the measured Home (World 01 uses the still +
video). Not a crop defect.

**Transparent padding >= 1 MiB (18):** the standard / premium pack-opening frames (`frame_01`..`09`,
18-66 % margin, up to 3.99 MiB each at 1024x1536) share one canvas so the animation stays registered;
`common/icons/icon_info.png` 1.56 MiB, `icon_plus.png` 1.83 MiB (both name references only, not
drawn), `daily/daily_login_calendar.png` 1.41 MiB, `gameplay/tutorial/speech_bubble.png` 2.15 MiB,
`home/environment/home_prop_keep_clean_sign.png` 1.55 MiB, `popups/videos/result_scrubby_win_still.png`
1.01 MiB. Trimming would change the art's anchor / registration and so needs layout work; memory
waste only, not a visual defect. Sum of padding over all 641 images: 132.68 MiB if everything were
resident at once (it never is: per-screen budgets in UI-ADR-008).

## Text / watermark

Heuristic candidates, each looked at by Claude (a crop of the corner on BG01):
`characters/robots/dusty/dusty_gameplay.png` (bottom-right: dust puffs),
`characters/robots/moppy/moppy_gameplay.png` (bottom-right: water drops),
`rewards/set_complete_video/set_complete_badge_still.png` (bottom-right: a confetti piece). No text.
Besides the heuristic, Claude looked at contact sheets of the bottom-right and bottom-left corner
(15 % of the short side) of all 433 non-thumbnail final/ PNGs on BG01: no logo, text or generator
mark. Top corners were only checked by the heuristic.

## Import settings, filtering, compression, memory

- Every PNG imports lossless (`compress/mode=0`), without mipmaps, `fix_alpha_border=true` (Godot
  bleeds edge colour into transparent pixels, so linear filtering does not pull in a dark / white
  matte) and `premult_alpha=false`. Nothing to fix.
- 243 runtime images have no tracked `.import` (88 under `characters/`, 27 `gameplay/`, 24 `rewards/`,
  19 `home/`, level previews / sources, plugin SVGs ...). Godot writes the default texture import on
  `--import` (CI does the same), which is lossless, no mipmaps, `fix_alpha_border=true`; the check
  above ran on those generated files. Their `uid://` is not stable across checkouts, so they must stay
  referenced by `res://` path (they are).
- Filtering: the project default canvas filter is Linear (no override in `project.godot`), right for
  the painted UI; the board (`board_renderer.gd`) and the Results level teaser (`results_screen.gd`)
  set `TEXTURE_FILTER_NEAREST` for the logical pixel art. The boot splash uses `use_filter=true`.
- Size limits on the 568 final/ PNGs: 135 card arts at 1080, 61 at 512 (boosters, small icons),
  44 at 1024, 3 at 256, 325 none (UI-ADR-008; `m22_026_texture_budget.gd` owns them). No limit puts a
  texture below its drawn rect (test).
- Memory (resident RGBA8 at the imported size, no mipmaps): 1479.43 MiB for all 568 final/ PNGs,
  386.61 MiB for the 167 with a visible drawn rect; largest single textures 8.90 MiB (`home/worlds/world_01_whispering_park_1080x2160.png`,
  `system/splash/boot_splash_portrait.png`). Per-screen and cold / warm budgets stay as measured by
  `m22_026_texture_budget.gd` and `m22_029_texture_cold_warm.gd`. VRAM compression stays an owner
  visual decision (UI-ADR-008 step 7).

## Owner phone review (visual judgements this audit does not claim)

- Softness of the full-screen video stills and videos (Home Scrubby, pack opening) and of the gameplay
  shell on a 1170x2532-class phone: acceptable, or re-render at 1080x1920 / higher-res shell master?
- Mobile readability of the 128 px profile icons (trophy, crown, no-booster) at ~94-106 px.
- Identity consistency of Scrubby / robots across Home, Results, Profile and the video stills.
- Overall alpha-edge look on device (the automated halo rule found nothing; dark outlines are by style).

## Not covered

- SVG pixel checks (vector; only their import is checked). Plugin SVGs are editor-only.
- Textures never drawn in a measured scenario get no resolution verdict (`res=unmeasured`, 401).
- Top-left / top-right corners were not viewed by eye.
