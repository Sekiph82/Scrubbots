# SB-M42 HOME MASTER-vs-ACTUAL VISUAL GAP REGISTER V01

Date: 2026-09-25
Authority: OWNER comparison screenshot + ChatGPT visual review
Owner local comparison file:
`C:\Users\sekip\Desktop\ScrubBots\assets\art\references\_owner_inbox\master - actual differences.png`
Canonical repo destination:
`assets/art/references/_owner_inbox/master - actual differences.png`

## Interpretation

The comparison image is side-by-side:
- LEFT = OWNER TARGET / master visual direction.
- RIGHT = current Godot Home runtime before this remediation.

The master is authoritative for composition, visual hierarchy, density, scale, depth, card treatment, branded UI language and spatial relationships.

It is NOT literal authority for superseded economy/content semantics. Preserve current owner-locked ScrubBots rules:
- coin/star soft currency -> Scrub Bucks banknote;
- XP -> Bot Parts N/250;
- old event/star meter -> Gift Meter;
- old event timer -> absent;
- STAR EXCHANGE -> CARDS EXCHANGE;
- star-road rewards -> Win Streak SB rewards +1/+5/+10/+25/+100;
- all amounts, levels, names, timers, counters, badges and state -> live/runtime values, never baked into art.

The target is therefore: **master visual composition adapted to current ScrubBots semantics**, not a literal restoration of obsolete labels/currencies.

Every item below must receive one final implementation disposition:
- `FIXED`
- `PRESERVED_V1` (only where literal master semantics conflict with current owner-locked rules)
- `ASSET_CANDIDATE_OWNER_REVIEW_REQUIRED` (only when code/layout cannot solve it and a replacement visual candidate is genuinely necessary)
- `BLOCKED_WITH_PROOF` (last resort; exact blocker required)

No item may be silently omitted.

---

## 222-point register

### A. Overall composition and proportions

1. Target composition is dense; current Home has excessive empty sky and ground.
2. Target visual weight is Scrubby + arch + platform; current visual weight is the background.
3. Current Home is background-first; target is game-UI/character-first.
4. Adapt target composition to the taller shipping portrait viewport without creating dead vertical zones.
5. Restore the target vertical rhythm: HUD -> meter -> arch -> hero -> Play -> rewards -> nav.
6. Make HUD, shortcuts, Play and bottom nav feel like one coherent branded system.
7. Restore the consistent blue/cyan metallic/plastic UI language instead of mostly flat translucent native rows.

### B. Top profile / player card

8. Present a large Scrubby avatar in the profile region.
9. Present the approved profile avatar frame.
10. Present the live player/display name with target-like hierarchy.
11. Present the live rank/title with target-like hierarchy when canonical state provides it.
12. Present level as a distinct strong badge/value rather than only a tiny inline string.
13. Present Bot Parts progress as a clear framed profile/progression element.
14. Give the profile region a substantial rounded/beveled branded card body.
15. HOME-027 Scrubby portrait must have a concrete presentation node.
16. HOME-034 profile avatar frame must have a concrete presentation node.
17. HOME-035 profile rank badge must have a concrete presentation node.

### C. Scrub Bucks / Heart HUD

18. Make the Scrub Bucks chip large, clear and target-comparable in hierarchy.
19. Increase the visual prominence/readability of the Scrub Bucks banknote icon.
20. Heart presentation should use a large icon + live count and, when applicable, live regen time; do not hardcode target values.
21. Heart HUD must feel as strong as the target HUD while preserving current 5-heart rules/state.
22. Balance Scrub Bucks and Hearts spatially instead of crowding both into a tiny top-right cluster.
23. Restore a visible top-right menu/hamburger affordance if it belongs to the current Home navigation contract.
24. Top HUD should read as a deliberate visual band, not a thin text strip.

### D. Gift Meter

25. Use a substantial horizontal Gift Meter treatment comparable to the target.
26. Place the approved Gift Meter emblem prominently.
27. Place the approved Gift Meter reward crate prominently.
28. Make Gift Meter read as a foreground UI element.
29. Replace the current visually-thin meter treatment with a strong branded meter while retaining native/live functionality.
30. HOME-051 gift_meter_emblem must be visibly integrated.
31. HOME-054 gift_meter_reward_crate must be visibly integrated.
32. Increase bar fill thickness/readability.
33. Add appropriate frame/depth/end treatment using native styling and approved art.
34. Give Gift Meter adequate hierarchy rather than secondary-caption weight.

