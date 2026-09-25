# OWNER M42 HOME VISUAL REVISION V03

Date: 2026-09-26
Authority: OWNER
Scope: Home visual/layout/modal behavior revision after V02 runtime review

This decision supersedes the prior Home visual target on the specific points below. It does not revoke the existing approved PNG byte approvals unless explicitly stated. Current ScrubBots economy/navigation semantics remain authoritative.

## A. Top profile / HUD

1. **Profile/robot card: narrow the WIDTH, do not generally shrink the whole card.**
   - The owner correction is specifically about horizontal width.
   - Preserve enough height for a stronger portrait treatment.

2. **Make the Scrubby portrait substantially larger.**
   - The current robot portrait reads too small.

3. **Create a “pop-out of the frame” portrait treatment.**
   - `ProfilePortrait` should draw in front of `ProfileAvatarFrame`.
   - The portrait may extend above/outside the frame's top boundary.
   - The avatar container must not clip the portrait.
   - The frame remains behind the robot image, so Scrubby feels like it is emerging from the frame.

4. **Remove the top-right Settings/menu button entirely.**
   - Settings already exists in the bottom navigation.
   - There must be only one visible Settings entry on Home: bottom nav.

5. **Bot Parts copy becomes compact.**
   - Do not show `BOT PARTS` inline beside the level.
   - The progress bar shows only the live numeric ratio, e.g. `0/250`.
   - Level remains a separate live badge/value.

## B. Gift Meter

6. Remove the long caption `GIFT METER N/1000 · NEXT GIFT AT X`.
7. Show only the live fill ratio, e.g. `0/1000`, in/over the meter.
8. Keep approved Gift Meter emblem and reward-crate presentation.
9. Preserve canonical Gift Meter logic; this is presentation-only.

## C. City background / street foreground

10. The Home must visibly read as a **city**, not mostly sky.
11. `home_bg_city_far` and `home_bg_city_mid` must be visibly present around/behind the portal.
12. Building masses must be visible to the LEFT, RIGHT and above/around the Whispering Park portal, not only through its opening.
13. Reduce empty-sky dominance.
14. Raise/recompose `home_bg_street_foreground`.
15. The visible street/foreground region should begin immediately above the five-button bottom navigation dock and extend upward enough to ground the world.
16. The bottom-nav dock must sit flush with the screen bottom; no extra game-background strip may remain underneath it.
17. The city, portal, platform and foreground must share one coherent perspective plane.
18. If the existing layered assets cannot produce an acceptable city result, a new **candidate** full lower-city/street foreground may be created, containing visible city architecture plus street perspective.
19. Any replacement candidate must remain under `assets/ui/generated/` until owner approval; do not overwrite the current approved final file.

## D. Whispering Park portal / world placement

20. Reposition the Whispering Park arch/portal so it feels physically embedded in the city scene.
21. The portal may not look suspended in empty sky.
22. The portal base must visually sit on the street/world plane.
23. The live `WHISPERING PARK / AREA N` treatment should visually integrate with the arch rather than read as a detached capsule floating in front.
24. Keep title/area values live/localizable.
25. Tune portal scale together with city visibility; do not solve one by simply oversizing the other.

## E. Platform / Scrubby

26. **Retire `HOME-011 / home_platform_top` from active Home presentation.**
   - Preserve the approved file/history.
   - Do not delete or modify its bytes.
   - It is no longer part of the owner's current Home composition.

27. Scrubby stands directly on `HOME-010 / home_platform_main`.
28. The main platform must read as the single physical support under Scrubby.
29. Remove the stacked/two-disc “wedding cake” appearance.
30. Main platform, portal base and street foreground must feel physically connected.

## F. Scrubby idle overlays

31. **Disable HOME-031 face/blink overlay in production Home.**
32. **Disable HOME-032 brush-arm overlay in production Home.**
33. Remove/disable the timer/state loop that causes an alternate face or alternate hand/arm to appear while the user waits.
34. Scrubby should remain visually stable while idle.
35. Preserve the approved HOME-031/HOME-032 files/history; they are owner-disabled from active Home presentation, not deleted.

## G. Shortcut / Play row

