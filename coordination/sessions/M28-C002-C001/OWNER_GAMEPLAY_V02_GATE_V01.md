# M28-C002-C001 — OWNER GAMEPLAY V02 VISUAL GATE V01

Date: 2026-09-28
Status: OWNER INPUT REQUIRED
Technical audit: `coordination/sessions/M28-C002-C001/CHATGPT_AUDIT_V01.md`
Visual pack: `coordination/sessions/M28-C002-C001/OWNER_GAMEPLAY_V02_REVIEW_V01.md`

The Gameplay V02 core is technically accepted.

The owner now decides the remaining visual-only items before the next production cycle.

## V1 — Background

Current: native midnight-blue gradient.

Reason: the committed `gameplay_environment.png` is an isometric arena element, not a portrait gameplay backdrop; the master image's full industrial-jungle scene does not exist as an approved standalone background asset.

Choose:
- **V1-A:** accept the native midnight-blue gradient for V1.
- **V1-B:** create/approve a dedicated portrait gameplay background before final Gameplay V02 closure.

## V2 — Profile chip + slot chrome

Current: native Godot renditions.

Reason: the approved profile-frame and slot PNGs have opaque white backgrounds/corners and do not composite cleanly.

Choose:
- **V2-A:** accept the native Godot profile/slot renditions.
- **V2-B:** produce transparent corrected re-exports of those same visual assets, then bind them.

No existing approved source asset should be destructively edited.

## V3 — Profile content

Current:
- Scrubby;
- live Level N;
- live Bot Parts progress.

Master-only title / XP-like figures are omitted because no gameplay authority exists for them.

Choose:
- **V3-A:** accept the data-backed minimal profile.
- **V3-B:** define an owner-backed additional profile data model before showing more values.

## V4 — Speech bubble

Current: hidden.

Reason: no tutorial wording is yet authorized; FTUE/tutorial copy belongs to M44.

Choose:
- **V4-A:** keep hidden until M44.
- **V4-B:** explicitly authorize a specific gameplay/tutorial message now.

## V5 — Tall-phone spare height

Current: width-limited board remains aspect-correct; extra vertical height is distributed above/below gameplay-critical bands.

Choose:
- **V5-A:** accept current spacing.
- **V5-B:** request a different decorative spacing treatment while keeping the board aspect and critical controls unchanged.

## V6 — Railroad segment density

Current: whole approved rail segments chained along straight runs, with visible coupling/flange rhythm.

Choose:
- **V6-A:** accept current segment density.
- **V6-B:** make straight segments visually longer/fewer.
- **V6-C:** make them shorter/more frequent.

This is presentation only; canonical Railroad geometry/routing does not change.

## Dependency reminder

Even after V1-V6 are resolved, full M28-C002 remains open until:
- M43-C002 canonical Pause/modal foundation;
- M43-C003 BoosterAcquire + final 2x Acquire;
- popup-open input suppression;
- final popup-inclusive owner evidence/playtest.

No owner decision here should fake-close those dependencies.
