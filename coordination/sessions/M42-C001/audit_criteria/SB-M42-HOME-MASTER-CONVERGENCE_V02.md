# SB-M42 HOME MASTER CONVERGENCE V02 — CHATGPT AUDIT CRITERIA V01

Auditor: ChatGPT
Scope: one-pass remediation for SB-M42-011 / SB-M42-017
Visual contract:
`coordination/sessions/M42-C001/SB-M42-HOME-MASTER_ACTUAL_VISUAL_GAP_REGISTER_V01.md`

## PASS contract

AUDITED_PASS requires all of the following.

### A. Owner comparison reference

1. Owner comparison PNG is committed at:
   `assets/art/references/_owner_inbox/master - actual differences.png`
2. Its local owner file was not edited/recompressed/resized during commit.
3. Implementation log records dimensions, size and SHA-256.
4. If Claude claims visual inspection, the log contains `VISION_INSPECTION_CONFIRMED` plus observations demonstrably tied to the image.
5. If direct vision was unavailable, the log says `VISION_UNAVAILABLE`; no fake visual claims are accepted.

### B. 222-point ledger completeness

6. Ledger exists at:
   `coordination/sessions/M42-C001/task_logs/SB-M42-HOME-222-COMPLETION-LEDGER.md`
7. Ledger has exactly 222 numbered rows, 1..222, no missing or duplicate numbers.
8. Every row uses only:
   - FIXED
   - PRESERVED_V1
   - ASSET_CANDIDATE_OWNER_REVIEW_REQUIRED
   - BLOCKED_WITH_PROOF
9. Any PRESERVED_V1 row genuinely corresponds to an owner-locked current semantic adaptation, not convenience.
10. Any asset-candidate/blocker row names exact asset/path and gives concrete proof why code/layout alone cannot satisfy it.
11. No item is silently omitted.

### C. Semantic integrity

12. Scrub Bucks remains canonical soft currency; no coin/star balance is restored.
13. Bot Parts remains N/250 progression; XP is not restored.
14. Gift Meter remains current system; Event Points/event timer are not restored.
15. Cards Exchange remains Cards Exchange; Star Exchange is not restored.
16. Win Streak rewards remain +1/+5/+10/+25/+100 SB.
17. Dynamic names/levels/amounts/timers/counts/badges remain live/localizable, not baked into art.
18. Master example values such as Level 329 are not hardcoded as gameplay truth.

### D. Approved-art integrity

19. All 49 unique currently approved PNG Git blobs remain byte-identical to the owner approval artifacts unless a NEW owner approval artifact explicitly authorizes replacement.
20. No approved PNG is silently regenerated, recompressed, resized, moved, renamed or overwritten.
21. Any new/replacement art produced by an authorized generator exists only as a candidate under `assets/ui/generated/`.
22. No candidate is self-promoted to final or receives APPROVED status without owner approval.
23. Manifest/hash validation is not weakened.

### E. Presentation-accounting architecture

24. Production has deterministic accounting for all 50 approved ART entries.
25. Every ART entry is explicitly classified as STATIC_PRESENTATION, STATE_PRESENTATION or HOME-087 reuse.
26. Every STATIC_PRESENTATION maps to a concrete Home node.
27. Every STATE_PRESENTATION maps to a concrete node/state/animation destination.
28. HOME-087 is exact reuse of HOME-042.
29. Binder lifecycle availability is not treated as sufficient proof of visible presentation.
30. Tests fail if a static approved ART entry becomes orphaned.

### F. Master composition

31. Overall screen no longer contains the previous huge dead sky/ground bands without purpose.
32. Vertical hierarchy reads as HUD -> Gift Meter -> area/arch/world -> Play -> reward track -> nav.
33. Character/UI hierarchy dominates background rather than background dominating the screen.
34. UI/card language is visually coherent and branded rather than thin unrelated native rows.

### G. Profile/top HUD

35. HOME-027 is presented.
36. HOME-034 is presented.
37. HOME-035 is presented.
38. Scrub Bucks HOME-042 is visible with live amount.
39. Heart HOME-043 is visible with live state.
40. Player/profile/level/Bot Parts hierarchy is materially stronger than baseline.
41. Top HUD does not remain a tiny text strip.
42. Any menu affordance is consistent with existing architecture and does not invent gameplay truth.

### H. Gift Meter

43. HOME-051 visible.
44. HOME-054 visible.
45. Meter has substantial readable visual treatment.
46. Values remain live/current.
47. No Event Points/timer regression.

### I. Arch/area

48. HOME-006 visible.
49. HOME-007 visible.
50. HOME-008 live title node exists.
51. HOME-009 live area/number node exists.
52. Arch frames central world rather than being absent or floating nonsensically.

### J. Hero/platform/world