### E. Whispering Park / area header

35. Present the large Whispering Park-style arch/banner region.
36. Present live area title/number copy in that region.
37. Present HOME-007 arch decoration.
38. Restore the cyan accent/symbol language around the arch where appropriate.
39. Make the arch body substantial enough to frame the world.
40. Integrate the arch with the surrounding world rather than floating as an unrelated overlay.
41. Use the arch to frame/focus Scrubby as in the master.
42. HOME-006 arch art must be visibly integrated.
43. HOME-007 arch decor must be visibly integrated.
44. HOME-008 area title must exist as live/localizable Godot text.
45. HOME-009 area number must exist as live/localizable Godot text.

### F. Scrubby hero

46. Increase Scrubby's visual dominance to target-like hero scale.
47. Scrubby's feet must visibly contact/stand on the platform.
48. Remove any floating-character impression.
49. Match the target cleaning-hero silhouette/energy as closely as possible with owner-approved/current assets.
50. Avoid a casual pose/composition that weakens the cleaning-hero identity where composition can solve it.
51. Match the target's substantial robot-presence/scale through layout before considering asset replacement.
52. Preserve current canonical Scrubby branding; do not invent a conflicting chest symbol.
53. Make the cleaning tool a clear part of the hero silhouette.
54. Restore bubbles/cleaning FX or equivalent target-consistent environmental FX where current rules allow.
55. Integrate Scrubby into the world rather than looking like a pasted PNG.
56. Eliminate the platform/ring crossing behind or through Scrubby's torso/waist.

### G. Central platform

57. Position a broad platform beneath Scrubby.
58. Platform layers may not intersect Scrubby's torso.
59. Make the platform top surface clearly visible.
60. HOME-011 platform top must be integrated.
61. Restore platform body/side-wall depth.
62. Add contact/depth treatment between platform and ground using native/FX methods where appropriate.
63. Make the platform-ground relationship visually coherent.
64. Use the platform as the hero's visual anchor.

### H. World/environment

65. Bring the world closer to the target's detailed cleaning-themed alley/world density.
66. Reduce the generic empty-futuristic-city feeling where compositing/approved props can solve it.
67. Strengthen central perspective/focus toward Scrubby.
68. Reduce the amount of empty sky dominating the composition.
69. Add pipes/neon/pavement/cleaning detail through existing approved layers/props.
70. Present approved environment-prop layers rather than leaving them orphaned.
71. Present the wet-floor-sign asset.
72. Present the keep-clean-sign asset.
73. Present hose/cleaning-equipment art.
74. Present foam/bubble clusters.
75. Present the cleaning bucket.
76. Present additional cleaning equipment.
77. Present neon decorative details.
78. Arrange world details to frame the hero rather than behave as random stickers.

### I. Helper bots

79. Present a left/lower helper-bot presence comparable to the target world.
80. Present a right/lower helper-bot presence comparable to the target world.
81. Use helper bots to make the world feel populated/living.
82. Do not leave all approved helper bots visually absent.
83. HOME-022 helper_bot_floor_cleaner must be integrated.
84. HOME-023 helper_bot_cart must be integrated.
85. HOME-024 helper_bot_alt_pose must be integrated.
86. Helper bots must support the target's living-robot-world feeling without blocking controls.

### J. Left shortcut column

87. Shortcuts should read as substantial rounded blue cards/panels.
88. Replace thin translucent row treatment with branded card treatment.
89. Increase shortcut icon scale.
90. Make icons readable at mobile size.
91. Use stronger live label typography.
92. Increase label contrast.
93. Win Streak should read as a real card, not a narrow text row.
94. Gift Bar should present its gift-box identity clearly.
95. Collection should present collectible-card identity clearly.
96. Shop should present shop/basket identity clearly.
97. Distribute shortcut cards vertically around the world area with target-like rhythm.
98. Do not compress all four shortcuts into one cramped upper-middle cluster.
99. Use shortcut cards to frame the hero/world.
100. WIN STREAK must not be clipped to "WIN STR...".
101. COLLECTION must not be clipped to "COLLECT...".
102. Disabled shortcut styling must stay legible.

