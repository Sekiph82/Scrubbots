# M21-C001 — Strict Audit Criteria V03

Date: 2026-09-12
Purpose: close the single residual of F-M21-STRICT-003 and reconcile the final direct-evidence cells before M21 strict-v2 final closure.

V03 is a **surgical final correction + validation pass**. V01/V02 accepted gameplay architecture and the closed F-M21-STRICT-001/002/004 findings are not reopened unless V03 produces a concrete contradiction.

## A. Governance / lifecycle

1. Work only in `Sekiph82/Scrubbots` on `main`.
2. Safely synchronize with `origin/main` while preserving all pre-existing owner/local tracked and untracked work.
3. Read root `TASKS.md`, `CLAUDE.md`, `AUDIT_POLICY.md`, `AUDIT_INDEX.md`, `CHATGPT_AUDIT_V01.md`, `CHATGPT_AUDIT_V02.md`, `CHATGPT_AUDIT_CRITERIA_V03.md`, `CHATGPT_PROMPT_V03.md`, and `OWNER_DIFFICULTY_V1_SCOPE_NOTE.md` before edits.
4. Treat V03 scope as frozen to the residual F-M21-STRICT-003 path resolution/preflight issue plus the explicitly enumerated direct-evidence reconciliation cells.
5. Before implementation, make and push a tracker-only start commit containing only root `TASKS.md` lifecycle fields for `M21-C001 V03 / IN_PROGRESS / CLAUDE`.
6. Do not change any M19/M20 production gameplay source.
7. Do not redesign Difficulty V1, `difficulty_rules.gd`, or `production_level_validator.gd`.
8. Do not implement Level Factory, PixelLab/Art Intelligence runtime integration, M22/M23/M24 UI/touch, scoring, win/lose, progression, economy or save systems.
9. Do not mutate, optimize, re-encode, resize or recolor the owner-approved Hazard Bot source PNG.
10. Do not close any `SB-M21-*` or `SB-UI-014..016` task checkbox.
11. Progress remains `304/719` main+ui and `304/943` overall at Claude handoff.
12. `lastCompletedTaskId` remains `M20-C001-V11`.
13. Claude authors no audit verdict/file.

## B. Locked accepted identities / behavior

14. Owner source path remains `assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png`.
15. Owner source Git blob remains `b565743ba52699899007882b750b7c8e7cdd00f9`.
16. Owner source SHA-256 remains `ede1e02a9096c4c7ba040b91ed7db2d2c2af3b2e20d5c8774068c8d08ad59899`.
17. M20 CompleteClearingLoop blob remains `06391839523cbc27e88a4b3ef12b730012cd45fa`.
18. M20 ScrubbotDispatcher blob remains `eee10149e4f116af6706beec832042352bf3a6dd`.
19. Generic M09 `level_importer.gd` remains unchanged unless a concrete blocker is found, in which case stop BLOCKED rather than drive-by patching it.
20. V02 difficulty-identity behavior remains intact: mismatch/TEST/unknown/empty reject and valid owner EASY still succeeds.
21. V02 arbitrary-Variant fail-closed behavior remains intact.
22. V02 deterministic reference-composite generator remains intact and reproducible.
23. V01/V02 real-art production-collaborator gameplay behavior remains intact.

## C. F-M21-STRICT-003 residual — one path-resolution contract

24. The M21 production-art builder has one explicit physical path resolver for destination identity/preflight semantics.
25. `res://...` is resolved through `ProjectSettings.globalize_path`.
26. `user://...` is resolved through `ProjectSettings.globalize_path`.
27. A bare relative path is explicitly based at `res://` before globalization; it must not depend on shell/process CWD.
28. An already-absolute path remains absolute.
29. Lexical `.` / `..` segments and separator variants are simplified consistently.
30. Windows case folding, if used, is applied only to comparison identity and not fed back as the physical I/O path.
31. Source/destination alias comparison uses the same resolver contract as destination preflight.
32. Destination/destination alias comparison uses the same resolver contract as destination preflight.
33. Final destination parent/object preflight uses the resolved physical path, not a differently interpreted raw path string.
34. Planning/comparison/write behavior is demonstrably consistent with the same resolved destination identity.
35. No bare-relative destination can be treated as one physical location by alias checks and a different location by preflight/write.

## D. Direct builder path tests

36. A legitimate bare-relative output path under an existing project directory succeeds at the same physical location as the equivalent `res://...` path.
37. A legitimate bare-relative preview path succeeds at the equivalent `res://...` physical location.
38. A legitimate bare-relative metadata path succeeds at the equivalent `res://...` physical location.
39. Bare-relative source-equivalent output alias is rejected with source bytes unchanged.
40. Bare-relative destination vs equivalent `res://...` destination alias is rejected.
41. Where practical, bare-relative destination vs equivalent absolute destination alias is rejected.
42. Dot-segment equivalent forms continue to reject aliases.
43. `overwrite=true` never bypasses source alias protection.
44. A bare-relative later preview/metadata path with a missing parent rejects before an earlier output is created or changed.
45. An existing-different output with `overwrite=false` rejects before preview/metadata mutation.
46. An existing-different preview with `overwrite=false` rejects before output/metadata mutation.
47. An existing-different metadata with `overwrite=false` rejects before output/preview mutation.
48. An existing directory at output path rejects with both `overwrite=false` and `overwrite=true`.
49. An existing directory at preview path rejects with both `overwrite=false` and `overwrite=true`, before output mutation.
50. An existing directory at metadata path rejects with both `overwrite=false` and `overwrite=true`, before output/preview mutation.
51. A non-directory parent continues to reject before any final write.
52. Identical existing artifacts with `overwrite=false` remain `UNCHANGED`.
53. A legitimate three-artifact build still succeeds and a deterministic rerun remains `UNCHANGED`.
54. All path-safety tests clean up their temporary artifacts and do not modify canonical source/output artifacts except through the explicit canonical deterministic rerun.

