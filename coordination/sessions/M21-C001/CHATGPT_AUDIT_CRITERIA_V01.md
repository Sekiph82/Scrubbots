# M21-C001 — Strict Audit Criteria V01

Canonical tracker: repository-root `TASKS.md` only.

This is a **critical gameplay/content milestone** under Strict Audit Standard v2. V01 is the implementation/evidence pass, not final closure. Even if V01 is clean, ChatGPT may require a second auditor-authored validation pass before M21 task closure.

## A. Governance / handoff
1. Work is performed only in `Sekiph82/Scrubbots` on `main`.
2. `coordination/sessions/M20-C001/CHATGPT_AUDIT_V11.md` exists and says `AUDITED_PASS / STRICT_V2_FINAL_CLOSURE`.
3. M20 production basis remains accepted; V01 does not reopen M20 without a newly exposed concrete defect.
4. `coordination/sessions/M21-C001/OWNER_ASSET_APPROVAL_V01.md` exists before implementation.
5. `coordination/sessions/M21-C001/OWNER_ASSET_VALIDATION_V01.json` exists before implementation.
6. `CHATGPT_PROMPT_V01.md` and this criteria file exist before implementation edits.
7. Claude reads `CLAUDE.md`, root `TASKS.md`, `coordination/AUDIT_POLICY.md`, `coordination/AUDIT_INDEX.md`, this criteria, the active prompt, and the M20 final audit.
8. Claude preserves all pre-existing owner/local work and does not reset/restore it for cleanliness.
9. Local `main` is safely synchronized with `origin/main` before edits.
10. The stale M20 tracker state is reconciled from the ChatGPT V11 final audit before M21 implementation.
11. SB-M20-001..014 are marked complete in that authorized tracker reconciliation.
12. Post-M20 progress is exactly `304 / 719 = 42.28%` main+ui and `304 / 943 = 32.24%` overall.
13. `lastCompletedTaskId` becomes `M20-C001-V11` before M21 implementation.
14. Tracker then transitions to `M21-C001-V01 / IN_PROGRESS / CLAUDE`.
15. The M20-closure + M21-start tracker transition is committed and pushed before implementation/test edits.
16. No `.hiveai` live tracker is recreated or synchronized.
17. No M22/M23/M24 production UI/touch work is started.
18. No M25+ win/lose/progression/economy/save behavior is added.
19. No Magnific/AI artwork generation occurs in this cycle.
20. No production slot queue/refill/cooldown/consumption behavior is invented.
21. No automatic gameplay loop is added to production gameplay; automation is test/debug-only.
22. M21 and M08 checkboxes remain open at V01 handoff for ChatGPT closure.
23. Progress remains 304/719 and 304/943 at V01 handoff.
24. `lastCompletedTaskId` remains `M20-C001-V11` at V01 handoff.
25. Claude assigns no independent audit verdict.

## B. Owner-approved source integrity
26. Canonical source path is exactly `assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png`.
27. Git blob SHA is exactly `b565743ba52699899007882b750b7c8e7cdd00f9` before implementation.
28. SHA-256 is exactly `ede1e02a9096c4c7ba040b91ed7db2d2c2af3b2e20d5c8774068c8d08ad59899`.
29. File size is exactly 297 bytes.
30. Source dimensions are exactly 20x20.
31. Source contains exactly 400 logical pixels/cells.
32. Every source logical pixel is alpha 255.
33. No semi-transparent source pixel exists.
34. No transparent source pixel exists.
35. No off-palette logical color exists.
36. Exact used canonical IDs are C01, C03, C08, C11, C16.
37. Exact C01 count is 30.
38. Exact C03 count is 5.
39. Exact C08 count is 298.
40. Exact C11 count is 11.
41. Exact C16 count is 56.
42. Distinct used-color count is exactly 5, valid for EASY.
43. Every perimeter cell is C08; perimeter count is exactly 76.
44. The source PNG is never resized, recolored, smoothed, regenerated, optimized/re-encoded, or overwritten.
45. Final source Git blob SHA and SHA-256 remain exactly unchanged.

## C. M08-style source audit evidence
46. `coordination/sessions/M21-C001/M21_SOURCE_AUDIT.md` is created.
47. It records exact filename/path.
48. It records exact dimensions 20x20.
49. It records alpha/transparency facts.
50. It records exact five-color set and counts.
51. It records canonical C-ID mapping against `data/palettes/scrubbots_palette_v2.json`.
52. It records no off-palette color.
53. It records no semi-transparent color.
54. It records the one-logical-pixel = one-cell grid.
55. It records EASY as the legal difficulty from 20x20 dimensions.
56. It records the EASY 3-5 color-count rule and exact pass at 5.
57. It records that no spatial resize/interpolation is performed.
58. It records the owner approval artifact and hashes.
59. It does not infer provenance beyond owner-approved evidence.
60. It does not claim the earlier transparent sprite is the production source.

