# M21-C001 - Strict Audit Criteria V05

Date: 2026-09-13
Purpose: correct the frozen V04 owner-playtest presentation findings without reopening accepted M21 gameplay/art work, then produce a genuinely owner-playable scene suitable for independent audit and manual owner acceptance.

V05 is a focused correction + adversarial validation pass. The frozen finding set is exactly:

- `F-M21-V04-001` real ScrubbotAgent double-driven by the owner-scene controller;
- `F-M21-V04-002` visible SlotView geometry not mapped to the real agent/RouteRequest start;
- `F-M21-V04-003` singular active UI bookkeeping inconsistent with allowed concurrent assignments;
- `F-M21-V04-004` missing/proxy direct evidence for slot mapping, second portrait, actual UI activation path, and AgentLayer cleanup.

No new finding should be silently folded into unrelated architecture. If implementation exposes a genuine accepted-upstream M19/M20 defect, stop `BLOCKED` with exact evidence.

## A. Governance / lifecycle

1. Work only in `Sekiph82/Scrubbots` on `main`.
2. Safely synchronize local `main` with `origin/main` first while preserving every pre-existing tracked/untracked owner/local change.
3. Read `CLAUDE.md`, root `TASKS.md`, `coordination/AUDIT_POLICY.md`, `coordination/AUDIT_INDEX.md`, `CHATGPT_AUDIT_V04.md`, this criteria, `CHATGPT_PROMPT_V05.md`, and `OWNER_PLAYTEST_DECISIONS_V04.md` before implementation edits.
4. Treat `CHATGPT_AUDIT_V04.md` F-M21-V04-001..004 as the complete frozen V05 correction set.
5. Before implementation edits, create/push a tracker-only V05 start commit containing only the lifecycle change to `M21-C001 V05 / IN_PROGRESS / CLAUDE`.
6. Preserve all owner/local work; never reset/restore it merely to get a clean tree.
7. No force push.
8. Do not recreate `.hiveai` as a live tracker.
9. Claude authors no ChatGPT audit verdict/file.
10. Claude closes no M21/M22/UI task checkbox at handoff.
11. Progress remains 304/719 main+ui and 304/943 overall at handoff.
12. `lastCompletedTaskId` remains `M20-C001-V11` at handoff.
13. Do not ask the owner for final manual PASS during implementation; manual owner acceptance occurs only after independent ChatGPT V05 audit.
14. Do not generate Magnific/Higgsfield/speculative art.
15. Do not invent final M27 Scrubbot character art.
16. Do not implement Home/Results/economy/progression/win-lose/audio/haptics/boosters as side work.
17. Do not redesign Difficulty V1, Level Factory, content pipeline, or catalog systems.
18. If a required correction can be made in the V04 presentation/controller/UI/test/doc surface, do not touch accepted M19/M20 production gameplay.
19. Keep the V04 implementation log historical; create a new `CLAUDE_LOG_V05.md`.
20. Record every failed validation attempt and its correction truthfully in the V05 log.

## B. Preserve accepted source and gameplay basis

21. Owner source path remains `assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png`.
22. Owner source blob remains `b565743ba52699899007882b750b7c8e7cdd00f9`.
23. Owner source SHA-256 remains `ede1e02a9096c4c7ba040b91ed7db2d2c2af3b2e20d5c8774068c8d08ad59899`.
24. M20 `CompleteClearingLoop` blob remains `06391839523cbc27e88a4b3ef12b730012cd45fa` unless V05 stops BLOCKED before any edit.
25. M20 `ScrubbotDispatcher` blob remains `eee10149e4f116af6706beec832042352bf3a6dd` unless V05 stops BLOCKED before any edit.
26. Generic M09 importer remains unchanged.
27. `ProductionArtLevelBuilder` V03 path/identity behavior remains unchanged.
28. V04 preview-destination-directory `overwrite=false` and `overwrite=true` direct tests remain enabled and passing.
29. Canonical M21 LevelData remains pixel-equivalent to approved source.
30. ACTIVE/CLEARED semantics remain unchanged.
31. C01/C03/C08/C11/C16 M21 palette truth remains unchanged.
32. Slot gameplay truth remains owned by `SlotSystem`, exactly five slots.
33. TargetSelector current production policy remains bottom-most targetable row first, then left-most, deterministic tie break.
34. Preserve TargetSelector blob semantics introduced in V04; any source edit to TargetSelector requires explicit necessity and full M15 strict regression review.
35. All M15 strict-v2 reentry/coherence/reservation/rollback protections remain intact.
36. Routing remains HOW only; no retargeting or UI geometry policy enters RoutingSystem.
37. ScrubbotAgent remains movement-only in board-local cell units.
38. BoardRenderer remains presentation-only and does not select targets.
39. BoardPresentation remains a presentation-only board/agent transform boundary.
40. SlotView remains a presentation component and must not gain mutable SlotState/SlotSystem ownership.

