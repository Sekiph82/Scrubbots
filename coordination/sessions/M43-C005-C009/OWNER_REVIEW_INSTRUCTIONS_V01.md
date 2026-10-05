# M43-C005-C009 — OWNER REVIEW INSTRUCTIONS V01 — First-New-Card Celebration + Duplicate Count

Canonical task: SB-M43-067 · Requires **explicit OWNER VISUAL PASS** (after ChatGPT technical audit)

Both harnesses run the real shipping ceremonies (current code). They only wait for your clicks; nothing is
granted, saved or opened.

## Standard Pack

1. In the Godot editor open `res://tests/tools/owner_review/standard_pack_owner_review.tscn`.
2. Press **F6** (Run Current Scene).
3. Click once to open the pack (Tap 1). Wait until the three cards are held and the destination icons appear.
4. Click again to send the cards (Tap 2).

Keys:

| Key | What it shows |
|---|---|
| **1** | mixed: NEW / DUPLICATE (EXTRAS x1) / NEW — default |
| **2** | all NEW (three celebrations) |
| **3** | repeat: same card NEW then DUPLICATE (EXTRAS x1), plus an EPIC DUPLICATE (EXTRAS x4) |
| **4** | same card three times: FIRST COPY / EXTRAS x1 / EXTRAS x2 |
| **5** | all DUPLICATE: EXTRAS x1 / x3 / x8 (no glow, no celebration) |
| **E** | toggle FULL / Reduced Effects (restarts) |
| **R** | replay the current fixture |

## Premium Pack

1. Open `res://tests/tools/owner_review/premium_pack_owner_review.tscn`.
2. Press **F6**, then Tap 1 / Tap 2 as above.

| Key | What it shows |
|---|---|
| **1** | mixed: NEW, DUPLICATE x1, NEW, DUPLICATE x2, NEW — default |
| **2** | all NEW (five staggered celebrations) |
| **3** | repeat: FIRST COPY / EXTRAS x1 / EXTRAS x2 / EXTRAS x3 / EXTRAS x4 |
| **4** | duplicate-heavy: EXTRAS x2 / x1 / x5 / x3 / x10 |
| **E** / **R** | Reduced Effects toggle / replay |

## What to judge

1. **NEW glow / pop (FULL).** After the cards land in their slots and the pack has faded, each NEW card gets
   one short pulse: the card grows about 4% and back, and the canonical new-card glow
   (`card_new_glow.png`) swells behind it, then settles to a soft halo that stays during the hold. Several
   NEW cards pulse in model order, 0.1 s apart. It should feel positive but restrained: no looping, flashing,
   shaking or confetti.
2. **FIRST COPY.** Every NEW card shows the green **NEW** badge and **FIRST COPY** under its rarity.
3. **DUPLICATE.** Every duplicate shows the **DUPLICATE** badge and no glow.
4. **EXTRAS xN.** The duplicate count line reads **EXTRAS xN**, where N = copies owned after the pack − 1 (the
   first copy is protected). Check key 4 (Standard) or key 3 (Premium): x1, then x2 for the same card. NEW cards
   never show "EXTRAS x0".
5. **Premium 3 + 2 readability.** All five cards, badges, names, rarity chips and count lines stay readable,
   including key 2 (five glows) and key 4 (long "EXTRAS x10").
6. **Reduced Effects (E).** No pulse and no swell: the glow is a static soft halo, and NEW / FIRST COPY /
   DUPLICATE / EXTRAS read the same as FULL. Both taps are still required.
7. **Unchanged.** The pack art, the 01→09 frame cadence, card emergence, the 3-card and 3 + 2 layouts, the
   destination icons, the routing (NEW → Collection, DUPLICATE → Cards Exchange) and completion should look exactly
   as you accepted them. The only timing addition is the short pulse (0.4 s; 0.8 s with five NEW cards) between
   the pack fading and the destination icons appearing.

Reply with **OWNER VISUAL PASS** or list what to change.