## D. Production palette/content bridge
61. The implementation explicitly recognizes that historical M09 `LevelImporter` uses first-seen row-major palette ordering.
62. For this source, the raw first-seen order is proven to be `C08, C16, C01, C03, C11`.
63. Raw M09 first-seen ordering is not falsely claimed to satisfy the current production palette-order rule.
64. Historical generic M09 behavior remains backward-compatible.
65. `scripts/tools/level_importer.gd` is not silently converted from generic first-seen semantics into a different contract.
66. A narrow production-art validation/mapping layer is added or an equivalently isolated solution is used.
67. That layer reads `data/palettes/scrubbots_palette_v2.json` as machine-readable authority rather than hardcoding a parallel palette table.
68. Off-palette input is rejected; there is no nearest-color approximation.
69. Non-opaque artwork alpha is rejected for production logical cells.
70. Used-color count is computed from logical cells, not blindly from palette array length.
71. Difficulty color-count band is enforced.
72. Final local palette contains only colors actually used by cells.
73. Final local palette is ascending by global C-ID.
74. Final local palette is exactly C01, C03, C08, C11, C16 in that order.
75. `#RRGGBBFF` is treated as equivalent to canonical opaque `#RRGGBB` without admitting other alpha values.
76. Cell palette IDs are remapped deterministically to the reordered local palette.
77. The production-art layer is deterministic for identical input.
78. A second build produces byte-identical final Level Data and no meaningless diff.
79. The production-art layer does not mutate the source PNG.
80. If new file-writing logic is introduced, it fails closed on source/destination aliasing and incompatible overwrite conditions.
81. A deliberate off-palette negative fixture fails production-art validation.
82. A deliberate semi-transparent fixture fails production-art validation.
83. A deliberate wrong EASY color-count fixture fails production-art validation.
84. A deliberate noncanonical local-palette order is rejected or normalized deterministically according to the documented contract.
85. A successful normalized result reconstructs the same artwork despite palette-ID remapping.

## E. Final production Level Data artifact
86. Final Level Data path is `data/levels/m21_level_001_hazard_bot.json`.
87. Level id is `m21_level_001_hazard_bot`.
88. Display name is `Hazard Bot` unless the prompt-authorized implementation documents a purely metadata-level equivalent.
89. Difficulty is exactly `EASY`.
90. Width is exactly 20.
91. Height is exactly 20.
92. Cell count is exactly 400.
93. Final palette order is canonical ascending C-ID.
94. Final palette represents C01/C03/C08/C11/C16 only.
95. Cell-reference counts remain exactly 30/5/298/11/56 for C01/C03/C08/C11/C16.
96. `LevelValidator` accepts the final artifact.
97. `ProductionLevelValidator` accepts the final artifact.
98. The new production-art policy accepts the final artifact.
99. `LevelLoader` loads the committed final artifact successfully.
100. Loaded data exactly preserves id/name/difficulty/dimensions/palette/cells.
101. Reconstruction from final Level Data is 20x20 RGBA8.
102. Reconstruction raw RGBA8 bytes equal the approved source raw RGBA8 bytes for all 400 pixels.
103. No source-image shortcut is used during reconstruction comparison.
104. A committed preview is generated from final Level Data, not copied from source.
105. Preview path is `assets/art/levels/previews/m21_level_001_hazard_bot.png`.
106. Preview raw logical image bytes match source reconstruction exactly.
107. Import/build metadata records source path, hashes, dimensions, difficulty, canonical color IDs/order, output path and builder/version provenance.
108. Re-running the production build against committed identical artifacts reports/behaves as unchanged rather than producing drift.

## F. Real production gameplay bundle
109. M21 authoritative end-to-end evidence uses the real committed final Level Data artifact.
110. It uses real `LevelLoader`/`LevelData` and real `BoardState`.
111. It uses real `BoardRenderer`.
112. It uses real `SlotSystem`.
113. It uses real `ColorCandidateIndex`.
114. It uses real `ReservationState`.
115. It uses real `TargetSelector`.
116. It uses real `ProductionAccessQuery`.
117. It uses real `ProductionRoutingSystem`.
118. It uses real `ScrubbotDispatcher`.
119. It uses real `CompleteClearingLoop`.
120. No M20 candidate/reservation/dispatcher test seam substitutes for a production collaborator in the authoritative M21 full-level run.
121. M20 loop production blob remains `06391839523cbc27e88a4b3ef12b730012cd45fa` unless a newly exposed defect causes BLOCKED.
122. Dispatcher production blob remains `eee10149e4f116af6706beec832042352bf3a6dd` unless a newly exposed defect causes BLOCKED.
123. If the real-art run exposes an upstream production defect, Claude stops and reports BLOCKED rather than opportunistically fixing M20/M19 in this prompt.
124. Five slots are configured exactly once against the five local palette IDs representing C01/C03/C08/C11/C16.
125. The five slot palette identities are directly asserted.
126. A debug-only real-art vertical-slice scene exists and uses the same committed Level Data and production collaborator classes.
127. The debug scene uses BG01 `#202533` behind the board.
128. Debug presentation does not replace BoardRenderer with a flattened concept image.
129. Debug presentation does not implement M22 production slot UI or M24 touch controls.

