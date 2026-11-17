# 166-home-scrubby-magenta-videos decision

APPROVE (2026-11-17). CLAUDE_PEER_REVIEW round 1: PASS (round-1/review.md). Owner delivered three Flow videos on magenta (bow, full_turn, sweep) and asked to trim and add them.

- Code commit d227fba8: three keyed .ogv (frames 0..184, loop point = frame 0, clearly-background pixels snapped to #FF00FF, libtheora -q:v 8) added to home_scrubby_videos_keyed_v2 (5 gestures); frame 0 aligns with the keyed still at 0 px. No runtime code change.
- Suites LOCAL_PASS: 9 Home suites (m42_home_v04 18/18 now pins all 5 sha256 + Theora); reviewer reran 18/18.
