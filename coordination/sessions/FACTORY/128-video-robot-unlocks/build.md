STATUS: READY

# Build: SB-VIDEO-010 robot unlock signature videos

## Summary
Branch `factory/128-video-robot-unlocks` has two commits. Neither is pushed.
- `267f27f3`: code, assets and tests.
- `71465fdf`: TASKS.md (the queue row is DONE and the checklist line is [x], with per-robot notes).

What the branch does: the Robot Unlock ceremony (`MetaCeremonies.robot_unlock`) now plays that robot's own Flow signature video when effects are FULL.
- **Playback.** `start_motion` sends it through the shared `play_hero_video` into a 400x480 hero. The video plays once, then the hero holds the keyed last frame.
- **Key per background.** Magenta, green or blue, depending on the robot.
- **Fallbacks.** Reduced Effects, a missing stream or a failing stream all leave today's static roster art (330x396).
- **Unchanged.** EQUIP and KEEP stay usable throughout. Unlock, equip and the economy are untouched. There is one decoder, freed on finish or on close.

Files:
- `scripts/ui/ceremony/meta_ceremonies.gd`: adds `ROBOT_VIDEO_DIR/SIZE/EDGE/KEY` and the injectable `static var robot_video`.
  - `robot_unlock` tags HeroBox with `video = "robot:<id>"` (FULL only).
  - `start_motion` resolves `<id>_unlock.ogv` + `_still.png` and the shader for that robot.
- `scripts/ui/feel/chroma_key_blue.gdshader` (+ .uid), new. The magenta and green shaders are unchanged.
  - Key: m = B - max(R,G), alpha = 1 - smoothstep(0.30, 0.45, m).
  - Despill: B is clamped to max(R,G)+0.30, so Clippy's purple armour stays purple.
  - Has an `edge_fade` uniform.
- `tools/build_result_scrubby_videos.py`: new `robots` set with `ROBOT_KEY`, `robot_box`, `key_blue`, a 480x576 scale and `TRIM` for polly/spark. The other sets are unchanged and were not rebuilt.
- `assets/ui/final/robots/unlock_videos/`: `<id>_unlock.ogv` (+ .uid) and `<id>_unlock_still.png` (+ .import) for all 10 ids, plus `PROVENANCE.md` (master and output sha256, crop, key, encode command). The names avoid `_master` etc.; m22_026 passes.
- `tests/sb_video_010_robot_unlock_video.gd` (new suite) and `tests/tools/robot_unlock_video_capture.gd` (new evidence capture).
- `tests/m43_master_c005_meta_ceremonies.gd`: the e16 assertion now accepts Moppy's video still as the HeroArt texture in FULL. Identity is still checked: name, role, perk and perk icon.
- `tests/tools/meta_ceremony_snapshot.gd`: the robot event now comes from `economy.robots.unlock("moppy")`. Before this change, `actions.unlock_next_robot()` was feature-gated on the fresh save, so the tool had no robot_unlock event at all (pre-existing breakage).

**APK size added: 25.4 MB.** That is 23.0 MB of .ogv plus 2.36 MB of stills. Scrubby's pair alone is 2.34 MB and is not used yet. Every crop is scaled to 480x576 (at least the 400x480 hero box). Without the scale, the full-resolution crops were 41.3 MB.

