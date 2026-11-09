# Review round 1 - 131-a11y-text-scale-labels

Checks (worktree, Godot 4.7.2 headless):
- git diff --check origin/main...HEAD: clean.
- FOCUS_ACCESSIBILITY: exists in 4.7.2 (all scripts parse, suites run, no SCRIPT ERROR). It only takes focus when AccessKit/screen reader is active, so touch play gets no focus ring and no focus stealing. Input handlers, double-tap and modal code are untouched by the diff (only focus_mode lines, accessibility_name/description, and the Home lock pill).
- m50_accessibility_audit 11/11, m51_localization_readiness 8/8, m42_home_v04 18/18, m43_c002_c001_popup_modal_pause 23/23, m28_c002_c001_gameplay_v02 14/14: all PASS.
- Lock pill: built with the existing _badge_label (MOUSE_FILTER_IGNORE, grows inward like the NEW pill), reuses BOOSTER_LOCKED_LEVEL so EN "LV N", TR "BL N" matches the booster convention; hidden when unlocked. Layout is a 48 px anchor that grows inward, so wider text is safe.
- TR strings natural. Reduced Effects untouched. Flash audit method (general flash count, 10-degree field, 3/s limit) is the WCAG 2.3.1 approach.

Notes (non-blocking): remaining FOCUS_NONE in journey_strip, slot_view and debug scripts are non-player-interactive or debug; fine. Text-scale overhang (8-10 controls) is reported, not fixed; acceptable as documented.

Must-fix: none.

VERDICT: PASS