## C. F-M21-V04-001 - single movement owner

41. A real production ScrubbotAgent remains self-processing through its own `_process(delta)` -> `advance(delta)` contract.
42. The owner scene/controller must not call `advance()` on a real self-processing ScrubbotAgent during ordinary frame processing.
43. The owner scene/controller must not multiply frame delta by speed or another movement multiplier.
44. Exactly one component owns frame-to-frame position advancement for a production ScrubbotAgent: the agent itself.
45. The owner scene may observe agent state, owner id, slot id, lifecycle, or cleanup status without driving position.
46. Do not disable `ScrubbotAgent._process()` to make the controller the mover.
47. Do not change canonical ScrubbotAgent speed semantics merely to compensate for the V04 double-drive.
48. Route points remain board-local and unchanged by this correction.
49. AgentLayer transform remains presentation-only.
50. Authenticated arrival remains the clear authority; removing the parent double-drive must not introduce direct clear logic.
51. A direct sensitivity test calls/executes the owner controller's frame observer while an agent is MOVING and proves the controller itself does not change the agent's board-local position/progress.
52. The sensitivity test would fail against V04 because V04 controller `_process` advances the active agent.
53. A direct agent movement test advances one canonical agent frame/step once and proves distance/progress follows exactly one `speed * delta` application.
54. The movement test uses a route long enough that the chosen delta does not complete the route, so speed can be observed rather than hidden by endpoint clamping.
55. At least one test uses the actual M21 owner-scene/controller + real ScrubbotAgent, not only an isolated fake mover.
56. A real scene/frame smoke demonstrates the marker remains visibly in flight for a nonzero interval on a sufficiently long route rather than teleporting immediately because of a second controller tick.
57. Existing M18 lifecycle/movement tests remain enabled.
58. Existing M19 dispatcher tests remain enabled.
59. Existing M20 authenticated-arrival tests remain enabled.
60. No production M18/M19/M20 source change is required to close F-001 unless V05 stops BLOCKED with a proven upstream defect.

## D. F-M21-V04-002 - visible slot anchor maps to real route start

61. Remove independent slot-id-only hardcoded route-origin synthesis as the authority for visible slot activations.
62. Define one explicit presentation spawn anchor for every SlotView.
63. The spawn anchor is derived from actual laid-out SlotView geometry, not from a parallel slot-id row formula.
64. A reasonable anchor such as top-center/center is acceptable if documented and visually coherent.
65. SlotView may expose a narrow presentation-only anchor query; it must not expose gameplay SlotState.
66. Obtain the visible slot anchor in the scene's real global/canvas presentation coordinates after layout.
67. Convert that exact presentation anchor into AgentLayer/BoardPresentation board-local units through the real transform inverse.
68. Use the mapped board-local value as the `start_position` passed into `CompleteClearingLoop.activate_slot` for that visible activation.
69. The resulting RouteRequest start position therefore comes from the visible slot anchor, not from duplicated constants.
70. The mapped board-local point may lie outside board bounds when the visible slot is outside the board; routing's existing exterior-origin semantics remain authoritative.
71. Do not pass raw screen pixels directly into RoutingSystem as board-local units.
72. Do not move UI coordinate math into TargetSelector, RoutingSystem, ScrubbotDispatcher, or ScrubbotAgent.
73. Do not hardcode an unrelated left-edge spawn while the visible SlotView is below the board.
74. AgentLayer remains the parent of real owner-scene dispatched agents.
75. A successful dispatch records `agent.spawn_origin` equal to the mapped board-local slot anchor within explicit tolerance.
76. At dispatch start, the real agent's global position agrees with the visible SlotView spawn anchor global position within explicit tolerance.
77. The route result begins at the same board-local mapped start.
78. The route ends at the selected target center as before.
79. At arrival, transformed agent global position agrees with BoardRenderer target-cell center within explicit tolerance.
80. The mapping works for all five visible slots, not only slot 2/C08.
81. The mapping works at the M21 reference portrait viewport.
82. At least one second/tall portrait configuration proves the mapping is derived from layout and still coherent when presentation geometry changes.
83. The mapping uses the actual Control layout result after necessary frame/layout processing.
84. A direct test must fail if visible SlotView geometry moves but the route start remains a hardcoded old constant.
85. A direct test must fail if the transform conversion is removed.
86. A direct test must fail if slot N accidentally uses slot M's anchor.
87. No logical LevelData cell/color truth is modified by the mapping.
88. No route target identity is changed by presentation anchor mapping.
89. Update current owner-playtest guide to describe the visible slot anchor and actual agent departure point accurately.
90. Preserve the broad canonical gameplay/five-slot reference direction without flattening/copying it into runtime UI.

