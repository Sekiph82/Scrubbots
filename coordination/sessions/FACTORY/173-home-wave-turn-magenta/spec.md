# 173-home-wave-turn-magenta (SB-HOME-VIDEO-MAGENTA-2-2026-11-17)
Owner 2026-11-17: "ikisi de ok. bunlari kullan eski temizledigin videolarin yerine."
New owner Flow videos on magenta (owner-approved, read-only):
- flow_videos/home_scrubby_wave_magenta.mp4 (copy of Downloads/Robot_Scrubby_waving_hello_518379f9.mp4)
- flow_videos/home_scrubby_turn_magenta.mp4 (copy of Downloads/Robot_character_animation_on_bac..._03bba444.mp4)
Do exactly what job 166 did for bow/full_turn/sweep (factory/jobs/166-home-scrubby-magenta-videos: make_videos.py,
trim to the frame best matching frame 0, snap clearly-background pixels to #FF00FF, libtheora -q:v 8, 24 fps, no audio,
verify frame-0 alignment with the keyed still), then REPLACE the difference-matte keyed wave/turn (job 160) in the
keyed set home_scrubby_videos_keyed_v2 with these. git rm the old job-160 keyed wave/turn .ogv files (owner: delete,
don't archive). Manifest sha256 entries updated; m42_home_v04 / m42_c003 updated; exact PASS lines for the Home suites.
Evidence: before/after frame strips + Home captures mid-gesture for both.
