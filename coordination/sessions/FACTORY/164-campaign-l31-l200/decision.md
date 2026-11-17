# 164-campaign-l31-l200 decision

APPROVE (2026-11-17). CLAUDE_PEER_REVIEW round 1: PASS, no findings (round-1/review.md). Owner request 2026-11-17: 170 more levels from the Release Pool to reach 200. Owner answers 2026-11-17: 56x56 OK for L31+; Home area title follows the world name (background stays plaza); IP-like pool sprites stay in the pool, kept out of the game.

- Code commit 55af903f: 170 Ready-pool levels imported as L31..L200 (cells/palette verbatim, all 170 verified against the pool by the reviewer), catalog 200 entries, cadence-ordered; real-play gate on 28741ed1: 170/170 WON_CANONICAL (10 after --regen of the same clicks; L73 Squid dropped); tools/real_play_gate_l31_l200.json committed; end-of-content moved to L200 in suites; Home area title = world name (UiText.caps, HOME_AREA_WORLD).
- Size: ~4.6 MB raw / ~0.6 MB compressed.
- Suites LOCAL_PASS: campaign_l31_l200 5/5 (CI, exact guard) + 18 affected suites; reviewer reran campaign_l31_l200 and m52.
