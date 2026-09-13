# M21-C001 — Strict Audit Criteria V04

Date: 2026-09-13
Purpose: integrate the owner's first live Godot playtest decisions, preserve the accepted M21 production-art/gameplay chain, close the single V03 evidence-only residual, and produce a genuinely owner-playable five-slot real-art vertical slice suitable for M21 final strict closure.

V04 is a **focused owner-playtest integration + final validation pass**. It is broader than V03 because the owner supplied new runtime facts and explicit gameplay/presentation decisions after manually running the scene. It is not permission to redesign unrelated systems.

## A. Governance / lifecycle

1. Work only in `Sekiph82/Scrubbots` on `main`.
2. Safely synchronize local `main` with `origin/main` first while preserving all pre-existing owner/local tracked and untracked work.
3. Read root `TASKS.md`, `CLAUDE.md`, `coordination/AUDIT_POLICY.md`, `coordination/AUDIT_INDEX.md`, `CHATGPT_AUDIT_V03.md`, this criteria, `CHATGPT_PROMPT_V04.md`, and `OWNER_PLAYTEST_DECISIONS_V04.md` before editing implementation files.
4. Treat `OWNER_PLAYTEST_DECISIONS_V04.md` as owner-locked truth for this pass.
5. Before implementation, create and push a **tracker-only V04 start commit** containing only the root `TASKS.md` lifecycle transition to `M21-C001 V04 / IN_PROGRESS / CLAUDE`; do not mix implementation changes into that commit.
6. Preserve all accepted V01/V02/V03 production-art corrections unless a concrete contradiction is discovered.
7. Do not redesign Difficulty V1, Level Factory, CampaignBuilder, PixelLab/Art Intelligence, content publishing, progression, win/lose, economy, Home, Results, audio, haptics or unrelated future UI.
8. Do not generate speculative Magnific artwork for this pass.
9. Do not replace the owner-approved Hazard Bot source art.
10. Do not invent final Scrubbot character artwork; the existing debug marker is sufficient for the V04 movement-visibility proof.
11. Do not merge TargetSelector and RoutingSystem responsibilities.
12. Do not move board-space/screen-space presentation math into routing truth.
13. Do not opportunistically rewrite M19/M20 dispatcher/clearing code. If an actual upstream defect makes the owner-playtest integration impossible, stop `BLOCKED` with exact evidence rather than drive-by patching accepted production.
14. Do not close M21/M22/UI task checkboxes merely because Claude implemented code; independent ChatGPT audit owns closure.
15. Progress and `lastCompletedTaskId` remain at the pre-V04 audited values at Claude handoff unless the V04 prompt explicitly authorizes only lifecycle wording changes.
16. Claude authors no ChatGPT audit verdict/file.

## B. Locked identities / accepted M21 basis

17. Owner source path remains exactly `assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png`.
18. Owner source Git blob remains `b565743ba52699899007882b750b7c8e7cdd00f9`.
19. Owner source SHA-256 remains `ede1e02a9096c4c7ba040b91ed7db2d2c2af3b2e20d5c8774068c8d08ad59899`.
20. M20 `CompleteClearingLoop` blob remains `06391839523cbc27e88a4b3ef12b730012cd45fa` unless the pass stops BLOCKED before any edit to it.
21. M20 `ScrubbotDispatcher` blob remains `eee10149e4f116af6706beec832042352bf3a6dd` unless the pass stops BLOCKED before any edit to it.
22. Generic M09 importer remains unchanged.
23. M21 `ProductionArtLevelBuilder` V03 physical-path semantics remain intact.
24. V02 difficulty-identity and arbitrary-Variant fail-closed behavior remain intact.
25. V02 reproducible M21 reference-composite generator remains intact.
26. Canonical M21 LevelData remains pixel-equivalent to the approved source.
27. Initial exact candidate counts remain C01=30, C03=5, C08=298, C11=11, C16=56.
28. All 400 logical cells still begin ACTIVE.
29. ACTIVE/CLEARED semantics remain ACTIVE=source color/opaque and CLEARED=alpha 0 revealing BG01.
30. Five-slot model truth remains owned by `SlotSystem`; presentation must not create a parallel gameplay slot model.

