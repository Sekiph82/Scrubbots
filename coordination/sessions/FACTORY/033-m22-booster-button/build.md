STATUS: READY

# Build: SB-M22-022 / 023 / 025 booster button verify

## Summary
Only TASKS.md changed (commit cf5700c8 on factory/033-m22-booster-button). 022 ticked (already on main); 023 and 025 left open with precise notes; queue row rewritten to the remainder.

## Acceptance criteria
1. [x] 022 exists on main: gameplay_screen.gd _make_booster / set_booster_states / _apply_booster_visual, states available/purchasable/unavailable/selected/locked. Tests: m28_c002_c001_gameplay_v02 PASS 14/14, m39c_boosters PASS, m43_c003_c001_acquisition PASS 34/34 (exit 0, no SCRIPT/Parse errors). Selected/unavailable/purchasable/available asserted in m28; LOCKED exists (disabled + overlay) but is never produced (m28 asserts none locked); unlock gating is SB-M44-031, not done.
2. [ ] 023 not closed: 4 booster icons + selected ring + unavailable overlay bound; booster_free_badge_frame, booster_reward_glow, booster_activated_burst, booster_tutorial_pointer have zero references.
3. [ ] 025 not closed. Stdlib check (job folder chk.py, uncommitted): boosters 10 PNG all RGBA, all with .import, est 59.99 MiB RGBA8 (1254x1254 each = 6 MiB, drawn ~100px); all final art 560 PNG est 2947.67 MiB, all compress/mode=0, mipmaps off, 7 PNGs without alpha. Needs downscale/compress + memory budget.

## Validation
Three Godot suites above PASS (LOCAL_PASS). git diff --check clean. Worktree has untracked addons/game_feel_flow *.uid files from Godot import (not mine, not committed).

## Log
### Round 1
Verify-only round as described; no code changes.
