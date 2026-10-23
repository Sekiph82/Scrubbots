VERDICT: PASS

## Checks
git diff --check origin/main...HEAD: pass
Godot suites: not run (reviewer-tests owns them)

## Findings
None.

## Notes
- Grandfather logic is correct. `FtueState.close()` only sets `closed`; `profile` stays "new", so a fresh save is still gated after the L1-L3 window closes. The level walk to L40 and the relaunch in the test cover this. `bootstrap_new_profile` runs at launch before Home, so there is no window where a fresh profile is briefly grandfathered.
- `feature_unlocks.gd` fails open as specified. A missing file, null parse or bad schema gives `ok:false` with an empty table, and `unlock_level` returns 1 for an unknown id. Locked state is derived each call from the frontier, so it can never be stranded.
- Home: `_shortcut_pressed` and the nav lambda both check `_locked` before emitting. Gift Bar is not in `GATED_ENTRIES`. Badges are forced to 0 or hidden while locked. `_render_values` recomputes the nav tooltip and disabled state, but `served` keeps the old behaviour (robots always enabled, events and RANKS only when `set_app_nav` listed them). Nothing else calls `open_popup` for gated ids.
- Boosters: the `"locked"` state is applied last in `booster_states()`, so it overrides `selected`, `available` and the terminal case. `request_booster` and `execute_booster` both reject with `locked` before any state change.
- FTUE director: skipping happens by `continue` without `mark_seen`. `home_play` is unconditional, so the L1-L3 window still closes.
- Performance: `current_level()` is a field read. The added cost is a few dictionary lookups per Home or HUD refresh, with no allocations except the small `boosters` filter inside `current_step`. The m46 retry timing failure in build.md is on a path this change does not touch. Please check the CI timing.
- The unlock text is a tooltip only, so touch devices won't see it. build.md already flags this. Consider a visible label in part 2.
- Edits to the m46 suites outside the spec's edit list are justified, and build.md lists them.