## C. V03 evidence-only residual

31. Add a direct new-builder test where the **preview destination is an existing directory and `overwrite=false`**.
32. The preview-directory false-mode case rejects before output or metadata mutation.
33. Preserve/directly retain preview-directory `overwrite=true` rejection.
34. Both preview-directory modes use the real M21 production-art builder, not only historical generic M09 importer tests.
35. Owner source remains unchanged across both cases.
36. The test is load-bearing on destination object-type preflight, not rejected first for an unrelated alias/missing-parent/difficulty error.

## D. Owner-locked TargetSelector priority

37. Target eligibility remains valid index + ACTIVE + requested color + unreserved + authoritative targetable/reachable truth.
38. Positional priority is applied **only among candidates that can otherwise proceed under TargetSelector's canonical contract**.
39. Primary priority is largest board-local `y` coordinate: bottom-most first.
40. Secondary priority within equal `y` is smallest board-local `x`: left-most first.
41. Any final tie is deterministic.
42. The previous ascending-row-major-first policy is removed from current comments/docs/tests as current design truth.
43. The new rule does not make an unreachable bottom-most/left-most cell selectable.
44. If the geometric first candidate is blocked, the selector tries the next candidate in bottom-most/left-most deterministic priority.
45. If the geometric first candidate is already reserved, it is skipped and the next eligible candidate can win.
46. If an entire bottom row is unavailable, selection proceeds to the next row upward.
47. The policy works on rectangular boards.
48. The policy works at the canonical maximum dimensions where the selector benchmark applies.
49. Candidate coordinate conversion uses canonical BoardState geometry (`get_cell_position` or an equivalently centralized API), not a new contradictory index formula scattered through presentation code.
50. Selection remains deterministic across identical state/candidate/access inputs.
51. No target-priority behavior is added to RoutingSystem.
52. RoutingSystem receives exactly the target already selected/reserved by TargetSelector.
53. No BoardRenderer target-selection responsibility is added.
54. No ScrubbotAgent target-selection responsibility is added.

## E. Preserve TargetSelector strict-v2 safety while changing order

55. Existing bind category/coherence validation remains intact.
56. Existing selection re-entry guard remains intact.
57. Existing bind re-entry guard remains intact.
58. Existing bind-generation snapshot/drift protection remains intact.
59. Existing candidate/reservation exact-board coherence checks remain intact.
60. Existing owner-already-reserved rejection remains intact.
61. Existing malformed reserved-snapshot fail-closed behavior remains intact.
62. Existing malformed candidate-list fail-closed behavior remains intact.
63. Existing malformed candidate entry handling remains safe and non-crashing.
64. Existing invalid index / CLEARED / wrong-color rejection remains intact.
65. Existing malformed `is_reserved` verdict behavior remains fail-closed.
66. Existing targetability callback category/verdict validation remains intact.
67. Operation coherence is still rechecked after external callbacks.
68. Existing same-owner side-effect protection remains intact.
69. Existing exact-pair rollback behavior remains intact.
70. Existing reserve-return type validation remains intact.
71. Existing post-reserve exact ownership proof remains intact.
72. No sorting/reordering implementation may widen a collaborator trust boundary or expose mutable internal state.
73. Target ordering must not mutate the raw candidate index or BoardState.
74. Existing M15 strict regression tests remain enabled; update only expectations that intentionally encode the superseded row-major selection policy.
75. Add sensitivity evidence showing that restoring ascending row-major order would make the new bottom-left tests fail.

## F. Target priority direct tests

