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

### Standard
- Frame 01: keep.
- Frame 02: keep.
- Frame 03: keep.
- Frame 04: reduce to a true first tear, centered, about 20–25% pack width. Reduce burst intensity. It must read materially earlier than Frame 05.
- Frame 05: keep unless minor adjustment is necessary for continuity after Frame 04.
- Frame 06: make the top edge of exactly ONE card clearly visible 15–20% above the opening. Card edge must be readable against the glow.
- Frame 07: keep.
- Frame 08: preserve exactly THREE cards but spread them enough that all three silhouettes are immediately distinguishable. Center highest, left/right approximately ±10–12°.
- Frame 09: exactly THREE full card backs in a clean fan with more negative space between silhouettes, center highest, left/right approximately ±14°. Reduce visual crowding without losing celebration.

### Premium
- Frame 01: keep.
- Frame 02: keep.
- Frame 03: keep.
- Frame 04: reduce to a true 20–25% centered initial tear with less burst intensity.
- Frame 05: keep unless continuity requires a minor adjustment.
- Frame 06: make exactly ONE card edge visibly readable at 15–20% exposure.
- Frame 07: keep.
- Frame 08: exactly FIVE cards, but spread the fan slightly so all five silhouettes are distinct. Keep geometry near -20/-10/0/+10/+20 degrees.
- Frame 09: keep if the improved Frame 08 reads naturally into it; otherwise make only the minimum fan-spacing adjustment necessary. Preserve exactly five cards and premium identity.

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

Create:
- OWNER_PACK_ASSET_REVIEW_V02.md
- CODEX_LOG_V02.md

Run the same 18-frame validator and git diff --check.

Return final SHA, changed frame list, validation summary, Standard/Premium contact-sheet links and OWNER_PACK_ASSET_REVIEW_V02.md URL.

Finish exactly:
AWAITING_GPT_M43_C005_C002_V03_AUDIT
