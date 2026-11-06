# Review round 1: 108 video region + need a hand

Checks:
- git diff --check: clean.
- sb_video_009_polish_011b_region_need_a_hand_video: PASS 7/7.
- sb_polish_011_character_motion: PASS 16/16.
- m43_c004_c001_fail_need_a_hand: PASS 40/40.
- project.godot restored (no tracked changes).

Findings:
- Decoder: play_hero_video frees the box on a failed start; finish and p.closed free it on every other path. The region overlay is removed and freed when no video box was added. Need a Hand falls back to the CharacterMotion tween only when the hero has no children, so the tween and the video never both play.
- No world trigger was invented. The video is wired only into world_unlock, FULL mode only. Reduced, other robots and failures keep the old paths (tested).
- Buttons stay usable (mouse ignored on the video), nothing is granted, and the diff is presentation only.
- Need a Hand layout: both stills show the 180x160 helper fitting beside the hint box with no overflow.
- Trim 0-181 is documented in PROVENANCE.md and in the build tool (TRIM). The 190-frame new_region clip has no trim, and its sparkle edge cut is noted in build.md.

Non-blocking: the region video is 2.5 MB and the NAH video 1.5 MB (acceptable, same as the earlier videos).

VERDICT: PASS
