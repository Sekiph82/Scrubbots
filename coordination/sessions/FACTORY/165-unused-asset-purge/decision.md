# 165-unused-asset-purge decision

APPROVE (2026-11-17). CLAUDE_PEER_REVIEW round 1: PASS (round-1/review.md). Owner instruction in chat 2026-11-17: delete (not archive) old videos and unused images so the game file does not bloat.

- Code commit e8a1e874 (rebased on 070d1786): 159 unused media files deleted (208.3 MiB): park-baked Home videos/still, old Home background, V02 gameplay shells + master, 22 retired Home entries, 124 never-referenced UI files. Manifest status RETIRED_DELETED; export presets exclude factory/* and flow_videos/*. Exported media estimate 742.6 -> 534.4 MiB.
- Kept on purpose: built-path families (robot unlock videos, card sets, plaza shells), Home gesture fallback frames, HOME-120 World Transition fallback, ~9.7 MiB dev-tool-only frames.
- Suites LOCAL_PASS: full CI list 95/95 + 12 affected non-CI suites; after rebase 7 Home suites; reviewer reran m42_assets, m42_home_v04, m43_master_c008_robots, m43_master_c007_collection.
