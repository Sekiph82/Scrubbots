# OWNER GAMEPLAY STATIC SHELL VISUAL ACCEPTANCE + R01 TUNING V01

Date: 2026-09-28
Authority: OWNER
Status: OWNER-LOCKED / CANONICAL
Technical base: `004434930ae63b68e98978605796af9814f18511`
Audit: `coordination/sessions/M28-C002-C002/CHATGPT_AUDIT_V01.md`

## Visual gate decisions

The owner accepts the C002 static-shell presentation subject to the two R01 tuning items below.

Resolved choices:

- **S1-A** — keep flat dark navy surround on non-1:2 screens.
- **S2-B** — on short phones, invisible touch hitboxes may grow a few pixels beyond the painted slot/supply cell as needed to satisfy the 88 px touch target, provided adjacent hitboxes never overlap and visual geometry does not change.
- **S3-B** — hide the visible AD placeholder/band/label until M57 real ad integration; preserve the reserved lower layout space invisibly.
- **S4-A** — accept current native Pause bars/play triangle and live `2x` text/state overlays inside the baked master boxes.
- **S5-A** — accept current live-state treatment: batch fill + white count, cyan edge for front supply, dim previews, cyan edge for ACTIVE slots.
- **S6-C** — current V02 shell family is approved only for square-board production content. The engine may remain rectangular-capable, but no non-square board may ship with a known baked-rail mismatch. A future alternate shell/rail treatment is required before non-square content is released.

## R01 tuning item A — mini Scrubby travel size

The owner finds the moving mini Scrubby agents too small.

Important clarification:
- the previously discussed ~4.9 px value is rail-alignment error/tolerance, **not** Scrubby visual size;
- live Scrubby size is currently `ScrubbotVisual.BODY_SPAN_CELLS = 1.8`.

Owner intent: make the moving mini Scrubbots visibly larger without changing gameplay/routing truth.

Canonical implementation target for R01:
- increase live travel body span from **1.8 cells -> 2.4 cells**;
- keep cell-relative sizing, never fixed screen pixels;
- preserve exact agent route position / movement / completion truth;
- preserve railway readability and avoid excessive overlap at dense 1x/2x scenes.

The detached arrival/retire echo should remain visually proportional to the enlarged live body. Implementation may adjust its presentation-only span accordingly, but must not alter event timing or gameplay truth.

Final owner acceptance requires fresh active-cleaning evidence at 1x and 2x.

## R01 tuning item B — speech bubble must not be blank

The owner does not accept an empty gameplay speech bubble.

The baked bubble art remains part of the master.

The obsolete baked instruction:
`Tap on a group of same colored tiles to clean them.`
must still not ship because it describes the wrong input model.

R01 must place live text over the bubble using the existing localization/text system.

Candidate owner-review copy:

Headline:
`LET'S CLEAN THIS MESS!`

Instruction:
`Tap a batch below to send the Scrubbots.`

This copy is mechanically correct for the current production input model.

Do not bake new text into the master PNG.
Do not modify the owner master image bytes.
The live text must scale/alignment-follow the same master reference transform.

The owner will visually review this copy/placement in R01 evidence; wording may be copy-polished later without changing gameplay truth.

## Consequence

Open **M28-C002-C002-R01 — Scrubby Scale + Bubble + Accepted Visual Gate Remediation**.

The six static masters remain canonical and byte-locked.

Do not reopen already accepted S1/S4/S5 shell styling except where needed to implement S2/S3 or the two R01 tuning items.
