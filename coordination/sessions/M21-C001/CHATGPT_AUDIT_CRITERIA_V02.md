# M21-C001 — Strict Audit Criteria V02

Date: 2026-09-12
Purpose: close the frozen V01 finding set and execute the mandatory AL-035 adversarial validation stage.

V02 is a **correction + validation** pass in the same M21-C001 cycle. It is not permission to redesign Difficulty V1, M19/M20 gameplay, M22 UI, or PixelLab/Art Intelligence.

## A. Governance / scope

1. Work only in `Sekiph82/Scrubbots` on `main`.
2. Safely synchronize with `origin/main` first while preserving all owner/local work.
3. Read `CHATGPT_AUDIT_V01.md`, this criteria, `CHATGPT_PROMPT_V02.md`, `AUDIT_POLICY.md`, `AUDIT_INDEX.md`, and `OWNER_DIFFICULTY_V1_SCOPE_NOTE.md` before edits.
4. Treat F-M21-STRICT-001..004 as the complete frozen pre-correction finding set.
5. Do not create a new unrelated finding/remediation scope unless a genuinely new runtime fact appears.
6. Do not edit M19/M20 production gameplay code.
7. Do not redesign `difficulty_rules.gd` or `production_level_validator.gd`.
8. Do not implement Difficulty Score, CampaignBuilder, Level Factory generation, PixelLab integration, M22+ UI, touch, scoring, win/lose, economy or progression.
9. Do not mutate/re-encode the owner-approved source PNG.
10. Do not close any `SB-M21-*` or `SB-UI-014..016` checkbox; final closure belongs to ChatGPT.
11. Progress remains 304/719 main+ui and 304/943 overall at Claude handoff.
12. Claude authors no audit verdict/file.

## B. Locked identities

13. Owner source path remains exactly `assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png`.
14. Owner source blob remains `b565743ba52699899007882b750b7c8e7cdd00f9`.
15. Owner source SHA-256 remains `ede1e02a9096c4c7ba040b91ed7db2d2c2af3b2e20d5c8774068c8d08ad59899`.
16. M20 CompleteClearingLoop blob remains `06391839523cbc27e88a4b3ef12b730012cd45fa`.
17. M20 ScrubbotDispatcher blob remains `eee10149e4f116af6706beec832042352bf3a6dd`.
18. Generic M09 `scripts/tools/level_importer.gd` semantics remain unchanged unless V02 proves an unavoidable concrete defect and stops BLOCKED before editing it.

## C. F-M21-STRICT-001 — one difficulty identity

19. `normalize_from_level_data` cannot validate one difficulty while emitting another.
20. The M21 compatibility difficulty is derived from one coherent source of truth or an explicit parameter is required to equal `raw.difficulty` before normalization continues.
21. A mismatch between `raw.difficulty` and an explicit compatibility difficulty is rejected before producing normalized LevelData.
22. TEST difficulty is rejected by the production-art normalization boundary.
23. Unknown/empty difficulty is rejected by the production-art normalization boundary.
24. Production validation is not silently skipped for an otherwise successful normalized production result.
25. A direct negative fixture isolates the mismatch case so unrelated palette/dimension failures do not cause the expected rejection.
26. A direct TEST fixture isolates TEST rejection.
27. A direct unknown-difficulty fixture isolates unknown rejection.
28. The valid M21 EASY fixture still normalizes to C01,C03,C08,C11,C16 with identical pixels.
29. No assertion or comment re-locks `20x20 => EASY` or `5 colors => EASY` as future Difficulty V1 design law.

## D. F-M21-STRICT-002 — arbitrary Variant / malformed raw boundary

30. The public normalization entry validates the narrow LevelData contract before any field dereference.
31. `null` returns a normal failed `NormalizeResult`.
32. integer input returns a normal failed `NormalizeResult` without SCRIPT ERROR.
33. string input returns a normal failed `NormalizeResult` without SCRIPT ERROR.
34. Vector2/Vector2i input returns a normal failed `NormalizeResult` without SCRIPT ERROR.
35. a non-LevelData RefCounted/Object input returns a normal failed `NormalizeResult` without SCRIPT ERROR.
36. a partial object that does not expose the required LevelData contract cannot cause a runtime fault.
37. Every invalid raw-input test proves no file write and no mutation of the valid owner source.
38. Valid LevelData behavior remains unchanged.

## E. F-M21-STRICT-003 — deterministic multi-artifact preflight

39. The new builder directly validates its own source/destination alias rules; historical M09 tests alone are not evidence for this new write path.
40. source==output is rejected with source bytes unchanged.
41. source==preview is rejected with source bytes unchanged.
42. source==metadata is rejected with source bytes unchanged.
43. output==preview is rejected.
44. output==metadata is rejected.
45. preview==metadata is rejected.
46. dot-segment / relative-vs-absolute equivalent path aliases are tested where supported by the existing lexical identity policy.
47. overwrite=true never permits source aliasing.
48. existing-different output with overwrite=false rejects before any final artifact mutation.
49. existing-different preview with overwrite=false rejects before output is written/changed.
50. existing-different metadata with overwrite=false rejects before output/preview are written/changed.
51. every enabled destination parent is resolved and checked before any final write.
52. a missing parent for a later preview/metadata destination rejects before an earlier output is written.
53. a non-directory parent rejects before any final write.
54. an existing directory at output path is rejected, including overwrite=true.
55. an existing directory at preview path is rejected, including overwrite=true, before output mutation.
56. an existing directory at metadata path is rejected, including overwrite=true, before output/preview mutation.
57. destination preflight is completed for all enabled artifacts before the first final artifact write.
58. a deliberate later-destination deterministic failure proves prior final files remain byte-for-byte unchanged or absent as appropriate.
59. identical existing artifacts with overwrite=false remain `UNCHANGED` rather than being rewritten.
60. valid overwrite behavior remains deterministic and does not mutate source.
61. no claim is made that software can make unforeseeable hardware/filesystem failure globally atomic; V02 closes deterministic failures knowable before commit.

