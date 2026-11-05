STATUS: READY

# Build: SB-VIDEO-007 + SB-VIDEO-008, Collection set complete and Welcome back videos

## Summary
Branch `factory/104-video-set-complete-welcome` has two commits, not pushed:
- `a77a7074`: code, assets and tests.
- `09673bdf`: TASKS.md.

What the branch does:
- **Collection SET COMPLETE ceremony** (`MetaCeremonies.set_complete`). With FULL effects, the hero slot plays the owner's magenta-keyed Flow video once: the gold crowned badge pops, flaps its wings, a light sweep crosses it, a star burst rains, and it ends glowing. The hero then holds the keyed last frame.
- **Welcome back screen.** The live surface is the Home comeback summary, `ProfileScreens.open_comeback`, which main.gd opens after a genuine absence of 48 h or more. With FULL effects and Scrubby as the active robot, it plays the owner's Scrubby video once in the popup hero slot (jump, wave both hands, hug, wave), then holds the keyed last frame.
- **Static paths.** Reduced Effects, a missing stream or a stream that fails to start leaves today's static art exactly as it is (emblem, or help pose), with no decoder. The same applies on the comeback screen when another robot is active, because the video shows Scrubby.
- **Lifecycle and safety.** There is one decoder, freed when the video finishes or the popup closes. The video ignores input, so buttons stay usable. Rewards, claim, the return window, catch-up, economy and routing are unchanged.

Files:
- `scripts/ui/ceremony/meta_ceremonies.gd`:
  - The 099 gift video code is now a shared `play_hero_video(p, h, stream, still, size, key, edge)`, used by gift, set complete and comeback. The video box is now a full-rect child of the HeroArt TextureRect instead of a sibling in HeroBox; it looks the same.
  - New: `set_complete` tags its hero with `video` meta (FULL only), `SET_VIDEO_*` constants, and injectable `static var set_video`.
- `scripts/ui/profile/profile_screens.gd`: `open_comeback` starts the video after `stack.push`. Adds `WELCOME_VIDEO_*` constants and injectable `static var welcome_video`.
- `scripts/ui/feel/chroma_key_magenta.gdshader`: new `edge_fade` uniform, default 0. When it is 0 the fade branch is skipped, so Results and Level Intro behave exactly as before.
- `tools/build_result_scrubby_videos.py`:
  - New `set_complete` set: fixed 624x624 crop, 6 % edge fade, last frame as the still, trimmed to 182 frames.
  - New `welcome_back` set: bbox crop, last frame as the still.
  - The existing sets build the same output: `key(..., edge=0)` multiplies by 1.0, and the results still is still frame 0.
- `assets/ui/final/rewards/set_complete_video/`: `set_complete_badge.ogv` (624x624, 182 frames, 3.57 MB), `set_complete_badge_still.png` (+ .import/.uid), `PROVENANCE.md`.
- `assets/ui/final/popups/welcome_video/`: `welcome_back_scrubby.ogv` (576x672, 190 frames, 2.64 MB), `welcome_back_scrubby_still.png` (+ .import/.uid), `PROVENANCE.md`.
- `tests/sb_video_007_008_set_complete_welcome_video.gd`: new suite, 8 cases.
- `tests/tools/set_welcome_video_capture.gd`: new evidence capture.
- `tests/sb_video_006_gift_meter_video.gd` and `tests/tools/gift_video_capture.gd`: node names updated from `GiftVideoBox`/`GiftVideo` to `HeroVideoBox`/`HeroVideo`.
- `TASKS.md`: the SB-VIDEO-007/008 queue rows are DONE and the checklist lines are [x].

## Acceptance criteria
1. [x] **Assets built like 093/095/099.** The masters were cropped to the content including the burst, encoded as Theora .ogv, and given a keyed last-frame still and a PROVENANCE.md (master and output sha256, crop, encode command).
   - Set complete: the stars fill the whole frame from about frame 100, so a bbox would be the full frame. I used a fixed square around the badge plus the burst, with a 6 % soft edge fade like the gift set.
   - Welcome back: bbox crop (95,359,576,672).
   - No first-frame still: no surface would display it.
