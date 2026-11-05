STATUS: READY

# Build: SB-VIDEO-001/002 WIN and LOSE result Scrubby videos (magenta chroma key) + video program rows in TASKS

## Acceptance criteria (written by the builder; no spec-writer for this job)
1. TASKS.md has a new `## Owner Video Program 2026-11-05` section listing SB-VIDEO-001..010, with a note that the owner DROPPED the Home small background robot videos. Matching Autonomous Queue rows sit right after the SB-POLISH rows, in order: 001/002 DONE, 003..010 OWNER. CRLF is kept.
2. Assets: each owner master is cropped to the robot's bounding box over all frames plus a margin and encoded as Theora .ogv with the magenta kept, in `assets/ui/final/popups/videos/`. Frame 0 is written as a PNG still keyed to transparent at build time. Provenance is recorded (owner Flow, Veo 3.1 Lite, trimmed at frame 184).
3. A canvas_item chroma-key shader keys magenta to alpha with a soft edge and removes the pink spill. It clamps R and B toward G only where the pixel is magenta-ish, so teal and cyan stay accurate (no blue-only despill).
4. Results WON with Scrubby plays the keyed WIN video once in the robot slot. LOST with Scrubby plays the LOSE video once. When the video ends, the keyed still (frame 0 = last frame) is held.
5. Fallbacks: other robots keep the approved pose + CharacterMotion tween. A video that fails to load or play also keeps the pose + tween. Reduced Effects shows the keyed still only.
6. Only one decoder exists. It is stopped and freed when Results hides (and when a video finishes or Results re-shows). Buttons stay usable. The robot slot rect does not change size (keeps the factory-091 confetti/layout-settle fix).
7. Evidence: 2 stills each for WIN and LOSE at 1080x2160 over the real Results panel, using the rendering driver, with clean keying edges and no pink fringe.
8. Tests extend `tests/sb_polish_011_character_motion.gd`. That suite and m43_c001a pass. No CI, no phone builds, project.godot restored.

## Summary
Branch `factory/093-video-win-lose`, commits `93a02ced` (code/assets/tests) and `f41d94cf` (TASKS.md).

On WON or LOST, when the robot is Scrubby (`robot_id` empty or `"scrubby"`), the Results robot slot now plays the owner's Flow video once. A VideoStreamPlayer inside an AspectRatioContainer is added as a child of the robot TextureRect, with the chroma-key material on it. The robot's own pixels are hidden with `self_modulate` while it plays. When it finishes, the player is freed and the keyed still that was already bound to the TextureRect shows. Reduced Effects and a re-show of the same terminal show only the keyed still. Other robots, or a video that fails, go through the unchanged CharacterMotion path. `_stop_video()` is called from `_stop_feel()`, so every re-show and every hide frees the decoder.

Files:
- `scripts/ui/results_screen.gd`: `_show_scrubby_video`, `_start_video`, `_on_video_finished`, `_stop_video`, `get_result_video`, and new constants.
- `scripts/ui/feel/chroma_key_magenta.gdshader` (+ .uid): `m = min(R,B) - G`. R and B are each lowered by `max(m,0)`, so teal, cyan, blue and green (R < G or B < G) are never touched. Alpha is `1 - smoothstep(0.15, 0.45, m)`.
- `tools/build_result_scrubby_videos.py`: crops to the bbox + 16 px (sides rounded up to multiples of 16), encodes Theora q8 yuv420p with no audio, keys the frame-0 still with the same formula, and writes PROVENANCE.md.
- `assets/ui/final/popups/videos/`: `result_scrubby_win.ogv` (560x864, 3.36 MB), `result_scrubby_lose.ogv` (512x624, 2.06 MB), `result_scrubby_{win,lose}_still.png` (+ .import/.uid), PROVENANCE.md with the master/output SHA-256s and the exact ffmpeg command.
- `tests/sb_polish_011_character_motion.gd`: 6 new cases. The old CharacterMotion Results cases now use `robot_id: "spark"`, because Scrubby now takes the video path.
- `tests/tools/result_video_capture.gd`: the evidence capture.
- `TASKS.md`: video program section + 10 queue rows.

