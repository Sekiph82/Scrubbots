# M43-C005-C003 — COLLECTION CARD PROVENANCE FINDING V01

Date: 2026-10-03
Status: VERIFIED

## What happened

The current canonical 135 Collection card PNGs under
`assets/ui/final/collection/cards/set_01..set_15/card_01..card_09.png`
were introduced on 2026-09-19 in commit:

`47b4343defe8d33a10b6396be73afab5b7dd1656`
(`assets(codex): generate isolated visual asset batch`)

Repository history for the canonical card directory shows no later commit replacing those 135 PNGs.

The visual-asset master list explicitly instructed the worker to derive card identity from the owner 3x3 reference sheets and said:

`Prefer clean extraction/crop over regeneration when possible.`

The matching Codex visual log confirms VA-163..VA-297 were fulfilled by **extracting the 135 cards from the 15 approved 3x3 Collection composites**, not by producing 135 fresh independent high-resolution card assets.

## Later owner correction

On 2026-09-23 the owner explicitly directed that all 135 cards be redone **one by one** and not remain cropped screenshot/composite fragments.

That owner correction did not result in a later commit replacing the canonical 135 card files on `main`.

Therefore the project later treated “135 card assets exist” as equivalent to “135 final card assets are ready”, even though provenance remained the old 3x3 extraction batch.

## Root cause

This was a tracking/provenance failure:

1. file-count completeness (135/135 paths exist) was treated as production completeness;
2. the older “prefer crop/extraction” instruction remained in the visual-asset master list;
3. the later owner instruction to regenerate each card independently was not promoted into a completed asset replacement commit;
4. later ceremony work consumed the existing canonical paths and exposed the low-resolution/crop-edge problem again.

## Owner lock from now on

The 135 final Collection cards must be rebuilt **individually, one card at a time**.

- No final card may be a crop from a 3x3 sheet.
- No final card may be produced by generating a multi-card sheet and slicing it.
- One card = one independent generation/output asset.
- Owner source sheets are identity/name/rarity/theme references only.
- Primary builder: Claude.
- If Claude has no approved image-generation capability, it must stop cleanly and hand back a blocker. ChatGPT will then hand the exact same production contract to Codex.