2. [x] **Magenta key works on the drifting background.** I measured min(R,B)-G on the frame borders: 242 at frame 0, at least 140 at the end, above key_hi 0.45 (115). The background is fully keyed with the existing thresholds; only the new `edge_fade` uniform was added.
   - Build-time keyed stills composited on BG01 and cream: clean.
   - In-game captures: no pink fringe. The gold stars and confetti are kept, because for gold R > G > B, so m < 0.
3. [x] **Set complete, FULL: plays once, then holds the keyed last frame.** Suite cases `set_full_plays` (one decoder, magenta shader with edge_fade 0.06, mouse ignored, emblem hidden, hero 320x320 holding `set_complete_badge_still.png`) and `set_finish_holds_last_frame`.
4. [x] **Welcome back, FULL with Scrubby: plays once, then holds the keyed last frame.** Suite case `welcome_full_plays` uses the real app root on a throw-away save (one decoder, magenta key with no edge fade, help pose hidden, hero 240x280 holding the still). Case `welcome_finish_and_close` covers the finish.
5. [x] **Buttons and claim stay usable during the video.**
   - Set complete: set cards, reward rows and CONTINUE are visible and enabled, and CONTINUE closes the popup mid-video (`action:continue`).
   - Welcome back: the summary lines and LET'S CLEAN are usable and close it mid-video.
   - The wallet is unchanged, so nothing is granted.
6. [x] **Reduced Effects shows today's static art with no player.** Cases `set_reduced_static` (emblem, 230x230) and `welcome_static_paths` (Reduced: help pose, 220x220).
7. [x] **A failing stream falls back to the static art.** A null stream and a broken `VideoStreamTheora` were tested on both surfaces: no decoder or box is left and the art and size are unchanged. Cases `set_failure_fallback` and `welcome_static_paths`.
8. [x] **One decoder, freed on finish or close.** Cases `set_close_frees_decoder` and `welcome_finish_and_close`: the decoder is out of the tree at close and invalid one frame later.
9. [x] **No economy, claim or routing change; 099 behaviour kept.** The diff is presentation only. The gift, collection, comeback and economy suites pass unchanged. The only test edit is the renamed node name in the 099 suite and its capture tool.
10. [x] **Layout fits.** `tests/tools/meta_ceremony_snapshot.gd` (opengl3) for set_complete, FULL at 1080x1920, 1080x2160, 1170x2532, 1290x2796 and 1536x2048, plus Reduced: `META_CEREMONY_EVIDENCE CLEAN (0 rejected)`.
11. [x] **Stills.** Captured with `tests/tools/set_welcome_video_capture.gd` (opengl3; the comeback stills use a throw-away save that is deleted afterwards) into `evidence/`:
    - `set_complete_video_1080x1920.png` (star burst mid-video)
    - `set_complete_held_1080x1920.png` (glowing badge held)
    - `welcome_back_video_1080x1920.png` (both hands up)
    - `welcome_back_held_1080x1920.png` (end pose held)

