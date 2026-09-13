# M21-C001 — Strict Audit Criteria V06

Date: 2026-09-13
Purpose: close the single frozen V05 evidence residual `R-V05-TALL-001` by exercising a **genuine second/tall 1080×2400 owner-scene layout configuration** and directly re-proving the visible-slot-anchor → board-local route start → real ScrubbotAgent path.

V06 is **validation-only**. V05 production/presentation corrections are accepted and must remain byte-identical unless the genuine tall run exposes an actual defect. If it does, stop `BLOCKED`; do not silently repair production in V06.

## A. Governance / lifecycle

1. Work only in `Sekiph82/Scrubbots` on `main`.
2. Safely synchronize local `main` with `origin/main` first while preserving all owner/local tracked and untracked work.
3. Read root `TASKS.md`, `CLAUDE.md`, `coordination/AUDIT_POLICY.md`, `coordination/AUDIT_INDEX.md`, `CHATGPT_AUDIT_V05.md`, this criteria, `CHATGPT_PROMPT_V06.md`, `CHATGPT_AUDIT_CRITERIA_V05.md`, and `M21_V05_OWNER_PLAYTEST.md` before editing.
4. Treat `R-V05-TALL-001` as the **only** frozen V06 residual.
5. Before validation-file edits, create and push a tracker-only V06 start commit containing only the lifecycle transition to `M21-C001 V06 / IN_PROGRESS / CLAUDE`.
6. Preserve all pre-existing owner/local work. Never reset/restore it merely for cleanliness.
7. No force push.
8. Do not recreate `.hiveai` as a live tracker.
9. Claude authors no ChatGPT audit verdict/file.
10. Claude closes no `SB-M21-*`, `SB-M22-*`, or `SB-UI-*` task checkbox.
11. Progress remains `304/719 = 42.28%` main+ui and `304/943 = 32.24%` overall.
12. `lastCompletedTaskId` remains `M20-C001-V11`.
13. Owner manual visual PASS remains pending; do not request it during V06.
14. V06 is validation-only. Do not make production/presentation changes merely to make the tall-layout test pass.
15. If genuine 1080×2400 execution exposes a real defect, stop `BLOCKED`, preserve exact reproduction evidence, and wait for ChatGPT-scoped correction.

## B. Immutable accepted V05 basis

16. Owner source blob remains `b565743ba52699899007882b750b7c8e7cdd00f9`.
17. M20 `CompleteClearingLoop` blob remains `06391839523cbc27e88a4b3ef12b730012cd45fa`.
18. M20 `ScrubbotDispatcher` blob remains `eee10149e4f116af6706beec832042352bf3a6dd`.
19. TargetSelector blob remains `bb1e48a2a82f6ca4e8962f2a24de60e815c1a945`.
20. V05 owner-scene controller blob remains `66050fe5ec95498a43c6d4abccf62c4d82744d39`.
21. V05 BoardPresentation blob remains `2093df48d367903d332a910dfb3369154831a9ed`.
22. V05 SlotView blob remains `480dffc0ee135150bd3dd2258f002264273ead10`.
23. `project.godot` remains unchanged for V06; do not change the default project viewport just to manufacture evidence.
24. `scripts/**`, `scenes/**`, LevelData, importer/builder, difficulty/validator, routing, agent, dispatcher, clearing and UI production/presentation source remain unchanged in a successful V06 validation-only pass.
25. The accepted bottom-most/left-most TargetSelector policy remains unchanged.
26. The accepted single-mover correction remains unchanged.
27. The accepted visible-slot-anchor mapping remains unchanged.
28. The accepted per-assignment active bookkeeping remains unchanged.
29. The accepted Button signal chain remains unchanged.
30. The accepted AgentLayer cleanup behavior remains unchanged.

## C. Genuine second/tall configuration

31. Add a dedicated frame-aware V06 tall-layout smoke, preferably `tests/m21_v06_tall_layout_smoke.gd`.
32. The test must run in a fresh Godot process.
33. It must create/use the real `scenes/debug/m21_real_art_vertical_slice.tscn` owner-playtest scene.
34. It must establish an actual tall presentation/window/viewport configuration of **1080×2400**, not merely create a `Vector2(1080, 2400)` comparison constant.
35. The mechanism used to establish 1080×2400 must be observed directly after application.
36. The test must assert the actual relevant root/window/viewport/content size used for Control layout is 1080×2400, or otherwise directly prove the scene is laid out under that real second configuration.
37. Do not satisfy criterion 36 by asserting the same value that was only assigned to a local variable.
38. Await enough process/layout frames after changing the tall configuration for Control layout/global transforms to settle.
39. The test must distinguish the tall configuration from the canonical default `1080×2160` configuration.
40. The committed default `project.godot` must not be edited merely to make V06 tall validation possible.

## D. Tall-layout visible geometry proof

41. After the real tall configuration and layout frames, observe exactly five real SlotView instances.
42. Read each slot's actual laid-out global rect from the real scene.
43. Prove all five slot rects are inside the actual tall content/viewport bounds.
44. Prove no slot rect has negative position or extends beyond the actual tall bounds.
45. Observe the actual BoardRenderer/presentation display rect/region rather than using only duplicated design constants when practical.
46. Prove the visible slot bar does not overlap/cover the displayed board region in the tall configuration.
47. Prove the board remains inside/visible in the tall presentation.
48. Do not claim M44 full responsive UI completion; this is only a focused V06 sanity configuration.
49. Do not invent safe-area/notch behavior beyond the current owner-playtest scene contract.