## E. Final real-art direct-evidence reconciliation

55. Use a fresh real M21 LevelData/BoardState/production-collaborator bundle for the V03 direct assertions.
56. Assert all 400 cells start ACTIVE.
57. Assert exact fresh candidate counts: C01=30, C03=5, C08=298, C11=11, C16=56.
58. Preserve the V02 exact-zero-side-effect blocked non-C08 activation proof or add an equivalent fresh proof.
59. The blocked activation returns exactly `NO_REACHABLE_TARGET`.
60. BoardState, all five candidate buckets, reservation truth/count, dispatcher truth and M20 clear count are exactly unchanged by that blocked activation.
61. On fresh success state, a real C08 activation uses real TargetSelector/access/routing/dispatcher/ScrubbotAgent collaborators.
62. Before arrival, the target is ACTIVE, reservation owner/target identity exists, dispatcher owns the assignment, and the real agent is MOVING.
63. Authenticated arrival increments loop cleared_count by exactly one.
64. The exact target becomes CLEARED.
65. The candidate bucket no longer contains the cleared target.
66. Target->owner and owner->target reservation truth is released for that assignment.
67. Dispatcher no longer owns that owner and active assignment count reflects completed cleanup.
68. Renderer truth for the cleared cell is alpha 0.
69. Continue real clears until at least one initially blocked non-C08 color becomes reachable and clears through the real production path, with no forced target or M20 fault seam.

## F. Full regression / reproducibility

70. Existing V01 and V02 M21 tests remain enabled.
71. Existing M19/M20 tests remain enabled.
72. Full root suite passes; exact check count is recorded.
73. Dedicated `tests/m21_real_art_smoke.gd` passes from a fresh process with exactly 400 clears, 400 CLEARED, 0 ACTIVE, all five colors encountered, zero candidates/reservations/dispatcher-active/orphan agents and renderer alpha 0 everywhere.
74. The full-smoke finite no-progress/deadlock guard remains present.
75. All currently required M20 queue-free and V04/V05/V07/V08/V09/V10 lifecycle smokes pass.
76. M21 debug scene headless-boots/parses cleanly.
77. M21 level builder rerun reports canonical level/preview/metadata unchanged.
78. M21 reference-composite generator runs twice and second run reports unchanged.
79. Required command outputs contain zero literal `SCRIPT ERROR` and zero literal `Parse Error`.
80. `git diff --check` is clean except any explicitly documented pre-existing owner/local line-ending advisory.
81. Final source blob + SHA-256 are reverified after all work.
82. Final M20 loop/dispatcher blobs are reverified after all work.
83. Headless timing, if recorded, is labeled diagnostic only and is not presented as mobile FPS/GPU proof.

## G. Evidence sensitivity

84. The bare-relative success test would fail if bare-relative preflight were again evaluated outside the project `res://` base.
85. The bare-relative alias test would fail if alias and preflight identities diverged.
86. Preview/metadata conflict tests isolate those specific later-artifact conflicts and prove earlier artifacts remain unchanged/absent.
87. Metadata-directory test is arranged so removing final-object-type preflight would permit an earlier write before the later failure.
88. Fresh candidate-count assertions derive from real committed LevelData/BoardState state rather than hardcoded fake candidates.
89. First-arrival cleanup assertions observe the actual assignment target/owner rather than only aggregate final state.

## H. Handoff

90. Create `coordination/sessions/M21-C001/CLAUDE_LOG_V03.md`.
91. Log exact synchronized starting commit and tracker-only start commit SHA.
92. Log every changed file and confirm no unauthorized production gameplay file changed.
93. Log a criteria/evidence table for the F-M21-STRICT-003 residual and V03 direct-evidence reconciliation.
94. Log every required command and actual result, including failures encountered and corrections made.
95. Log exact final owner-source blob/SHA-256 and M20 locked blobs.
96. At handoff root tracker becomes `M21-C001 V03 / AWAITING_AUDIT / CHATGPT` with progress unchanged and `lastCompletedTaskId=M20-C001-V11`.
97. No M21/UI task checkbox is closed by Claude.
98. Push all authorized work safely to `origin/main` without force.
99. Claude's final response is exactly two lines: `AWAITING_AUDIT` and the direct GitHub blob URL for `coordination/sessions/M21-C001/CLAUDE_LOG_V03.md`.
100. If V03 exposes a genuinely new M19/M20 production defect, stop `BLOCKED`, record exact evidence, and do not opportunistically patch the closed subsystem.

Total numbered criteria: **100**.
