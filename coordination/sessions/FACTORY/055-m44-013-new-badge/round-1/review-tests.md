VERDICT: PASS

## Findings
None.

## Notes
Re-ran all 11 requested suites myself (exit 0, 0 SCRIPT ERROR / Parse Error for each). Final PASS lines:
- m44_new_badge: `M44 new badge evidence: PASS (6/6 cases, 0 fail)`
- m44_unlock_gate: `PASS (6/6 cases, 0 fail)`
- m44_ftue: `PASS (23/23 cases, 0 fail)`
- m44_contextual_coach: `PASS (7/7 cases, 0 fail)`
- m42_home: `M42 home evidence: PASS`
- m42_navigation: `M42 navigation evidence: PASS`
- m40_save_system: `M40 save system evidence: PASS`
- m36_v02_migration: `M36 V02 migration evidence: PASS`
- m43_master_c010_meta: `PASS (12/12 cases, 0 fail)`
- m49_responsive_matrix: `PASS (8/8 cases, 0 fail)`
- m51_localization_readiness: `PASS (4/4 cases, 0 fail)`
(Godot prints teardown leak noise after the PASS line. It is not an error.)

Real behaviour asserted:
- Badge appears at the unlock boundary: frontier walk L1 empty, L4 daily, L8 shop, L40 all seven.
- Press clears it: Shortcut_shop and the Nav badges are hidden after the press handler, and visited is marked.
- Persistence: reload into a fresh AppState keeps shop cleared and daily/tasks NEW. The Home press also survives reload, so the save is actually requested.
- Grandfathered profiles: empty at L1, 5, 8, 20, 40.
- Legacy snapshots without feature_visited keys, and without meta_ui, import and show no NEW.
- Locked entries (tasks, robots, events): no badge, and pressing them never marks visited.
- A count wins over NEW (DAILY shows "1").
- The mark is gated on `new_features().has(id)` in `_mark_visited`, so the suite fails if the gating or the rule breaks.

No real user save touched: the suite uses `AppState.new("user://m44_new_badge_<tag>_<usec>.save")` temp paths and deletes them. main.tscn is not booted. No tracked file is modified in the worktree. Only .import/.uid artefacts are dirty, and they predate the job.

Non-blocking: the walk test treats L7 as "daily only until visited". That is the consistent reading of the spec's conflicting AC1, and build.md documents it. The new suite is not wired into CI. The previous job didn't wire its suite either, so this is consistent.
