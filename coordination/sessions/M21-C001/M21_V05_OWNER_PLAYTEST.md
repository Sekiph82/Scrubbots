# M21-C001 V05 — Owner Manual Playtest Guide (current)

Cycle `M21-C001` V05. This supersedes the V04 guide as the current manual run
guide (the V04 guide stays as history). Automated headless checks are green; this
is the owner's **visual** confirmation. Owner manual PASS is not claimed here — it
happens only after the independent ChatGPT V05 audit.

## 1. Open and run

1. Pull latest `main` of `Sekiph82/Scrubbots`; open in Godot **4.7.1**.
2. Open `scenes/debug/m21_real_art_vertical_slice.tscn`.
3. Run the **current scene** with **F6**. The scene wires the real production
   systems on load; do not edit gameplay scripts.

## 2. What you should see

- The **Hazard Bot** 20×20 artwork over the owner-locked BG01 (`#202533`).
- A row of **exactly five** color slots beneath the board:

  | Slot | Palette | Color |
  | --- | --- | --- |
  | 0 | C01 | Coral Red `#E94B4B` |
  | 1 | C03 | Sunny Yellow `#F2C94C` |
  | 2 | C08 | Deep Blue `#3451A3` |
  | 3 | C11 | Earth Brown `#956447` |
  | 4 | C16 | Pure Black `#000000` |

## 3. What to click and watch

1. Click the **Deep Blue (C08)** slot first (C08 is the frame, reachable on the
   fresh board).
2. **Target policy:** clearing chooses the **bottom-most, then left-most currently
   targetable** matching cell — not the top of the art. Blocked/enclosed cells are
   skipped; the next reachable one in that order wins.
3. **Scrubbot origin (fixed in V05):** the marker now departs from the **actual
   clicked slot's visible spawn anchor** (top-center of that slot button), mapped
   into the board coordinate space — no longer an unrelated board edge. It travels
   the real route and arrives at the exact target cell center.
4. On arrival, exactly that cell clears to transparency (BG01 shows through).
5. **Movement speed (fixed in V05):** the marker moves at the real single agent
   speed — the previous accelerated/near-instant flash is gone (the scene no longer
   double-drives the agent).
6. **Concurrency (fixed in V05):** try **rapid clicks on the same slot** — if
   gameplay permits, several distinct Scrubbots dispatch and the slot stays
   highlighted while **any** of them are still in flight, going inactive only after
   the last finishes. After other colors become reachable, click **different**
   slots; each slot's active highlight is independent.
7. A color with **no currently reachable target** correctly spawns nothing and
   clears nothing.

SPACE remains a developer fallback; the visible slots are the intended interaction.

## 4. Functional/debug vs final art

- The moving Scrubbot is the **existing debug marker**, not final M27 character art.
- The five slot buttons are **functional native Godot controls**, not the final
  decorative slot/HUD art direction.
- No boosters, rewards, timers, win/lose, economy, Home/Results, or audio are in
  this scene — intentionally deferred.
- Broad five-slot layout direction referenced the owner canonical gameplay screen
  (`ASSET_GENERATION_MANIFEST.json` → `canonical_references.gameplay` =
  `assets/art/references/_owner_inbox/Game Screens/deneme 3 OK.png`) for slot
  count/placement intent only; it was **not** flattened/copied into the runtime.

## 5. Acceptance flow

```
five visible color slots
→ click a color
→ bottom-most/left-most reachable matching cell chosen
→ a visible Scrubbot departs the clicked slot's visible anchor
→ travels the real route at real speed
→ authenticated arrival clears exactly that cell to transparency
→ rapid same-slot / cross-slot activations keep each slot's highlight independent
   until its own assignments finish
```

If that is what you see, M21 is ready for final strict closure on the visual axis.
Automated evidence does not equal your visual PASS.
