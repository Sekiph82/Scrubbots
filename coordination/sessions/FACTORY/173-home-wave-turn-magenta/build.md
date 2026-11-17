STATUS: READY

# Build: Home wave/turn from the owner magenta videos (SB-HOME-VIDEO-MAGENTA-2-2026-11-17)

## Summary
In the keyed Home set `home_scrubby_videos_keyed_v2`, wave and turn are now made from the owner's magenta Flow videos (`flow_videos/home_scrubby_{wave,turn}_magenta.mp4`, read-only). They replace the job-160 difference-matte versions. Commit `5b13fa0f` on `factory/173-home-wave-turn-magenta` (not pushed). No runtime code changed.

The new videos keep the same paths and `.uid`s. The job-160 bytes are overwritten in the tree and are not archived anywhere, which matches the owner's "delete, don't archive". Because the paths did not change, there was no separate `git rm`.

Files changed:
- `assets/ui/final/home/videos/home_scrubby_{wave,turn}_keyed.ogv`: replaced.
- `assets/ui/HOME_ASSET_MANIFEST.json`: the wave/turn sha256 pins and one provenance sentence.
- `tests/m42_home_v04.gd`: `OLD_MATTE_SHAS` plus a check that the wave/turn pins are not the job-160 difference mattes.

I reused job 166's tooling unchanged: `make_videos.py`, `analyze.py` and `check_overlay.py`.

## Acceptance criteria
1. [x] **Trim to the frame that best matches frame 0.** I ran `analyze.py` on both videos, which have 190 frames each.
   - wave: frame 184 is the minimum (mean |diff| 7.31; 183 = 14.15, 185 = 11.18).
   - turn: frame 184 is the minimum (6.36; 183 = 42.96, 185 = 11.46).
   - Kept frames 0..184 (185 frames). After normalisation, frame 184 against frame 0 is 2.57 for wave and 2.67 for turn.
2. [x] **Background snapped to #FF00FF and re-encoded.** Pixels with `min(R,B)-G > 100` were set to exact magenta. Turn's background drifts as far as (239,33,216), and those pixels were snapped too. Encoded with libtheora `-q:v 8`, 24 fps, no audio. Sizes are 3.58 MB (wave) and 3.37 MB (turn).
3. [x] **Frame 0 aligned with the keyed still.** `check_overlay.py` gives IoU 0.986 for wave and 0.985 for turn, with the best shift at dx=0, dy=0 for both. Both bounding boxes are 156,476-565,953.
4. [x] **Manifest updated.** The new sha256 values are wave `77d497c5…182fd6` and turn `7e0d4656…3bae21`. The provenance names this job.
5. [x] **Tests.**
   - m42_home_v04 18/18. It prints `ok: all 5 keyed videos pinned (sha256 == bytes) and bound as Theora streams` and `ok: wave/turn are the magenta Flow re-encodes, not the job-160 difference mattes`.
   - m42_c003_scrubby_animation 25/25. It reads the pins from the manifest, so it needed no edit.
6. [x] **Evidence** is in this job folder.
   - Frame strips before and after: `evidence/strip_{wave,turn}_{before,after}.png`.
   - First frames: `evidence/{wave,turn}_f0.png`.
   - GPU Home captures mid-gesture: `captures/home_video_{wave,turn}_{1.6,3.0}s_1080x2160.png`. They were made with `tests/tools/home_snapshot.gd -- captures 1080x2160 video`, which uses a temp-save AppState, not main.tscn.
   - Combined sheet: `evidence/home_captures_wave_turn_sheet.png`. The key is clean with no magenta halo. In the wave video Scrubby holds a round brush; in the turn video he holds the broom. The owner approved both videos.

## Validation
- I ran a one-off Godot 4.7.2 `--headless --import` (exit 0). Afterwards I reverted the import churn and the CRLF phantoms with `git checkout` and removed the untracked generated files. I did not use stash or clean.
- Each suite was run with `$GODOT --headless --path . -s res://tests/<suite>.gd`. All are LOCAL_PASS: exit 0, no SCRIPT ERROR or Parse Error, and the final summary line says PASS / 0 failures. Logs are in `work/`.
  - m42_home_v04 18/18
  - m42_c003_scrubby_animation 25/25
  - m42_assets PASS
  - m42_home PASS
  - m42_home_composition 9/9
  - m42_home_v05 13/13
  - m42_home_v06 13/13
  - maint_home_export_asset_gate_c001 11/11
  - m28_c002_c003_r01_remediation 24/24
- `git diff --check` was clean.
- `git status --porcelain` is empty.
- TASKS.md was not edited, as the caller instructed.

## Log
### Round 1
- Analysed the loop point of both videos and ran job 166's pipeline on wave and turn.
- Replaced the keyed .ogv files and updated the manifest pins and provenance.
- Added a regression check to m42_home_v04.
- Ran nine Home suites (all LOCAL_PASS) and made GPU captures.
- One commit (`5b13fa0f`), not pushed.
