# M43-C005-C003 Owner Card Style Pilot V01

Status: PILOT_SELF_CHECK_PASS
Date: 2026-10-03
Task: M43-C005-C003

## Locked pilot template decisions

- Canvas: 1024×1536 RGBA.
- One rounded card silhouette with transparent pixels outside the outer card edge.
- Shared frame geometry, inset trim, centered rarity plaque, star row, art safe area, and bottom name plaque.
- Family colors: Common teal/cyan, Rare indigo/blue, Epic violet, Legendary gold.
- Typography is composed deterministically in Segoe UI Bold. The label and name are exact inventory strings.
- Subject art is generated separately for each card, from a card-specific text prompt with a true transparent background; no owner-sheet pixels are used.

## Pilot self-check

| Pilot | Identity | Rarity and stars | Exact text | Frame | Crop contamination | Quality |
|---|---|---|---|---|---|---|
| Set 1 Card 1 — Scrubby | PASS, white/teal Scrubby with broom and open cyan eyes | PASS, Common, 2 stars | PASS | PASS | PASS, independently generated illustration | PASS |
| Set 1 Card 5 — Squeegee | PASS, Scrubby-family robot with glass squeegee | PASS, Rare, 2 stars | PASS | PASS | PASS, independently generated illustration | PASS |
| Set 1 Card 7 — Turbo Scrubby | PASS, Scrubby identity with jet pack and action pose | PASS, Epic, 3 stars | PASS | PASS | PASS, independently generated illustration | PASS |
| Set 1 Card 9 — Scrubmaster X | PASS, crowned gold Scrubby with blue crystal staff and red cape | PASS, Legendary, 4 stars | PASS | PASS | PASS, independently generated illustration | PASS |

All four rendered examples were visually inspected. They share the same frame proportions and typography; each rarity has a distinct color family; names and rarity labels are legible; the full subject stays within the art safe area. No generated text is present in the illustrations.

## Pilot generation attempts

- Common Scrubby: 3 separate calls; 2 discarded expression/style retries.
- Rare Squeegee: 1 call.
- Epic Turbo Scrubby: 2 separate calls; 1 discarded open-eye identity correction.
- Legendary Scrubmaster X: 2 separate calls; 1 discarded open-eye identity correction.
- Total: 8 image-generation calls for 4 pilot subjects. These remain candidate examples and will not be reused as production output.

## Evidence

- evidence/pilot_comparison.png
- evidence/four_rarity_template_examples/
- candidate/pilot_01_common_scrubby.png
- candidate/pilot_02_rare_squeegee_illustration.png
- candidate/pilot_03_epic_turbo_scrubby_illustration.png
- candidate/pilot_04_legendary_scrubmaster_x_illustration.png