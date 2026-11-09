# Round 1 review (reviewer-tests)

NOTE: the reviewer reported via hand-back but no file was found on disk; orchestrator transcription.

- Re-ran tests/m50_accessibility_audit.gd: exit 0, PASS (8/8 cases, 0 fail), no SCRIPT/Parse errors.
- a06 measures real RewardedAdsButton / ProfileLevel / booster Price with real EN+TR copy and 9999 values, fit_font args match production. EN 24/20/19 px, TR 24/18/19 px; floor 18 enforced (TR "Bolum 9999" at 18 fails if longer). Synthetic 60% shrink kept as printed note.
- a07: ui_text_tr.gd matches "reduced" only via key SETTINGS_REDUCED_EFFECTS; narrow copy-table exclusion, hides no code path.
- Not re-run: m49/m51 (builder claims 5/5, 4/4, 8/8).
- Non-blocking: event pill (30 px start) not covered by real-copy assertion.

VERDICT: PASS
