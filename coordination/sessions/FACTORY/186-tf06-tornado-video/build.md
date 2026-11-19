STATUS: READY

# Build: Tornado booster video (SB-TF-06)

## Summary
Branch `factory/186-tf06-tornado-video` (commits `e6c3c132` asset, `773ed331` code/tests/CI/docs,
`45c5d042` round 2: cells wait on the board until 60 % of the clip, then swirl into the funnel).
The Tornado booster effect now plays the owner's black-background clip additively in ONE
`VideoStreamPlayer` (child of the existing input-transparent `BoosterVfx` overlay, created on play,
`queue_free`d at the burst / in `stop()`). The measured tornado track maps key 0 onto the real
Tornado button centre and the last key onto the real board centre (captured at start from the
nodes). The purged colour's ghost (every cell, one ImageTexture) and the <= 48 samples / supply and
slot tiles stay put until `PULL_FROM` = 60 % of the clip (the tornado has grown onto the board),
then swirl (`PULL_TURNS` = 0.75 turns around the tornado centre while converging, ease-in) into
the tornado's CURRENT position, reaching the eye as the clip ends. After the clip: 0.25 s spin-collapse
(1.5 turns, scale to 15 %, ease-in) of the paused last frame, then the existing burst (0.25 s).
Total = clip (1.333 s) + 0.5 s. The vector arms / dashed rings and `VORTEX` are deleted. Reduced
Effects: unchanged (button flash only; turning it on mid-effect frees the player). A missing /
broken stream runs code-only into the board centre over `TORNADO_CLIP_S`.

Files:
- `assets/ui/final/boosters/videos/tornado_additive.ogv` (+ `.uid`), `PROVENANCE.md` (new)
- `tools/build_tornado_booster_video.py` (new; reproducible trim / crop / encode / black check / track)
- `ASSET_GENERATION_MANIFEST.json` (`canonical_references.tornado_booster_video_v1`)
- `scripts/ui/feel/booster_vfx.gd` (tornado effect), `scripts/ui/gameplay_screen.gd` (capture adds `button_center`, `board_center`)
- `tests/sb_tf06_tornado_video.gd` (new), `tests/sb_polish_003_booster_vfx.gd` (child count <= 2, tornado settle bound = its duration)
- `.github/workflows/android-family-first10.yml` (comment line, validate list, exact 12/12 guard)
- `AGENTS.md`, `docs/ACCESSIBILITY.md`

### Deviations / decisions for the reviewer
1. **Mapping (Req 4) vs the 1.25 ratio.** With sx, sy each = screen distance / clip distance, the
   ratio is ~2.3 at every viewport (the clip travels 125 px left / 740 px up; the real layout
   needs ~0.37 x / 1.0 y of that ratio), so Req 4's formula and its own ratio bound cannot both
   hold. Implemented: sy = screen / clip y travel; sx = x ratio clamped to [sy/1.25, sy*1.25]; the
   remaining x travel (screen x minus sx * clip x) is added as a translation that follows the
   tornado's travel progress (y fraction along the track). Result: key 0 and the last key land
   exactly (0.00 px) on button / board centres at all 8 viewports, ratio = 1.250, no rotation.
   The tornado therefore drifts sideways a bit more than the raw clip; visually fine in the strip.
2. **Trim measured, not ~0.5 s.** Start = source frame 7 (first frame whose changed-pixel count
   exceeds 3x the idle level of frames 1-6, 0.29 s); end = frame 38 (first frame whose bbox centre
   and width are within 3 px of the steady spin). 32 frames = 1.333 s (in 1.3..2.2). A start at
   frame 11 (the visible growth) would give 1.17 s, below the spec's minimum.
3. **Crop threshold 12/255** (not "> 0"): the master has stray H.264 specks of 9..12 at the frame
   edges that would force a full-width crop; > 12 gives 544x1008 (x=91 y=215).
4. **`DURATION["tornado"]`** stays a const (Godot consts are read-only) set to the nominal 1.833;
   `play()` sets `_dur` = opened clip length + 0.5 s, which is what `_process` uses.
5. **Player free.** `_free_video()` hides and `queue_free`s the player (not `stop()` + `remove_child`):
   an in-`_process` teardown cost ~3-5 ms in one frame (decoder join) and broke the 4 ms max; the
   teardown now runs in the frame's delete flush and is measured separately (2.3-4.8 ms, once).
