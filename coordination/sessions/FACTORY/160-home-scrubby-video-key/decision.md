# 160-home-scrubby-video-key decision

APPROVE (2026-11-17). CLAUDE_PEER_REVIEW round 1: PASS (round-1/review.md). Owner chose the difference-matte key ("parkli videolardan scrubbyi ayirmaya calis") and approved the result in chat ("Ship them").

- Code commit 4dce6eb8: wave + turn keyed from the park masters onto magenta (chroma_key_magenta.gdshader), new video set home_scrubby_videos_keyed_v2 + keyed still HOME-125; bow and full_turn left out (could not be keyed cleanly); still hidden once the video's first frame is up (no double Scrubby).
- Known visual flaws accepted by the owner: small edge shards in fast frames, ~1 px edge shimmer, semi-transparent pink tongue.
- Suites LOCAL_PASS: 13 Home suites; reviewer reran m42_home_v04 18/18 and m42_c003_scrubby_animation 25/25.