## Acceptance criteria
1. [x] TASKS: `git diff` showed +23 lines only. That is 10 queue rows directly after `- DONE SB-POLISH-012`, and the new section before `## Project Status` with the "Home small background robot videos are DROPPED" note. CRLF was kept (edited with `newline=''`).
2. [x] Assets: the build script printed crop win (87,278,560,864) and lose (126,304,512,624). The bbox was taken over all 185 frames, where foreground means `min(R,B)-G <= 80`. Provenance is in `assets/ui/final/popups/videos/PROVENANCE.md`. Both masters were read-only input; `flow_videos/` was not committed.
3. [x] Shader: see Summary. Teal (R < G) is untouched by construction. Visually, in `evidence/robot_edges_zoom.png` the teal/cyan rims and screen glow look the same as in the master.
4. [x] Test `video_scrubby_win_lose`:
   - "Scrubby WON: keyed WIN video playing": the stream is WIN_VIDEO and the material shader is CHROMA_KEY.
   - "still bound under the video, no tween".
   - "Scrubby LOST: keyed LOSE video playing".
   - `video_finish_holds_still`: "video finished: decoder freed, keyed LOSE still held".
5. [x] Fallbacks:
   - `video_other_robot`: spark gets the victory/robots pose + CharacterMotion and no video.
   - `video_fail_fallback`: `_start_video(null)` and a VideoStreamTheora pointing at a missing file are both refused and leave no decoder. `_show_scrubby_video` then returns false and show_model runs CharacterMotion.
   - `video_reduced_still`: the keyed still only, no decoder, no tween.
6. [x] One decoder, freed, rect unchanged:
   - "one decoder, ignores input, CLEAN NEXT live".
   - "LOST after WON: still one decoder, robot slot rect unchanged (880x340)".
   - `video_freed_on_hide`: "hidden Results: decoder stopped and freed", plus "re-show of the same terminal: still only, the video is not replayed".
   - Existing `results_input_live` and `results_no_node_growth` still PASS.
7. [x] Evidence is in `factory/jobs/093-video-win-lose/evidence/`: `results_win_0_1080x2160.png` (t=1.67 s), `results_win_1_1080x2160.png` (t=4.27 s), `results_lose_0_1080x2160.png` (t=1.61 s), `results_lose_1_1080x2160.png` (t=4.21 s), and a 1.5x crop `robot_edges_zoom.png`.
   - They were made with `godot --path . --rendering-driver opengl3 -s res://tests/tools/result_video_capture.gd -- <dir>`: the real ResultsScreen in a 1080x2160 SubViewport over BG01, with no main.tscn boot. The video was playing in every shot.
   - Pixel check on the robot region: 0 magenta-ish pixels (`min(R,B)-G > 40`) in the WIN shots, and 19 in each LOSE shot. Those 19 are the faint lavender rim of the glowing "?" (cyan glow blended into magenta in the source). The body edges have no pink fringe.
8. [x] See Validation.

## Validation
- `godot --headless --path . -s res://tests/sb_polish_011_character_motion.gd`: LOCAL_PASS, exit 0, `SB-POLISH-011 character motion: PASS (16/16 cases, 0 fail)`, no SCRIPT ERROR/Parse Error. One expected engine `ERROR: Cannot open file 'res://tests/__missing_video__.ogv'` comes from the deliberate bad-stream case.
- `godot --headless --path . -s res://tests/m43_c001a_results_foundation.gd`: LOCAL_PASS, exit 0, `PASS (11/11 cases, 0 fail)`, no SCRIPT ERROR/Parse Error. "30 resources still in use at exit" also appears with HEAD's results_screen.gd (checked), so this change did not introduce it.
- `git diff --check` on the changed scripts: clean.
- project.godot: Godot's `--import` rewrote it, and it was restored with `git checkout -- project.godot`. The untracked .import/.uid files the import generated were deleted.
- Tree: the only remaining `git status` entries are 250 `.import` files that are EOL-only noise (`i/lf w/lf`, `git diff --ignore-cr-at-eol` is empty). They were there before this job started, and the owner checkout has the same noise. They are not touched or staged.
- No CI, no phone builds, no push (as instructed).

## Log
### Round 1
- Built the assets from the trimmed masters, the shader, the Results video path with fallbacks, 6 new test cases, and the capture tool, and added the TASKS video program.
- Design choice: Reduced Effects shows the keyed video still, not the old pose. A failed video and non-Scrubby robots use the old pose + tween.
- Known ceiling: the "?" glow in LOSE keeps a faint lavender halo. Despill only clamps R/B toward G, so a cyan glow mixed into magenta cannot be recovered without touching teal.
- SB-POLISH-011B (OWNER row) was left unchanged. WIN/LOSE are now covered by SB-VIDEO-001/002; Need a Hand / Level Intro still use tweens.
