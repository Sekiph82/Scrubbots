# SB-M42 HOME COMPOSITION REMEDIATION — CHATGPT AUDIT CRITERIA V01

Verdict may be AUDITED_PASS only if all requirements below are independently satisfied.

1. No owner-approved PNG changed between remediation baseline and implementation commit.
2. All 49 unique approved Git blobs still match the owner approval artifacts.
3. The Home no longer treats binder availability as equivalent to presentation integration.
4. There is deterministic presentation accounting for all 50 approved ART manifest entries.
5. All static current-Home art has a concrete presentation node; optional state/animation assets have an explicit state/node mapping; HOME-087 is the documented HOME-042 reuse.
6. HOME-006/007 banner art is integrated and HOME-008/009 remain live text.
7. HOME-010/011 are composed so the platform reads below/supporting Scrubby rather than cutting through his torso.
8. Environment props and helper bots intended for the static Home composition are actually bound to independently placeable nodes.
9. HOME-027/034/035 profile art is integrated without baking live values.
10. HOME-051/054 Gift Meter art is integrated while progress/next milestone remain live and Economy V1-correct.
11. HOME-078 Play frame is visible around a real native interactive PLAY/CONTINUE control.
12. HOME-086/087/090..094 reward-track art is integrated with live +1/+5/+10/+25/+100 SB values and no Star semantics.
13. HOME-101..105 bottom-nav icons are integrated while nav labels remain live.
14. Full shortcut labels are readable at the reference viewport; WIN STREAK, COLLECTION and CARDS EXCHANGE are not clipped.
15. Disabled/future shortcuts remain recognizably disabled but readable.
16. Decorative art does not intercept input or cover actionable controls incorrectly.
17. Required viewport matrix passes geometry/readability/touch assertions, including >=88 px touch targets.
18. Dynamic text/amounts/timers/state remain live/localizable and are not baked into art.
19. Validator and hash-pin lifecycle rules are not weakened.
20. `m42_assets`, `m42_home`, `m42_navigation` and root `run_tests` exit 0 with zero SCRIPT ERROR and no new regressions.
21. `git diff --check` is clean.
22. Root `TASKS.md`, owner artifacts and ChatGPT audits are untouched by Claude.
23. Implementation log is complete and maps exact evidence/SHAs.
24. Final composed visual owner gate remains open after code audit; Claude may not self-close SB-M42-011 or SB-M42-017.

If any approved PNG changes, any required static asset remains orphaned, or the runtime composition contract is still represented only by abstract binder tests, verdict is CHANGES_REQUIRED.