## E. Tall-layout anchor → real agent start proof

50. Select a reachable visible slot through the real V05 owner scene after the tall layout has settled; C08/slot 2 is acceptable on the fresh Hazard Bot.
51. Obtain that SlotView's actual `get_spawn_anchor_global()` value **after** the genuine tall layout.
52. Map that exact global anchor through the real `BoardPresentation.global_to_board_local()` inverse.
53. Trigger the visible-slot gameplay path under the tall configuration.
54. Prefer the same load-bearing Button signal chain accepted in V05; direct `request_slot()` alone is insufficient as the only tall activation evidence.
55. A successful result must contain a real production ScrubbotAgent parented under AgentLayer.
56. Prove `agent.spawn_origin` equals the mapped tall-layout slot anchor within explicit tolerance.
57. Prove the agent's initial global position equals the actual tall-layout visible slot anchor within explicit tolerance.
58. Prove the real route's first point equals that mapped board-local start within explicit tolerance.
59. Prove the route/assignment target is the target selected through the real production path; do not force target identity.
60. Prove the final transformed agent position agrees with `BoardRenderer.get_cell_center_global()` for the actual selected target within explicit tolerance.
61. Prove authenticated arrival still clears exactly that target through M20, not via test-side BoardState mutation.
62. Pump enough frames to resolve deferred cleanup and prove AgentLayer has zero ScrubbotAgent children afterward.

## F. Anti-proxy / sensitivity requirements

63. The V06 test must fail if the actual tall-configuration step is removed and the process remains at 1080×2160.
64. The V06 test must fail if the test merely changes a local bounds constant to 1080×2400 while leaving the actual scene layout at 1080×2160.
65. The V06 test must fail if the slot anchor → board-local inverse transform is removed/bypassed.
66. The V06 test must fail if a hardcoded old left-edge start is substituted for the mapped slot anchor.
67. The V06 test must fail if the clicked slot uses another slot's anchor.
68. The V06 test must fail if Button-to-scene activation wiring is broken.
69. The V06 test must directly record the actual default/reference size and actual tall size used during the validation so the two configurations cannot be conflated.
70. If changing root/window size is unreliable under headless Godot, use another **real** mechanism that produces and directly observes the second layout configuration. Document the engine behavior and prove the resulting Control geometry/configuration is genuinely distinct from the default. A larger comparison rectangle alone is forbidden.

## G. Preserve previously accepted evidence

71. Existing V05 single-mover root-suite tests remain enabled and passing.
72. Existing V05 same-slot concurrency tests remain enabled and passing.
73. Existing V05 cross-slot active-state tests remain enabled and passing.
74. Existing V05 Button signal-path test remains enabled and passing.
75. Existing V05 frame-aware anchor/cleanup smoke remains enabled and passing.
76. Existing V04 target-priority tests remain enabled and passing.
77. Existing V04 preview-directory false/true evidence remains enabled and passing.
78. M21 V01/V02/V03 tests remain enabled and passing.
79. Existing M18 agent tests remain enabled and passing.
80. Existing M19 strict dispatcher tests/smokes remain enabled and passing.
81. Existing M20 complete-clearing/lifecycle/queue-free tests/smokes remain enabled and passing.
82. `tests/m21_real_art_smoke.gd` still reaches exactly 400 clears with exact clean final state.
83. The M21 owner scene still headless-boots/parses cleanly.
84. Required outputs contain zero literal `SCRIPT ERROR` and zero literal `Parse Error`.
85. Root suite passes with exact check count recorded.
86. `git diff --check` is clean except explicitly documented pre-existing owner/local advisories.

## H. Exact source immutability checks

87. Recheck owner source Git blob after all V06 work.
88. Recheck M20 loop blob after all V06 work.
89. Recheck M20 dispatcher blob after all V06 work.
90. Recheck TargetSelector blob after all V06 work.
91. Recheck V05 owner-scene controller blob after all V06 work.
92. Recheck V05 BoardPresentation blob after all V06 work.
93. Recheck V05 SlotView blob after all V06 work.
94. Show a Git diff/file list proving successful V06 did not change `scripts/**`, `scenes/**`, or `project.godot`.

## I. Evidence / handoff

95. Create `coordination/sessions/M21-C001/CLAUDE_LOG_V06.md`.
96. Log synchronized starting HEAD and the tracker-only V06 start commit SHA.
97. Log exactly how the genuine 1080×2400 layout was established and directly observed.
98. Log the actual default/reference size and actual tall size observed at runtime.
99. Log a concrete tall-layout tuple: slot id/color, actual slot anchor global, mapped board-local start, agent.spawn_origin, route first point, target index/coordinate, agent initial global, target-cell global, and cleanup result.
100. Log every required command and actual result, including failed attempts/corrections.
101. Log exact post-run protected blob rechecks.
102. At handoff set root tracker to `M21-C001 V06 / AWAITING_AUDIT / CHATGPT`; progress and lastCompleted remain unchanged.
103. Push all authorized validation-only work safely to `origin/main` without force.
104. Claude's final response is exactly two lines: `AWAITING_AUDIT` and the direct GitHub blob URL for `coordination/sessions/M21-C001/CLAUDE_LOG_V06.md`.
105. If genuine tall execution exposes a real production/presentation defect, do **not** patch it in V06. Set handoff to `BLOCKED`, document the exact reproduction and which accepted source would need change, push evidence only, and return `BLOCKED` plus the direct log URL.

Total numbered criteria: **105**.
