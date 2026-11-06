STATUS: READY

# Build: SB-VIDEO-009 + SB-POLISH-011B, New region unlock and Need a Hand Scrubby videos

## Summary
Branch `factory/108-video-region-need-a-hand` has two commits, not pushed:
- `5211f9fa`: code, assets and tests.
- `4eb963aa`: TASKS.md (queue rows DONE, checklist [x]).

What the branch does:
- **New region unlock (SB-VIDEO-009).** The world unlock surface is the World Transition shell, `MetaCeremonies.world_unlock` (SB-M43-073). No world event is emitted yet: there is only World 01, and `CeremonyEvents` has no world authority. So the video is wired into that builder behind its normal trigger, and no trigger or mechanic was invented. With FULL effects, `start_motion` adds an empty `RegionHero` overlay over the native world art and plays the generic Scrubby video on it once through the shared `play_hero_video`. It then holds the keyed last frame (the ready pose) over the art. The world art stays visible the whole time.
- **Need a Hand (SB-POLISH-011B).** In `AcquisitionFlow.open_need_a_hand`, with FULL effects and Scrubby as the helper, the Scrubby video replaces the CharacterMotion `help` tween. It plays once at 180x160 instead of the 120x132 pose, then holds the keyed start pose (the "?" pose).
- **Fallbacks.** Reduced Effects, another active robot, or a missing or failing stream all keep today's behaviour: the help pose plus the tween, or the static pose in Reduced.
- **Shared rules.** One decoder, freed on finish or on close. The video ignores input. Economy and routing are untouched.

Files:
- `scripts/ui/ceremony/meta_ceremonies.gd`: `REGION_VIDEO_DIR`, injectable `static var region_video`; `world_unlock` tags `WorldArtSlot` with `video` meta (FULL only); `start_motion` plays it.
- `scripts/ui/popup/acquisition_flow.gd`: preloads MetaCeremonies; `NAH_VIDEO_DIR`, `NAH_VIDEO_SIZE`, injectable `static var need_a_hand_video`; `open_need_a_hand` plays the video or falls back to `CharacterMotion.play`.
- `tools/build_result_scrubby_videos.py`: new `new_region` and `need_a_hand` sets (bbox crop, last-frame still, like `welcome_back`); `TRIM["need_a_hand"] = 182`.
- `assets/ui/final/popups/new_region_video/`: `new_region_scrubby.ogv` (720x848, 190 frames, 2.49 MB) + .uid, `new_region_scrubby_still.png` + .import, `PROVENANCE.md`.
- `assets/ui/final/popups/need_a_hand_video/`: `need_a_hand_scrubby.ogv` (576x512, 182 frames, 1.55 MB) + .uid, `need_a_hand_scrubby_still.png` + .import, `PROVENANCE.md`.
- `tests/sb_video_009_polish_011b_region_need_a_hand_video.gd`: new suite, 7 cases.
- `tests/tools/region_need_a_hand_video_capture.gd`: new evidence capture.
- `TASKS.md`: the SB-VIDEO-009 and SB-POLISH-011B queue rows are DONE and the checklist lines are [x].

## Acceptance criteria
1. [x] **Assets built like 093/095/099/104** (crop including the sparkles; Theora .ogv, keyed last-frame still and PROVENANCE.md with master/output sha256, crop and encode command).
   - New region: the bbox over all frames includes the golden sparkles, which reach the frame sides from about frame 150, so the crop is (0,295,720,848), full width. One sparkle touches x=719 around frame 174 and is cut at the box edge for a few frames. I left it because an edge fade would also fade the top of the jumping robot.
   - Need a Hand: bbox (78,487,576,512) includes the "?". Frames 0-181 are used. In the master's last 8 frames the Veo render dims the eyes and fades the "?" out, so frame 181 is the held start pose (same reason as the set_complete trim in 104).