### K. Right shortcut column

103. No Ads should read as a substantial illustrated card.
104. Avoid reducing No Ads to a tiny line item.
105. Daily should present its clipboard/identity clearly.
106. Avoid reducing Daily to a tiny icon.
107. Tasks should read as a substantial card.
108. Avoid reducing Tasks to a tiny icon.
109. Cards Exchange should have strong visual weight comparable to the target's exchange card.
110. Do not bury Cards Exchange in a thin upper-row treatment.
111. CARDS EXCHANGE must not be clipped to "CARDS EXC...".
112. Give each right-side shortcut a coherent branded card body.
113. Avoid an undifferentiated translucent-list appearance.
114. Preserve enough central negative space around Scrubby while maintaining card prominence.

### L. Notification badges

115. Restore visible, branded notification badges where live state calls for them.
116. Badge hierarchy must be visually obvious.
117. Position badges cleanly on card corners.
118. Make badge treatment consistent across shortcut cards.
119. Do not hardcode master badge numbers; use live state only.

### M. Play CTA

120. Make Play the strongest call-to-action on the Home screen.
121. Present the approved green/beveled Play frame prominently.
122. Present large high-contrast live PLAY/CONTINUE text.
123. Present a clear play-triangle affordance using native UI if appropriate.
124. Present live continue/level subtitle when canonical launch state supports it.
125. Restore strong outer border/depth/shadow treatment.
126. HOME-078 play_button_frame must be visibly integrated.
127. Do not leave Play as plain text on the background.
128. Make the CTA unmistakably button-like.
129. Ensure the CTA remains legible over the world/background.
130. Present a visible play triangle/affordance.
131. Present live continue/frontier subtitle rather than hardcoded target values.
132. Make the interactive hit region visually correspond to the visible CTA.
133. Position Play close enough to the hero/platform to preserve the target flow.

### N. Win Streak reward track

134. Give the reward track its own strong dark/blue container/region.
135. Present the Win Streak reward badge.
136. Present five clear reward gift objects.
137. Preserve visually differentiated reward gift objects.
138. Keep reward amounts live below/with the gifts.
139. Present a readable progress/fill relationship.
140. Do not leave reward gift art absent.
141. HOME-086 reward badge must be integrated.
142. HOME-090 reward_gift_1 must be integrated.
143. HOME-091 reward_gift_5 must be integrated.
144. HOME-092 reward_gift_10 must be integrated.
145. HOME-093 reward_gift_25 must be integrated.
146. HOME-094 reward_gift_100 must be integrated.
147. HOME-087 Scrub Bucks icon reuse must participate in the reward-track presentation where appropriate.
148. Do not reduce the track to tiny text-only chips.
149. Ensure track values have strong contrast over the world.
150. Give the track a clear boundary/container.
151. Make progression state visually understandable.
152. Rewards should read as reward objects, not only numbers.

### O. Bottom navigation

153. Present a full-width branded bottom navigation dock.
154. Do not leave the dock visually absent.
155. Events must have a visible icon + live label.
156. Events must not read as text-only.
157. Robots must have a visible icon.
158. Robots must not read as text-only.
159. Home selected state should be visually prominent, target-like and clearly selected.
160. Home must not be text-only.
161. Leaderboard must have its trophy/approved icon treatment.
162. Do not reduce Leaderboard to only "RANKS" text.
163. Settings must have a visible gear icon.
164. Settings must not be text-only.
165. HOME-101..105 must all have concrete visible presentation nodes.
166. Give tabs clear boundaries/structure.
167. Do not leave tab labels floating directly on the pavement/background.
168. Make selected Home state unmistakable.
169. Visually separate the nav region from the world background.

### P. Typography

