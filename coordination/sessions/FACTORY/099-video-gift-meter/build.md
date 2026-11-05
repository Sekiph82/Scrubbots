STATUS: READY

# Build: SB-VIDEO-006 Gift Meter gift box opening video

## Summary
Branch `factory/099-video-gift-meter`, commits `7fbfd50c` (code + assets + tests) and `ee444fe3` (TASKS.md). Not pushed.

The Gift Meter milestone ceremony (`MetaCeremonies.gift_milestone`) now plays the owner's Flow box opening in the hero slot when effects are FULL. Normal milestones get the small gift box and the cycle-max milestone gets the big robotic crate. The video is keyed from flat green and plays once. The hero then holds the keyed LAST frame (the open, glowing box). Reward rows and CONTINUE stay usable the whole time. Reduced Effects, a missing stream or a stream that fails to start all leave the static hero art exactly as before. Rewards, claim, Gift Meter economy and routing are untouched.

Files:
- `scripts/ui/ceremony/meta_ceremonies.gd`:
  - `gift_milestone` tags the hero with `video` meta (FULL only).
  - `start_motion` calls `_start_gift_video`, which creates one `VideoStreamPlayer` inside an `AspectRatioContainer` in HeroBox. It hides HeroArt with `self_modulate` and resizes HeroArt to the video box (300x420 small, 300x450 big). HeroArt's texture becomes the keyed last-frame still.
  - The decoder is `queue_free`d on `finished` or on popup `closed`.
  - A missing or failed stream removes the player and changes nothing.
  - Injectable `static var gift_video`, keyed by hero art (`gift_small`/`gift_big`).
- `scripts/ui/feel/chroma_key_green.gdshader` (+ .uid), new sibling shader. The magenta shader is unchanged. Key: m = G - max(R,B). Despill: G -= max(m,0). Alpha: 1 - smoothstep(0.15,0.45,m), times a 6 % UV edge fade per side.
- `tools/build_result_scrubby_videos.py`: new `gift` set with a fixed crop per master, the green key with the same edge fade, and the still taken from the LAST frame. The `results` and `level_start` paths are unchanged and were not rebuilt.
- `assets/ui/final/rewards/gift_videos/`:
  - `gift_small_opening.ogv` (3.17 MB, crop 624x928 @76,112)
  - `gift_big_opening.ogv` (3.94 MB, crop 528x800 @106,288)
  - `gift_{small,big}_opening_still.png` (+ .import, .ogv.uid)
  - `PROVENANCE.md` (master and output sha256, crops, encode command)
- `tests/sb_video_006_gift_meter_video.gd` (new suite) and `tests/tools/gift_video_capture.gd` (evidence capture).
- `TASKS.md`: the SB-VIDEO-006 queue line is DONE and the checklist line is [x].

## Acceptance criteria
1. [x] **Small box for normal milestones, big crate for cycle max:** suite case `small_vs_big`, milestone 10 -> `gift_small` stream, 1000 -> `gift_big`, one decoder each, green shader, mouse ignored. Captures `evidence/gift_10_video_1080x1920.png` and `evidence/gift_1000_video_1080x1920.png`.
2. [x] **Plays once, then holds the keyed last frame (open glowing box):** case `finish_holds_last_frame` (after `finished`: decoder freed, HeroArt visible with `*_opening_still.png`). Captures `evidence/gift_10_held_1080x1920.png` and `evidence/gift_1000_held_1080x1920.png`.
3. [x] **Reward rows and CONTINUE visible and usable during the video:** case `rows_cta_usable` (rows visible, button enabled; pressing CONTINUE mid-video closes with `action:continue`).
4. [x] **Reduced Effects shows the static hero exactly as now, with no VideoStreamPlayer:** case `reduced_static` (both sizes: original texture, `self_modulate` 1, original 220/300 size).
5. [x] **Video failure falls back to the static hero:** case `failure_fallback` (null stream and a broken `VideoStreamTheora`, both sizes: no decoder or box left, static art and size unchanged). The first capture run also hit this for real: a decoder started inside `_initialize` before the first frame did not play, and the popup showed the unchanged static art.
6. [x] **One decoder, freed when finished or when the popup closes:** cases `small_vs_big` (exactly one), `finish_holds_last_frame`, and `close_frees_decoder` (out of the tree at close, invalid one frame later).
7. [x] **Green key with despill, so rays don't look green:** checked visually on the stills (cream and BG01 composites, in-game captures). The light rays read yellow-white and the crate's lid debris is outside the crop.
8. [x] **No change to rewards, claim, economy or routing:** the diff touches only presentation in `meta_ceremonies.gd`. The gift and economy suites below pass unchanged, with no edits to existing tests.
9. [x] **Layout still fits with the taller video hero:** `tests/tools/meta_ceremony_snapshot.gd` (rendering driver) for gift 10 and 1000, FULL at 5 viewports plus Reduced: `META_CEREMONY_EVIDENCE CLEAN (0 rejected)`.

