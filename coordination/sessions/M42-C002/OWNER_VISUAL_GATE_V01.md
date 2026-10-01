# M42-C002 — OWNER VISUAL GATE V01

Date: 2026-10-01
Status: **OWNER VISUAL ACCEPTANCE REQUIRED**

Implementation:
`72a78620de42da6aa1b9f2ba00b6d15da9acfc7b`

Independent audit:
`coordination/sessions/M42-C002/CHATGPT_AUDIT_V01.md`

Task:
`SB-M42-034`

## Technical status

Technical audit PASS.

Locked production scale:

`SCRUBBY_SCALE = 1.612`

This is exactly +30% from the former 1.24 scale.

Measured soles/platform registration error is <0.001 px at all four required viewports.

Functional UI collision test reports 0 opaque Scrubby pixels inside required interactive controls.

## Owner questions

### V1 — +30% hero size

Review:

`evidence/home_scrubby_before_124_vs_after_1612_1080x2160.png`

and:

`evidence/home_scrubby_1612_1080x2160.png`

Question:

> Is the new 1.612 Home Scrubby size visually correct and preferable to the old 1.24 size?

Answer:
- OK
- TOO LARGE
- TOO SMALL

### V2 — Platform planting

Review the 1080×2160 and 1080×1920 images.

Question:

> Does Scrubby look naturally planted on the platform, without visually floating or sinking?

Answer:
- OK
- NOT OK

### V3 — Responsive composition

Review all four:

- `evidence/home_scrubby_1612_1080x2160.png`
- `evidence/home_scrubby_1612_1080x1920.png`
- `evidence/home_scrubby_1612_1290x2796.png`
- `evidence/home_scrubby_1612_1536x2048.png`

Question:

> Is the enlarged hero composition acceptable across all four target viewports?

Answer:
- OK
- NOT OK

### V4 — Helper bot / panel relationship

Pay particular attention to:

- the left helper-bot bucket/water-spray area near Scrubby's brush;
- the right-side DAILY panel at 1080×1920;
- COLLECTION/DAILY spacing at 1080×2160.

Technical facts:

- left helper-bot catalog rect contains some opaque brush-bristle pixels in its right strip;
- right helper bot has 0 opaque overlap;
- COLLECTION/DAILY have 0 opaque Scrubby pixels inside their control rects;
- nearest opaque Scrubby pixel to DAILY at 1080×1920 is 26.6 px away.

Question:

> Does the brush/helper relationship and panel spacing still look visually acceptable?

Answer:
- OK
- ADJUST

## Closure

If V1–V4 are all owner-approved:

- SB-M42-034 CLOSES;
- M42-C002 CLOSES;
- SB-M42-035 Home Scrubby Runtime Animation becomes current.

If any item fails:
- keep SB-M42-034 open;
- create only a narrow placement/composition remediation;
- do not reduce the locked 1.612 scale unless the owner explicitly changes the scale decision.
