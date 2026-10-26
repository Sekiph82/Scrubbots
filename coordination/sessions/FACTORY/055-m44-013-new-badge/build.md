STATUS: READY

# Build: NEW badge for newly unlocked Home entries + coachmark visual language doc

## Summary
A NEW (fresh FTUE) profile now sees a localized "NEW" pill on a gated Home entry (SHOP / COLLECTION / TASKS / DAILY shortcuts, ROBOTS / EVENTS / RANKS tabs) once it unlocks, until the first press. Pressing it marks the meta_ui presentation key `feature_visited:<feature_id>` and requests the canonical save. That is the same `meta_ui.mark_seen` + `_app.request_save()` path that `ceremony_presenter.gd` uses. Grandfathered profiles never see NEW. A real count on the same entry wins over NEW. There is no new save section, no schema bump, no new art, and no change to economy, unlock or gameplay. SB-M44-018 is closed by documenting the existing CoachmarkLayer visual language in docs/16 §1.5.

Commits on `factory/055-m44-013-new-badge`: b07ca99e (code, docs, suite), 30d3203d (TASKS).

Files changed:
- `scripts/ui/home/home_badges.gd`: now owns `GATED_ENTRIES` (moved from home_screen). Adds `visited_key(feature)` and the pure rule `new_features(app) -> Array`.
- `scripts/ui/home/home_screen.gd`: `GATED_ENTRIES` now aliases `HomeBadges.GATED_ENTRIES`. Badge refresh is unified: counts first, then NEW for shortcuts and the robots / events / leaderboard NavBadge. `_mark_visited(id)` runs on the shortcut press and on the unlocked nav press.
- `scripts/ui/components/ui_shortcut_button.gd`: `set_badge_text(t)` reuses the existing badge node and style. The badge grows inward (`GROW_DIRECTION_BEGIN`), so the wider pill stays on the panel.
- `scripts/ui/ui_text.gd`: `HOME_BADGE_NEW: "NEW"`. EN is the repo's only string table.
- `tests/m44_new_badge.gd` + `.uid`: the new suite.
- `docs/16_FTUE_FEATURE_UNLOCK_AND_RETENTION_SURFACES.md`: new §1.4 (NEW badge) and §1.5 (coachmark visual language). The stale "owner visual approval pending" line in §1.1 now points to §1.5.
- `TASKS.md`: [x] SB-M44-013 and [x] SB-M44-018 with evidence; queue row 44 set to DONE.

## Acceptance criteria
1. [x] Frontier walk: `m44_new_badge` case `rule_walk` passes. A fresh profile has no NEW at L1, and `["daily"]` at L4 and L7. With daily visited, L7 is empty and L8 is `["shop"]`. With nothing visited, L8 is `[daily, shop]` (nothing above L8) and L40 lists all seven entries. The spec said "frontier 7: empty", but it also said daily (L4) stays NEW until visited, so the two conflict. I tested the consistent reading: L7 is empty once daily has been visited.
2. [x] `visit_clears` passes: marking shop at L12 leaves `[daily, tasks]`. `home_ui` passes: after the SHOP press, `Shortcut_shop` shows no NEW.
3. [x] `persistence` passes: after save and reload into a new AppState, shop stays cleared and daily + tasks stay NEW. The Home press also survives a reload, which proves the canonical save was requested.
4. [x] `grandfather` passes: an established profile has an empty list at L1, L5, L8, L20 and L40.
5. [x] `legacy_snapshot` passes. A snapshot without `ftue` and with meta_ui but no `feature_visited:` keys imports and shows no NEW at L40. A snapshot without `meta_ui` (baseline path) does the same.
6. [x] `home_ui` passes: at L8, locked TASKS / ROBOTS / EVENTS show no badge, and pressing them marks nothing.
7. [x] `home_ui` passes. Shop shows "NEW", visible. DAILY shows count "1" instead of NEW. After the press handler runs, NEW is hidden. At L30, NavBadge_robots / NavBadge_events show NEW, and pressing the tab hides it. RANKS is unserved (disabled), so it shows no NEW. An established-profile Home shows no NEW pill.
8. [x] The suite ends with `M44 new badge evidence: PASS (6/6 cases, 0 fail)`, exit 0, no SCRIPT ERROR or Parse Error.
9. [x] Regression suites (LOCAL_PASS, Godot 4.7.2 headless; each exit 0, 0 SCRIPT ERROR / Parse Error, last line PASS):

   | Suite | Result |
   |---|---|
   | m44_unlock_gate | 6/6 |
   | m44_ftue | 23/23 |
   | m44_contextual_coach | 7/7 |
   | m42_home | PASS |
   | m42_navigation | PASS |
   | m40_save_system | PASS |
   | m36_v02_migration | PASS |
   | m43_master_c010_meta | 12/12 (the home-badge suite; `ls tests \| grep -i badge` finds only the new suite) |
   | m43_r15_001_r01_sequential_unlock | 14/14 |
   | m47_touch_r01_mobile_ux | 14/14 |
   | m49_responsive_matrix | 8/8 |
   | m50_accessibility_audit | 4/4 |
   | m51_localization_readiness | 4/4 |

10. [x] docs/16 §1.5 holds the coachmark visual-language section. TASKS.md shows `[x] SB-M44-013` and `[x] SB-M44-018`. `git diff --check HEAD~2 HEAD` is clean.

## Validation
- `"$GODOT" --headless --path <worktree> -s res://tests/<suite>.gd` for the 14 suites above: all PASS.
- `"$GODOT" --headless --path <worktree> --import` (exit 0), run only to generate `tests/m44_new_badge.gd.uid`.
- `git diff --cached --check` before each commit, and `git diff --check HEAD~2 HEAD`: clean.
- main.tscn was never booted. The tests use only `user://m44_new_badge_*` temp saves, which the suite deletes.

## Notes
- The imported worktree was already dirty before this job: about 1500 Godot `.import` / `.uid` artefacts (modified and untracked). The `--import` run touched the same kind of files. None of them are staged or committed, and none are mine to clean, so `git status --porcelain` is not empty. Every task file is committed.
- I did not add the new suite to `.github/workflows/android-family-first10.yml`. The spec doesn't ask for it, and the previous job left `m44_contextual_coach` out as well.
- AGENTS.md does not describe Home badge behaviour, so it is unchanged.

## Log
### Round 0
Implemented the spec in commits b07ca99e and 30d3203d. The visited flag is written only through `economy.meta_ui.mark_seen`, followed by `_app.request_save()` (the existing presentation-ledger path); no economy balance is touched. It is marked only while the entry is currently NEW, so grandfathered or locked presses never write. Ran the new suite and all 13 regression suites (LOCAL_PASS).