6. **Docs not touched:** `docs/UI_VIS_006_ASSET_QA.md` lists only texture stills, not videos (no
   entry needed). `flow_videos/FLOW_TORNADO_BOOSTER_VIDEO.md` is not tracked in git (only in the
   owner's Desktop checkout, which I must not edit), so the v3 one-liner was not added. TASKS.md
   not edited per the orchestrator's instruction.
7. Pull timing (round 2): the cells do not move before 60 % of the clip (0.8 s), then swirl into
   the funnel over the last 40 % (0.53 s), meeting the eye at the clip end. The reviewer suggested
   45 %; on the strip, 45 % with 1.25 turns swung the ghost off the board's left edge and under
   the funnel (the tornado centre was still at the slot strip at 0.7 s), so I tuned it to 60 % /
   0.75 turns against the strip.

## Acceptance criteria
1. [x] `tests/sb_tf06_tornado_video.gd` prints `SB-TF-06 tornado video evidence: PASS (12/12 cases, 0 fail)`, exit 0 (headless and windowed). Per case:
   1. [x] asset: 146.3 KB (149,835 B <= 2,000,000; target met), Theora opens, 1.333 s, no Vorbis/Opus header.
   2. [x] PROVENANCE.md sha256 and manifest `tornado_booster_video_v1` sha256 == file sha256 `2a4630c7...`.
   3. [x] black level: real readback worked even headless: decoded 544x1008 frame corners max 0/255.
   4. [x] track: 14 keys, frames 0..31 ordered, diameter 83 -> 493 (5.9x), travels up 740 px.
   5. [x] mapping, 8 viewports (720x1280 .. 1536x2048) on a real GameplayScreen: key 0 -> button centre 0.00 px, last key -> board centre 0.00 px, ratio 1.250, rotation 0.
   6. [x] real play: exactly one playing VideoStreamPlayer, `BLEND_MODE_ADD`, `MOUSE_FILTER_IGNORE`, child of the overlay, kind "tornado"; `_draw_tornado` source has no `draw_polyline` / `draw_arc`, no `VORTEX`.
   7. [x] cells: colour 2 (#2450a4) 298/298 lit pixels exact canonical colour; second run colour 4 (#000000) 56/56; samples 43 / 28 <= 48; children 2; +1 node only.
   8. [x] truth: same level (Retry) + same colour, effect vs Reduced: identical `r` (`{"action":"tornado","id":"tornado","ok":true,"paid_with":"charge","save":{"ok":true}}`), board cells, supply + slot snapshots, deltas (charges -1, SB 0); BoardRenderer image hash unchanged by the effect.
   9. [x] timeline (manual clock 1/60): VIDEO -> COLLAPSE -> BURST; the ghost waits untouched on the board for 47 ticks (<= 60 % of the clip: pivot on the cell centroid, scale 1, alpha 1), then its pivot sits within 1.5 px of `tornado + (centroid - tornado).rotated(-TAU * 0.75 * u) * (1 - u)` at every tick (swirl up to 3.11 rad off the straight line; tornado travels 1195 px, ends on the board centre); collapse paused, scale 0.15, -1.5 turns; burst frees the player; total 1.833 = clip 1.333 + 0.500; done: kind "", player freed, ghost hidden, 1 child.
   10. [x] Reduced: ok, no VideoStreamPlayer, not playing, ActivatedBurst flashes; on mid-effect frees the player (1 -> 0).
   11. [x] null and broken stream: VIDEO -> COLLAPSE -> BURST over 1.333 s into the board centre, no player, node count unchanged, 1 child; second play mid-effect leaves exactly one player. (The broken-stream case prints the engine's `ERROR: Cannot open file .../missing.ogv`, as in sb_video_009; no SCRIPT ERROR.)
   12. [x] performance (round 2): `PERF avg=0.386 max=1.479 ms` headless (267 frames); windowed `avg=0.830 max=1.865 ms` (111 frames). Budget avg <= 1.0, max <= 4.0 met.
2. [x] CI: `grep -n sb_tf06 .github/workflows/android-family-first10.yml` -> line 91 (comment), 212 (validate list), 486 (`grep -qxF 'SB-TF-06 tornado video evidence: PASS (12/12 cases, 0 fail)' validate_logs/sb_tf06_tornado_video.log`) with `TORNADO-VIDEO verdict=PASS (12/12)` / FAIL lines, same shape as SB-TF-05.
3. [x] Other suites (headless, LOCAL_PASS unless noted): see Validation. Two failures are pre-existing on main `a236b507` (shown below).
4. [x] `ffprobe`: one stream `codec_name=theora|width=544|height=1008|r_frame_rate=24/1`, duration 1.333333, size 149835, no audio stream. `git diff --stat a236b507 HEAD -- scripts/gameplay scripts/economy data` is empty; `BoardRenderer` untouched.
5. [x] Evidence (windowed, rendering driver, 1080x2160, level 2 apple, orange-red #ff4500 purge of 296 cells): `factory/jobs/186-tf06-tornado-video/evidence/tornado_strip_1080x2160.png` (10 frames, t = 0.01 .. 2.04 s, labelled with time + phase; full frames in `evidence/frames/`), `evidence/perf.txt`. Re-captured in round 2: the strip shows the tornado starting small at the Tornado button and growing up to the board centre while the orange apple stays intact on the board (0.01-0.70 s), the orange cells swirling into the funnel over the board (0.93 s), gone by 1.15 s, the board not tinted by the black, the collapse, the burst and the clean board after; no vector arms / rings.
6. [x] Docs: `grep -n "SB-TF-06" AGENTS.md docs/ACCESSIBILITY.md` -> AGENTS.md:27, ACCESSIBILITY.md:89; manifest parses (`python -c "import json;json.load(open('ASSET_GENERATION_MANIFEST.json'))"` ok).

## Validation
Godot 4.7.2 (`godot.exe --headless --path <worktree> -s res://tests/<suite>.gd`), after `--import`:
- sb_tf06_tornado_video: exit 0, `SB-TF-06 tornado video evidence: PASS (12/12 cases, 0 fail)` (LOCAL_PASS; also windowed with `--evidence`)
- sb_polish_003_booster_vfx: exit 0, `SB-POLISH-003 BOOSTER VFX: PASS` (tornado ended by itself 1749 ms)
- sb_tf04_gameplay_layout: exit 0, `PASS (7/7 cases, 0 fail)`
- sb_tf05_reward_reveal: exit 0, `PASS (16/16 cases, 0 fail)`
- sb_phone_2026_11_12_f_slot_pop_hold: exit 0, `PASS (100/100 cases, 0 fail)`
- m39c_boosters: exit 0, PASS; m39_c003_random_any_booster_rewards: exit 0, PASS
- m22_026_texture_budget: PASS; ui_vis_006_asset_qa: PASS; m55_long_session: PASS
- m22_025_booster_texture_budget: FAIL (1) `9 booster PNGs (expected 10)`: PRE-EXISTING, see main check below (the SB-ASSET-PURGE commit deleted a booster PNG; this branch adds no PNG: 9 PNGs on both `a236b507` and HEAD).
- m43_c005f_phase3_meta_rewards_acquisition: FAIL (15/15 cases, 1 fail) `no production script outside FeedbackAdapter names a plugin ["res://scripts/economy/events_v02_service.gd"]`: PRE-EXISTING (file untouched here); its 2 SCRIPT ERRORs are the suite's announced `EXPECTED_FAULT_INJECTION`.
- Main check (temporary detached worktree at `a236b507`, imported, then removed): m22_025 exit 1 `FAIL: 9 booster PNGs (expected 10)`; m43_c005f_phase3 exit 1 `FAIL (15/15 cases, 1 fail)` with the same events_v02_service.gd finding. Identical to this branch.
- `git diff --check` on the changed paths: clean. ffprobe as in AC4. Manifest JSON parses.
- Exit-time `ObjectDB instances leaked` warning in sb_tf06 comes from the broken-stream injection (bisected: gone without the failure-path case); the precedent sb_video_009 prints the same with its broken streams.
- Not done: phone profiling (no APK/IPA build), CI run (not pushed).

## Log
### Round 1
Built the clip with a new reproducible tool (trim 7..38, crop 544x1008, q5, black corners 0/255,
149,835 B), baked the 14-key track, replaced the vector vortex with the additive video layer,
track mapping, moving-target cell spiral, collapse + burst, code-only failure path, Reduced
handling; added `button_center` / `board_center` to the capture; new 12-case suite + CI guard;
polish_003 updated minimally; AGENTS / ACCESSIBILITY docs; evidence strip + perf. Found and
documented the Req 4 ratio contradiction (decision 1) and moved the decoder teardown out of
`_process` (decision 5). TASKS.md left to the orchestrator.

### Round 2
Review round 1 (`round-1/review.md`, REWORK), one finding:
1. `booster_vfx.gd` `_tick_tornado` pulled the ghost with `ease_in(t / clip)` over the whole clip toward the tornado, which starts at the button, so the orange cells streamed down toward the button at 0.24-0.70 s and the board was empty before the tornado arrived. **Fixed** (`45c5d042`):
   - New `_pull()` = `clamp((t / clip - PULL_FROM) / (1 - PULL_FROM))` with `PULL_FROM` 0.6: the ghost, the <= 48 samples and the supply/slot tiles (`_draw_tornado` now runs the old 0.85 s timeline over `_pull() * 0.85`) do not move until the tornado has grown onto the board.
   - The ghost now swirls into the funnel: its pivot follows `tornado + (centroid - tornado).rotated(-TAU * PULL_TURNS * u) * (1 - u)` (`PULL_TURNS` 0.75), while spinning, shrinking and fading, so it spirals around the tornado centre as it converges instead of travelling in a straight line. Samples and tiles already spiral around the current tornado position (`_spiral_rect`).
   - Tuned against the strip: 0.45 / 1.25 turns (the suggested start) swung the ghost off the board's left edge and below the board, because the tornado was still at the slot strip at 0.7 s; 0.6 / 0.75 keeps the apple intact through 0.70 s and swirls it into the funnel over the board (0.93 s).
   - Test case 9 now asserts: no movement (pivot on the centroid, scale 1, alpha 1) for every tick up to 60 % of the clip (47 ticks), then the exact swirl position within 1.5 px at every tick, with a real swirl (> 0.5 rad off the straight line; measured 3.11).
   - Purge truth unchanged: case 8 still identical; no gameplay file touched.

Re-run (headless, exit 0, no SCRIPT ERROR / Parse Error): sb_tf06_tornado_video `PASS (12/12 cases, 0 fail)`, sb_polish_003_booster_vfx `PASS`, sb_phone_2026_11_12_f_slot_pop_hold `PASS (100/100 cases, 0 fail)`. Windowed evidence re-captured: `evidence/tornado_strip_1080x2160.png`, `evidence/frames/`, `evidence/perf.txt`. TASKS.md not edited.
