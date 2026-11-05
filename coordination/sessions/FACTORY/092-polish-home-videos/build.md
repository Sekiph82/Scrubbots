STATUS: READY

# Build: SB-POLISH-009 Home Scrubby gestures as owner Flow videos

## Acceptance criteria (written by the builder; no spec-writer for this job)
1. The 4 owner videos are re-encoded from the trimmed masters to Theora .ogv at 720x1280, 24 fps, about 3-4 MB each, in assets/ui/final/home/videos/.
2. The still is frame 0 of one video. The frame 0s of all 4 match (mean diff about 5/255 or less).
3. Provenance is in ASSET_GENERATION_MANIFEST.json and HOME_ASSET_MANIFEST.json: owner Flow videos, Veo 3.1 Lite, trimmed at frame 184 (matches frame 0), no art changes.
4. On World 01 Home the background layer shows the still, which replaces the background and the separate Scrubby art. Still and video use the same crop/scale rect as the background on every aspect ratio. The HUD, buttons and nav stay native on top.
5. Scheduler: 5-6 s hold, then one random video, never the same one twice in a row. Each video ends back on the still and the hold starts again.
6. The video stops when Home is hidden, a modal is open or the app is backgrounded (focus out or paused). Reduced Effects shows the still only. There is never more than one video decoder. A failed play keeps the still.
7. The old frame assets stay as the fallback.
8. The hero suite covers the scheduler, the pause gates and Reduced Effects. The Home suites pass locally.
9. The APK size delta is noted. TASKS.md has SB-POLISH-009 set to DONE.

## Summary
World 01 Home now plays the owner's 4 Flow videos (wave, bow, turn, full_turn). `HomeScreen` adds `WorldStill` (TextureRect) and `WorldVideo` (one VideoStreamPlayer) to the `Background` layer, above `WorldBackground` and below `Layer_characters`/UI. Both get the exact `WorldBackground` rect, so they follow the existing crop and scale rules.

`HomeScrubbyHero` gets a video mode. It takes precedence over the frame set when the binder serves an approved `video_sets` entry. In video mode:
- HOME-026 (`Art_scrubby`) is faded out with self_modulate 0, so node rects are unchanged and the old tests still see them. The HeroFocusShade is hidden because it would dim the baked Scrubby.
- The scheduler holds a uniform 5..6 s, then picks uniformly among the clips, excluding the last one.
- `start_gesture` assigns the stream, shows the player and plays. If the player is not playing or the stream length is 0, it ends, the still stays, and the next attempt waits a full 5-6 s hold (no per-frame retry).
- The `finished` signal ends the clip. A 9 s watchdog is a safety net in case it never fires. Ending stops the player, sets the stream to null and hides the player.
- Hidden, modal, focus-out, paused and Reduced Effects all end the clip right away (the reused `motion_allowed`/`can_start_gesture` gates). Each gate gets a fresh 5-6 s hold when it reopens.

The frame-swap system is untouched and is the fallback whenever the video set does not bind.

Asset gate: `HOME_ASSET_MANIFEST.json` gains HOME-123 `home_scrubby_video_still` (ART, sha-pinned, presentation-map row STATIC -> `WorldStill`) and a `video_sets.home_scrubby_videos_v1` block (4 sha-pinned .ogv). The validator gains `_validate_video_sets`: an .ogv under final/, a pin, and the strict/packaged integrity rule. The binder gains `video_set(id)`.

Files changed:
- assets/ui/final/home/videos/home_scrubby_{wave,bow,turn,full_turn}.ogv (+ .uid), home_scrubby_still.png (+ .import)
- ASSET_GENERATION_MANIFEST.json, assets/ui/HOME_ASSET_MANIFEST.json
- scripts/ui/home/home_scrubby_hero.gd, scripts/ui/home/home_screen.gd, scripts/ui/home/home_art_binder.gd, scripts/ui/home/home_presentation_map.gd, scripts/tools/home_asset_manifest_validator.gd
- tests/m42_c003_scrubby_animation.gd (7 new video cases; the frame cases now force the frame fallback through `_home(video=false)`)
- tests/m42_home.gd, m42_home_composition.gd, m42_home_v04.gd, m42_home_v05.gd, m42_home_v06.gd, maint_home_export_asset_gate_c001.gd: the manifest entry counts went from 53 to 54 and the STATIC/active counts from 25 to 26 (HOME-123).
- TASKS.md

Commits: 0914b4dd (code, assets, tests), 4e803898 (TASKS.md), b288419f (round 2: failed-play retry fix + bounded-attempt test).