## Validation
All suites ran headless on Godot 4.7.2 and are LOCAL_PASS: exit 0, last line PASS, and no SCRIPT ERROR or Parse Error unless noted.
- `sb_video_007_008_set_complete_welcome_video`: PASS (8/8). It prints 2 expected engine `ERROR: Cannot open file .../missing.ogv` lines from the injected broken streams; these are not SCRIPT ERRORs.
- `sb_video_006_gift_meter_video`: PASS (6/6).
- `m43_master_c005_meta_ceremonies`: PASS (32/32).
- `m43_c005_c001_ceremony_visual_masters`: PASS (17/17).
- `m43_c005_c074_c077_celebrations`: PASS (6/6).
- `m43_c005_c072_feature_unlock_ceremony`: PASS (9/9).
- `m54_collection_set_master_exactly_once`: PASS.
- `m43_master_c011_c014` (comeback c01/c02): PASS (28/28).
- `m43_master_c010_meta`: PASS (12/12).
- `m43_personal_ranks`: PASS (8/8).
- `m47_touch_r01_mobile_ux`: PASS (14/14).
- `m43_c005f_phase3_meta_rewards_acquisition`: PASS (15/15). Its SCRIPT ERROR is the suite's own injected `explode` fault (pre-existing).
- `m43_c005f_phase4_qa_r01_feel_lifecycle`: PASS (4/4).
- `m43_c005f_phase4_terminal_home_micro`: PASS (19/19). Its 5 SCRIPT ERRORs are the injected `explode` lines (pre-existing, allowlisted).
- `m39d_daily_collection`: PASS.
- `m43_master_c007r_pity`: PASS (11/11).
- `m43_master_c005r_gift_micro_progress`: PASS (8/8).
- `sb_polish_002_gift_meter`: PASS (11/11).
- `m39_c003_random_any_booster_rewards`: PASS.
- `m22_026_texture_budget`: PASS.
- `m22_029_texture_cold_warm`: PASS.
- Magenta shader users: `sb_video_005_level_intro` PASS (8/8) and `m43_c001a_results_foundation` PASS (11/11).
- `meta_ceremony_snapshot` set_complete: CLEAN.
- `set_welcome_video_capture`: 4 stills written, err=0.
- `git diff --cached --check`: clean.

Most suites ran before a last cosmetic edit, which removed an unused bool return from `play_hero_video`. After that edit, on the committed tree, I re-ran `sb_video_007_008`, `sb_video_006` and `m43_master_c005_meta_ceremonies`; all PASS.

No CI run and no phone build, as instructed.

## Log
### Round 1
- **Surfaces.**
  - The set-complete ceremony is `MetaCeremonies.set_complete`, presented by CeremonyPresenter, which calls `start_motion` after the push.
  - The welcome-back screen exists and is live: `ProfileScreens.open_comeback`, opened by `main.gd._drain_home_ceremonies` when `returns.summary_due()`. So SB-VIDEO-008 is wired into it, with no new mechanic.
  - I did not touch any album or card-loading code (job 103).
- **Judgement calls:**
  - **Trimmed the set-complete video to frames 0-181.** In the master's last 8 frames the Veo render dissolves the wings and turns the gold copper. Holding frame 189 would have shown a wingless copper badge, so the held pose is frame 181. This is recorded in PROVENANCE.md and in the `TRIM` constant of the build tool.
  - **Fixed square crop plus edge fade for set complete,** because the stars fill the frame. To get the edge fade I added an `edge_fade` uniform to the magenta shader, default 0, which is a no-op for 093/095, instead of creating another shader. This is the "tune only via a uniform" route.
  - **Hero sizes while the video plays:**
    - Set complete goes from 230 to 320x320, so the badge reads about the same size as the static emblem inside the burst.
    - Comeback goes from 220x220 to 240x280, matching the video's aspect ratio.
    - Both sizes apply only once playback has started; Reduced and failure keep the original size. The set_complete fit check is CLEAN at all 5 viewports.
  - **The comeback video plays only when Scrubby is active.** It shows Scrubby, as with the Results videos in 093; other robots keep their own help pose.
  - **Shared helper.** I generalized 099's `_start_gift_video` into `play_hero_video`, so all three surfaces share one decoder lifecycle. The 099 node names changed to `HeroVideoBox`/`HeroVideo`; the 099 suite and capture tool were updated and still pass.
  - **Asset names:** `set_complete_badge*` and `welcome_back_scrubby*`, in new folders `rewards/set_complete_video/` and `popups/welcome_video/`, outside `collection/`. I ran every static-guard suite that reads these sources; all pass.
  - **CI workflow.** The new suite is not added to the workflow list, same as 095 and 099, because the workflow has exact-count guards.
- **Import churn.** `--import` rewrote about 260 tracked .import files (line endings only) and project.godot. I restored them in the worktree only. The untracked generated .uid/.import files are left in place, as in 099, so `git status` is not empty. No tracked file is modified.
