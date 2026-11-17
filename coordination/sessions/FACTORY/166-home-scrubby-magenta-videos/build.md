STATUS: READY

# Build: Home Scrubby magenta videos (SB-HOME-VIDEO-MAGENTA-2026-11-17)

## Summary
The keyed Home video set `home_scrubby_videos_keyed_v2` now holds five gestures: wave and turn from job 160, plus bow, full_turn and sweep made from the owner's magenta Flow videos. Home already picks a random video from this set, so no runtime code changed. Commit `d227fba8` on `factory/166-home-scrubby-magenta-videos` (not pushed).

Files changed:
- `assets/ui/final/home/videos/home_scrubby_{bow,full_turn,sweep}_keyed.ogv` (+ `.uid`)
- `assets/ui/HOME_ASSET_MANIFEST.json`: three entries added to the keyed set, each with a sha256, plus one provenance sentence. Nothing was deleted (job 165 coordination).
- `tests/m42_home_v04.gd`: `KEYED_GESTURES` is now the five gestures, plus a new check that all five keyed videos match their sha256 pins and bind as Theora streams.

Job-folder tooling: `make_videos.py` (trim, normalise, encode), `analyze.py` (per-frame diff against frame 0 and background drift), `check_overlay.py` (frame 0 against the keyed still).

## Acceptance criteria
1. [x] **Inspect each video.** I looked at frame strips of all 190 frames (`evidence/strip_*_before.png`) and at close-up crops of each gesture section.
   - The background is flat magenta throughout, with no floor, shadow or extra objects. It does drift in colour: sweep goes from about (248,1,251) to (241,23,228) during frames 30–160, and bow and full_turn drift less.
   - Each video has only one brush and stays on-model.
   - The loop point is frame 184 in all three. Its full-frame mean |diff| against frame 0 is 7.9, 7.6 and 6.8, while frames 185–189 drift away again (12–30). This matches the old masters.
   - Kept frames 0..184 (185 frames, 7.71 s) and dropped 185..189. Nothing makes a video unusable. One minor point: bow is more of a hunch with the hands at the chest than a deep bow, and the brush is partly hidden during the hold, but it is still on-model.
2. [x] **Background normalised and re-encoded.** Pixels with magenta-ness `min(R,B)-G > 100` are set to exact #FF00FF. The shader already keys these fully, so only background changes; Scrubby and his soft edge are untouched. Encoded with libtheora `-q:v 8` (same as wave/turn), 24 fps, no audio. Sizes are 2.96, 3.47 and 2.72 MB. After normalisation, frame 184 against frame 0 has a mean diff of 2.7–2.8.
3. [x] **Added to the keyed set and aligned with the still.** The manifest entries carry sha256 values and the owner 2026-11-17 authority. Frame 0's Scrubby mask overlays HOME-125 (`home_scrubby_still_keyed.png`) with IoU 0.984 / 0.984 / 0.986, and the best shift is dx=0, dy=0 for all three (`check_overlay.py`). The bounding boxes match the still within 1–2 px.
4. [x] **Tests.** `m42_home_v04` checks the set contents (`["wave","turn","bow","full_turn","sweep"]`) and that all five pins and Theora streams are correct.
   - `ok: keyed video set bound (["wave", "turn", "bow", "full_turn", "sweep"]), still + player chroma-keyed, shade + frame Scrubby off`
   - `ok: all 5 keyed videos pinned (sha256 == bytes) and bound as Theora streams`
   - No asset counts changed: these are video_set entries, not ART assets.
5. [x] **Owner evidence.**
   - Before/after frame strips: `evidence/strip_{bow,full_turn,sweep}_{before,after}.png`.
   - GPU Home captures: `captures/home_video_{g}_{1.6,3.0}s_1080x2160.png` for all five gestures. These came from `tests/tools/home_snapshot.gd ... 1080x2160 video`, a temp-save AppState, not main.tscn.
   - Combined sheet: `evidence/home_captures_new3_sheet.png`.
   - In the captures the key is clean (no magenta halo) and Scrubby stands where the still stands.

## Validation
- Godot 4.7.2 `--headless --import` run once in the fresh worktree. Afterwards I restored `project.godot` and every import-churn file, and removed the generated untracked `.uid`/`.import`/`.translation` files. I did not use stash or clean.
- Suites run with `$GODOT --headless --path . -s res://tests/<suite>.gd`. All were LOCAL_PASS: exit 0, no SCRIPT ERROR or Parse Error, and the last line says PASS. Logs are in `work/`.
  - m42_home_v04 18/18
  - m42_c003_scrubby_animation 25/25
  - m42_assets PASS
  - m42_home PASS
  - m42_home_composition 9/9
  - m42_home_v05 13/13
  - m42_home_v06 13/13
  - maint_home_export_asset_gate_c001 11/11
  - m28_c002_c003_r01_remediation 24/24
- `git diff --check` was clean on the changed text files.
- `git status --porcelain` is empty.
- TASKS.md was not edited, as the caller instructed.

## Log
### Round 1
- Inspected the three owner magenta videos and found the trim (0..184).
- Normalised the background, encoded with Theora and added the three videos to `home_scrubby_videos_keyed_v2`.
- Extended m42_home_v04, ran nine Home suites (all LOCAL_PASS) and made GPU captures plus contact sheets.
- One commit (`d227fba8`), not pushed.
