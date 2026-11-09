# Review round 1: 145-won-terminal-tick-perf

## Checks
- git diff --check d322afc8..HEAD: clean
- m46_rm005_terminal_frame_profile: PASS (5/5 groups)
- m43_master_c005_meta_ceremonies: PASS (33/33)
- m46_performance: PASS (22/22)
- m44_featured_card_onboarding: PASS (8/8)
- m43_c005_c074_c077_celebrations: PASS (6/6)
- m60_release_gates: PASS (6/6; the output shows a "FAIL SB-M60-006" line but the suite verdict is PASS, exit 0)
- Cleanup done: git checkout, untracked import files removed, status empty.

## Equivalence (check 1)
I read every builder. build() returns null only in these places, and presentable() mirrors each one:
- robot_unlock: null when RobotRoster.entry is empty. Mirrored.
- featured_card: null when CollectionCardCatalog.entry is empty. Mirrored.
- feature_unlock: null when name or icon is empty or the icon is missing from ResourceLoader. Mirrored by _named_art(name, icon).
- world_unlock: null when title or art is empty or the art is missing. Mirrored by _named_art(title, art).
- set_complete, master_complete and gift_milestone have no null path. presentable returns true for them.
- Unknown kind: null in build, false in presentable.

No texture, video or locale failure can make a build return null after presentable said true. The video code runs in start_motion, which degrades to the static still and cannot reject the ceremony. The only residual risk is a malformed event, for example a set event with no "set" key. Before this change that also crashed in pending(). Now it would crash in drain().
drain() does not null-check build(). That is safe because the same list comes from pending() and both calls use the same deterministic checks. If it ever did return null, the first `p.closed.connect` would error. Nothing is acknowledged or saved before that point. This is a non-blocking hardening note.

## Findings
1. Check 2 holds but e33 is partly tautological, because build() now gates on presentable(). For a refused event, `presentable == (build != null)` can never fail. The refused cases still test the refusal rules, because e33 also requires exactly 7 presentable events. Non-blocking.
2. Order and acknowledgement (check 3): pending() still builds the list as CeremonyEvents.pending + feature_events + world_events, with the same snooze filter. The only change is the presentability predicate. _on_closed, mark_seen and request_save are untouched, and so are the economy and progression save. Fine.
3. TASKS row (check 4): honest. It says LOCAL_PASS and "no CI run, no phone build", and it admits the m55 failure, which is the object drift owned by factory 144. The measured numbers match my T4 run, which passed.

## Notes
- Cold-tick Results show_model (~55 ms) remains. This is outside the scope of the job.

VERDICT: PASS

Must-fix list: none.
