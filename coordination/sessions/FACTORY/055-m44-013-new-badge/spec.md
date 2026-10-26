# NEW badge for newly unlocked Home entries + coachmark visual language doc

> Feature: SB-M44-013 (newly unlocked Home shortcut/Nav destination shows a NEW badge until first visit; clearing persists) and SB-M44-018 (tutorial coachmark/highlight visual language; closed by documenting the existing CoachmarkLayer language, no new art).

## Context
- Unlock table: `data/config/feature_unlocks_v1.json`; reader `scripts/progression/feature_unlocks.gd`; gate `AppState.feature_unlocked(id)` (`scripts/app/app_state.gd` ~209). Grandfather: any profile that is not `economy.ftue.is_new_profile()` has everything unlocked.
- Home: `scripts/ui/home/home_screen.gd`. `GATED_ENTRIES` maps entry id -> feature id (shop, collection, tasks, daily, robots, events, leaderboard->ranks). The refresh code (~1295-1325) sets numeric badges via `UiShortcutButton.set_badge(int)` (`scripts/ui/components/ui_shortcut_button.gd`) on `Shortcut_*` and a `NavBadge_<id>` Label for robots/events; counts come from `scripts/ui/home/home_badges.gd`. Locked entries carry no badge.
- Persisted seen-set already exists: `economy.meta_ui` (`scripts/economy/meta_ui_state.gd`, `is_seen/mark_seen`, saved in the economy snapshot section `meta_ui`, strict import, legacy baseline). Reuse it with key `feature_visited:<feature_id>`; add NO new save section or schema version.
- Visual language of tutorials: `scripts/ui/tutorial/coachmark_layer.gd`, `docs/16_FTUE_FEATURE_UNLOCK_AND_RETENTION_SURFACES.md`.

## Requirements
1. Add a NEW attention state for a Home entry: shown iff the entry is in `GATED_ENTRIES`, `_app.feature_unlocked(feature)` is true, and `meta_ui.is_seen("feature_visited:"+feature)` is false, AND the profile is not grandfathered (`economy.ftue.is_new_profile()`); grandfathered profiles never show it. Put the pure rule in `home_badges.gd` (e.g. `new_features(app) -> Array` of entry ids) so it is headless-testable.
2. Home renders it as a native text pill "NEW" (localized via `UiText`, new key added to the string table(s) the repo uses) on the Shortcut_* buttons (shop, collection, tasks, daily) and the Nav robots/events/ranks tabs where a badge slot exists, reusing the existing badge node/style; no new art. A real numeric count badge on the same entry wins over NEW (NEW only when count is 0).
3. Visiting clears it: when the player activates the entry (shortcut_requested / nav_requested path in Home), call `meta_ui.mark_seen("feature_visited:"+feature)` and request a canonical save through the existing AppState/action path used by the other `mark_seen` callers; then refresh badges. Locked/disabled entries cannot be visited so never mark.
4. Persistence is via the existing `meta_ui` snapshot; an old save without the key set loads unchanged (no NEW for grandfathered profiles; no schema/version bump; existing save/migration suites stay green).
5. Presentation only: no change to unlock table, gate, economy, or gameplay.
6. SB-M44-018: add a short section to `docs/16_...md` documenting the coachmark visual language (location `coachmark_layer.gd`, ring + pointer + bubble, colours/animation as implemented, reduced-effects behaviour, reuse rule: new tutorial highlights must use CoachmarkLayer; NEW pill style), stating that no additional art or Scrubby teaching poses are required. Tick SB-M44-013 and SB-M44-018 in `TASKS.md` with evidence; update the READY line 44 accordingly. Update `AGENTS.md` only if it lists Home badge behaviour.
7. New suite `tests/m44_new_badge.gd` (+ `.uid` as the repo does) covering the criteria below.

## Acceptance criteria
GODOT = C:/Users/sekip/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe; run as `"$GODOT" --headless --path <worktree> -s res://tests/<suite>.gd`.
1. New profile at frontier 7: `new_features` is empty; after progression reaches level 8, it contains `shop` (unlock level 8) and only entries whose level <= 8 and not visited (e.g. daily at 4 included until visited). `m44_new_badge.gd` prints a PASS line for this.
2. Marking `shop` visited removes it from the list and Home's `Shortcut_shop` shows no NEW; others remain.
3. Save then load into a fresh AppState/economy: visited entries stay cleared, unvisited stay NEW (persistence).
4. Grandfathered (non-new FTUE) profile: list empty at every frontier, including 1.
5. Old save (economy snapshot without any `feature_visited:` keys, and a legacy snapshot without `meta_ui`) loads without error and produces no NEW for a grandfathered profile.
6. Locked entries (frontier below unlock) never show NEW and never mark visited when pressed.
7. Home UI check: with a Home instance and a new profile past an unlock, the node for the entry shows text "NEW" visible; a numeric count > 0 shows the count instead; after the press handler runs it is hidden.
8. `m44_new_badge.gd` ends with a final `PASS`-style line and exit code 0 (the same convention as `tests/m44_unlock_gate.gd`).
9. Regression, all still PASS: m44_unlock_gate, m44_ftue, m44_contextual_coach, m42_home, m42_navigation, m40_save_system, m36_v02_migration (also run any m43 home-badge suite found by `ls tests | grep -i badge`).
10. `docs/16_...md` contains the coachmark visual-language section; TASKS.md shows `[x] SB-M44-013` and `[x] SB-M44-018`; `git diff --check` is clean.

## Out of scope
New art, Scrubby/robot poses, asset generation; new save sections or schema bumps; changing the unlock table or grandfather rule; badges for Gift Bar/Hearts (never gated); in-game (gameplay screen) booster unlock badges; animation or sound for the badge.

## Assumptions
- Reuse `meta_ui` seen set rather than a new "visited" field: already persisted, migrated and rolled back with the economy snapshot.
- "Visit" = pressing the enabled Home shortcut/Nav entry (not opening via other routes), the simplest observable event.
- A new-profile save made before this change that already passed some unlocks will show NEW once for them; acceptable, cleared on first visit.
- NEW is shown only for non-grandfathered profiles, since grandfathered ones have all features "unlocked" from the start.