## F. F-M21-STRICT-004 — reproducible reference evidence

62. A committed minimal debug/test tool or equally durable repository command path regenerates `M21_REFERENCE_COMPOSITE.png` from committed M21 LevelData/renderer truth.
63. The generator does not read the existing composite as its source of truth.
64. The evidence contains deterministic initial, partially-cleared and fully-cleared states over BG01.
65. ACTIVE source pixels and CLEARED alpha-0/background presentation are distinguishable.
66. Output dimensions/panel order are asserted or otherwise deterministic and documented.
67. A second generation reports/produces unchanged output.
68. The exact generation command and actual result are recorded in `CLAUDE_LOG_V02.md`.
69. The output is labeled headless evidence, not a real-device screenshot or FPS/GPU proof.
70. No M22 production UI is introduced by the evidence generator.

## G. Auditor-authored real-art adversarial validation

71. Use a fresh LevelData/BoardState bundle, not state left over from V01 tests.
72. All 400 cells start ACTIVE and exact candidate counts still match owner truth.
73. Snapshot BoardState, candidate buckets, reservation count, dispatcher count and M20 clear count before a blocked non-C08 activation.
74. The blocked non-C08 activation returns exactly `NO_REACHABLE_TARGET`.
75. The complete snapshot is unchanged after that blocked call except the returned failure object/result itself; no hidden gameplay side effect is tolerated.
76. A fresh C08 activation uses real production selector/access/routing/dispatcher/agent collaborators.
77. Reservation exists before arrival and real agent is moving.
78. Authenticated arrival commits exactly one clear and cleans reservation/dispatcher/candidate truth.
79. Continue real production clears until one color that was blocked in the fresh snapshot becomes reachable and succeeds without forced target.
80. The opened color target is ACTIVE before arrival and CLEARED after arrival.
81. V02 does not use M20 candidate/reservation/dispatcher doubles for this authoritative validation.
82. Run the dedicated full 400-cell real-art smoke again from a fresh process/state.
83. The full run ends at exactly 400 loop clears, 400 BoardState CLEARED, 0 ACTIVE.
84. All five colors were cleared at least once.
85. Candidate buckets, reservations and dispatcher active count all end at zero.
86. After frame cleanup there are zero orphan ScrubbotAgents/agent-parent children.
87. All 400 renderer logical pixels end alpha 0 and BG01 remains presentation background, not LevelData palette content.
88. The full-run driver retains a finite no-progress/deadlock guard.

## H. Regression / evidence / sensitivity

89. Add direct V02 tests in the root suite for F-001..003 and the fresh blocked-call snapshot validation.
90. The V02 tests are load-bearing: removing the relevant difficulty-coherence guard would make the mismatch test fail for the intended reason.
91. Removing the malformed-raw contract guard would make its exact test fail rather than be masked by another validation failure.
92. Removing later-destination preflight would make the partial-write preservation test fail for the intended reason.
93. Existing M21 V01 tests remain enabled.
94. Existing M19/M20 tests remain enabled.
95. Full root suite passes with exact check count recorded.
96. Dedicated `tests/m21_real_art_smoke.gd` passes and its elapsed headless diagnostic is recorded without mobile/FPS claims.
97. Required M20 queue-free / lifecycle smokes still pass.
98. M21 debug scene still headless-boots/parses cleanly.
99. Final outputs contain zero literal `SCRIPT ERROR` and zero literal `Parse Error` for the required runs.
100. `git diff --check` is clean except explicitly identified pre-existing owner/local line-ending advisories.
101. Final owner source and protected M20 blobs are reverified after all work.

## I. Handoff

102. `CLAUDE_LOG_V02.md` records exact starting base, changed files, commands, results, failures/fixes and the F-001..004 closure table.
103. The log distinguishes Claude runtime evidence from ChatGPT-independent evidence.
104. No M21/UI checkbox is closed by Claude.
105. Root tracker handoff becomes `M21-C001-V02 / AWAITING_AUDIT / CHATGPT` with progress unchanged.
106. All authorized V02 work is pushed safely to `origin/main` without force.
107. Claude's final response is exactly two lines: `AWAITING_AUDIT` and the direct GitHub blob URL for `coordination/sessions/M21-C001/CLAUDE_LOG_V02.md`.
108. If a genuinely new upstream M19/M20 production defect is exposed, stop `BLOCKED`, record exact evidence and do not opportunistically patch the closed subsystem.

Total numbered criteria: **108**.
