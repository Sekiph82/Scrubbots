# 166-home-scrubby-magenta-videos (SB-HOME-VIDEO-MAGENTA-2026-11-17)

Owner 2026-11-17 (chat): "videolari attim flow videos dosyasina. incele, kesilmesi gereken yerlerden kesip
uygulamaya yerlestir."

Sources (owner originals, read-only; never modify): C:/Users/sekip/Desktop/ScrubBots/flow_videos/
- home_scrubby_bow_magenta.mp4, home_scrubby_full_turn_magenta.mp4, home_scrubby_sweep_magenta.mp4
  (720x1280, 24 fps, 190 frames, 7.93 s). Generated in Flow with first = last frame
  flow_start_frame_home_scrubby_magenta_1080x1920.png (Scrubby at the exact Home pose on #FF00FF), prompts in
  FLOW_HOME_SCRUBBY_MAGENTA_3_VIDEO.md.

## Do
1. Inspect each video (frame strips): background flat magenta in all frames? one brush only? on-model? Flow often
   adds a fade/garbage at the very end or the pose drifts. Find the trim: start at frame 0, end at the frame that
   best matches frame 0 (loop point, like the old masters trimmed at frame 184 == frame 0). Cut obvious bad frames.
   Report anything that makes a video unusable instead of shipping it.
2. Normalise the background to exact magenta where Flow drifted (only pixels clearly background), re-encode
   libtheora like the existing keyed set (same fps, -q:v high enough to avoid magenta bleed), no audio.
3. Add them to the keyed Home video set next to wave + turn (job 160: home_scrubby_videos_keyed_v2, chroma_key_magenta
   shader), manifest entries with sha256, owner 2026-11-17. Same position/scale as the keyed still: verify
   frame 0 overlays the keyed still within a few px.
4. Tests: update Home video suites (counts, set contents), exact PASS lines.
5. Owner evidence: per-video frame-strip contact sheet (before/after trim), and GPU Home captures mid-gesture
   for each of the 3 (wait for the gesture timing; no main.tscn without a save override).

## Coordination
Job 165 (asset purge) is deleting the OLD park videos/still and editing HOME_ASSET_MANIFEST.json in parallel.
Do not delete anything; only add the new entries. Keep the manifest edit small and localised.
