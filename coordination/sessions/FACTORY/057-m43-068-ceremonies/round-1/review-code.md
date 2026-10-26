VERDICT: PASS

## Checks
git diff --check origin/main...HEAD: pass (no output)
Godot suites: not run (reviewer-tests owns them)

## Findings
None.

## Notes
- _on_closed rollback (ceremony_presenter.gd:119-124): safe for all kinds. It only runs on "action:" closes, snapshots meta_ui, and on a failed save restores that snapshot and snoozes the key for the session. pending() skips snoozed keys, so drain() goes idle instead of re-opening: no loop and no same-session re-show. After relaunch the mark was never saved, so the ceremony shows again (fail closed). mark_seen returns false for an already-seen key, so a replayed ack never rolls anything back. When the app is blocked, request_save returns ok=false and pending() is already empty.
- Side effect on old kinds: previously a failed save left the in-memory seen mark, which a later successful save would persist. Now it stays unsaved and the event is shown again next launch. This is the stricter and correct behavior.
- feature_events() is read-only. It is gated on is_new_profile, level > 1, feature_unlocked and not is_seen. It is appended after CeremonyEvents.pending, and the sort is deterministic (level, then id). CeremonyEvents output is untouched, so e30 stays true. Keys use the "unlock:" prefix, so they cannot collide with feature_visited: or What's New keys. HomeBadges NEW pill logic is untouched, and suite case h covers the independence.
- Test edits are not weakened. m44_ftue t23 only adds an assertion (Daily ceremony first and alone on the stack) and an ack before the original What's New assertions, which are unchanged. m44_contextual_coach _play marks the feature_events keys seen before the coachmark checks. That is a test-side adaptation: a modal over a coachmark is correct production behavior, and the ceremony is tested in the new suite (case i checks no coachmark shows under it).
- ui_text keys and the CI list entry are correct, and the header count says 48. meta_ceremonies.gd changed in a comment only.
- Minor: feature_events reads _app.unlocks.cfg["unlocks"] directly, which reaches into FeatureUnlocks internals. A small accessor would be cleaner, but this is not blocking.