36. Side shortcut columns become **3 + 3**:
   - Left: WIN STREAK / GIFTS / COLLECTION.
   - Right: NO ADS / DAILY / TASKS.

37. Move SHOP out of the left column and place it directly to the LEFT of Play.
38. Move CARDS EXCHANGE out of the right column and place it directly to the RIGHT of Play.
39. Build a coherent lower action row: **SHOP | PLAY | CARDS EXCHANGE**.
40. Preserve full live/localizable shortcut labels and current enabled/disabled semantics.

## H. Play CTA

41. Reduce Play button width/height from the current oversized treatment.
42. Reduce PLAY text proportionally while keeping it the primary CTA.
43. Keep the live frontier/level subtitle compact and secondary.
44. Prefer a simple native white play triangle over the current “blue square button inside the green button” look.
45. If HOME-078 is no longer used as the visible play symbol, preserve its approved file/history and explicitly account for it as owner-retired from active presentation rather than pretending it is visible.

## I. Win Streak reward track

46. Reduce the reward-track panel height materially.
47. Gift objects remain the visual focus.
48. Under each gift show only the live value:
   - `1`
   - `5`
   - `10`
   - `25`
   - `100`
49. Remove repeated `+` prefixes.
50. Remove repeated Scrub Bucks icons from every reward step.
51. Remove `WIN 1 / WIN 2 / WIN 3 / WIN 4 / WIN 5+` copy from individual steps.
52. Keep current streak/progression state understandable without repeating redundant copy.
53. If the left streak badge is kept, scale it to the thinner track.

## J. Bottom navigation

54. Keep the current five-button bottom navigation as the only persistent Home nav/settings row.
55. Dock it flush to the bottom edge.
56. Street foreground begins immediately above this dock.
57. Do not leave an extra visible world/background strip below the dock.
58. Current selected HOME treatment remains clear.
59. Current `RANKS` label may remain for V03; do not invent a new product naming decision in this pass.

## K. Modal / overlay behavior

60. Current defect: Gifts, Daily and Settings overlays appear BEHIND the Home shortcut cards because Home cards have a higher visual layer.
61. **When any Home popup/overlay/page is open, Home actionable buttons must disappear from the background.**
62. This applies at minimum to:
   - Gifts/Gift Bar popup;
   - Daily popup;
   - Cards Exchange popup;
   - Settings panel.
63. Hide/disable the Home interactive surfaces while the modal is open, including shortcut cards and any other Home action controls that could visually or interactively compete with the modal.
64. The modal/panel itself must always render above the decorative Home background.
65. Hidden Home controls must not receive pointer/touch/keyboard input.
66. On modal close/back, the exact Home controls restore correctly.
67. Opening one modal must not leave another Home modal/action surface interactive behind it.
68. Back navigation behavior remains deterministic: close the top modal first.
69. Add focused regression tests for open/close behavior for Gifts, Daily, Cards Exchange and Settings.

## L. ChatGPT additional visual requirements accepted for V03

70. City visibility is a primary acceptance gate: the final screenshot must unmistakably read as a city scene.
71. Portal, main platform and street must form one grounded visual stack.
72. Side cards should frame Scrubby rather than squeeze him.
73. The lower screen silhouette should read:
   **SHOP | PLAY | CARDS EXCHANGE**
   then a thin reward track,
   then bottom navigation.
74. Do not reintroduce obsolete Coin/Star/XP/Event semantics while matching the master.
75. Preserve all dynamic values as live/localizable Godot UI.

## Presentation-accounting update

The V02 presentation model must be updated honestly.

Owner-retired/disabled assets in V03:
- HOME-011 platform top
- HOME-031 blink layer
- HOME-032 brush-arm layer
- HOME-087 per-step Scrub Bucks reuse in the reward track (owner removed repeated currency icons)
- HOME-078 only if replaced by the native white triangle per item 44

Do not delete these files. Do not falsify them as visible.

Introduce an explicit presentation-accounting mode such as `OWNER_RETIRED` / `OWNER_DISABLED` for approved historical assets that the owner no longer wants active. Tests must distinguish historical approval from active presentation.

## Final owner review

No V03 implementation self-closes SB-M42-011 or SB-M42-017. A new runtime screenshot is required after ChatGPT audit.
