VERDICT: PASS

## Checks
git diff --check origin/main...HEAD: pass (clean)
Godot suites: not run (reviewer-tests owns them)

## Findings
None.

## Notes
- Logic is correct and minimal: pure rule in HomeBadges.new_features (null/blocked/grandfather guards), count wins over NEW via badge_text (str(count) if c > 0, else NEW), _mark_visited runs only after the _locked() guard in both the shortcut and nav paths, uses meta_ui.mark_seen + request_save like the ceremony callers, then refresh(). GATED_ENTRIES moved into HomeBadges and aliased in HomeScreen, so there is one source and no duplication.
- Layout: GROW_DIRECTION_BEGIN on both the shortcut badge and the NavBadge labels makes the wider NEW pill expand leftward (inward) from the top-right anchor, so it stays inside the button. Nav label is 48 px at 24 pt, so NEW grows about 10-20 px left; acceptable at the narrowest tab width. I did not render it.
- Behaviour change worth knowing: robots/events nav badge assignment moved out of the economy.orders guard, so leaderboard now also gets NEW. Intended by the spec (ranks).
- .uid: the repo tracks only 4 .gd.uid in scripts and 3 in tests, so tests/m44_new_badge.gd.uid should be dropped for consistency (the spec said "as the repo does"; the repo mostly does not). Non-blocking; the engine regenerates it.
- CI wiring: m44_unlock_gate is in the validate list in android-family-first10.yml (line 112, header comment line 33, "45 total"). m44_contextual_coach is NOT wired anywhere (not in the workflow or tools/run_suites.py), so omitting m44_new_badge is consistent with that precedent. Adding it would be cheap and sensible (append to the list and bump the "45 total" comment), but only if the suite exits non-zero on fail like m44_unlock_gate. Optional follow-up, not required.
