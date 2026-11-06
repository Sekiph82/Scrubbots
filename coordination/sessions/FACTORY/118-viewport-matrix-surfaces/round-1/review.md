# Review round 1 - job 118-viewport-matrix-surfaces

Checks: git diff --check clean. Ran m49_responsive_matrix (PASS 8/8), m43_master_c010_meta (PASS 12/12), m43_c001a_results_foundation (PASS 11/11). The two new 3-4 min suites were not run (per instruction). project.godot restored after the run.

Review:
- UI fixes are UI-only: min-size bumps to UiTokens.TOUCH_MIN (88), autowrap on event title and Results row text, removal of AUTOWRAP_OFF in ui_event_card _text, HomeStyle.fit_font on pills (PILL_MAX 600). No gameplay or economy code touched. English layouts change only by the 64/70/72 to 88 button height bumps.
- Suites extend the factory 115 helpers, walk 40/42 surfaces on all 8 sizes, assert frame, touch, text, LIFO close, scroll reachability and a compact notch case. The two not-built surfaces are recorded as NOT_BUILT, not invented. Events config is injected in tests only via a user:// temp path (live events_v1.json unchanged). Saves are throw-away.
- Diff holds only the 7 expected files; modified .import files are import noise, not committed.

Must-fix: none.

VERDICT: PASS
