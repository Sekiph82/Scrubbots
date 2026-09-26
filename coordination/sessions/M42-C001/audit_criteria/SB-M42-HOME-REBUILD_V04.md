# SB-M42 HOME REBUILD V04 — CHATGPT AUDIT CRITERIA

Verdict may pass only if every item below is independently verified.

## World 01 asset
1. Exact owner-approved source exists at the required owner-inbox path.
2. Exact dimensions are 1080x2160.
3. SHA-256 is exactly `8e04eda668aabd9f96172c0e82fd7dd47e61083cb691402a313120443a525e5b`.
4. Promoted final bytes are identical to owner-inbox bytes.
5. New world asset is integrated through the approved-art lifecycle.
6. No silent regeneration/recompression occurred.

## Single-world-background architecture
7. World 01 uses one complete background for city+portal+platform+props+helper bots.
8. No old sky/city/street layer is drawn over it.
9. No second arch/portal is drawn over it.
10. No HOME-010/HOME-011 platform is drawn over it.
11. No separate helper-bot/environment layers duplicate baked elements.
12. No live Whispering Park/Area overlay duplicates the baked sign.
13. Historical approved assets remain present and byte-identical.
14. Presentation accounting honestly marks superseded component art retired/baked rather than fake-visible.

## Scrubby geometry
15. Scrubby remains a separate runtime layer.
16. At canonical 1080x2160 center X is 540.
17. Feet anchor is Y=1297 within the documented tolerance.
18. Scrubby fits the documented safe box around x=353..727 / y=779..1297.
19. Actual visible feet, not transparent texture padding, touch the baked platform.
20. Scrubby does not cover the baked world sign.
21. Scrubby does not materially obscure baked helper bots.
22. Placement scales uniformly across required portrait viewports.

## Profile / HUD
23. Profile card remains narrow.
24. Portrait remains large and in front of frame.
25. Portrait bottom sits against the inner frame bottom.
26. Frame side/bottom remains visible.
27. Bot Parts bar is materially thicker than V03.
28. Bot Parts caption is numeric N/250 only.
29. Ratio is centered in the bar.
30. Level remains separate.
31. No top duplicate Settings/menu exists.

## Four-panel Home
32. Exactly four Home shortcut panels exist.
33. Left = SHOP, COLLECTION only.
34. Right = TASKS, DAILY only.
35. Win Streak panel absent.
36. Gifts panel absent.
37. No Ads panel absent.
38. Cards Exchange panel absent.
39. Removed panels do not delete underlying services/data.
40. Panels use one coherent smaller/lightweight style.
41. Panel backgrounds are near-transparent/light tint rather than heavy opaque cards.
42. Visible outer margin exists.
43. SHOP icon is enlarged.
44. COLLECTION icon is enlarged.
45. TASKS icon remains at current V03 size.
46. DAILY icon remains at current V03 size.
47. Panels do not cover Scrubby.
48. Panels do not materially cover baked helper bots.

## Play / reward
49. Play is standalone centered.
50. V03 Shop|Play|Cards row no longer exists.
51. Native white triangle remains.
52. HOME-078 remains retired.
53. Frontier subtitle remains live.
54. Coming-soon status is compact and does not distort reward track.
55. Reward track stays thin.
56. Five gifts remain.
57. Only 1/5/10/25/100 are shown under rewards.
58. No + / WIN N / repeated SB icons.
59. HOME-087 remains retired.
60. Current/reached/future state remains understandable.

## Currency / Gift Meter
61. Scrub Bucks icon is enlarged/foregrounded.
62. Heart icon is enlarged/foregrounded.
63. Scrub Bucks + button exists.
64. Hearts + button exists.
65. Plus buttons emit intent only and invent no transactions/prices.
66. Gift Meter remains ratio-only N/1000.
67. No long Next Gift/Event caption returns.
68. No old Coin/Star/XP/Event semantics return.

## Ownership / routing
69. Cards Exchange is no longer a Home shortcut and has Collection-owned routing seam.
70. No Ads is no longer a Home shortcut and has Shop-owned routing seam.
71. Gifts is no longer a Home shortcut while canonical reward services remain.
72. Win Streak is represented by reward track without Home shortcut.
73. Daily remains functional.
74. Settings remains bottom-nav only.

## Modal behavior
75. Daily modal hides Home action UI and blocks input behind it.
76. Settings modal hides Home action UI and blocks input behind it.
77. close/back restores exact Home action state.
78. modal architecture does not retain dead dependencies on removed shortcuts.

## Bottom nav / Ads
79. Bottom nav remains five buttons, Home selected, RANKS wording retained.
80. Dedicated AdBannerSlot exists below BottomNav.
81. AdBannerSlot is not fake ad content and has future provider integration seam.
82. AdBannerSlot can collapse for future No-Ads entitlement without breaking layout.
83. World background does not leak visually into the ad slot.

## Future-world seam
84. World background selection is data-driven/extensible.
85. No speculative level ranges/world mappings are invented.
86. World 01 is the current default.

## Regression / evidence
87. 83-row completion ledger exists with exactly 83 unique rows.
88. Required runtime evidence exists for 4 viewport sizes plus Daily/Settings/ad visible/ad collapsed.
89. Required focused suites pass exit 0.
90. Root suite passes exit 0 with zero SCRIPT ERROR.
91. git diff --check clean.
92. TASKS.md, owner artifacts and ChatGPT audit/criteria files were untouched by Claude.
93. No previously approved PNG changed.

## Final gate
Possible verdicts:
- `AUDITED_PASS / CODE READY FOR OWNER VISUAL REVIEW`
- `CHANGES_REQUIRED`

SB-M42-011 / SB-M42-017 remain open until owner reviews the new runtime Home screenshot.
