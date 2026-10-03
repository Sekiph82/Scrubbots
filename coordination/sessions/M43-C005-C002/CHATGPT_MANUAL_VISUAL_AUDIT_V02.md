# M43-C005-C002 — CHATGPT MANUAL VISUAL AUDIT V02

Date: 2026-10-03
Audited implementation: `6a6b05462366b9b9d19d93190905fdc286fd2878`
Scope: current 18 Standard/Premium pack-opening PNGs after card-count remediation
Result: **PARTIAL_VISUAL_PASS / TARGETED_REMEDIATION_REQUIRED**

## Audit method

I manually reviewed the current V02 Standard and Premium contact sheets frame-by-frame and cross-checked the current per-frame paths, manifest card counts and the Codex V02 log.

This audit does not accept metadata as a substitute for visible content. Card count and depth are judged from the rendered images first, then cross-checked against the manifest.

## Standard Pack

1. **Frame 01 Closed — PASS**
   - Clean owner-approved Standard identity.
   - Sealed pack, no premature effect.

2. **Frame 02 Charge — PASS**
   - Subtle buildup.
   - Identity and scale remain stable.

3. **Frame 03 Pressure — PASS**
   - Pressure/energy reads clearly while pack remains sealed.

4. **Frame 04 First Tear — FAIL**
   - Still too advanced for a first 20–25% center tear.
   - Opening and golden burst are too large.
   - Must become a much smaller initial rupture with restrained light.

5. **Frame 05 Tear Widens — PASS**
   - Works as the later wide-tear beat.
   - Keep unchanged after Frame 04 is reduced.

6. **Frame 06 Card Edge — FAIL**
   - Exactly-one-card metadata exists, but the card edge is not visually distinct enough from the bright opening.
   - The viewer should immediately read “one card has just started to emerge.”
   - The card edge must be visibly behind the torn front lip.

7. **Frame 07 One Card Rises — PASS**
   - Exactly one card is visibly present.
   - The card reads as rising from the pack rather than floating separately.
   - Keep unchanged.

8. **Frame 08 Three Cards Emerge — FAIL ON DEPTH COMPOSITION**
   - Card count is now visibly correct: exactly **3**.
   - Fan spacing is acceptable.
   - However, the lower card portions are clipped along a visually straight/common opening line.
   - This still reads as a compositor crop more than a physical torn foil foreground.
   - Replace the flat/common cutoff with the actual irregular torn front foil lip as a foreground occluder.
   - Keep exactly 3 cards and current general fan geometry.

9. **Frame 09 Final Three-Card Reveal — PASS**
   - Card count is now visibly correct: exactly **3**.
   - Final fan is clean and readable.
   - Full-card reveal is acceptable for the final beat.
   - Keep unchanged.

## Premium Pack

1. **Frame 01 Closed — PASS**
   - Strong Premium identity and clean separation from Standard.

2. **Frame 02 Charge — PASS**
   - Subtle premium buildup is readable.

3. **Frame 03 Pressure — PASS**
   - Pressure beat reads correctly while pack remains sealed.

4. **Frame 04 First Tear — FAIL**
   - Still too advanced for the requested first 20–25% center tear.
   - Opening/glow should be smaller and earlier in the sequence.

5. **Frame 05 Tear Widens — PASS**
   - Good later wide-tear beat.
   - Keep unchanged.

6. **Frame 06 Card Edge — FAIL**
   - One-card metadata exists, but the edge is visually lost in the glow.
   - Make one blue/gold card top edge unmistakably visible at roughly 15–20% exposure, behind the torn front lip.

7. **Frame 07 One Card Rises — PASS**
   - Exactly one card.
   - Visually reads as emerging from the pack.
   - Keep unchanged.

8. **Frame 08 Five Cards Emerge — FAIL ON DEPTH COMPOSITION**
   - Card count is visibly correct: exactly **5**.
   - Fan spacing is readable.
   - But all five lower card portions terminate on a common flat-looking clipping line.
   - The owner locked a real foreground-depth rule: card roots must disappear behind the irregular torn front foil lip, not a simple horizontal crop.
   - Keep exactly 5 cards and current general fan geometry; replace only the occlusion method/visual.

9. **Frame 09 Final Five-Card Reveal — PASS**
   - Card count visibly correct: exactly **5**.
   - Strong final Premium fan.
   - Full-card final beat is acceptable.
   - Keep unchanged.

## Current remaining remediation only

### Standard
- Frame 04
- Frame 06
- Frame 08

### Premium
- Frame 04
- Frame 06
- Frame 08

All other current frames are visually frozen unless a tiny registration repair is strictly required.

## Hard rule for Frame 08

The previous Codex log states the cards were “clipped at the opening line.” That is not sufficient for the owner's depth requirement.

Required visible layer order:

1. rear glow / rear particles;
2. card fan;
3. **actual irregular torn front foil lip + pack front body**;
4. optional foreground foil fragments.

The torn lip itself must cross in front of card roots with a non-straight foil contour. A flat horizontal alpha cutoff is a FAIL even when card count is correct.

## Result

**M43-C005-C002 current state = PARTIAL_VISUAL_PASS / TARGETED_REMEDIATION_REQUIRED**

Accepted and frozen:
- Standard 01/02/03/05/07/09
- Premium 01/02/03/05/07/09

Remediate only:
- Standard 04/06/08
- Premium 04/06/08