## Validation
All suites are headless Godot 4.7.2 and LOCAL_PASS (exit 0, last line PASS, no SCRIPT ERROR / Parse Error unless noted):
- `sb_video_006_gift_meter_video`: PASS (6/6 cases). It prints 2 expected engine `ERROR: Cannot open file .../missing.ogv` lines from the injected broken stream; these are not SCRIPT ERRORs.
- `m43_master_c005_meta_ceremonies`: PASS (32/32)
- `m43_c005_c074_c077_celebrations`: PASS (6/6)
- `m43_master_c005r_gift_micro_progress`: PASS (8/8)
- `sb_polish_002_gift_meter`: PASS (11/11)
- `m43_c005_c001_ceremony_visual_masters`: PASS (17/17)
- `m43_c005f_phase3_meta_rewards_acquisition`: PASS (15/15). It has 1 SCRIPT ERROR line, which is the suite's own injected FaultySpark `explode` fault (pre-existing, by design).
- `m43_c005f_phase4_qa_r01_feel_lifecycle`: PASS (4/4)
- `m43_c005f_phase4_terminal_home_micro`: PASS (19/19). Its 5 SCRIPT ERROR lines are all the injected `explode` line that CI allowlists (`INJECTED`).
- `m43_master_c011_c014`: PASS (28/28)
- `m39_c003_random_any_booster_rewards`: PASS
- `meta_ceremony_snapshot` (opengl3) for gift_milestone and gift_milestone_1000: CLEAN.
- `gift_video_capture` (opengl3): 4 stills in `evidence/`.
- `git diff --cached --check`: clean.

No CI run and no phone build, as instructed.

## Log
### Round 1
- Built the `gift` set from the two read-only masters. The crops are chosen by hand because the sparkles fill the whole frame, so a bbox would be the full frame:
  - Small box: the lid hovers high on its spring in the final frame, so the crop is tall (624x928).
  - Crate: 528x800, ending at x=634 so the lid debris that lands at x>=625 falls inside the 6 % edge fade and outside the crate.
  - The edge fade hides sparkles the crop cuts.
- Judgement calls:
  - **Taller hero only while the video plays.** The video needs vertical room for the burst and the floating lid, so the hero grows from 220x220/300x300 to 300x420/300x450. This happens only once the video has actually started. Reduced and failure keep the original size, and the snapshot fit checks pass at all 5 viewports.
  - **No first-frame still.** Only the keyed last-frame still (the hold pose) is exported. Nothing would display a first-frame still, so it would be an orphan image. The static art covers the pre-play state, and the video's first frame matches it.
  - **Sibling green shader** instead of generalizing the magenta one, so the magenta behaviour stays byte-identical.
  - **Injection** is a static var (`MetaCeremonies.gift_video`) because the builders are static. Existing suites needed no change: they pass with the real video path.
  - **Decoder release on close:** when the ModalStack frees the popup on close, `VideoStreamPlayer.stop()` is a no-op once the node is out of the tree. The decoder is still freed with the popup on the next frame, and the test asserts that.
- `--import` rewrote about 257 tracked .import files with line-ending-only changes in the worktree. I restored them (worktree only) and restored project.godot. The Godot-generated untracked .uid files are left in place, as instructed. They are not committed, so `git status` is not empty.