76. A synthetic/open board with multiple reachable same-color candidates proves the bottom-most row wins over higher rows.
77. Two reachable candidates on the same lowest row prove the left-most wins.
78. A lower-left candidate that is blocked proves the next reachable candidate is selected instead.
79. A lower-left candidate that is reserved proves the next eligible candidate is selected instead.
80. A lower row whose candidates are all unavailable proves the selector climbs one row and selects that row's left-most reachable candidate.
81. A rectangular board fixture proves the rule is coordinate-based and not square-board-specific.
82. A candidate array deliberately presented in a non-priority/randomized order still yields bottom-most/left-most selection.
83. Duplicate/malformed candidate entries do not produce duplicate reservation or crash.
84. Same state repeated with a fresh owner produces deterministic priority when reservations are reset appropriately.
85. M21 fresh-board direct assertion records the coordinate of the first selected C08 target and proves no targetable C08 candidate has a larger `y`, or the same `y` with a smaller `x`.
86. The M21 assertion is based on actual authoritative targetability, not merely raw perimeter membership.
87. A blocked lower candidate on a purpose-built test cannot beat a reachable higher candidate merely because it has a larger y.

## G. Shared board/agent presentation transform

88. ScrubbotAgent production movement remains in board-local cell units.
89. RouteRequest / RouteResult coordinate truth remains board-local, not display pixels.
90. Introduce a presentation-only agent layer/shared transform, or an equivalent architecture proven to align exactly with BoardRenderer.
91. The dispatcher in the owner-playable scene is bound with an explicit live agent parent suitable for presentation; it must no longer rely on an unscaled root/default parent for the visible scene.
92. The board and AgentLayer use the same board origin in display space.
93. AgentLayer scale maps exactly one board-local cell unit to the BoardRenderer's current cell-size in display space, or an equivalent mapping is used.
94. Renderer aspect-ratio preservation remains unchanged.
95. Rectangular board presentation is not broken by the shared transform.
96. A real dispatched agent is visibly larger than a sub-pixel speck at the M21 reference playtest size.
97. The debug marker remains presentation-only and does not become a logical board cell/color/resource.
98. The real agent starts at the route's real start position in board-local truth.
99. The real agent visually appears at the corresponding transformed start position.
100. The real agent's transformed final center agrees with the selected target's BoardRenderer cell center within an explicit tolerance.
101. Clearing still occurs only on authenticated arrival, not merely because the visual reaches an approximate screen point.
102. Agent cleanup/despawn remains intact after arrival.
103. Reset/cancel behavior leaves no orphan visible agent nodes.
104. Presentation transformation does not alter reservation, target, route, arrival or clearing identity.

## H. Agent presentation direct tests

105. A direct test compares a dispatched agent's board-local start transformed through AgentLayer with the expected screen/global start presentation.
106. A direct test compares final transformed agent position with `BoardRenderer.get_cell_center_global()` or an equivalent authoritative renderer position for the actual selected target.
107. Test uses a real production route and real ScrubbotAgent, not a fake mover.
108. Test observes actual scene/global presentation coordinates, not only local route coordinates.
109. At least one test exercises a non-unit cell size.
110. At least one test exercises a rectangular board or proves transform math is width/height independent.
111. Debug M21 scene headless smoke confirms AgentLayer exists and is the parent/presentation container for the real dispatched agent.
112. After completion/frame cleanup, AgentLayer has no orphan ScrubbotAgent children.

## I. Five visible slot presentation

113. Implement/reuse a production-compatible `SlotView`-style native Godot component rather than five one-off hardcoded debug draw calls.
114. Exactly five slot components are visible in the M21 owner-playable scene.
115. Slot views are bound to the canonical SlotSystem scalar/query truth, not their own independent palette/availability/activity model.
116. Each visible slot clearly communicates its bound palette color from the actual M21 local palette.
117. Slot UI does not add colors to LevelData and does not change logical artwork palette counts.
118. Dynamic state/color is rendered by Godot UI, not baked into a flattened screenshot.
119. A desktop mouse/click activation path exists for owner playtesting now.
120. Clicking a visible slot requests work through the existing `CompleteClearingLoop` / dispatcher path.
121. Slot click does not directly mutate BoardState or BoardRenderer.
122. Slot click does not bypass TargetSelector or ReservationState.
123. Slot click does not force a target index.
124. The visible slot's bound palette ID is exactly the color ID sent into the canonical gameplay request.
125. A visible slot has a coherent spawn/origin presentation used to derive or map the Scrubbot route start.
126. Route start used by gameplay corresponds to the clicked slot's visible spawn position through the defined board/display transform contract.
127. Active/in-flight state is visibly distinguishable on the clicked slot while its real assignment is active.
128. Active state clears/restores after assignment completion/failure according to the implemented narrow V04 behavior.
129. Five visible slots remain on screen and readable with the M21 20x20 board in the current portrait reference viewport.
130. Five slot components do not cover or corrupt the board interaction/readability region.
131. Slot presentation is native Godot Control/component layout, not final-screen image compositing.
132. Existing `SlotSystem.SLOT_COUNT == 5` remains the gameplay invariant rather than duplicating a magic sixth/hidden slot.
133. The SPACE-key developer fallback may remain, but visible slot activation is the authoritative owner-playtest interaction proof.
134. Do not invent final no-work visual semantics if the owner has not approved them; a neutral/no-dispatch functional response is acceptable for V04.
135. Do not implement booster art/state, rewards, ads or future decorative UI as a side effect of this slot work.

