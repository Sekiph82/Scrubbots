# OWNER M42 HOME REBUILD V04 — SINGLE WORLD BACKGROUND ARCHITECTURE

Date: 2026-09-26
Authority: OWNER
Scope: Home architecture + World 01 visual rebuild
Status: ACTIVE / supersedes prior Home composition choices where conflicting

## Approved World 01 source asset

Owner-approved visual: the latest generated Whispering Park scene containing:
- city/environment;
- Whispering Park arch/portal;
- baked text `WHISPERING PARK / AREA 1`;
- the world platform;
- world props;
- helper bots;
- reflective street/foreground.

Canonical production dimensions: **1080 x 2160 px**
Aspect ratio: **1:2 exactly**
SHA-256 of the exact canonical 1080x2160 asset prepared by ChatGPT:
`8e04eda668aabd9f96172c0e82fd7dd47e61083cb691402a313120443a525e5b`

Expected owner-inbox path before promotion:
`assets/art/references/_owner_inbox/world_01_whispering_park_1080x2160.png`

Target production path after owner-byte verification:
`assets/ui/final/home/worlds/world_01_whispering_park_1080x2160.png`

If the exact source file is missing locally, STOP. Do not recreate or approximate it.

## Exact Scrubby placement contract on the 1080x2160 world image

The world background is a complete composition. Scrubby remains a separate runtime layer.

Canonical background coordinates:

- canvas: `1080 x 2160`
- world center X: **540**
- platform top visual region, approx:
  - left **256**
  - top **1240**
  - right **826**
  - bottom **1337**
- Scrubby feet anchor: **(540, 1297)**
- recommended Scrubby visual safe box:
  - left **353**
  - top **779**
  - right **727**
  - bottom **1297**
  - width **374**
  - height **518**
- Scrubby texture must use KEEP_ASPECT_CENTERED / equivalent.
- feet, not texture bounding-box bottom whitespace, must align to the feet anchor.
- Scrubby must not cover the baked `WHISPERING PARK / AREA 1` sign.
- Scrubby must not cover the baked helper bots.

These coordinates are canonical at 1080x2160 and must scale uniformly for other portrait viewports.

## 83-point V04 owner contract

1. Home is rebuilt around one complete world-background image per world, not separate city/portal/platform/helper composition layers.
2. World 01 uses the owner-approved `world_01_whispering_park_1080x2160.png`.
3. The World 01 background contains the city, sky, portal, platform, street, props and helper bots as one composition.
4. The current sky proportion in the approved World 01 image is accepted and must not be reduced.
5. `WHISPERING PARK` is baked into World 01 art.
6. `AREA 1` is baked into World 01 art.
7. Godot must not add a second live Whispering Park title over this image.
8. Godot must not add a second portal/arch over this image.
9. Godot must not add HOME-010 or HOME-011 platform art over this image.
10. Godot must not add separate helper-bot art over this image.
11. Godot must not add the old HOME-001..004 layered sky/city/street art over this image.
12. Godot must not add old environment-prop layers that are already represented in the baked world background.
13. Old approved component files/history remain preserved; they are retired from active World 01 Home presentation, not deleted.
14. The world background fills the Home world canvas with aspect-correct scaling and no non-uniform stretch.
15. The approved 1080x2160 background is the canonical coordinate space for World 01 Home composition.

16. Scrubby remains a separate runtime sprite/TextureRect above the baked world background.
17. Scrubby is centered on X=540 at canonical 1080x2160.
18. Scrubby feet anchor is canonical `(540, 1297)`.
19. Scrubby recommended visual safe box is `x=353..727, y=779..1297`.
20. Scrubby preserves aspect ratio inside that placement contract.
21. Scrubby's actual visible feet, not transparent texture padding, must sit on the baked platform.
22. Scrubby must not cover the baked world-name sign.
23. Scrubby must not cover or visually erase the baked helper bots.

24. Profile card remains horizontally narrow; do not restore the oversized V02 width.
25. Profile Scrubby portrait remains large.
26. Profile portrait remains in front of the avatar frame with the pop-out effect.
27. Profile portrait bottom must sit against the inner bottom of the avatar frame instead of floating.
28. Frame side/bottom segments must remain visibly readable behind the portrait.
29. Profile progression bar must be thicker than the current V03 line.
30. Bot Parts copy is numeric ratio only, e.g. `1/250`.
31. Bot Parts ratio is centered inside the progression bar.
32. Level badge remains separate and visually attached to the same progression row.
33. No duplicate top-right Settings/menu button returns.

