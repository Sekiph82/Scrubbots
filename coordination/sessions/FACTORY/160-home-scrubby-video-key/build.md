STATUS: READY

# Build: 160-home-scrubby-video-key (SB-HOME-VIDEO-2026-11-17)

## Summary
Home plays the owner Flow videos again, over the plaza background. Scrubby was keyed out of the old park and placed on exact magenta #FF00FF. At runtime `chroma_key_magenta.gdshader` keys him over WorldBackground (HOME-124). **Only wave and turn ship.** Bow and full turn are left out because no clean key was possible (see below).

Commit `4dce6eb8` on `factory/160-home-scrubby-video-key` (not pushed).

Keying (offline, job folder `key_home_videos.py`):
- **Source:** the owner H.264 masters `flow_videos/home_scrubby_{wave,turn}_master.mp4`, read only.
- **Outside Scrubby's frame-0 silhouette:** per-frame difference against the owner's clean plate `flow_reference_home_background_1080x1920.png`.
- **Inside that silhouette** (Flow repaints the background there, so the plate is wrong): a per-video colour model trained on frame 0, combined with "still looks like frame 0, within 4 px".
- **Clean-up:** hysteresis, only components touching his start pose, holes filled, narrow bites closed, a 2-of-3 temporal vote, then a 1 px erode and 0.8 px feather.
- **Encode:** libtheora `-q:v 8`, 720x1280, 24 fps, 185 frames, no audio.
- **Still:** keyed frame 0 of turn (PNG on magenta, lossless import).

Files:
- `assets/ui/final/home/videos/home_scrubby_wave_keyed.ogv` (+ `.uid`), `home_scrubby_turn_keyed.ogv` (+ `.uid`), `home_scrubby_still_keyed.png` (+ `.import`): new. The old videos and still are untouched (byte-identical, still retired).
- `assets/ui/HOME_ASSET_MANIFEST.json`: HOME-125 (keyed still) plus video set `home_scrubby_videos_keyed_v2` (wave, turn, sha256 pinned). The v1 set is unchanged.
- `scripts/ui/home/home_screen.gd`: binds `home_scrubby_videos_keyed_v2`. One chroma-key ShaderMaterial is shared by WorldStill and WorldVideo. The focus shade is off in video mode.
- `scripts/ui/home/home_presentation_map.gd`: HOME-125 STATIC on WorldStill.
- `scripts/ui/home/home_scrubby_hero.gd`: the keyed video no longer covers the still, so the still hides once the video's first frame is up and comes back when it ends. Without this the first capture showed a double Scrubby.
- Tests:
  - `m42_home_v04`: the keyed set is bound, both nodes are chroma-keyed and share the WorldBackground rect, HOME-125 is shown, HOME-121/123 stay retired, 56 pins.
  - `m42_c003_scrubby_animation`: new assertion "still hidden once the video shows its first frame (no double Scrubby)".
  - `m42_home_v05`, `m42_home_v06`, `maint_home_export_asset_gate_c001`, `m42_home`, `m42_assets`, `m42_home_composition`: counts. `m42_assets` and `m42_home_composition` were already stale after job 158 (54/8 OWNER_RETIRED); they now hold the current truth.
  - `m28_c002_c003_r01_remediation` H2: the stale filter now matches only the baked `home_scrubby_still.png`.
  - `tests/tools/home_snapshot.gd`: new `video` capture mode.

## Acceptance criteria
1. [x] **Sources:** owner H.264 masters found in `C:/Users/sekip/Desktop/ScrubBots/flow_videos/` and only read. Earlier search: no magenta or green originals of these gestures exist; the Flow guide shows they were generated on the park.
2. [x] **Matte:** difference against the park plate plus the frame-0 cues above; everything else is exact magenta; libtheora at the same fps and frame count (ffprobe: theora, 720x1280, 24/1, 185 frames each). Wave is 2.81 MB, turn 2.44 MB.
3. [x] **Runtime:** Home binds the keyed set (manifest sha256, authority owner 2026-11-17). WorldStill and WorldVideo draw Scrubby only, over the plaza, through the chroma key. Position and scale match the frame-set Scrubby: same rect as WorldBackground, verified by `m42_home_v04` "keyed still + video share the WorldBackground rect". In the captures (`home_1080x2340.png` vs `home_frame_fallback_1080x2340.png`) the feet and brush land on the same tiles. Reduced Effects and the no-video fallback are unchanged (c003 cases pass). The old videos and still are byte-identical (pins in v04/v05/v06).
4. [x] **Quality gate.** Every frame was checked at 100% (strips plus single frames), and the runtime key was also simulated over the plaza:
   - No magenta fringe after the runtime key.
   - No arch, flowers or bench remain in wave or turn.
   - Matte stability, from `check_keyed.py` on the decoded .ogv:
     - wave: alpha flips where the source pixel did not move average 391 px/frame, worst frame 1350 (frame 32, a brief transition chunk beside the head);
     - turn: average 302 px/frame, worst 1048.
     - This is mostly 1 px edge shimmer on a body of about 100k px.
   - Remaining minor flaws, visible at 100% in a few transition frames: small shards at the waving hand and brush edge during fast motion, and a slightly rough top-left head outline.
   - The pink tongue is partly keyed by the shared shader formula, the same behaviour as the existing Results videos.
   - **Left out: bow and full turn.** In bow, the dark tree pixels beside the head persist through the hold, and loose helper-bot and brush fragments appear. In full turn, the back view keeps old floor patches under the feet and holes in the backpack and head. See the contact sheets `contact_sheet_bow_rejected.png` and `contact_sheet_full_turn_rejected.png`.