## E. F-M21-V04-003 - concurrency-correct active presentation

91. Do not introduce a new global single-active-agent gameplay rule to make UI bookkeeping easier.
92. Preserve current M19 ability to own multiple simultaneous active assignments when canonical dispatch allows them.
93. Remove singular presentation authority that can represent only one `_active_agent` / `_active_slot` for the whole scene.
94. Track owner-scene presentation lifecycle per real successful assignment.
95. Each tracked assignment retains enough detached identity to associate owner/agent with the originating slot id.
96. Maintain per-slot in-flight count/set derived from tracked assignments.
97. A successful visible activation increments/adds exactly one assignment for its slot.
98. A failed/no-work activation adds no active assignment and does not highlight the slot.
99. Slot active visual is true iff that slot has one or more currently tracked in-flight assignments.
100. Completion of assignment A removes only A from presentation bookkeeping.
101. Completion of A must not clear the highlight if assignment B for the same slot remains in flight.
102. Completion of slot A's assignment must not clear slot B's highlight.
103. Multiple assignments from the same slot are represented correctly when canonical gameplay permits them.
104. Multiple assignments from different slots are represented correctly when reachability permits them.
105. UI completion observation must not become clear authority and must not mutate BoardState/ReservationState directly.
106. Connecting a benign presentation observer to `agent_completed` is acceptable if gameplay authority remains with M19/M20.
107. Presentation tracking handles a real agent that becomes invalid/queued for deletion without dereferencing stale objects.
108. Reset/scene cleanup clears presentation tracking deterministically.
109. After reset/cleanup and deferred frees, every SlotView active visual is false.
110. After reset/cleanup and deferred frees, AgentLayer has no ScrubbotAgent children.
111. Presentation bookkeeping does not own/resurrect agents.
112. Presentation bookkeeping does not cancel a healthy assignment merely for UI state reasons.
113. Rapid repeated activation cannot duplicate one target/owner reservation.
114. Same-slot rapid activation test proves two distinct successes, if both allowed, have distinct owner and target identities.
115. Same-slot test then completes one assignment while leaving the other moving and proves slot remains active.
116. Same-slot final completion proves slot becomes inactive only after the last assignment resolves.
117. Cross-slot test creates two concurrently active slots after arranging real reachability and proves both highlights are independently true.
118. Completing one cross-slot assignment leaves the other slot active.
119. Completing/resetting the remainder clears only the appropriate remaining presentation state.
120. Existing dispatcher active-count/reservation/candidate cleanup remains canonical and green.

## F. F-M21-V04-004 - direct evidence and sensitivity

121. Replace the V04 criterion-126 proxy/self-comparison with the real visible-slot-anchor -> mapped board-local start -> agent start proof from section D.
122. Add a second/tall portrait sanity test distinct from the 1080x2160 reference case.
123. A suitable second case is 1080x2400 or another repository-canonical tall portrait target.
124. The tall case proves all five slot rects are visible/in content bounds.
125. The tall case proves board remains visible/readable and is not covered by the slot bar.
126. The tall case proves slot-anchor -> agent-start transform remains correct.
127. Add a real SlotView activation-path test that does not call `request_slot()` directly as its activation stimulus.
128. The activation test exercises the actual Button/input/signal chain into `slot_activated` and the scene handler.
129. Prefer a real `InputEventMouseButton` routed through the Viewport at the visible slot center when reliable under headless Godot.
130. If Godot headless GUI routing prevents a trustworthy mouse event, additionally prove the actual BaseButton `pressed` signal -> SlotView `_on_pressed` -> `slot_activated` -> scene handler chain, and document the engine limitation; direct `request_slot()` alone is not acceptable.
131. The activation-path test proves a reachable slot produces a real DispatchResult/agent through CompleteClearingLoop.
132. The activation-path test proves the requested color matches the clicked visible slot's real SlotSystem palette id.
133. Add direct AgentLayer child-count evidence after authenticated arrival and deferred cleanup.
134. Pump/process the necessary frame(s) so `queue_free()` is actually resolved before asserting zero child agents.
135. Add direct AgentLayer no-orphan evidence after dispatcher/loop reset/scene teardown path used by the V05 harness.
136. Tests must be sensitive to removed/broken slot signal wiring.
137. Tests must be sensitive to reinstating V04 hardcoded slot origins.
138. Tests must be sensitive to reinstating V04 parent-driven `agent.advance(delta * 6.0)`.
139. Tests must be sensitive to singular active-slot bookkeeping under two active assignments.
140. Do not count comments/log statements as direct runtime evidence.
141. Preserve V04 bottom-most/left-most sensitivity tests.
142. Preserve V04 blocked/reserved target-priority tests.
143. Preserve V04 rectangular target-priority test.
144. Preserve V04 malformed candidate-entry safety test.
145. Preserve V04 fresh M21 first-C08 authoritative targetability proof.

