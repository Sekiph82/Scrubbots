STATUS: READY

# Build: SB-POLISH-011 V1 tween character animations (WIN / LOSE / Need a Hand / Level Intro)

## Acceptance criteria (written by the builder; there was no spec-writer)
1. WIN Results: the robot does a jump-in with squash/stretch, then a happy bob loop with an occasional sparkle. It plays alongside the existing confetti and starts and ends on the static pose.
2. LOSE Results: a gentle droop, then a hopeful bounce. Motivating, not punishing.
3. Need a Hand: the helper robot slides in, then does a small wave/tilt.
4. Level Intro: a quick "ready" bounce under 1 s.
5. Presentation only: buttons work right away, the robot never takes input, and nothing in economy, save or navigation changes.
6. Reduced Effects means fully static: no tween, no material, no node.
7. At most one or two nodes per screen, and no node growth across many Results (M55).
8. It uses only existing art (assets/ui/final/popups/...). No new art and no video.
9. Evidence: 2 stills per screen at 1080x2160, made with the rendering driver and never booting main.tscn without a save override.

## Summary
`scripts/ui/feel/character_motion.gd` adds one static helper, `CharacterMotion.play(control, mode, reduced, intro)` / `stop()`. It has four modes: `win`, `lose`, `help` and `ready`. Motion is scale and rotation tweens around a feet pivot (`pivot_offset_ratio`), plus a draw-only vertical/horizontal offset from the tiny canvas shader `character_offset.gdshader`. Because of that, the container layout rect never moves. Each Control has one live motion, and the tweens are owned by the Control. The `win` loop's sparkle is a single `Sparkle` CPUParticles2D under the robot, and `stop()` removes it.

