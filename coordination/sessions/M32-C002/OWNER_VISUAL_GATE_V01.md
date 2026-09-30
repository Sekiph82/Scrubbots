# M32-C002 — OWNER VISUAL GATE V01

Date: 2026-09-30
Status: **OWNER VISUAL ACCEPTANCE REQUIRED**

Implementation:
`649cf6290752e298b888eac6e080fb65bb2be9ed`

Independent audit:
`coordination/sessions/M32-C002/CHATGPT_AUDIT_V01.md`

Task:
`SB-M32-UI-012`

## Technical status

Technical audit PASS.

Measured body footprint at 1080x2160:

- 20x20: 58.64 px
- 32x32 reference: 58.64 px
- 38x38: 58.64 px
- 59x59: 58.64 px
- 59x40: 58.64 px
- 24x40: 58.64 px
- synthetic 100x100: 58.64 px

Echo/live reference ratio remains 2.1/2.4 = 0.875.

## Owner questions

### V1 — Cross-board apparent size

Review:

`evidence/m32c002_MONTAGE_BOARD_CROP_20_32_38_59_full_res.png`

Question:

> Do the Scrubbots on 20x20, 32x32, 38x38 and 59x59 look approximately the same physical size?

Answer:
- OK
- NOT OK

### V2 — 32x32 reference preservation

Review:

`evidence/m32c002_32x32_L2_apple_REFERENCE_1080x2160.png`

and, if useful:

`evidence/m32c002_MONTAGE_BOARD_CROP_preC002_vs_C002_20_38_59_full_res.png`

Question:

> Does 32x32 still look like the accepted existing Scrubbot size, rather than being visually enlarged or reduced?

Answer:
- OK
- TOO LARGE
- TOO SMALL

### V3 — Rectangular boards

Review:

- `evidence/m32c002_rect_59x40_TEST_width_limited_1080x2160.png`
- `evidence/m32c002_rect_24x40_TEST_height_limited_1080x2160.png`

Question:

> Do Scrubbots look natural and consistent on both rectangular board shapes?

Answer:
- OK
- NOT OK

### V4 — Live / retire-echo proportion

Use the individual gameplay screenshots and real runtime if needed.

Technical ratio is locked at 0.875 of live-body footprint.

Question:

> Does the retire echo still look proportionally right relative to the moving Scrubbot?

Answer:
- OK
- TOO LARGE
- TOO SMALL

## Informational only

No owner decision is required for:

- synthetic 100x100 validity; it remains TEST/presentation-only;
- live relayout geometry; technically PASS;
- route/progress/position truth; technically PASS;
- performance; technically PASS.

## Closure

If V1–V4 are all owner-approved:

- SB-M32-UI-012 CLOSES;
- M32-C002 CLOSES;
- next task: SB-M39-053 clock-boundary test stability.

Any failed item opens only a narrow visual remediation.
