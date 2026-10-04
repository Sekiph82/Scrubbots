# Premium Pack — Owner Review V01 (SB-M43-065)

This scene is the **exact shipping Premium Card Pack ceremony**, wrapped in review-only tooling. Same interaction as the
accepted Standard Pack; the gold Premium pack and five cards are the difference.

## Steps

1. Open the Godot project: `C:\Users\sekip\Desktop\ScrubBots\project.godot`
2. In the **FileSystem** panel, open: `res://tests/tools/owner_review/premium_pack_owner_review.tscn`
3. Press **F6 — Run Current Scene**. (F5 is not required.)
4. First screen: the **Premium Pack alone**, "Tap to open". It waits for you.
5. **Click once.** Judge:
   - all **9 Premium opening beats** are visibly readable one after another (closed → charge → pressure → small tear →
     tear widens → card edge → one card rises → five cards emerge → final five);
   - **no rectangular / dark background box** around any frame or glow.
6. Watch the **five cards rise out of the five card backs** of the open pack; the pack then disappears.
7. Judge the **5-card hold**: 3 cards on top, 2 below, in draw order (top left = first card). The first card is always
   Rare, Epic or Legendary — that is the Premium guarantee, shown by its real rarity (there is no extra badge).
   Collection is upper-left, Cards Exchange upper-right, "Tap to collect your cards".
8. **Click again** and judge the routing: one card at a time, in draw order, NEW cards fly to Collection, DUPLICATE
   cards fly to Cards Exchange.
9. Press **R** to replay from the closed pack.
10. Press **E** to switch between Full and **Reduced Effects** (restarts; press E again to go back).
11. Press **1 / 2 / 3** to change the cards (each restarts from the closed pack):
    - **1** = mixed: Prism Bot EPIC NEW · Bubble Bucket DUP · Sewer Bubble NEW · Bug Vac RARE DUP · Moon Mop NEW (default)
    - **2** = all NEW: Rainbow Supreme LEGENDARY · Moppy · Shower Slime · Turbo Cleaner · Soap Bubbler
    - **3** = repeats: Power Core RARE NEW · Power Core DUP · Power Core DUP · Park Cleaner DUP · Park Cleaner DUP

After the cards are routed a small grey "Review complete" note appears; press R / E / 1 / 2 / 3 to continue. Close the
window to stop.

## Timing (same as the accepted Standard)

Frame 01 stays **0.40 s** after your click, frames 02..08 **0.22 s each**, frame 09 rests **0.30 s** before the cards
rise. Reduced Effects jumps to frame 09 and uses short fades; both clicks are still yours.

## Good to know

- Watch for any skipped-looking frame, any background box, overlapping or unreadable cards, and wrong destinations.
- Nothing here changes your save, Scrub Bucks, Collection or Cards Exchange. The cards are fixed test results.
- Nothing is clicked for you: both clicks are yours.
- Only you can give **OWNER VISUAL PASS**; give it only after judging the live motion.
