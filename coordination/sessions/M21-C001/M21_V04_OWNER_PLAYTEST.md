# M21-C001 V04 — Owner Manual Playtest Guide

Cycle `M21-C001` V04. This is the exact manual review the owner performs after the
independent audit. Automated headless checks are green; this guide is for the
owner's **visual** confirmation. Owner manual PASS is still pending until the owner
runs these steps.

## 1. Sync and open

1. Pull latest `main` of `Sekiph82/Scrubbots`.
2. Open the project in Godot **4.7.1**.

## 2. Open and run the scene

1. In the FileSystem dock open:
   `scenes/debug/m21_real_art_vertical_slice.tscn`
2. Run the **current scene** with **F6** (Run Current Scene). Do not change any
   gameplay script; the scene wires the real production systems on load.

## 3. What you should see

- The **Hazard Bot** 20×20 artwork rendered over the owner-locked BG01 Midnight
  Slate (`#202533`) background.
- A row of **exactly five color slots** beneath the board. Their colors are the M21
  local palette, in slot order 0..4:

  | Slot | Palette | Color |
  | --- | --- | --- |
  | 0 | C01 | Coral Red `#E94B4B` |
  | 1 | C03 | Sunny Yellow `#F2C94C` |
  | 2 | C08 | Deep Blue `#3451A3` |
  | 3 | C11 | Earth Brown `#956447` |
  | 4 | C16 | Pure Black `#000000` |

## 4. What to click and watch

1. Click the **Deep Blue (C08)** slot first — C08 is the frame/perimeter, so it has
   reachable targets on the fresh board.
2. Watch target priority: clearing begins at the **bottom-most, then left-most
   currently reachable** matching cell — no longer the top of the artwork. A
   geometrically low cell that is blocked/enclosed is skipped; the next reachable
   one in that bottom→top / left→right order is chosen.
3. Watch the **Scrubbot marker** (a small debug circle) leave from that slot's
   spawn origin (just off the left edge) and travel the real route across the board
   in the same coordinate space as the artwork — it is now plainly visible and
   aligned with the board, not a tiny dot at the window corner.
4. On arrival, exactly that target cell clears: it turns transparent and BG01 shows
   through (an ACTIVE→CLEARED hole).
5. Click again — the next reachable bottom/left target is chosen under the changed
   board state. Clearing C08 progressively opens the interior so the other colors
   (Coral Red, Sunny Yellow, Earth Brown, Pure Black) eventually become reachable
   and can be cleared too.
6. Clicking a color that has **no currently reachable target** (e.g. an enclosed
   interior color early on) does nothing — no Scrubbot, no clear. That is correct
   behavior, not a bug.

The SPACE key is a developer fallback that clears one reachable target; the visible
slots are the intended interaction.

## 5. What is functional/debug vs final art

- The moving Scrubbot is the **existing debug marker**, not the final Scrubbot
  character art (that is a later owner-approved character-visual milestone).
- The five slot components are **functional native Godot controls** for this
  vertical slice, not the final decorative slot/HUD art direction.
- No boosters, rewards, timers, win/lose, economy, Home/Results screens, or sound
  are part of this scene — intentionally out of V04 scope.
- The artwork, BG01 background, ACTIVE/CLEARED transparency, bottom/left target
  priority, and the real dispatch→route→arrival→clear chain are the **real
  production behavior** you are confirming.

## 6. Acceptance

You are confirming the flow:

```
five visible color slots
→ click a color
→ bottom-most/left-most reachable matching cell is chosen
→ a visible Scrubbot leaves the slot origin and travels the real route
→ authenticated arrival clears exactly that cell to transparency
→ the next activation continues from the next bottom/left reachable target
```

If that is what you see, M21 is ready for final strict closure on the visual axis.
