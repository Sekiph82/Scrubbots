# 162-gift-meter-48h decision

APPROVE (2026-11-17). CLAUDE_PEER_REVIEW round 1: PASS (round-1/review.md). Owner economy decision in chat 2026-11-17: Gift Meter restarts from zero at most every 2 days.

- Code commit c1c12590: 48 h cycle window from first progress (gift_meter_service.gd, economy clock like Hearts); expiry resets unfinished progress only, Gift Bar queue untouched; monotonic cycle index for milestone ids; schema 4 + cycle_window_hours 48; migration starts the window at first load for saves with progress; Home countdown label (UiText TIME_DH / TIME_M, TR "sa"/"dk").
- Suites LOCAL_PASS: new sb_gift_meter_48h 7/7 (in CI, exact guard; fails on base), 29 economy/Home suites; reviewer reran sb_gift_meter_48h, sb_polish_002, m39a, m39_v03.
