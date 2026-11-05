# Review round 1, job 104 (SB-VIDEO-007 + 008)

## Checks
- git diff --check (a77a7074~1..09673bdf): clean.
- sb_video_007_008_set_complete_welcome_video: PASS 8/8 (re-run by reviewer).
- sb_video_006_gift_meter_video: PASS 6/6 (099 gift behaviour intact after the refactor).
- m43_master_c005_meta_ceremonies: PASS 32/32.
- No tracked file modified after the runs (only untracked import noise).

## Findings on the requested checks
- Decoder freed on every path: play_hero_video returns early before creating anything on null stream or still. If play() fails it removes and frees the box. Otherwise a single finish lambda is bound to both `finished` and `p.closed`. It stops the player, queue_frees the box and restores the art, and it is idempotent. Covered by the close and finish tests.
- Buttons: the box and the player both use MOUSE_FILTER_IGNORE. Mid-video CONTINUE and LET'S CLEAN are tested.
- No economy, claim, routing or comeback-window change. The profile_screens diff is only the constants plus one play_hero_video call after mark_summary_shown. The call is gated on Scrubby being active and not Reduced.
- Shader: edge_fade defaults to 0.0 and the fade block is guarded by `if (edge_fade > 0.0)`, so 093/095 output is unchanged. The helper sets the uniform only when edge > 0.
- Trim to frame 181 is documented in PROVENANCE.md (182 frames used, with the reason) and in the build tool TRIM constant.
- Stills: set-complete held and mid-video, and welcome-back held and mid-video, show no magenta fringe. The edge fade is invisible against the cream panel, and the stars and confetti are kept.

## Must-fix
None.

## Notes (non-blocking)
- Welcome-back mid-video still sits on a pure black backdrop, because the capture uses a test scene. This is not a defect.
- Node names changed from GiftVideo/GiftVideoBox to HeroVideo/HeroVideoBox; the 099 test and capture tool were updated.

VERDICT: PASS