34. Home has exactly **four** shortcut panels.
35. Left shortcut column contains only **SHOP** and **COLLECTION**.
36. Right shortcut column contains only **TASKS** and **DAILY**.
37. WIN STREAK shortcut panel is removed from Home.
38. GIFTS shortcut panel is removed from Home.
39. NO ADS shortcut panel is removed from Home.
40. CARDS EXCHANGE shortcut panel is removed from Home.
41. The four panel backgrounds become smaller/lighter than V03.
42. Panel surfaces should be near-transparent with only enough dark/blue tint, outline or glow for readability.
43. SHOP icon is enlarged relative to its current V03 size.
44. **TASKS icon stays at its current size.**
45. **DAILY icon stays at its current size.**
46. COLLECTION icon is enlarged relative to its current V03 size.
47. All four panel containers use the same size/style system even though icon sizes may differ.
48. Panels receive visible outer-screen margin and may not stick directly to the screen edges.

49. The four panels must not cover Scrubby.
50. The four panels must not cover important baked helper bots.
51. The four panels frame the world composition instead of dominating it.
52. PLAY returns to a centered standalone CTA; the V03 `SHOP | PLAY | CARDS EXCHANGE` row is retired.
53. Current V03 Play size is a good starting point; do not enlarge it back to V02.
54. Native white play triangle remains.
55. Live `PLAY/CONTINUE` and frontier-level subtitle remain runtime text.
56. `Level N is coming soon` status must stay compact near Play and must not distort reward-track layout.
57. HOME-078 remains retired from active Play presentation.

58. Win Streak progression remains represented by the lower reward track, so no separate Win Streak shortcut is needed.
59. Reward track remains thin.
60. Reward track shows the five gift objects.
61. Reward values remain only `1 / 5 / 10 / 25 / 100`.
62. No per-step `+`, no per-step `WIN N`, no repeated per-step Scrub Bucks icons.
63. HOME-087 remains retired from active per-step reward presentation.
64. Current/reached/future Win Streak state remains visually understandable.

65. Scrub Bucks and Heart icons are enlarged toward the approved target-HUD visual language.
66. Currency/Heart icons sit in front of their chip panels so the panel appears to extend from behind the icon.
67. Add a visible `+` button to the right side of Scrub Bucks.
68. Add a visible `+` button to the right side of Hearts.
69. These `+` buttons emit purchase/open-store intent only; do not invent transactions or prices.
70. Gift Meter keeps the compact live ratio-only form `N/1000`.
71. Gift Meter emblem/crate may be modestly enlarged for visual balance.
72. No long `GIFT METER ... NEXT GIFT ...` caption returns.
73. No obsolete Coin/Star/XP/Event semantics return.

74. Cards Exchange becomes a Collection-owned flow/entry point, not a Home shortcut.
75. No Ads becomes a Shop-owned flow/entry point, not a Home shortcut.
76. Gifts are not a Home shortcut; reward granting/claim behavior remains service-driven/automatic according to canonical game rules.
77. Removing Home shortcuts must not delete their underlying economy/services/data.
78. Daily remains the only directly opened economy/reward popup among the four Home panels in this pass; existing modal behavior remains deterministic.
79. When a modal/page such as Daily or Settings opens, Home action UI must hide and must not receive input; V03 modal regression behavior is preserved.
80. Bottom navigation remains five buttons with HOME selected and current RANKS wording preserved.
81. A dedicated persistent `AdBannerSlot` sits below BottomNav; BottomNav is no longer required to be the screen-bottom element.
82. The world background must stop above/behind the UI composition and may not visually leak into the AdBannerSlot; No-Ads entitlement can later collapse the ad slot.
83. Introduce a data-driven World Home background seam for future worlds, but DO NOT invent level ranges yet. World 01 is the current default; future world IDs/backgrounds can be mapped once owner-defined progression ranges exist.

## World architecture rule

Future worlds should be represented by one complete world background each, sharing the same canonical composition template:
- 1080x2160;
- world title/area baked into art;
- portal/platform/environment/helper bots baked into art;
- Scrubby placement anchor contract kept compatible where practical;
- dynamic HUD/buttons/reward/nav/ad remain Godot UI.

Do not hardcode speculative level ranges such as 1-100 / 101-200 until the owner defines them.
