# M28-C002-C002 — OWNER STATIC SHELL VISUAL GATE V01

Date: 2026-09-28
Status: OWNER INPUT REQUIRED
Technical audit: `coordination/sessions/M28-C002-C002/CHATGPT_AUDIT_V01.md`
Review pack: `coordination/sessions/M28-C002-C002/OWNER_GAMEPLAY_STATIC_SHELL_REVIEW_V01.md`

The six-shell implementation is technically accepted.

Please resolve the remaining visual/UX choices.

## S1 — Surround fill on non-1:2 screens

Current: flat dark navy outside the uniformly aspect-fitted 1:2 master on tall phones/tablets.

- **S1-A:** keep dark navy.
- **S1-B:** later create a dedicated approved extension/backdrop outside the shell.

Recommendation: **S1-A** for now. It preserves the master exactly and avoids inventing extra artwork.

## S2 — Short-phone hitbox size

At 1080×1920, the painted slot/supply cells become about 83 px, below the project's nominal 88 px touch token.

- **S2-A:** hitbox must remain exactly inside the painted cell.
- **S2-B:** allow invisible hitboxes to extend a few pixels beyond the painted cell while never overlapping neighbouring hitboxes.

Recommendation: **S2-B**. It preserves visuals while improving touch usability.

## S3 — Reserved AD band before M57

Current: faint dark band with a small AD label.

- **S3-A:** keep the placeholder visible.
- **S3-B:** hide the AD label/band until the real M57 ad system exists, while preserving the reserved layout area.

Recommendation: **S3-B**. Reserve the space invisibly until there is a real ad.

## S4 — Pause / 2x glyph treatment

Current:
- Pause drawn as native bars/play triangle;
- 2x drawn as live text;
- selected state uses translucent cyan;
- free automatic 2x uses green.

Reason: committed pause icon is corrupt, and the 2x PNG includes its own button frame which would duplicate the baked master box.

- **S4-A:** accept current native glyph/text overlays.
- **S4-B:** later create clean transparent icon-only assets.

Recommendation: **S4-A** unless the owner dislikes the rendered result.

## S5 — Live state colours

Current:
- live batch-colour fill;
- white count;
- front supply row cyan edge;
- preview rows dimmed;
- ACTIVE slots cyan edge.

- **S5-A:** accept.
- **S5-B:** request different front/preview/ACTIVE styling.

Recommendation: **S5-A**.

## S6 — Future non-square boards

Current content is square. A future non-square board would fit inside the baked rail but cannot make the runtime rail exactly coincide with all four baked rail sides simultaneously.

- **S6-A:** owner-lock current V02 master shells to square-board production content.
- **S6-B:** allow non-square boards later with known visual rail mismatch.
- **S6-C:** require a future alternate shell/rail treatment before any non-square board ships.

Recommendation: **S6-C**. It avoids accepting a known visual mismatch and does not constrain the engine itself.

## Dependency reminder

Even after S1-S6 are resolved, full M28-C002 still needs:
- M43-C002 Pause/modal foundation;
- M43-C003 BoosterAcquire + final 2x Acquire;
- popup-open input suppression;
- popup-inclusive evidence;
- final owner playtest.

Those are separate implementation dependencies, not part of this visual gate.