## G. Initial real-art reachability / AL-028 proof
130. Fresh board starts with all 400 cells ACTIVE.
131. Fresh candidate counts match source color counts.
132. Initial renderer pixels match approved source pixels at every logical coordinate.
133. All 76 perimeter cells are directly proven C08.
134. No C01/C03/C11/C16 cell is on the perimeter.
135. Before any clear, each non-C08 slot has raw matching candidates.
136. Before any clear, non-C08 slot activation fails exactly with `NO_REACHABLE_TARGET` (not fake absence of raw candidates).
137. Each such failed activation spawns no agent.
138. Each such failed activation creates no reservation.
139. C08 slot activation succeeds on the fresh board.
140. Its selected target is C08 and currently ACTIVE.
141. Its reservation exists before arrival.
142. Its real ScrubbotAgent is MOVING before arrival.
143. Driving the real agent to arrival yields exactly one M20 clear.
144. The cleared target becomes BoardState CLEARED.
145. The renderer cell becomes alpha 0.
146. The candidate index no longer returns that cell.
147. The successful reservation pair is gone after commit.
148. Dispatcher assignment is finalized after commit.
149. The agent disappears/frees with no return behavior.
150. At least one initially-unreachable non-C08 color later becomes genuinely reachable after prior clears and then dispatches successfully.
151. That transition is observed through the real production selector/access/routing path, not a forced target.

## H. Full real-art level run
152. A deterministic test/debug driver may automate slot attempts, but the automation stays outside production gameplay logic.
153. The driver has a finite guard and fails if it stops making progress.
154. Every successful activation is followed through real movement and authenticated arrival before the next sequential success is counted.
155. Exactly 400 successful clears occur for the 400-cell level.
156. No cell is cleared twice.
157. M20 `get_cleared_count()` ends at exactly 400.
158. BoardState CLEARED count ends at exactly 400.
159. BoardState ACTIVE count ends at zero.
160. All five source colors are actually cleared at least once through real dispatch.
161. Final candidate queries contain no ACTIVE candidate for any of the five colors.
162. Final reservation count is zero.
163. Final dispatcher active count is zero.
164. Final agent-parent child count is zero after queue-free/frame cleanup.
165. No orphan ScrubbotAgent remains.
166. Final renderer logical pixels are all alpha 0.
167. Final renderer does not paint BG01 into LevelData/BoardRenderer pixels; BG01 remains behind transparency.
168. The full run does not add scoring, win/lose, progression, reward, slot refill or automatic follow-up dispatch to production systems.

## I. Reference output / performance truth
169. A reproducible M21 reference output is captured or generated from authoritative renderer/scene state.
170. Any headless composite is labeled as an evidence composite, not a real-device screenshot.
171. The reference output makes ACTIVE artwork and CLEARED transparency visually distinguishable against BG01.
172. The debug scene remains available for later owner/manual visual review.
173. Performance evidence records CPU/headless timing separately from any visual/FPS claim.
174. No headless timing is presented as mobile FPS or GPU performance.
175. Full-level dispatch/clear count and elapsed CPU time are logged.
176. Any memory/node-count evidence is reported as measured, not inferred.
177. M21 visual gaps are recorded in `coordination/sessions/M21-C001/M21_VISUAL_GAPS.md`.
178. The gap report distinguishes current debug Scrubbot marker from future final character visuals.
179. The gap report does not pre-authorize Magnific generation or M22/M27 asset work.

## J. Regression / log / final handoff
180. All previously enabled M19 tests remain enabled.
181. All previously enabled M20 V01-V11 tests remain enabled.
182. New M21 tests are registered in the full root suite.
183. Full root suite passes.
184. Existing M20 queue-free and lifecycle smoke tests still pass where separately required by current repository policy.
185. A dedicated M21 real-art smoke/test entrypoint exists if frame/queue-free behavior cannot be proven synchronously in the root suite.
186. Dedicated M21 smoke passes if created.
187. Debug M21 scene headless-boots/parses cleanly.
188. Final output is inspected for literal `SCRIPT ERROR`.
189. Final output is inspected for literal `Parse Error`.
190. `git diff --check` is clean except explicitly documented benign line-ending advisories.
191. Approved source blob/hash is reverified after all work.
192. M20 loop and dispatcher locked blobs are reverified after all work.
193. `CLAUDE_LOG_V01.md` records exact commands and actual results rather than only aggregate claims.
194. The log contains a criteria/evidence map for source audit, production palette normalization, artifact roundtrip, initial reachability, full-level run, renderer, cleanup and performance.
195. The log truthfully distinguishes root-suite, smoke, static/source, generated-artifact and manual/unavailable evidence.
196. Exact changed files are recorded.
197. Final commit(s) are pushed to `origin/main` without force.
198. Final tracker is `M21-C001-V01 / AWAITING_AUDIT / CHATGPT`.
199. Progress remains 304/719 main+ui and 304/943 overall; no M21/M08 task is closed by Claude.
200. Claude final user-facing response is exactly two lines: `AWAITING_AUDIT` and the direct GitHub blob URL for `coordination/sessions/M21-C001/CLAUDE_LOG_V01.md`.
201. Any newly exposed upstream production defect causes `BLOCKED` with evidence and no unauthorized upstream fix.

Total numbered criteria: **201**.