## G. Reference and owner-playtest readiness

146. V05 log explicitly names the existing canonical gameplay/five-slot owner reference already recorded in repository inventory/tasks.
147. Record what broad slot layout guidance was taken from it and what was intentionally not copied.
148. Do not treat a reference screenshot as flattened production UI.
149. Do not generate new decorative art for V05.
150. Create `coordination/sessions/M21-C001/M21_V05_OWNER_PLAYTEST.md`.
151. The V05 guide supersedes V04 as the current manual run guide but leaves V04 historical.
152. Guide gives exact scene path and F6/current-scene steps.
153. Guide lists the five slot palette colors truthfully.
154. Guide explains bottom-most then left-most currently targetable selection.
155. Guide explains the marker is functional/debug art, not final M27 character art.
156. Guide states the marker now departs from the actual visible clicked slot anchor via presentation mapping.
157. Guide tells owner to try rapid clicks on the same slot and different reachable slots and observe independent active highlights without disappearing/stuck states.
158. Guide tells owner that a no-reachable-work color correctly spawns nothing and clears nothing.
159. Guide tells owner what visual polish remains intentionally deferred.
160. Guide does not claim automated evidence equals owner visual PASS.

## H. Regression / exact identity

161. Root suite remains fully enabled and passes, with exact count recorded.
162. V04's 4580-check baseline is preserved or increased; no prior passing strict test is deleted/disabled to get green.
163. Dedicated `tests/m21_real_art_smoke.gd` passes from a fresh process with exactly 400 clears and exact clean final state.
164. Existing M15 strict tests pass.
165. Existing M16/M17 routing tests pass.
166. Existing M18 agent lifecycle/movement tests pass.
167. Existing M19 strict dispatcher tests/smokes pass.
168. Existing M20 lifecycle/queue-free smokes pass.
169. M21 V01/V02/V03/V04 tests remain enabled, with intentionally superseded V04 proxy assertions replaced rather than silently deleted.
170. M21 owner scene headless boots/parses cleanly.
171. Required test/scene outputs contain zero literal `SCRIPT ERROR` and zero literal `Parse Error`.
172. M21 level builder deterministic rerun remains UNCHANGED.
173. M21 reference composite deterministic rerun remains UNCHANGED.
174. Owner source blob and SHA-256 are reverified after all work.
175. M20 loop/dispatcher blobs are reverified after all work.
176. Any headless timing remains diagnostic only, never mobile FPS/GPU proof.
177. `git diff --check` is clean except explicitly identified pre-existing owner/local advisories.
178. No `.godot`/cache/build junk or `.uid` sidecars are committed accidentally.
179. No current owner/local unstaged work is swallowed into the V05 commit.
180. Final changed-file list is narrow and explained.

## I. Handoff evidence

181. Create `coordination/sessions/M21-C001/CLAUDE_LOG_V05.md`.
182. Log synchronized starting head.
183. Log tracker-only V05 start commit SHA.
184. Log exact implementation/handoff commit SHA(s) that exist at log-writing time without inventing self-referential final-SHA evidence.
185. Log every changed file and why.
186. Include a frozen finding -> correction -> direct evidence table for F-M21-V04-001..004.
187. For F-001, show exact evidence that controller observation no longer moves the real agent.
188. For F-002, record one actual clicked slot's visible global anchor, mapped board-local start, agent spawn_origin, and agent global start comparison.
189. For F-003, record same-slot and cross-slot concurrent active-state lifecycle evidence.
190. For F-004, record the actual signal/input path, tall portrait case, and AgentLayer post-cleanup child count.
191. Log exact root-suite count/result.
192. Log fresh 400-cell smoke result.
193. Log all required M20 smokes.
194. Log scene boot result.
195. Log deterministic builder/composite reruns.
196. Log protected source/M20 blob rechecks.
197. Distinguish automated/headless evidence from pending owner manual visual acceptance.
198. At handoff set root tracker to `M21-C001 V05 / AWAITING_AUDIT / CHATGPT` without closing M21/M22/UI rows or changing progress.
199. Push all authorized work to `origin/main` without force.
200. Claude final response is exactly two lines: `AWAITING_AUDIT` and the direct GitHub blob URL for `coordination/sessions/M21-C001/CLAUDE_LOG_V05.md`.
201. If correction requires editing accepted M19/M20 production because of a newly proven upstream defect, stop `BLOCKED`, document reproduction and wait for ChatGPT-scoped remediation.

Total numbered criteria: **201**.
