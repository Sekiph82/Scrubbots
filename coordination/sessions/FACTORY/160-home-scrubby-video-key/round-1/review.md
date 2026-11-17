VERDICT: PASS

## Checks
- git diff --check: pass
- merge-tree vs current origin/main (jobs 161/162/163 landed): 0 conflicts
- manifest sha256 (wave .ogv, turn .ogv, still .png) recomputed: all match; old video/still files untouched (only manifest and m42_assets.gd are M in the diff, no assets modified/deleted)
- m42_home_v04: 18/18 cases, 0 failures
- m42_c003_scrubby_animation: 25/25 cases, 0 failures
  (first run failed only because the fresh worktree was not imported; after godot --import both pass. The import dirtied .import files in the worktree, an artifact, not the commit.)

## Findings
None.

## Notes
- Visibility: _end_gesture sets still.visible = has_video(), so the video-end, Reduced Effects stop and watchdog paths return the still, and the no-video fallback hides it and shows the frame-set Scrubby. step() hides the still only once stream_position > 0, so there is no double Scrubby and no invisible gap. The new c003 assertion covers the hand-off.
- Test count bumps (54->56 approved, 25->26 active, OWNER_RETIRED 8->10, still_approved 28->30) are explained. HOME-125 is added, and the m42_home_composition numbers also correct pre-existing drift from the HOME-121/123 retirements. Both are asserted by exact id lists, so no regression is hidden.