## J. Five-slot direct tests

136. Scene/UI test proves exactly five SlotView instances are present.
137. Each SlotView's displayed/bound palette ID matches `SlotSystem.get_slot_palette_id(slot_id)`.
138. Each SlotView's visible color matches the actual LevelData palette entry within appropriate 8-bit/tolerant color comparison rules.
139. A slot activation test proves the correct color is passed into real gameplay and a valid assignment is produced when work exists.
140. A slot with no currently reachable work produces no bot/no reservation and no BoardState clear.
141. Rapid repeated activation while the relevant single-flight/in-flight rule applies cannot duplicate the same target/owner assignment.
142. Slot active visual state does not become gameplay truth and cannot mutate SlotSystem by direct reference leakage.
143. UI component does not expose a mutable internal SlotState reference.
144. Five-slot scene still boots under headless Godot with zero parse/script errors.
145. Reference portrait layout test asserts all five slot rects are within the intended viewport/safe content area used by the scene.
146. A second aspect-ratio/tall portrait sanity test proves slots stay visible and board remains readable, without claiming M44 responsive completion.
147. Desktop click/input smoke proves a visible slot can trigger the same handler as programmatic activation without direct board mutation.

## K. Owner-playable end-to-end M21 proof

148. Running the M21 real-art scene shows the approved Hazard Bot artwork over BG01.
149. Exactly five visible colored slots are present.
150. Activating a color with no reachable target spawns no Scrubbot and clears no pixel.
151. Activating C08 on the fresh Hazard Bot selects the bottom-most/left-most **currently targetable** C08 target according to the new owner rule.
152. The actual selected target coordinate is logged/tested.
153. A visible Scrubbot marker departs from the slot/presentation origin.
154. The marker moves through the real production routing result.
155. The marker is visibly aligned over/around the same board display coordinate system rather than moving as a tiny root-space dot.
156. On authenticated arrival, exactly the selected target clears to transparency.
157. Candidate/reservation/dispatcher cleanup still occurs for that exact assignment.
158. A subsequent activation selects the next reachable target according to the same bottom-most/left-most rule under the changed board state.
159. No activation deletes an arbitrary blocked interior cell.
160. Continue enough real clears to prove a previously blocked non-C08 color can become reachable and then clear through the visible interaction/gameplay path or an equivalently real production path.
161. The dedicated 400-cell full-real smoke remains passing after the target-order change.
162. The final full run still reaches exactly 400 clears, 0 ACTIVE, 0 candidates, 0 reservations, 0 dispatcher-active and no orphan agents.

## L. Existing M22 functional tasks pulled forward, not replaced

163. Audit/use the existing canonical gameplay/five-slot owner references already recorded in the repository before deciding V04 slot geometry.
164. Create/reuse a SlotView component suitable for later M22 continuation.
165. Implement exactly five-slot layout.
166. Bind views to SlotSystem state/query API.
167. Implement palette/color presentation.
168. Provide desktop-testable interaction target; do not claim full M24 mobile touch completion.
169. Implement active/in-flight visual state needed for the V04 proof.
170. Keep `SB-M22-008 No-work state if approved` unresolved as a final visual design unless owner approval exists; only functional no-work safety is required.
171. Establish coherent visible Scrubbot spawn point per slot.
172. Run focused aspect-ratio sanity tests.
173. Run focused safe-area/content-bound sanity tests appropriate to this V04 scene without claiming the whole M44 milestone.
174. Run rapid-click regression appropriate to the existing one-by-one dispatch rules.
175. Do not execute M22 booster/decorative Magnific tasks 013+ merely to complete V04.
176. V04 outputs must be reusable by M22/M23 rather than a dead-end debug-only mock implementation where practical.