## Acceptance criteria
1. [x] **Assets built like 093/099/104/108.** One Theora .ogv per robot, a keyed last-frame still, and PROVENANCE.md.
   - Crop: a 5:6 box around everything that is foreground in at least 5 % of frames. That covers the robot, tool swings and the recurring bubbles, water and sparkles. The box is shifted so the robot body (foreground in at least 30 % of frames) is always inside.
   - Short full-frame bursts (Scrubby's sparkle rain, Spark's speed lines, Atlas's spark burst) are cut by a 6 % edge fade.
   - Crops (x, y, w, h):

     | Robot | Crop |
     |---|---|
     | scrubby | 0,291,720,864 |
     | moppy | 0,342,720,864 |
     | bubbles | 0,228,720,864 |
     | spark | 0,208,720,864 |
     | squeegee | 14,236,680,816 |
     | dusty | 40,275,680,816 |
     | rinse | 80,382,640,768 |
     | polly | 45,260,660,792 |
     | clippy | 15,253,700,840 |
     | atlas | 0,304,720,864 |
2. [x] **Last ~10 frames inspected; trims documented.** I made full-resolution close-up sheets of the last 12-18 frames for every robot.
   - **polly: frames 0-179 used.** In frames 180-189 the face screen powers down and the polisher motion-blurs down to the floor.
   - **spark: frames 0-184 used.** In frames 185-189 the brush swings down and its head morphs into a different broom.
   - **The other 8 robots: full 190 frames.** Their ends are stable. Rinse's nozzle lowers slightly in the last 2 frames, which is acceptable.
3. [x] **Frame-by-frame glitch review** (every 4th frame for all 10, plus close-ups). Art is noted only, not fixed:
   - **scrubby:**
     - The face screen blinks dark around frame 4, then powers on. The start frame is already lit.
     - A lighter halo ring sits in the background.
     - A white dust puff appears at landing (~112-120).
     - The sparkle rain fills the frame width from ~116 to 170.
     - The sprout is present throughout.
     - The magenta drifts the furthest of all the masters, to ~#C843B1.
   - **moppy:**
     - The robot turns sideways around 40-48.
     - A cyan swish streak runs to the left frame edge around 84-96 (cut by the fade).
     - The tool, tank and sprout stay consistent. No glitch.
   - **bubbles:**
     - The face screen goes blank (dark, no eyes) from ~84 to 124.
     - The bubble column leaves the top of the master frame from ~36 to 130 (cut by the fade).
     - The purple/teal sprout survives the green key.
   - **dusty:**
     - The face shows "x_x" eyes from ~4 to 48 instead of happy eyes.
     - The flat floor wand from frame 0 morphs into a long nozzle around 8-12.
     - A white glow appears behind the tank around 16-32.
     - The dust cloud and the nozzle tip reach the right frame edge.
   - **squeegee:**
     - The tool passes in front of the face around 136-148 and switches hands. The end pose holds it in the other hand.
     - The blue sprout matches the start frame.
   - **rinse:**
     - A white glow sits behind the tank from 0 to 52. It keys to a light haze.
     - Water spray reaches the right frame edge around 4-44 and 84-92 (cut by the fade).
   - **polly:**
     - The floor polisher and the hand-held pad morph into each other (~16-28, ~72-80, end).
     - The screen dims grey with closed eyes from ~76 to 124.
     - The end is trimmed (see 2).
   - **spark:**
     - Spark has an antenna with a ball instead of a leaf sprout. This matches the start frame and the roster art.
     - The broom-like brush becomes a round scrub brush around 28.
     - The back view during the spin (~36-76) has full-frame speed lines (cut by the fade).
   - **clippy:**
     - **Doubled tool.** From ~20 to the end, a big claw is held in one hand while the original small claw tool stays on the other hand.
     - The background has ripple rings.
     - Keyed white sparkles keep a lavender halo: the blue spill sits inside the glow, a keyer limit.
   - **atlas:**
     - The brush morphs from a floor brush to a round overhead scrub brush (~28-80) and back.
     - After the thump (~130) the body re-proportions until the end: a bigger torso and chest light, the tank moves, longer arms. This is off-model drift that cannot be trimmed, because it is the whole last third.
     - The gold spark burst around 100-125 fills the frame width (cut by the fade).
4. [x] **Keys.**
   - **Magenta:** I measured the background m = min(R,B)-G per frame (median over clear-background pixels). The minimum is at least 156 for moppy, dusty, squeegee, rinse, spark and atlas, all above key_hi 115, so the existing magenta shader is used unchanged with `edge_fade 0.06`.
   - **Scrubby:** it ends at m ≈ 105, below 115. Its late frames leave a faint (~3-10 % alpha) haze, which shows only on light backgrounds (visible in my cream composite). It is not used today (see 6).
   - **Green:** flat (min 247), handled by the unchanged `chroma_key_green.gdshader`, which already has a 0.06 edge.
   - **Blue:** Clippy's background m = B-max(R,G) is at least 137 (0.54). The purple armour has median m 46 (p90 70). The new blue key uses 0.30/0.45, with the despill clamp keeping purple intact.
   - **Composites:** I checked keyed composites on BG01 and cream for 9 frames per robot. Bodies are clean.
5. [x] **Integration.** The Robot Unlock ceremony plays that robot's video once through `play_hero_video` and then holds the keyed last frame. Suite cases:
   - `full_plays`: all 10 ids. Each has one decoder playing `<id>_unlock.ogv`, the right shader, `edge_fade` 0.06 and mouse ignored. The roster art is hidden, the hero is 400x480 and holds `<id>_unlock_still.png`.
   - `finish_holds_last_frame`: the decoder is freed, the still is visible and the popup stays open.
6. [x] **Scrubby.** Scrubby is the starter, and `CeremonyEvents.events` skips `initial_robot`, so no Scrubby unlock ceremony path exists. Its video and still are built and mapped by the same id rule, which the suite covers by calling the builder directly. They are kept for later.
7. [x] **Reduced, failure and missing all fall back to today's static art.**
   - `reduced_static` (moppy, bubbles, clippy): no player, no video meta, roster master art at 330x396.
   - `failure_fallback`: a null stream and a broken `VideoStreamTheora` (spark, bubbles) leave no decoder or box, and the static art is unchanged. A missing file resolves to null through `ResourceLoader.exists`.
8. [x] **Buttons usable.** In `buttons_usable` (polly), the perk card is visible, and EQUIP and KEEP are each visible and enabled mid-video. Pressing either one closes the popup with `action:equip` / `action:keep`.
9. [x] **One decoder, freed.** Covered by `full_plays` (exactly one), `finish_holds_last_frame`, and `close_frees_decoder` (out of the tree at close, invalid one frame later).
10. [x] **No economy or unlock change.** The diff is presentation only. m43_master_c008_robots, m54_regression_pack_022_027 (robot cases) and the meta ceremony suites pass.
11. [x] **Shader per key colour.** `ids_map_streams` checks that each of the 10 roster ids has a Theora stream and a 480x576 still. `full_plays` checks magenta for 7, green for bubbles/polly and blue for clippy. The blue shader source keys B - max(R,G).
12. [x] **Stills** with the rendering driver (opengl3). They use static builders only: no save is touched and main.tscn is not booted. They are in `factory/jobs/128-video-robot-unlocks/evidence/`:
    - `robot_moppy_video_1080x1920.png` / `robot_moppy_held_1080x1920.png` (magenta)
    - `robot_bubbles_video_1080x1920.png` / `robot_bubbles_held_1080x1920.png` (green)
    - `robot_clippy_video_1080x1920.png` / `robot_clippy_held_1080x1920.png` (blue)
13. [x] **Layout fits the taller video hero.** `meta_ceremony_snapshot.gd -- <tmp> robot_unlock` (opengl3, throw-away save that the tool deletes) at 5 viewports FULL plus Reduced gives `META_CEREMONY_EVIDENCE CLEAN (0 rejected)`.

## Validation
All suites are headless Godot 4.7.2 and LOCAL_PASS: exit 0, last line PASS, and no SCRIPT ERROR or Parse Error unless noted.
- `sb_video_010_robot_unlock_video`: PASS (7/7, new). It prints 2 expected engine `ERROR: Cannot open file .../missing.ogv` lines from the injected broken stream; these are not SCRIPT ERRORs.
- `m43_master_c008_robots`: PASS (10/10).
- `m43_master_c005_meta_ceremonies`: PASS (32/32).
  - The first run failed 1 assert: e16 expected the master art on HeroArt in FULL.
  - I updated the assert, and my first edit had a Parse Error (`:=` on an untyped `in`). Both are fixed and the rerun is clean.
- `m54_regression_pack_022_027`: PASS (12/12).
- `m43_c005_c001_ceremony_visual_masters`: PASS (17/17).
- `m43_c005f_phase6_unlock_feel`: PASS (8/8).
- `m43_c005f_015_e2e_feel`: PASS (6/6). Its SCRIPT ERROR lines are all the suite's announced `EXPECTED_FAULT_INJECTION` FaultySpark `explode` (pre-existing, by design).
- `sb_video_006_gift_meter_video`: PASS (6/6).
- `sb_video_007_008_set_complete_welcome_video`: PASS (8/8).
- `sb_video_009_polish_011b_region_need_a_hand_video`: PASS (7/7).
- `m22_026_texture_budget`: PASS.
- `m22_025_booster_texture_budget`: PASS.
- `m43_c001a_results_foundation`: PASS (11/11).
- `m43_c005_c074_c077_celebrations`: PASS (6/6).
- `meta_ceremony_snapshot` robot_unlock (opengl3): CLEAN.
- `robot_unlock_video_capture` (opengl3): 6 stills, err=0.
- `git diff --cached --check`: clean on both commits.

No CI run and no phone build, as instructed. The new suite is not added to the CI workflow list, same as 095/099/104/108.

## Log
### Round 1
- Decoded all 10 masters. Measured the background drift and key strength per frame, built contact sheets (every 4th frame) and full-resolution close-ups of the tails and suspicious ranges. Recorded the per-robot glitches above.
- Judgement calls:
  - **Crop rule.** I used a frequency bbox (>= 5 % of frames) instead of the all-frames bbox. On 6 of 10 masters the all-frames bbox is the full frame because of one-off bursts. The 5:6 aspect matches the static hero (330x396). Bursts the crop cuts get the gift/set_complete 6 % edge fade, and the robot body is always inside the crop.
  - **Scaled to 480x576.** The hero shows the video at 400x480, so full-resolution crops (41.3 MB) were wasted APK weight. Scaling brings the total to 25.4 MB.
  - **Bigger hero during the video only** (400x480 vs 330x396). The robot plus its effects needs the room. Reduced and failure keep 330x396, and the snapshot fit check is CLEAN.
  - **Blue thresholds 0.30/0.45.** With 0.15 like the other keys, the purple armour (m up to ~0.3) would go see-through. With 0.40/0.50, sparkle halos stayed more lavender. Despill clamps rather than subtracts, so purple is never shifted toward magenta.
  - **No eager loading** of 10 streams at script load. They are resolved per ceremony, with the injectable `robot_video` overriding.
  - **Scrubby's weak late key is left as is**, because no ceremony shows it. If a Scrubby path appears later, pass a higher key_hi or regenerate the master.
- `--import` rewrote about 400 tracked .import files and project.godot (line endings only). I restored them in the worktree. I then deleted every untracked Godot-generated file in the worktree, so `git status --porcelain` is empty.
