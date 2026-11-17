# 160-home-scrubby-video-key (SB-HOME-VIDEO-2026-11-17)

Owner 2026-11-17 (chat): "videolulari koy" — the Home Scrubby must use the owner Flow videos
(wave / bow / turn / full_turn, still) again, on the NEW plaza Home background (job 158).

Problem: the four Home videos and home_scrubby_still.png are full 720x1280 frames with the OLD Whispering
Park background baked in (pixel-aligned to the retired home_background.png). Job 158 therefore unbound them.

## Approach
Key Scrubby out of each video and composite him over the new background, reusing the existing magenta
chroma-key pipeline (scripts/ui/feel/chroma_key_magenta.gdshader, used by win_overlay.gd /
level_intro_overlay.gd):
1. Source: the owner H.264 masters if found locally (search the owner's flow_videos folder), else the
   committed .ogv files. Never modify owner originals; work in the job folder.
2. Matte: the old background is static and pixel-aligned, so per frame build Scrubby's mask from the
   difference against the old background (old home_background.png resized to 720x1280 and/or the
   frame-0-minus-Scrubby median), cleaned (threshold, morphology, largest components, small feather;
   temporal stability), Scrubby region limited to the scrubby_safe_box area. Replace everything else
   with exact magenta #FF00FF, then re-encode libtheora (same fps/frames, -q:v high enough to avoid magenta
   bleed). Same for the still (PNG with real alpha is fine for the still).
3. Runtime: Home binds the keyed video set again (new manifest entries, sha256, owner 2026-11-17);
   WorldStill/WorldVideo draw Scrubby only, over WorldBackground (plaza), using the chroma-key material.
   Scrubby's position/scale must match where the non-video Scrubby stands now (feet on the tile floor).
   Reduced Effects / no-video fallback unchanged. Old videos/still stay byte-identical, retired.
4. Quality gate: no magenta fringe/halo, no leftover old-background pixels (arch, flowers, bench) around
   Scrubby in any frame, no flicker of the matte. Check a frame strip at 100% for all four videos.
   If a clean key is impossible for a video, say so in build.md and leave that video out rather than
   ship artefacts.
5. Tests: update m42_home_v04 (video-set retired check -> keyed set bound) and other Home video suites;
   exact PASS lines. Texture/size budget suites if touched.
6. Owner captures: GPU captures of Home EN mid-gesture (2-3 frames from different videos) at 1080x2340,
   plus a frame-strip contact sheet. Wait for any intro/animation to finish; never boot main.tscn
   without a save override.

## Must not change
Home layout/label from job 158, the plaza background, gameplay, other art.