2. [x] **Magenta key works on the drifting background.** I measured min(R,B)-G on the frame borders:
   - need_a_hand: at least 142 on every frame (#FA02FA to #E637CB).
   - new_region: 239 at frame 0 and 171 on the last frame. Its border minimum dips only where sparkles touch the frame edge.
   - All of these are above key_hi 0.45 (115), so the existing `chroma_key_magenta.gdshader` is used unchanged.
   - Build-time keyed stills composited on BG01 and cream: clean robot.
   - On light backgrounds the "?" glow keeps a faint lavender halo and the tiny sparkles show faint rims. These are the same keyer limits as 093/104 and are not visible in-game over the world art or the popup (see stills).
3. [x] **New region, FULL: plays once over the world art, then holds the keyed last frame.**
   - Case `region_full_plays`: one decoder playing `region_video`; magenta shader with no edge fade; mouse ignored; WorldArt still visible; RegionHero hidden while playing and holding `new_region_scrubby_still.png`.
   - Case `region_finish_and_close`: after `finished` the decoder is freed and the overlay shows the still.
4. [x] **Need a Hand, FULL with Scrubby: the video replaces the tween, plays once, then holds the keyed last frame.**
   - Case `nah_full_plays` uses the real app root on a throw-away save: one decoder, magenta key, mouse ignored, no CharacterMotion tween and no motion material, help pose hidden, helper 180x160 holding the still.
   - Case `nah_finish_and_close`: after finishing, the decoder is freed and the start pose is held.
   - It plays once, with no loop. The 182-frame (7.6 s) clip covers what the wave loop did, and its last frame equals its start pose.
5. [x] **Buttons usable during the video.**
   - World unlock: WorldBody and CONTINUE are visible and enabled, and CONTINUE closes the popup mid-video (`action:continue`).
   - Need a Hand: both cards and both BUY buttons are visible and enabled. WATCH AD is visible; it is blocked headless only because no ad provider is present, which is pre-existing behaviour. Closing mid-video works.
   - The wallet is unchanged, so nothing is granted.
6. [x] **Reduced Effects = today's behaviour, no player.**
   - `region_static_paths`: WorldArtSlot holds only WorldArt.
   - `nah_static_paths` (Reduced): the help pose at 120x132, no tween, no decoder.
7. [x] **A failing stream falls back.** A null stream and a broken `VideoStreamTheora` were tested on both surfaces: no decoder or video box is left.
   - World unlock: the art is shown alone.
   - Need a Hand: the help pose at 120x132 and the CharacterMotion `help` tween playing, exactly as before.
8. [x] **Non-Scrubby fallback.** Case `nah_other_robot`: with Atlas active (snapshot import on the throw-away save), the helper shows `atlas_help_pose.png` at 120x132 with the tween and no decoder.
9. [x] **One decoder, freed on close.** Cases `region_finish_and_close` and `nah_finish_and_close`: the decoder is out of the tree at close and invalid one frame later.
10. [x] **No economy or routing change.** The diff is presentation only. The acquisition, need-a-hand, ceremony and economy suites below pass unchanged, and no existing test was edited.
11. [x] **Stills.** Captured with `tests/tools/region_need_a_hand_video_capture.gd` (opengl3; the Need a Hand stills use a throw-away save that is deleted afterwards; main.tscn is never booted without a save override) into `evidence/`:
    - `new_region_video_1080x1920.png` (mid-jump over the Whispering Park art)
    - `new_region_held_1080x1920.png` (ready pose held)
    - `need_a_hand_video_1080x1920.png` (helping wave)
    - `need_a_hand_held_1080x1920.png` ("?" start pose held)

## Validation
All suites ran headless on Godot 4.7.2 and are LOCAL_PASS: exit 0, last line PASS, and no SCRIPT ERROR or Parse Error unless noted.
- `sb_video_009_polish_011b_region_need_a_hand_video`: PASS (7/7, 38 asserts). It prints 2 expected engine `ERROR: Cannot open file .../missing.ogv` lines from the injected broken streams; these are not SCRIPT ERRORs.
- `sb_polish_011_character_motion`: PASS (16/16).
- `m43_c004_c001_fail_need_a_hand`: PASS (40/40).
- `m43_master_c005_meta_ceremonies`: PASS (32/32).
- `m43_c005_c001_ceremony_visual_masters`: PASS (17/17).
- `m43_c005f_phase6_unlock_feel`: PASS (8/8).
- `sb_video_007_008_set_complete_welcome_video`: PASS (8/8).
- `sb_video_006_gift_meter_video`: PASS (6/6).
- `sb_video_005_level_intro`: PASS (8/8).
- `m43_c005f_phase3_meta_rewards_acquisition`: PASS (15/15). Its 2 SCRIPT ERROR lines are the suite's own announced `EXPECTED_FAULT_INJECTION` (`explode`), which is pre-existing.
- `m43_c003_c001_acquisition`: PASS (34/34).
- `m43_c005_c072_feature_unlock_ceremony`: PASS (9/9).
- `m43_c005_c074_c077_celebrations`: PASS (6/6).
- `m43_master_c007r_pity`: PASS (11/11).
- `m39_c003_random_any_booster_rewards`: PASS.
- `m22_025_booster_texture_budget`: PASS.
- `m22_026_texture_budget`: PASS.
- `m43_c001a_results_foundation`: PASS (11/11).
- `m28_c002_c003_final_gate`: **FAIL (12/22), pre-existing and unrelated.**
  - With `meta_ceremonies.gd` and `acquisition_flow.gd` reverted to origin, it fails identically (12/22, 19 fail, 47 SCRIPT ERRORs on a nil booster-acquire popup).
  - It is not in any CI workflow.
- `region_need_a_hand_video_capture` (opengl3): 4 stills written, err=0.
- `git diff --cached --check`: clean on both commits.

No CI run and no phone build, as instructed.

## Log
### Round 1
- **Surfaces.**
  - World/region unlock: only `MetaCeremonies.world_unlock` exists, and it is a shell. Its doc and two suites pin that no world event is emitted. I wired the video there behind its normal trigger, `CeremonyPresenter` push followed by `start_motion`.
  - Need a Hand: `AcquisitionFlow.open_need_a_hand` (091 slide-in plus wave).
- **Judgement calls:**
  - **The video plays over the world art, not instead of it.** The art is the world-specific part and the video is generic, so it goes in an empty overlay that `play_hero_video` fills. On failure the overlay is removed again.
  - **Need a Hand plays once and holds, with no loop.** The brief allowed a looping cadence. A single 7.6 s play that ends on its start pose was the simplest fit and keeps one decoder per popup. Looping can be added if the owner wants it.
  - **The helper grows to 180x160** while the video plays, to match the video aspect (576x512). The popup still fits (see the stills).
  - **The SB-VIDEO-009 TASKS line said "3-5 s full screen".** The owner's actual master is 7.9 s, and the brief said to play it over the native world unlock surface, so it is not full screen. This is recorded in TASKS.md.
  - **Spin blur.** The sprout disappears under motion blur for about 5 frames around 116-136, as the brief noted. Accepted and recorded in PROVENANCE.md.
  - **The new suite is not added to the CI workflow list,** same as 095/099/104 (the workflow has exact-count guards).
  - **`tests/tools/character_motion_capture.gd` was not changed.** It restarts the `help` tween on the Need a Hand helper by hand, so with the video its Need a Hand stills would now show the tween on top of the video. It is a throw-away evidence tool and is not run by any suite.
- **Import churn.** `--import` rewrote about 397 tracked .import files (line endings) and project.godot. I restored them in the worktree only. Untracked generated .uid/.import files, including addons icons, are left in place as in 099/104, so `git status --porcelain` lists only `??` entries. No tracked file is modified. The branch is 4 commits behind origin/main (other jobs); I did not rebase.
