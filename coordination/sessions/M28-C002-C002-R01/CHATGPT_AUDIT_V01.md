# M28-C002-C002-R01 — CHATGPT INDEPENDENT AUDIT V01

Date: 2026-09-28
Auditor: ChatGPT controller
Repository: `Sekiph82/Scrubbots`
Audited HEAD: `47b7b9f940dd5ce5f3d0232389735cc59617cb48`

## Verdict

**AUDITED_PASS / M28-C002-C002-R01 / OWNER VISUAL ACCEPTANCE REQUIRED**

The R01 visual remediation is technically accepted.

The owner must still visually approve:
- 2.4-cell moving mini Scrubby scale;
- bubble copy / short-phone text readability.

## 1. Diff scope

PASS.

Compared `271e498` -> `47b7b9f`.

Production changes are limited to:
- moving Scrubby presentation scale;
- retire echo presentation scale;
- live bubble text;
- supply-front invisible hitbox expansion;
- hidden AD placeholder;
- square-only production catalog gate.

Supporting changes:
- focused R01 test;
- M35 policy migration;
- screenshot harness;
- R01 evidence/log/matrix/review.

Root `TASKS.md` was not edited by the implementer.

The six owner master PNGs are absent from the diff.

## 2. Moving mini Scrubby scale

PASS.

`ScrubbotVisual.BODY_SPAN_CELLS` is now exactly `2.4`.

The sizing remains in board-cell units:
`scale = BODY_SPAN_CELLS / longest_texture_dimension`.

No fixed screen-pixel size was introduced.

Independent source inspection confirms route position, speed, completion and board truth remain owned by `ScrubbotAgent`; the visual only changes the child sprite transform.

Focused evidence compares 2.4-cell and 1.8-cell bodies over 400 ticks and reports identical agent positions / board truth.

## 3. Retire echo

PASS.

`ECHO_SPAN_CELLS` is now `2.1`, preserving approximately the old live/echo size ratio.

Unchanged:
- lifetime 0.28 s;
- shrink 0.5;
- cap 16;
- authenticated-clear event source;
- no gameplay mutation.

M32 presentation regressions pass.

## 4. Speech bubble

PASS technically.

The obsolete baked board-tapping instruction remains masked.

Live UI text is now supplied through `UiText`:

- `LET'S CLEAN THIS MESS!`
- `Tap a batch below to send the Scrubbots.`

Both labels are positioned in master-reference coordinates and therefore follow the same shell transform as the rest of the live overlays.

The shrink-to-fit loop uses the Label's current uncached `get_minimum_size()`, fixing the stale-measure defect found during evidence rendering.

Focused guards cover:
- all six shells;
- repeated relayout;
- 5->6 shell switch;
- phone / short-phone / tablet sizes;
- no text clipping.

The short 1080x1920 case uses 18 px headline / 15 px instruction. Technical fit passes; physical-device readability remains an OWNER visual decision.

## 5. Short-phone touch targets

PASS.

Supply front tiles receive invisible `HitArea` controls that:
- expand toward the 88 px touch token;
- never change visible cell geometry;
- clamp expansion to non-overlap-safe space;
- reuse the existing front-input gesture path.

At 1080x1920, all 3/4/5-column fronts reach at least 88 px in the focused test.

Preview rows remain non-interactive.

Execution slots remain non-interactive by game law, so no slot hitbox expansion was added.

## 6. AD placeholder

PASS.

The reserved lower AD region remains as a layout anchor.

Its visible placeholder/band/label is removed.

No ad SDK/provider behavior was introduced.

## 7. S1/S4/S5 preserved

PASS.

Accepted visual choices remain:
- dark navy surround;
- native Pause/play glyph and live 2x state;
- current front/preview/ACTIVE cyan/dim treatment.

## 8. S6-C square-production gate

PASS against owner authority.

The generic engine remains rectangular-capable.

The production level catalog now rejects non-square levels with an explicit S6-C reason.

M35's former 24x28 catalog assertion was migrated so the same rectangular level is still proven otherwise-valid, but is rejected only by the new production-shell policy.

No routing/difficulty engine rewrite was introduced.

## 9. Six master assets

PASS.

Builder re-verified all six locked SHA-256 values after final work.

The compare diff contains no gameplay master PNG mutation.

## 10. Lifecycle / sensitivity

PASS.

Focused R01 suite reports 10/10.

Eight deliberate mutations are reported to fail the focused suite:
- old live-body size;
- old echo size;
- no touch expansion;
- visible AD;
- empty bubble instruction;
- no shrink-to-fit;
- square gate disabled;
- stale cached bubble measurement.

Node/HitArea counts remain stable across repeated +1 Slot / Retry cycles.

## 11. Regression

Accepted.

Builder reports:
- R01 focused: 10/10;
- C002 static shell: 16/16;
- C001 Gameplay V02: 14/14;
- M28 layout smoke: 253 / 0;
- M29 relevant suites PASS;
- M32 visual suites PASS;
- M39/M40 PASS;
- First 10 owner plans PASS;
- M55 long-run / chaos / anti-rollback PASS;
- root: **5323 checks, ALL PASS**;
- `git diff --check`: clean.

Only the same historical M21 corridor-model failures remain, with no routing changes in R01.

## 12. Owner visual gate

Technical implementation is complete.

Owner must visually decide:

### R1 — 2.4-cell moving Scrubby
Accept current enlarged size, or request another presentation size.

### R2 — bubble copy
Current:
- `LET'S CLEAN THIS MESS!`
- `Tap a batch below to send the Scrubbots.`

Accept or provide replacement wording.

### R3 — short-phone instruction size
Current 1080x1920 instruction renders at 15 px.

Accept as readable on target device, or request copy/layout adjustment to permit a larger minimum.

## Final

`AUDITED_PASS / M28-C002-C002-R01 / OWNER VISUAL ACCEPTANCE REQUIRED`
