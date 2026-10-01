# M42-C003 — OWNER ASSET ROUTE GATE V01

Date: 2026-10-01
Status: **OWNER ASSET ROUTE DECISION REQUIRED**

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

Choose one:

- `A — FRAME ANIMATION`
- `B — LAYERED RIG`

If Route A is chosen and ChatGPT is to create the candidate art, provide the canonical HOME-026 image as an image attachment in the active conversation so it can be used directly as the visual reference/edit target.

No runtime code should begin until the selected art route has usable candidate assets.