## Acceptance criteria
1. [x] Re-encode: `ffmpeg -i home_scrubby_<g>_master.mp4 -an -c:v libtheora -q:v 4`. The ffprobe count shows 720x1280, 24/1 and 185 frames for all 4. Sizes: wave 3,315,021, bow 3,364,758, turn 3,250,678, full_turn 3,449,361 bytes. PSNR against the master is 32.9-33.0 dB. The suite checks this too: "re-encoded clips ~3-4 MB each".
2. [x] Frame 0 of the 4 masters, raw mean abs diff pairwise: 5.07-5.46/255. That is codec grain: after a 3 px Gaussian blur it is 1.65-1.89/255. The still is frame 0 of the turn master (lowest average diff), extracted losslessly to PNG. Runtime clips against the still, blurred: frame 0 is 1.6-2.5/255 and frame 184 is 2.4-2.9/255, so no visible jump at start or end. Raw diffs of 6.8-9.1 come from Theora q4 noise.
3. [x] ASSET_GENERATION_MANIFEST `canonical_references.home_scrubby_videos_v1` holds the paths, the provider google_flow_veo_3_1_lite, the trimmed-at-184 note, the master sha256s and "No art changes". HOME_ASSET_MANIFEST has HOME-123 plus `video_sets` with the provenance and pins.
4. [x] Suite case `video_mode_layout` on 1080x2160, 1080x1920, 1290x2796 and 1536x2048: the still is bound and shown, `WorldStill`/`WorldVideo` rects equal the `WorldBackground` rect, the order is WorldBackground < WorldStill < WorldVideo < Layer_characters, Art_scrubby alpha is 0, the shade is hidden and both nodes are MOUSE_FILTER_IGNORE. The existing `buttons_usable` and m42_home suites pass (native UI on top).
5. [x] Case `video_scheduler`: 1 h deterministic run. 248 videos, 0 immediate repeats, holds 5.02..6.00 s, picks wave 56 / bow 62 / turn 61 / full_turn 69 (about uniform). Every start has the picked stream on WorldVideo and playing. Every end has the player hidden and the stream released. A second start is refused while one runs. Case `video_real_playback`: real Theora decode in headless. The decoder produced 720x1280 frames, `finished` fired after 7704 ms, then the still came back with the stream released and a 5.66 s hold.
6. [x] Case `video_gates`: modal (settings) and the DAILY popup, Home hidden, FOCUS_OUT and APPLICATION_PAUSED each stop a running video (gesture "", hidden, stream null, not playing, still visible). Nothing starts for 40 s, and the gate reopens with a fresh 5-6 s hold. Case `video_reduced`: live ON stops the video and shows the still only, 60 s with no video and starts refused; OFF resumes within one hold. One decoder: `exactly one VideoStreamPlayer in Home`, and the stream is set to null on every end. Case `video_play_failure`: with an unreadable stream, start is refused and the still is kept for 30 s with nothing counted. Round 2: only 6 failed attempts in those 30 s (asserted 2..7, one per hold, never per frame). The `Cannot open file` engine ERROR lines in that log come from this deliberate fault.
7. [x] The frame assets and `home_scrubby_gestures_v03` are unchanged. The 18 original frame cases pass on the forced fallback, and `static_fallback` still passes.
8. [x] See Validation.
9. [x] APK delta estimate: +14.5 MB deflated (4 ogv files at 13.38 MB raw, barely compressible, plus the still .ctex at 1.21 MB). The frames are kept, so nothing is removed. No APK was built (per the job instructions). TASKS.md queue row and checklist line are set to DONE with the evidence.

## Validation
Godot 4.7.2 console, headless, from the worktree. All results are LOCAL_PASS (exit 0, no SCRIPT ERROR or Parse Error, last line PASS or 0 failures):
- `-s res://tests/m42_c003_scrubby_animation.gd`: 25/25 cases, 0 failures (217 ok lines)
- m42_home: PASS
- m42_home_composition: 9/9, 0 failures
- m42_home_v04: 18/18, 0 failures
- m42_home_v05: 13/13, 0 failures
- m42_home_v06: 13/13, 0 failures
- m42_home_v07_safe_area: 9/9, 0 failures
- maint_home_export_asset_gate_c001: 11/11, 0 failures (packaged mode resolves the .ogv)
- m22_026_texture_budget: PASS
- m43_c005f_phase1_foundation: PASS, 23/23. Its one SCRIPT ERROR is the suite's labelled EXPECTED_FAULT_INJECTION and was there before.
- m43_master_c005f_feel: PASS, 10/10
- `git diff --check` on the changed scripts, tests and manifests: clean.

No CI and no phone build, per the job instructions. The "ObjectDB instances leaked at exit" warning appears in every existing suite log and is not new. Godot rewrote project.godot during the runs; I restored it with `git checkout -- project.godot`.

Worktree note: before this job started, the worktree already had Godot reimport noise: modified `*.import` and untracked `*.uid`/`*.import` files across the repo. I left it alone and staged only explicit paths. `git status --porcelain` therefore still lists that pre-existing noise, but no changes from this job.

## Log
### Round 1
- Probed the masters: 720x1280, 24 fps, 185 frames, no audio. Compared frame 0 and frame 184 of all 4 (structurally identical, about 1.8/255 blurred). Picked the turn frame 0 as the still.
- Encoded at Theora q4 (q5 gave 4.2 MB and q6 5.3 MB), about 3.3 MB each.
- Built the video mode in HomeScrubbyHero and the WorldStill/WorldVideo nodes in HomeScreen, and added the video_sets manifest gate (validator and binder).
- Decision: the HeroFocusShade is hidden in video mode, because it would darken the Scrubby baked into the video. Edge mirrors for tablets still use HOME-121; they sit outside the world rect and do not overlap.
- Found that VideoStreamPlayer reports `is_playing() == true` for an unreadable file, so the failure check also requires `get_stream_length() > 0`.
- Updated the hardcoded manifest counts in 6 Home suites for HOME-123.

### Round 2
- Review finding 1 (a failed play retried every frame because `_wait` stayed at or below 0): the failure branch of `start_gesture` now sets `_wait = _next_interval()` and counts the failure in a new `_failed` counter, exposed as `get_state()["failed"]`. Commit b288419f.
- The `video_play_failure` test now asserts a bounded attempt count: 6 failed attempts in 30 s (asserted 2..7). The deliberate "Cannot open file" engine ERROR now appears 6 times in the log instead of once per frame.
- Re-ran only `tests/m42_c003_scrubby_animation.gd` as instructed: exit 0, 25/25 cases, 0 failures, no SCRIPT ERROR or Parse Error (LOCAL_PASS). Restored project.godot afterwards.
