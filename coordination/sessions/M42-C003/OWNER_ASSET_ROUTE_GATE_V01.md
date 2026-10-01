# M42-C003 — OWNER ASSET ROUTE GATE V01

Date: 2026-10-01
Status: **OWNER SELECTED ROUTE A — FRAME ANIMATION / HOME-026 VISUAL-REFERENCE ATTACHMENT RECEIVED**

Task:
`SB-M42-035 — Home Scrubby Runtime Animation`

Independent audit:
`coordination/sessions/M42-C003/CHATGPT_AUDIT_V01.md`

Asset specification:
`coordination/sessions/M42-C003/ASSET_PRODUCTION_SPEC_V01.md`

## Current status

Runtime implementation is intentionally not started.

The repository has no approved Wave/Bow/Turn frame set.

The static HOME-026 fallback and accepted 1.612 geometry remain unchanged.

## Route A — registered frame animation

Preferred for the current owner design.

Produce candidate frame sets against HOME-026:

- Wave: 14 authored in-betweens;
- Bow: 15;
- Turn/Look: 17;
- exact 1158×1358 canvas;
- fixed pivot/feet registration;
- keep-out zones from the accepted four-viewport geometry.

Candidates remain generated/unapproved until owner visual review.

After owner acceptance, promote byte-identical accepted frames to:

`assets/ui/final/characters/scrubby/home_animation/`

Then Claude resumes M42-C003 runtime implementation.

## Route B — artist-painted layered rig

Alternative only if owner explicitly chooses it.

Requires approved layered Scrubby body/limb/brush art suitable for:

- Wave;
- Bow;
- true Turn/Look;

without crude deformation of HOME-026.

Runtime-only warping/rotation of the single static HOME-026 image is not authorized.

## Owner decision

**SELECTED: `A — FRAME ANIMATION`**

Owner supplied a HOME-026 visual-reference image attachment in the active ChatGPT conversation on 2026-10-01 for direct visual-reference use. The chat attachment is not treated as a byte-identical canonical replacement; the repository asset remains authoritative.

Candidate production order is locked as Wave → Bow → Turn/Look. Candidates remain unapproved until owner visual review and must satisfy `ASSET_PRODUCTION_SPEC_V01.md` before promotion to `assets/ui/final/characters/scrubby/home_animation/`.

No runtime code should begin until Route A has usable owner-approved candidate assets.
