# M32-C002 — CHATGPT AUDIT CRITERIA V01

Date: 2026-09-29
Auditor: ChatGPT
Task: `SB-M32-UI-012`

Expected verdict if clean:

`AUDITED_PASS / OWNER VISUAL ACCEPTANCE REQUIRED`

## A. Geometry-derived sizing — BLOCKING

PASS requires sizing to derive from actual BoardPresentation / rendered cell geometry.

FAIL for:
- 20/32/38/59 lookup table;
- fixed per-dimension constants;
- screen-pixel math inside ScrubbotAgent/routing/gameplay truth.

The 32x32 / 2.4-cell appearance is the reference.

## B. Apparent-size consistency — BLOCKING

On a fixed viewport/presentation:

- 20x20;
- 32x32;
- 38x38;
- 59x59;
- rectangular boards

must render the live Scrubbot at approximately the same displayed footprint.

Target: within ±3% of 32x32 reference, unless integer renderer flooring creates a documented edge case whose geometry-derived target is nevertheless exact and not hand-tuned.

Synthetic 100x100 proof must not expand production validity.

## C. 32x32 reference preservation

32x32 must retain the accepted reference size.

No silent visual rescale of the reference baseline.

## D. Dynamic relayout — BLOCKING

A live Scrubbot must update apparent size after responsive relayout without:

- agent recreation;
- route replacement;
- progress mutation;
- position jump;
- timing change;
- texture reload.

Same agent identity must survive.

## E. Presentation-only truth — BLOCKING

Visual compensation must not change:

- authoritative agent position;
- route points;
- progress;
- arrival;
- completion/clear timing;
- speed;
- target/claim/reservation truth.

Differential movement proof required.

## F. Rectangular correctness

No square-board assumption.

Use actual rendered cell scale.

At least representative width-limited and/or height-limited rectangular evidence must show consistent apparent size.

## G. Echo consistency

Retire echo must use the same board-resolution compensation so its apparent footprint does not drift relative to the live Scrubbot.

Preserve:
- 2.1/2.4 approximate footprint ratio;
- placement;
- lifetime;
- shrink;
- cap;
- event semantics.

## H. Asset/performance discipline

Same canonical texture.

Shared cache preserved.

No per-agent decode.

No per-board-size image assets.

No unbounded relayout/per-frame scene-tree scanning or allocation pattern.

## I. Fresh evidence

Require screenshots for:
- 20;
- 32;
- 38;
- 59;
- rectangular;
- responsive before/after.

Require numeric report with cell sizes, compensation, local span and measured displayed pixels.

Technical audit may rely on geometry/measurement evidence; final perceived appearance remains OWNER gate.

## J. Regression/governance

FAIL if Claude edits `TASKS.md`.

Required relevant suites:
- M32;
- M29;
- M28;
- M31;
- M30;
- M39;
- M52;
- M55;
- root;
- git diff check.

Only known historical m21_v08/v09 baseline signatures may remain.

## K. Owner gate

Technical PASS does not close SB-M32-UI-012.

Owner reviews:
1. 20/32/38/59 same apparent size;
2. 32x32 reference still correct;
3. rectangular appearance;
4. live/echo ratio.

Only owner acceptance closes the task.