53. HOME-010 visible and correctly placed.
54. HOME-011 visible and correctly placed.
55. Scrubby's feet visually contact/support on platform.
56. Platform does not intersect Scrubby torso/waist.
57. Scrubby is visually grounded, not floating.
58. HOME-013..021 have concrete presentation.
59. HOME-022..024 have concrete presentation.
60. World has foreground/midground depth rather than flat background-only composition.
61. Scrubby remains visually dominant and readable.
62. Optional HOME-031/032 have explicit state destinations if retained.

### K. Shortcut cards

63. Left and right shortcuts use substantial branded card treatment.
64. Icons are mobile-readable.
65. Labels are live and high-contrast.
66. WIN STREAK is not clipped at 1080x2160.
67. COLLECTION is not clipped at 1080x2160.
68. CARDS EXCHANGE is not clipped at 1080x2160.
69. Disabled shortcuts remain readable.
70. Badges use live state and are visually attached correctly.
71. Shortcut cards frame the hero instead of obscuring it.

### L. Play CTA

72. HOME-078 visibly frames a real native interactive control.
73. Play CTA is visually dominant.
74. Live PLAY/CONTINUE label is readable.
75. Play triangle/affordance visible.
76. Frontier/continue subtitle is live if available.
77. Hit region matches visible CTA.
78. CTA is not plain text on pavement/background.

### M. Reward track

79. HOME-086 visible.
80. HOME-087 reuse used correctly.
81. HOME-090 visible.
82. HOME-091 visible.
83. HOME-092 visible.
84. HOME-093 visible.
85. HOME-094 visible.
86. Track has a coherent container/progression treatment.
87. Five reward objects are visually legible.
88. +1/+5/+10/+25/+100 SB values remain live.
89. Current/reached/future states are distinguishable.
90. Track is not reduced to tiny text floating on pavement.

### N. Bottom nav

91. HOME-101 visible.
92. HOME-102 visible.
93. HOME-103 visible.
94. HOME-104 visible.
95. HOME-105 visible.
96. Full-width dock is visually distinct from world.
97. Icon + live label used.
98. Selected Home state is obvious.
99. HOME and SETTINGS behavior unchanged.
100. Future destinations remain disabled as designed.

### O. Typography/contrast/depth

101. Important UI text is not lost over busy art.
102. Typography hierarchy materially approaches master visual language using licensed/project resources.
103. PLAY and shortcut labels have appropriate prominence.
104. Bottom nav readable.
105. Reward track readable.
106. Disabled states readable.
107. Decorative art does not intercept input.
108. Depth order is coherent: background -> arch/world -> platform/props -> hero -> CTA/UI.
109. No major decorative layer incorrectly covers actionable UI.

### P. Responsive matrix

110. 1080x2160 passes.
111. 1170x2532 passes.
112. 1290x2796 passes.
113. 1080x2400 passes.
114. 1440x3200 passes.
115. required 16:9 portrait case passes.
116. required tablet portrait case passes.
117. no critical label clipping at any required viewport.
118. no actionable control outside safe area.
119. minimum touch target >=88 px.
120. Scrubby/platform relation remains coherent across matrix.
121. Play remains usable.
122. reward track remains visible/readable.
123. bottom nav remains visible/usable.
124. profile/currency/Gift Meter remain readable.

### Q. Visual evidence / iterative loop

125. Deterministic visual snapshot harness exists or equivalent reproducible evidence method is documented.
126. Final 1080x2160 screenshot evidence exists.
127. At least one tall-phone screenshot exists.
128. At least one compact/16:9 portrait screenshot exists.
129. Evidence comes from production Home composition, not a mock.
130. If vision available, at least two post-change visual inspections are recorded.
131. If vision unavailable, no self-visual-pass claim is made.

### R. Tests and repository integrity

132. `m42_assets.gd` exit 0.
133. `m42_home.gd` exit 0.
134. `m42_navigation.gd` exit 0.
135. new focused composition/presentation test(s) exit 0.
136. root `run_tests.gd` exit 0.
137. zero SCRIPT ERROR.
138. no hidden FAIL.
139. baseline intentional corrupt-image engine ERROR lines, if present, are unchanged/explained.
140. `git diff --check` clean.
141. root `TASKS.md` untouched by Claude.
142. owner approval/decision files untouched by Claude.
143. ChatGPT audit/criteria files untouched by Claude.
144. implementation log accurately records exact commits/files/evidence/tests.

## Final visual closure rule

Even if every code/audit criterion passes, ChatGPT must not close SB-M42-011 or SB-M42-017 solely from Claude's statement.

Final closure requires:
1. ChatGPT independent source/diff/test/evidence audit;
2. owner review of the new runtime Home visual.

Possible audit outcomes:
- `AUDITED_PASS / CODE READY FOR OWNER VISUAL REVIEW`
- `AUDITED_PASS_WITH_ASSET_OWNER_GATES`
- `CHANGES_REQUIRED`

Any unresolved `BLOCKED_WITH_PROOF` affecting a major master-composition requirement prevents code-ready closure.
