# M43-C005-C002 — PACK ASSET VISUAL REMEDIATION V03

Status: READY FOR CODEX
Date: 2026-10-03
Repository: Sekiph82/Scrubbots
Branch: main
Task: SB-M43-076
Do not edit root TASKS.md.

## First action
Safely sync local checkout with origin/main exactly as required by repository governance. Preserve all owner-local work. No destructive reset/clean/force push.

## Read
- CHATGPT_PROMPT_V02.md
- CHATGPT_AUDIT_CRITERIA_V01.md
- PACK_ASSET_MANIFEST_V01.json
- OWNER_PACK_ASSET_REVIEW_V01.md
- CHATGPT_AUDIT_V01.md for this C002 session

## Mission
Do not regenerate the whole asset family. Preserve accepted frames/pack identity and remediate only the visually weak beats.


## DEPTH / OCCLUSION LOCK — OWNER DECISION

For every card-emergence frame, the visual must read as **cards physically emerging from inside the pack**, never as a card layer pasted on top of the pack.

Required compositing order:

1. **Back layer:** internal glow, rear particles, rear foil fragments.
2. **Middle layer:** card / card fan.
3. **Front layer:** the pack front body + irregular torn front foil lip.
4. **Optional foreground:** a few front foil fragments / sparkles.

Critical rule:
- the lower portion of each emerging card must pass **behind the pack's real torn front lip**;
- the front foil lip must visibly occlude the card roots;
- do not achieve this with a flat horizontal mask alone;
- use the actual irregular torn front edge/foil shape as the occluding foreground;
- the result must clearly communicate "cards are inside the pouch and are rising out of it."

For Frames 07 and 08 in both packs:
- at least roughly the lower **20–25%** of the card body at the opening should remain hidden behind the pack front lip where physically appropriate;
- the card should visually continue downward into the pouch;
- internal glow should originate behind/inside the pack, not sit as a flat overlay in front of the pouch.

For Frame 09:
- cards may be fully revealed, but their lower roots must still visually connect to the opening;
- keep enough front-lip overlap / depth cue that the fan does not look pasted onto the pack.

This depth rule is a hard visual gate. A frame that has the correct card count but looks composited on top of the pouch is **FAIL**.

### Standard
- Frame 01: keep.
- Frame 02: keep.
- Frame 03: keep.
- Frame 04: reduce to a true first tear, centered, about 20–25% pack width. Reduce burst intensity. It must read materially earlier than Frame 05.
- Frame 05: keep unless minor adjustment is necessary for continuity after Frame 04.
- Frame 06: make the top edge of exactly ONE card clearly visible 15–20% above the opening. Card edge must be readable against the glow.
- Frame 07: keep the one-card timing and count, but **fix depth if needed** so the lower ~20–25% of the card is clearly occluded by the pack's irregular torn front lip. Card must read as emerging from inside the pouch, not pasted on top.
- Frame 08: **CURRENT PNG IS WRONG: it visibly contains FIVE cards.** Discard/regenerate this frame so it contains exactly THREE card backs, no hidden fourth/fifth card, with all three silhouettes immediately distinguishable. Center highest, left/right approximately ±10–12°. All three card roots must sit behind the irregular torn front foil lip so the fan visibly emerges from inside the pack.
- Frame 09: **CURRENT PNG IS WRONG: it visibly contains FIVE cards.** Discard/regenerate this frame so it contains exactly THREE full card backs, no hidden fourth/fifth card, in a clean fan with clear negative space; center highest, left/right approximately ±14°. Preserve a clear depth connection to the opening: the fan must not appear pasted onto the pack.

### Premium
- Frame 01: keep.
- Frame 02: keep.
- Frame 03: keep.
- Frame 04: reduce to a true 20–25% centered initial tear with less burst intensity.
- Frame 05: keep unless continuity requires a minor adjustment.
- Frame 06: make exactly ONE card edge visibly readable at 15–20% exposure.
- Frame 07: keep the one-card timing and count, but **fix depth if needed** so the lower ~20–25% of the card is clearly occluded by the Premium pack's irregular torn front lip. Card must read as emerging from inside the pouch, not pasted on top.
- Frame 08: exactly FIVE cards, but spread the fan slightly so all five silhouettes are distinct. Keep geometry near -20/-10/0/+10/+20 degrees. All five card roots must visually sit behind the torn front foil lip, with the pack foreground clearly occluding the lower card portions.
- Frame 09: keep if the improved Frame 08 reads naturally into it; otherwise make only the minimum fan-spacing/depth adjustment necessary. Preserve exactly five cards and premium identity. Maintain a clear physical depth cue from the opening so the fan never reads as a flat overlay.

## Locks
- Same owner-approved Standard/Premium pack identities.
- Same 1024×1536 RGBA transparent canvases.
- Same registration/bottom anchor.
- Same blue/gold card-back family.
- No card faces, rarity, NEW/DUPLICATE, UI or text additions.
- No runtime wiring.
- No Collection-card cleanup here.
- No Booster-of-choice work here.
- No Legendary Pack.
- Do not touch accepted C005 ceremony candidates.

## Validation
Regenerate only changed frames, update manifest hashes/bounds/margins, rebuild contact sheets and owner review V02.

For Standard Frames 08 and 09, do **visual pixel/content verification**, not metadata-only validation. The prior manifest falsely said 3 while the PNG visibly showed 5. The validator must fail if rendered content count and metadata disagree. Include a manual visual-count note in CODEX_LOG_V02.

Also visually verify depth/occlusion for Standard 07/08/09 and Premium 07/08/09. The audit note must explicitly state whether each card set is behind the real torn front foil lip and whether the image reads as cards emerging from inside the pouch.

Create:
- OWNER_PACK_ASSET_REVIEW_V02.md
- CODEX_LOG_V02.md

Run the same 18-frame validator and git diff --check.

Return final SHA, changed frame list, validation summary, Standard/Premium contact-sheet links and OWNER_PACK_ASSET_REVIEW_V02.md URL.

Finish exactly:
AWAITING_GPT_M43_C005_C002_V03_AUDIT
