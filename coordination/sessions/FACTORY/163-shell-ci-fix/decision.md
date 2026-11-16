# 163-shell-ci-fix decision

APPROVE (2026-11-17). CLAUDE_PEER_REVIEW round 1: PASS (round-1/review.md). Fixes GitHub CI run 43958427421 failures caused by job 159.

- Code commit ad7cc787: 5-column plaza masters rebuilt at 0.95 cell scale (m50 symbol floor at 720x1280), COLS_5/ROWS_5 + SHAs re-measured; L30 intendedColumnClicks reordered (same 120-click multiset) via tools/real_play_verify.gd --regen because the visible-slot route start (M29) is closer to the rail on the plaza art; m46 density floor 90 -> 68 (80% of measured peak 85, negative check kept). No gameplay code, no level cell data changed.
- Suites LOCAL_PASS: m50 10/10, m46 22/22, real_play_levels 4/4, m55, campaign_l11_l30 5/5, shell suites; reviewer reran real_play_levels and m50.
