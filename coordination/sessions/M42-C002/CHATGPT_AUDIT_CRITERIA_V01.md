# M42-C002 — CHATGPT AUDIT CRITERIA V01

Date: 2026-09-30
Auditor: ChatGPT
Task: `SB-M42-034`

Expected verdict if clean:

`AUDITED_PASS / OWNER VISUAL ACCEPTANCE REQUIRED`

## A. Exact owner scale — BLOCKING

PASS requires:

`SCRUBBY_SCALE = 1.612`

exactly.

This equals +30% from 1.24.

FAIL for responsive shrinking or approximate replacement.

## B. Current Home authority — BLOCKING

Implementation must use the current:

- 940×1672 Home world;
- current owner-selected background;
- current scrubby feet anchor/safe box.

FAIL for reverting to stale HOME-120 or old 1080×2160 world geometry.

## C. Soles/platform registration — BLOCKING

Across:
- 1080×2160;
- 1080×1920;
- 1290×2796;
- 1536×2048;

visible soles must remain registered to the canonical platform contact within 1 px.

Center/placement must remain deterministic.

## D. Functional UI collision — BLOCKING

Enlarged hero must not make these functional surfaces unusable:

- TopCurrencyHUD;
- GiftMeter;
- Play;
- BottomNav;
- SHOP;
- COLLECTION;
- TASKS;
- DAILY.

Scale may not be reduced to avoid collision.

Any layout adjustment must preserve 1.612.

## E. Hero identity / asset lock

Same approved HOME-026 texture.

No regenerated/replaced Scrubby.

Separate runtime hero remains.

No baked-in hero.

No revival of old face/brush overlay implementation.

No animation asset production yet.

## F. Responsive stability

Same hero node survives relayout.

No duplicate hero/shade nodes.

Texture object stable.

Returning to a previous viewport restores deterministic geometry.

## G. Presentation-only scope

No change to:
- Home navigation;
- Play;
- economy;
- progression;
- launch;
- modal truth;
- ad behavior.

## H. Shade/helper-bot discipline

If HeroFocusShade changes, it must be geometry-only and remain stylistically equivalent.

Helper-bot avoidance must not regress.

No baked-sign collision.

## I. Fresh evidence

Require fresh current-background screenshots at all four viewports and a before/after 1.24→1.612 montage.

Require measurement report with geometry/collision results.

## J. Regression/governance

Required:
- M42 focused/current suites PASS;
- navigation/opening PASS;
- relevant M40/M43 PASS;
- root PASS;
- git diff check clean.

FAIL if Claude edits root `TASKS.md`.

## K. Owner gate

Technical PASS does not close SB-M42-034.

OWNER must visually accept:
1. enlargement;
2. platform planting;
3. four-viewport composition;
4. UI/helper-bot relationship.

Only then may SB-M42-035 animation begin.
