# Standard Pack — Owner Review V02 (current V03 ceremony)

This scene is the **exact current V03 shipping Standard Pack ceremony** (clean transparent frames + visible 01→09
cadence), wrapped in review-only tooling. Nothing in it is shipping UI.

## Steps

1. Open the Godot project: `C:\Users\sekip\Desktop\ScrubBots\project.godot`
2. In the **FileSystem** panel, open: `res://tests/tools/owner_review/standard_pack_owner_review.tscn`
3. Press **F6 — Run Current Scene**. (F5 is not required.)
4. First screen: the **Standard Pack alone**, "Tap to open". It waits for you.
5. **Click once.**
6. Judge the opening:
   - are **all 9 opening beats** visibly readable, one after another (closed → charge → pressure → small tear →
     tear widens → card edge → one card rises → three cards emerge → final three)? Does any beat look skipped?
   - is there **no rectangular / dark background box** around any frame or its glow? (Frames 05/07/09 used to have a
     black box, 06/08 a dark haze.)
7. Wait for the three cards with **Collection** (upper-left) and **Cards Exchange** (upper-right) and
   "Tap to collect your cards".
8. **Click again** and judge the routing: NEW cards fly to Collection, DUPLICATE cards fly to Cards Exchange.
9. Press **R** to replay from the closed pack.
10. Press **E** to switch between Full and **Reduced Effects** (restarts from the closed pack; press E again to go back).
11. Press **1 / 2 / 3** to change the cards (each restarts from the closed pack):
    - **1** = mixed: Mud Blob NEW · Greasy Pan DUPLICATE · Scrubbot Prime NEW (default)
    - **2** = all NEW: Scrubby · Turbo Wheels · Storm Cleaner
    - **3** = repeat: Mighty Mop NEW · Mighty Mop DUPLICATE · Sludge Beast DUPLICATE

After the cards are routed a small grey "Review complete" note appears; press R / E / 1 / 2 / 3 to continue. Close the
window to stop.

## V03 FULL timing (what you are judging)

- frame 01 (closed pack) stays **0.40 s** after your click;
- frames 02..08 stay **0.22 s each**;
- frame 09 (open pack, three card backs) rests **0.30 s**, then the cards rise out of it.

Reduced Effects skips straight to frame 09 and uses short fades; both clicks are still yours.

## Good to know

- Watch specifically for **any skipped-looking frame** and **any remaining rectangular matte**.
- Nothing here changes your save, Scrub Bucks, Collection or Cards Exchange. The cards are fixed test results.
- Nothing is clicked for you: both clicks are yours.
- Only you can give **OWNER VISUAL PASS**; give it only after judging the live motion.