5. [x] **Tests:** `m42_home_v04` updated from the retired check to the keyed set bound; the other Home video suites updated. Exact PASS lines are under Validation.
6. [x] **Owner captures** (GPU, 1080x2340, EN, isolated temp save, `home_snapshot.gd ... 1080x2340 video`), all in `C:/Users/sekip/Desktop/ScrubBots/factory/jobs/160-home-scrubby-video-key/captures/`:
   - `home_1080x2340.png`: idle still
   - `home_video_wave_1.6s_1080x2340.png`, `home_video_wave_3.0s_1080x2340.png`
   - `home_video_turn_1.6s_1080x2340.png`, `home_video_turn_3.0s_1080x2340.png`
   - `home_frame_fallback_1080x2340.png`: frame-set Scrubby, for the position comparison
   - Frame-strip contact sheets (every 12th frame plus the last, 50%) in the job folder: `contact_sheet_wave.png`, `contact_sheet_turn.png`, `contact_sheet_bow_rejected.png`, `contact_sheet_full_turn_rejected.png`.

## Validation
Godot 4.7.2 headless, worktree, LOCAL_PASS. Each suite exited 0 with no SCRIPT ERROR or Parse Error, and its last line is:
- `m42_home_v04: 18/18 cases, 0 failures`
- `m42_home_v05: 13/13 cases, 0 failures`
- `m42_home_v06: 13/13 cases, 0 failures`
- `M42 home evidence: PASS`
- `m42_home_composition: 9/9 cases, 0 failures`
- `M42 assets evidence: PASS`
- `maint_home_export_asset_gate_c001: 11/11 cases, 0 failures`
- `m42_c003_scrubby_animation: 25/25 cases, 0 failures`
- `m42_c002_scrubby_scale: 7/7 cases, 0 failures`
- `M42 navigation evidence: PASS`
- `M43 master C011-C014 evidence: PASS (29/29 cases, 0 fail)`
- `M22-026 TEXTURE BUDGET: PASS`
- `M28-C002-C003-R01 five-finding remediation: PASS (24/24 cases, 0 fail)`

`m42_navigation`, `m43_master_c011_c014`, `m42_c002_scrubby_scale` and `m22_026_texture_budget` ran before the final hero.gd still-hide edit. The Home suites and c003 were re-run after it.

Other checks:
- `git diff --check` is clean.
- project.godot and the unrelated `.import` churn from `--import` were restored with `git checkout -- <files>`. The generated untracked `.uid`, `.import` and `.translation` files were deleted by explicit path. No stash and no clean were used.
- `git status --porcelain` is empty.
- TASKS.md was not edited (orchestrator instruction).

## Log
### Round 1
- First pass (BLOCKED): following the orchestrator's correction, I searched for magenta or green originals of the Home gestures. None exist; the masters and the raw Flow download all have the park background.
- Owner decision 2026-11-17 ("parkli videolardan scrubbyi ayirmaya calis"): build the difference matte. Iterations:
  1. A plain plate difference left the background Flow repaints inside Scrubby's start silhouette.
  2. A loose threshold there ate the white head over the white clouds.
  3. Final approach: a per-video colour model plus a frame-0 sameness cue (shift-tolerant), colour- and core-aware hole filling, and closing of bites.
- Wave and turn pass the 100% review; bow and full turn were rejected.
- The first GPU capture showed a double Scrubby (the keyed still was visible under the keyed video). Fixed in home_scrubby_hero.gd and covered by a c003 assertion.
- One commit (`4dce6eb8`), not pushed.
