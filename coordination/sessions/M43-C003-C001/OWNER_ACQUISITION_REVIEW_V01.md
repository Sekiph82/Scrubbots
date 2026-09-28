# M43-C003-C001 — OWNER ACQUISITION VISUAL REVIEW V01

Date: 2026-09-28
Status: PENDING OWNER REVIEW (the technical audit happens first). This is not self-approved.

All screenshots are in `evidence/` and come from the real app on Home or Level 2. Every surface uses the approved M43-C002 popup family and existing production art. Every number, price, timer and label is live Godot text.

## Review items

| # | Topic | Current candidate | Evidence |
|---|---|---|---|
| A1 | **Life fidelity to the selected Life reference** | Sprout-Scrubby peeking over the frame, royal LIFE pill, big red heart with the live count, "Next life in:" panel with a clock pill, "You have N SB", two yellow SB offers with +N heart badges (+1 = 500 SB, refill = 400 × missing), green FREE video CTA with a play glyph and a +1 badge, and a "Keep going! You're doing great!" note at the bottom. The frame is the approved cream/cyan medium frame, not the reference's plain blue. The close button is the approved royal X, not the reference's red X. | `life_partial_rewarded_available_*`, `life_full_5of5_*`, `life_zero_heart_gate_*` |
| A2 | **Full 5/5 state** | "Hearts full!" + static 15:00; offers greyed; refill shows FULL (no price); "Your Hearts are full. Go play!" | `life_full_5of5_*` |
| A3 | **Rewarded unavailable (the production default until M57)** | FREE becomes a greyed **NO VIDEO** plus "Free videos aren't available right now." | `life_rewarded_unavailable_*` |
| B1 | **Booster Acquire hierarchy** | Booster name pill, then the icon beside the effect sentence and "Owned: N", then a target picker (Selector: batch chips with colour + count; Tornado: colour swatches), then balance, then yellow **USE · price SB**, then green **FREE** (video). With an owned charge it shows a single green **USE (N OWNED)** and no purchase CTA. | `booster_*` |
| B2 | **Safety state** | A red line, e.g. "+1 Slot is already active this level.", and the SB CTA greys out | `booster_plus_one_slot_already_used_*` |
| C1 | **Rewarded WATCH/GET placement** | Full-width green FREE CTA below the yellow SB CTA. The play glyph is on the left; the +1 badge sits at the top-right corner. There is no rewarded CTA on 2x, Pause, confirmations, error, loading or generic insufficient-SB. | `life_*`, `booster_*` |
| D1 | **2x offer hierarchy** | 2x emblem, entitlement state ("2x is not active" / "Active · 15:00 left" / "Active for this level") and balance. A one-line explainer. A 2×2 grid of yellow offers: THIS LEVEL 200, 15 MIN 300, 30 MIN 500, 60 MIN 750. While timed 2x is active the offers read "+15 MIN" etc. (they extend it). CANCEL is below. | `speed_*` |
| E1 | **Insufficient SB → Shop handoff clarity** | "NOT ENOUGH SB · <item> costs N SB · You have X SB · Y SB short", then **GET SCRUB BUCKS** / CANCEL. GET SCRUB BUCKS opens the Shop state: "The Shop is opening soon. Nothing was charged. Needed for: <item> (N SB)" with BACK. BACK returns to the popup the player came from. | `life_insufficient_sb_*`, `booster_insufficient_sb_*`, `booster_shop_handoff_*`, `speed_insufficient_sb_*`, `shop_handoff_from_home_sb_plus_*` |
| F1 | **Text density / readability** | 30 px body, 44 px titles, 34 px CTAs, 24 px notes. At 1080×1920 the Selector with 12 chips fits. | `*_short_phone_*` |
| G1 | **Popup family consistency** | All surfaces use the medium frame plus the family pill, green/cream CTAs, and the new yellow **offer** CTA (taken from the Life reference). | all |

## Owner decisions requested

1. **A1 / G1 — Life frame and close button.**
   - Keep the approved family frame and royal X (current)?
   - Or match the Life reference's blue frame and red X more literally? That would need an owner-approved variant; no art has been generated for it.
2. **B1 — Selector/Tornado target picker.** No target-selection UI existed before this cycle, and no TASKS row owned it. Without one, a Selector/Tornado purchase could never execute. So the one Booster Acquire component now carries the picker, which offers only solver-safe batches for Selector and colours present on the board for Tornado. Do you approve this as the V1 target selection, or should target picking move to an in-board interaction in a later cycle?
3. **C1 — Rewarded offer while the booster is not currently legal.** Per the prompt (§F), a rewarded grant made while the booster is illegal keeps the charge, so FREE stays offered and the player receives a saved charge. Keep that, or hide FREE while the booster is illegal?
4. **D1 — 2x layout.** Is the 2×2 offer grid OK, and is the "+15 MIN" extension wording OK?
5. **E1 — Shop placeholder copy.** Until M43-C006 exists, the Shop is an explicit "coming soon" state. Is the copy OK?
6. **Zero-Heart gate on Pause → Restart.** A Restart that would leave 0 Hearts opens Life instead of restarting, and nothing is consumed. Confirm this interpretation of the owner rule "zero-Heart attempt gate".