170. Move toward target-like bold/branded UI typography using available licensed/project fonts and native styling.
171. Use outline/shadow/readability treatment where appropriate.
172. Avoid generic system-font appearance when project typography resources allow.
173. PLAY should have hero-level display treatment.
174. Shortcut labels should be strong uppercase/localizable labels.
175. Restore typographic hierarchy across top HUD.
176. Increase undersized text where needed for the 1080x2160 reference viewport.

### Q. Contrast/readability

177. Put important UI copy on purposeful card/panel surfaces.
178. Avoid placing critical text directly over busy detailed art without contrast treatment.
179. Maintain high contrast on actionable buttons.
180. Disabled items must still be readable.
181. Reward-track values must not disappear into pavement texture.
182. Bottom-nav labels/icons must not disappear into pavement texture.
183. Shortcut icons must remain distinguishable from the world background.
184. Use branded panel/card bodies to guarantee readability.

### R. Spacing/positioning

185. Balance spacing between top HUD and Gift Meter.
186. Avoid crushing HUD + Gift Meter into the extreme top.
187. Eliminate the huge dead-sky band below them.
188. Put area header in the upper/middle composition where it can frame the world.
189. Fill the previous empty-sky area with intentional world/banner hierarchy.
190. Let Scrubby occupy a stronger central portion of the screen.
191. Avoid positioning Scrubby too high/small relative to the master.
192. Keep Play visually close to Scrubby/platform.
193. Remove the excessive dead-ground gap before Play.
194. Keep reward track visually connected to Play.
195. Avoid reward-track/bottom-nav crowding.
196. Make bottom nav a distinct footer.
197. Do not visually merge bottom nav with the street texture.

### S. Depth/layering

198. Restore clear background/midground/foreground separation.
199. Avoid treating world art as only stacked full-screen centered images.
200. Establish target-like depth order: background -> arch/world -> platform -> hero/props -> CTA/UI.
201. Correct the hero/platform depth-order failure.
202. Use environment props to create foreground/midground depth.
203. Avoid a flat world caused by absent props.
204. Keep shortcut cards clearly in front of world art.
205. Give shortcut panels enough opacity/depth to separate from the environment.

### T. Missing visual systems

206. Implement the profile-card visual system.
207. Implement rank-badge presentation.
208. Implement the menu/hamburger visual/interaction if consistent with current navigation architecture.
209. Implement the full Gift Meter visual system.
210. Implement area arch/title system.
211. Implement platform-top/contact composition.
212. Implement environment-prop composition.
213. Implement helper-bot composition.
214. Implement bubble/cleaning FX where appropriate.
215. Implement large shortcut-card bodies.
216. Implement notification-badge presentation.
217. Implement branded Play CTA.
218. Implement reward-track container/system.
219. Implement reward gift objects.
220. Implement bottom-nav dock.
221. Implement bottom-nav icons.
222. Implement clear selected-Home-tab visual treatment.

---

## Mandatory semantic adaptation, not literal master copying

The following target details are examples only and must remain current/live:
- target coin icon/75,680 -> live Scrub Bucks banknote/balance;
- target profile XP -> live Bot Parts N/250;
- target old event/star meter -> Gift Meter;
- target old event timer -> no event timer;
- target STAR EXCHANGE -> CARDS EXCHANGE;
- target star road -> Win Streak SB reward track;
- target exact level 329 -> current frontier level;
- target exact Heart count/timer -> current Heart service state;
- target exact badge counts -> live badge state;
- target exact player/rank/area values -> canonical state where available;
- text remains live/localizable and must never be baked into newly generated art.

## Asset replacement policy

First solve the gap through composition, scaling, native styling, depth, layout and the already approved asset set.

If a gap cannot reasonably be solved because an approved visual itself is materially different from the owner target (for example hero pose or background art direction):
1. identify the exact asset ID/path and explain why layout cannot solve it;
2. do not overwrite the approved file;
3. if the active Claude environment has an authorized image-generation skill/connector, generate a new candidate under `assets/ui/generated/` only;
4. never self-promote that candidate to `assets/ui/final/`;
5. record `ASSET_CANDIDATE_OWNER_REVIEW_REQUIRED`;
6. if no image-generation capability exists, record `BLOCKED_WITH_PROOF` and continue fixing every other item.

The owner decides any replacement-art promotion.
