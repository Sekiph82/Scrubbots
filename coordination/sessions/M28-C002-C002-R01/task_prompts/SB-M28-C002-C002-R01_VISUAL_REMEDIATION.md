# SB-M28-C002-C002-R01 — SCRUBBY SCALE + BUBBLE + VISUAL GATE REMEDIATION

Status: READY FOR CLAUDE
Date: 2026-09-28
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/OWNER_GAMEPLAY_STATIC_SHELL_VISUAL_ACCEPTANCE_V01.md`
4. `coordination/OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01.md`
5. `coordination/sessions/M28-C002-C002/CHATGPT_AUDIT_V01.md`
6. `coordination/sessions/M28-C002-C002/OWNER_GAMEPLAY_STATIC_SHELL_REVIEW_V01.md`
7. M32 Scrubbot visual authority/tests

Do NOT edit root `TASKS.md`.

## Mission

Apply the owner's final C002 visual choices plus two targeted visual remediations without reopening the accepted six-shell architecture.

## A. Mini Scrubby size

Current production truth:
`scripts/gameplay/presentation/scrubbot_visual.gd`
has:
`BODY_SPAN_CELLS = 1.8`.

Change the live moving Scrubby presentation span to:

`BODY_SPAN_CELLS = 2.4`

Requirements:
- cell-relative only; no fixed screen-pixel sizing;
- no route/position/speed/completion change;
- bob/lean/squash remain presentation-only;
- shared texture/cache behavior unchanged;
- debug fallback unchanged;
- verify dense simultaneous-agent readability at both 1x and 2x;
- verify large/medium/small board visual readability.

The existing ~4.9 px measurement in C002 is rail alignment error, not agent size. Do not alter rail geometry merely to change sprite scale.

### Retire echo
Inspect the current `ECHO_SPAN_CELLS = 1.6`.

Keep the disappearance echo visually proportional to the new 2.4-cell live body. A reasonable proportional target is about 2.1 cells (preserving the previous ~0.89 live/echo ratio), but confirm visually and document the final presentation-only value.

Do not change echo lifetime, event source, clear semantics or gameplay truth.

## B. Speech bubble

The bubble must no longer be blank.

Keep the static master bytes untouched.

Continue masking the obsolete baked instruction, then overlay live Godot/localized text in the baked bubble area.

Candidate copy for owner review:

Headline:
`LET'S CLEAN THIS MESS!`

Instruction:
`Tap a batch below to send the Scrubbots.`

Requirements:
- use live text/localization infrastructure, not raster editing;
- text must fit all six masters;
- text must follow the same master reference transform;
- no clipping at tall/short/tablet layouts;
- keep readable hierarchy similar to the supplied master;
- no obsolete same-colored-board-tile instruction visible underneath.

## C. S2-B short-phone touch targets

At 1080x1920, painted cells are ~83 px.

Allow invisible front-supply/slot touch geometry to expand enough to meet the project's nominal 88 px touch target where needed.

Rules:
- visible cell/frame geometry remains unchanged;
- neighbouring hitboxes must never overlap;
- preview rows remain non-interactive;
- slot gameplay law remains unchanged;
- expansion may extend outside the painted cell only invisibly.

Prove this at 1080x1920.

## D. S3-B ad placeholder

Hide the visible `AD` label/band until M57.

Preserve the reserved lower layout space/anchor for future ads.

No ad SDK/network behavior in this cycle.

## E. S1/S4/S5 accepted as-is

Preserve:
- dark navy surround;
- native Pause/play glyph + live 2x state;
- current cyan/front/preview/ACTIVE state colors.

Do not redesign these.

## F. S6-C future non-square policy

Do not change the generic rectangular board engine.

Add/adjust production-content validation/documentation so that the current V02 static-shell visual path is considered owner-approved only for square boards.

Do not silently ship a non-square production level with known rail mismatch.

Do not rewrite routing or difficulty.

## Evidence required

Produce fresh owner-review screenshots:

1. active cleaning at 1x with enlarged 2.4-cell Scrubbots;
2. active cleaning at 2x;
3. dense multi-agent state showing overlap/readability;
4. short 1080x1920 showing touch-target-safe layout;
5. speech bubble at 1080x2160;
6. speech bubble at 1080x1920;
7. tablet portrait;
8. one +1 Slot six-slot state confirming shell unchanged.

The screenshots must clearly show the larger mini Scrubbots and non-empty bubble.

## Tests

Update/add focused tests proving:

- `BODY_SPAN_CELLS == 2.4`;
- body visual scale changed, agent route position/progress unchanged;
- retire echo remains presentation-only and proportionate;
- bubble contains the two live text elements and obsolete baked sentence is still masked;
- live bubble text uses the shell transform;
- 1080x1920 interactive front hitboxes meet >=88 px nominal target or the maximum non-overlap-safe bound if an exact 88 is geometrically impossible; document any exception;
- expanded hitboxes do not overlap adjacent columns/rows;
- previews remain non-interactive;
- AD placeholder invisible while reserved region remains;
- S1/S4/S5 behavior unchanged;
- no new node/signal accumulation.

Run:
- focused C002/R01;
- M32 Scrubbot visual evidence;
- M29 movement/origin;
- M28 shell/smoke;
- M39/M40 relevant economy/save;
- M52 First 10;
- M55 long-run/chaos;
- root suite;
- `git diff --check`.

Preserve documented historical M21 baseline failures if unchanged.

## Outputs

Create:
- `coordination/sessions/M28-C002-C002-R01/VISUAL_REMEDIATION_MATRIX_V01.md`
- `coordination/sessions/M28-C002-C002-R01/OWNER_VISUAL_REVIEW_V01.md`
- `coordination/sessions/M28-C002-C002-R01/CLAUDE_LOG_V01.md`
- evidence screenshots under the same session.

## Scope locks

Do not:
- alter any of the six master PNG bytes;
- redraw shell chrome;
- change route/supply/slot/economy truth;
- implement M43 Pause/Acquire popups yet;
- add real ad integration;
- invent non-square production content;
- edit TASKS.md.

## Finish

Commit and push.

Finish with:

`AWAITING_CHATGPT_AUDIT / M28-C002-C002-R01 VISUAL REMEDIATION`
