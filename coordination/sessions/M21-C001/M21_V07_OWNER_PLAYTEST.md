# M21-C001 V07 — Owner Manual Playtest Guide (current)

Cycle `M21-C001` V07. This supersedes the V05 guide as the current manual run guide
(V05 stays historical). Automated headless checks are green; this is the owner's
**visual** confirmation. Owner manual PASS is not claimed here — it happens only
after the independent ChatGPT V07 audit.

## 1. Open and run

1. Pull latest `main` of `Sekiph82/Scrubbots`; open in Godot **4.7.1**.
2. Open `scenes/debug/m21_real_art_vertical_slice.tscn`.
3. Run the **current scene** with **F6**.

## 2. Interaction is slot-click ONLY

- **Do NOT press SPACE.** SPACE gameplay dispatch has been removed entirely. There
  is exactly one player-facing activation path: clicking a visible color slot.
- If pressing SPACE does anything gameplay-related, that is a bug — report it.

## 3. What you should see

- The **Hazard Bot** 20×20 artwork over BG01 (`#202533`).
- Exactly five color slots beneath the board: C01 Coral Red, C03 Sunny Yellow,
  C08 Deep Blue, C11 Earth Brown, C16 Pure Black (slots 0..4).

## 4. Exterior corridor behaviour to verify

1. On a fresh board, click the **Deep Blue (C08)** slot.
2. The **first** cleared target must be the **far-left bottom cell (0,19)** — the
   bottom-left corner of the artwork — not a cell directly under the slot.
3. Watch the Scrubbot: it leaves the clicked C08 slot, connects (down/up as needed)
   to the **one-cell exterior walking corridor** that runs around the outside of the
   board, travels **left along the outside** of the artwork, then enters (0,19) from
   below. It must NOT tunnel straight through the ACTIVE bottom-row artwork.
4. On arrival, exactly (0,19) clears to transparency (BG01 shows through).
5. Click C08 again: subsequent clears advance **left-to-right along the bottom row**
   ((1,19), (2,19), … i.e. indices 381, 382, …) while those cells stay
   targetable/unreserved.
6. Try other colors only once they become legitimately reachable (as interior C08
   clears open the artwork).
7. A color with **no currently reachable target** correctly spawns nothing and
   clears nothing.

## 5. Functional/debug vs final art

- The moving Scrubbot is the existing **debug marker**, not final M27 character art.
- The five slot buttons are **functional native Godot controls**, not final HUD art.
- The exterior corridor is **routing space only** — it is not drawn artwork, adds no
  board cells, and never changes the level palette.

## 6. Please report

Tunnelling through ACTIVE artwork, a wrong first target (anything other than
(0,19)), a marker that starts from a board edge instead of the clicked slot, a stuck
slot highlight, an orphan marker left behind, or any hidden keyboard dispatch.

Automated evidence does not equal your visual PASS.