Wiring:
- `results_screen.gd`: WON plays `win` and LOST plays `lose` on the existing robot. A re-show of the same terminal identity (for example the Continue re-arm) skips the intro and goes straight to the loop. Hide and `_stop_feel` stop the motion. The WIN confetti now targets the robot *slot* (the robot's static layout box), and `_after_layout` waits on the slot, because the robot's own transform is animated.
- `acquisition_flow.gd`: `open_need_a_hand(offer, reduced := false)` plays `help` on the bubble Scrubby. `main.gd` passes the canonical Reduced Effects flag.
- Level Intro: there is **no live Level Intro screen** in the game (TASKS SB-M43-170: "Ranks/Level Intro not live"; the `popups/level_intro` art is unused by any script). Building that screen is a separate product surface, so I did not invent it. The `ready` mode is implemented and tested (0.62 s), and the stills show it in a clearly labelled HARNESS made of the existing level_intro frame, the normal emblem and the help pose. Wiring it is a one-line `CharacterMotion.play(robot, "ready", reduced)` once the screen exists.

Files changed:
- new: `scripts/ui/feel/character_motion.gd`, `scripts/ui/feel/character_offset.gdshader`, `tests/sb_polish_011_character_motion.gd`, `tests/tools/character_motion_capture.gd`
- modified: `scripts/ui/results_screen.gd`, `scripts/ui/popup/acquisition_flow.gd`, `scripts/app/main.gd`, `tests/m43_c005_c005_reward_reveal_sequencer.gd`, `tests/m43_c005f_phase2_results_pack_feel.gd`, `TASKS.md`

Commits: e292f742 (code and tests), a8d1d33a (TASKS.md). Not pushed.

## Acceptance criteria
1. [x] WIN: `sb_polish_011_character_motion` cases modes_move, win_loop_sparkle and results_won_lost (intro crouch running on WON; one Sparkle emitter after 2 loop cycles; `stop()` gives the static pose). Stills `evidence/win_1_jump_1080x2160.png` (stretched mid-jump, scale 0.93x1.09) and `evidence/win_2_bob_sparkle_1080x2160.png` (bob with gold sparks plus the existing confetti).
2. [x] LOSE: results_won_lost case (droop: scale.y < 1, negative tilt). Stills `evidence/lose_1_droop_1080x2160.png` (1.04x0.94, -4 deg) and `evidence/lose_2_hopeful_hop_1080x2160.png` (stretch up, +1 deg).
3. [x] Need a Hand: the modes_move help case, plus the capture runs the real third-failure Need a Hand. Stills `evidence/need_a_hand_1_slide_in_1080x2160.png` (t = 0.12 s, sliding and fading in) and `evidence/need_a_hand_2_wave_1080x2160.png` (7 deg wave).
4. [x] Level Intro `ready`: ready_under_1s case (`READY_S` = 0.62 s; ends static and stops before 1 s). Stills `evidence/harness_level_intro_1_squash_hop_1080x2160.png` and `evidence/harness_level_intro_2_ready_peak_1080x2160.png`. These are a HARNESS because the screen is not live (see Summary).
5. [x] Input never blocked: results_input_live case (mid-intro, the robot is `MOUSE_FILTER_IGNORE`, CLEAN NEXT is enabled, and a press emits continue_requested once). m43_c004_c001 40/40 (Need a Hand flows unchanged). The motion touches no economy, save or navigation code.
6. [x] Reduced: the reduced_static case (all 4 modes: no tween, no material, no child) and the Results Reduced model case (static robot). Need a Hand takes `app_state.effects.is_reduced()`.
7. [x] Nodes: results_no_node_growth (4 WON Results with sparkles, then hidden: node count 29 == 29). Each screen gets 0 or 1 extra node (only the WIN Sparkle). A replay kills the old tween (replay_no_stack).
8. [x] No new art. The capture uses only `assets/ui/final/popups/{victory,help,level_intro}` plus existing Results/Need a Hand art.
9. [x] 8 stills at 1080x2160 in `factory/jobs/091-polish-result-anim/evidence/`. They come from `tests/tools/character_motion_capture.gd` (rendering driver, main.tscn with `boot_save_path_override` on a temp save, real terminal signal). Each motion is restarted at t = 0 and stepped with `Tween.custom_step`, so the moments are exact and repeatable.

## Validation
Godot 4.7.2 console, `--headless --path . -s` (project.godot was restored after every run):
- `tests/sb_polish_011_character_motion.gd`: LOCAL_PASS 10/10, exit 0, no SCRIPT ERROR.
- `tests/m43_c001a_results_foundation.gd`: LOCAL_PASS 11/11.
- `tests/m43_c001b_won_results_visual.gd`: LOCAL_PASS 11/11.
- `tests/m43_c004_c001_fail_need_a_hand.gd`: LOCAL_PASS 40/40.
- `tests/m43_c005f_phase2_results_pack_feel.gd`: LOCAL_PASS 22/22, exit 0. Its SCRIPT ERROR lines are the suite's own announced `EXPECTED_FAULT_INJECTION` (the base commit has them too).
- `tests/m43_c005_c005_reward_reveal_sequencer.gd`: LOCAL_PASS 12/12, run twice. On the **base commit this suite already failed 3/12** (r03 counted transient feel/ceremony tweens from r02 into its baseline). I stabilised r03 by waiting 1 s for one-shot feel tweens before the baseline and after freeing, and its tween counter now excludes the robot's CharacterMotion tween.
- `tests/m43_c001r_c001_results_momentum.gd`: FAIL 21/40. This is **pre-existing**: the sorted FAIL lines are identical on the base commit and on the branch (the production catalog now has more than 10 levels, so its L10/L11 assumptions no longer hold). Not caused by this job and not fixed here.
- Capture: `godot --path . -s res://tests/tools/character_motion_capture.gd -- <job>/evidence` exited 0 and saved 8 SNAPSHOTs.
- `git diff --cached --check`: clean.

Not run, per the usage rule: CI, phone builds, m55 (node growth is covered directly by results_no_node_growth).

Worktree note: the `.import` (LF/CRLF only) and untracked `*.uid` / owner-inbox `.import` files were Godot-generated and already present in this worktree. I did not commit them.

## Log
### Round 1
- Read CLAUDE.md, the animation analysis A1-A4 (main checkout, untracked), results_screen, acquisition_flow and the feel scripts.
- Found there is no live Level Intro screen. I implemented and tested the `ready` mode, and showed it only in a labelled harness.
- Added CharacterMotion, the offset shader and the Results / Need a Hand wiring.
- Fixed a regression I introduced: the animated robot rect delayed `_after_layout` (the WIN confetti could be skipped). The settle check and the confetti target now use the robot slot. I adjusted the m43_c005f_phase2 centring check to the slot to match.
- Stabilised m43_c005_c005 r03 (it failed on base too).
- The coordinator asked for a "READY row ... marked OWNER". I recorded it in the queue's OWNER state (`- OWNER SB-POLISH-011B`), because it waits for the owner's videos. The checklist also has `- [ ] SB-POLISH-011B`.
