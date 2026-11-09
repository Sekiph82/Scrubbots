# Review round 1, 128-video-robot-unlocks

Tests run in the worktree: sb_video_010 PASS 7/7, m43_master_c008_robots PASS 10/10, m43_master_c005 PASS 32/32. Worktree .import churn after --import is not committed. git diff --check clean.

- Decoder: it goes through the shared play_hero_video, which frees the player on finished and on popup close. Failed starts free it immediately. The new test checks the broken-stream path.
- Reduced: no "video" meta is set, so the static art stays. A missing or failing stream also leaves static art (verified by the test).
- Buttons, economy: no change to unlock, equip or economy. The video box ignores the mouse.
- Shader: blue is a new file. Magenta and green shaders are untouched. The formula is sound (m = B - max(R,G), purple stays below the key range). The build tool keys the still the same way.
- e16 adaptation: fair. It accepts master art or the video still, and still checks name, role, perk and perk icon. The static art is covered by the Reduced/failure cases in the new suite.
- Snapshot tool: switching to economy.robots.unlock("moppy") is sane. The facade call is feature-gated on a fresh save.
- Size: +25.4 MB, documented in build.md. Trims for polly and spark are documented in PROVENANCE. Crop and sha for each robot are recorded.
- Evidence stills (clippy, bubbles): clean edges, no visible halo or green or blue fringe at that scale.

Notes (non-blocking): scrubby's pair (2.3 MB) is shipped but unused. The size is acceptable.

No must-fix items.

VERDICT: PASS
