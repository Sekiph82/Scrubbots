VERDICT: PASS

## Checks
- git diff --check origin/main...HEAD: pass
- godot --import then tests/sb_polish_011_character_motion.gd: pass (16/16, 0 fail; the only ERROR line is the deliberate missing-video case)
- project.godot restored after import: yes

## Findings
None.

## Notes
- One decoder: _video is a single field, _stop_video runs from _stop_feel (every re-show and hide) and on finished (deferred, guarded by player identity). Box is removed then queue_free'd; stop() is called first.
- Fallbacks hold: non-Scrubby returns false, so pose + CharacterMotion run. Null stream, load failure, not playing, or zero length all stop and return false. Reduced Effects, re-show and outside-tree show only the keyed still. Both videos use mouse_filter IGNORE, so buttons are not blocked. The slot rect is unchanged, since the box is a child with a full-rect anchor.
- Shader: m = min(R,B) - G, and R/B are only lowered by max(m,0), so teal, cyan and green (R or B below G) are untouched. Build script uses the same thresholds.
- Provenance and TASKS rows are accurate: 001/002 DONE, 003..010 OWNER, Home robot videos noted as dropped.
- Minor: _stop_video resets self_modulate.a to 1.0 unconditionally. Fine today since nothing else sets it on the robot.
- The worktree has untracked .uid files from --import. They are not part of the branch.