## M. Regression / compatibility

177. Existing M15 strict-v2 tests remain enabled and pass after intentional priority expectation updates.
178. Existing M16/M17 routing tests remain enabled and pass unchanged in semantics.
179. Existing M18 ScrubbotAgent tests remain enabled and pass.
180. Existing M19 strict dispatcher tests/smokes remain enabled and pass.
181. Existing M20 complete-clearing tests and required lifecycle/queue-free smokes remain enabled and pass.
182. Existing M21 V01/V02/V03 tests remain enabled.
183. Root suite passes with exact check count recorded.
184. Dedicated `tests/m21_real_art_smoke.gd` passes from a fresh process.
185. M21 owner-playable scene headless-boots/parses cleanly.
186. V03 production-art builder path tests still pass including the new preview-directory false-mode cell.
187. M21 level builder deterministic rerun remains unchanged.
188. M21 reference-composite deterministic rerun remains unchanged unless V04 deliberately adds a separate presentation reference artifact; do not silently repurpose the existing evidence semantics.
189. Required outputs contain zero literal `SCRIPT ERROR` and zero literal `Parse Error`.
190. `git diff --check` is clean except explicitly documented pre-existing owner/local line-ending advisories.
191. Source PNG blob/SHA-256 is reverified after all work.
192. Protected M20 loop/dispatcher blobs are reverified after all work.
193. Any headless timing is labeled diagnostic only, not mobile FPS/GPU proof.
194. No previously passing strict test is deleted/disabled merely because the new priority policy changes an expected target; update the narrow superseded expectation instead.

## N. Manual owner-review readiness

195. Provide a short committed `M21_V04_OWNER_PLAYTEST.md` with exact Godot scene/run steps and what the owner should visibly verify.
196. The guide says which five slot colors correspond to the M21 local palette.
197. The guide explains that target priority is bottom-most then left-most among currently reachable targets.
198. The guide explains the current visible Scrubbot is functional/debug presentation, not final M27 character art.
199. The guide explains any intentionally deferred visual polish so the owner does not mistake functional V04 UI for final art direction.
200. The scene can be run with F6/current scene without modifying canonical gameplay truth.

## O. Evidence / handoff

201. Create `coordination/sessions/M21-C001/CLAUDE_LOG_V04.md`.
202. Log exact synchronized starting head and tracker-only V04 start commit SHA.
203. Log every changed production/test/UI/scene/doc file.
204. Log the exact pre-change TargetSelector blob SHA `a0daad67f8ba2238dd54cb903ac25dec7aa3144d` and final blob SHA.
205. Log source/M20 protected blob rechecks.
206. Include a requirement-to-evidence table covering: V03 preview-directory false-mode; target order; blocked/reserved priority behavior; AgentLayer transform; five visible slots; correct color activation; visible movement; rapid input; full 400-cell smoke.
207. Log every required command and actual result, including any failed attempt and correction.
208. Distinguish headless/automated evidence from the owner's later manual visual acceptance.
209. At handoff set tracker lifecycle to `M21-C001 V04 / AWAITING_AUDIT / CHATGPT` while leaving task checkboxes/progress unclosed for ChatGPT.
210. Push all authorized work safely to `origin/main` without force.
211. Claude's final response is exactly two lines: `AWAITING_AUDIT` and the direct GitHub blob URL for `coordination/sessions/M21-C001/CLAUDE_LOG_V04.md`.
212. If an actual accepted-upstream production defect is discovered that requires editing locked M19/M20 code, stop `BLOCKED`, document exact reproduction/evidence and wait for ChatGPT-scoped remediation.

Total numbered criteria: **212**.
