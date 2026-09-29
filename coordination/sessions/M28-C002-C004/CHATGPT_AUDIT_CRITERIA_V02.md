# M28-C002-C004 — CHATGPT AUDIT CRITERIA V02

Date: 2026-09-29
Auditor: ChatGPT

Owner authority:
`coordination/OWNER_M28_COLOR_BATCH_TILE_VISUAL_V01.md`

Prior audit:
`coordination/sessions/M28-C002-C004/CHATGPT_AUDIT_V01.md`

Expected verdict if clean:

`AUDITED_PASS / OWNER FINAL VISUAL RECHECK REQUIRED`

## A. Narrow scope

PASS requires the implementation to change only the lower occupied-tile base color behavior plus directly necessary tests/evidence.

FAIL for redesigning already owner-approved:
- height;
- shadow;
- highlight;
- count sizing/centering;
- ACTIVE/WAITING;
- preview;
- EMPTY.

## B. Exact same-color base — BLOCKING

For occupied tiles:

`base_fill == face_fill == canonical Palette v3 batch color`

PASS requires:
- exact equality, not perceptual similarity;
- all C01..C16 covered;
- no fixed white/light-gray occupied base;
- no approximate lightened/darkened substitute for the base BODY fill.

A separate darker edge/border/shadow is allowed.

## C. Existing accepted visual behavior preserved

PASS requires:
- BASE_FRACTION/geometry unchanged;
- shadow size/offset preserved;
- highlight preserved;
- count white/dark outline preserved;
- count exact face-centering preserved;
- 1/2/3 digit behavior preserved;
- ACTIVE/WAITING distinction preserved;
- preview hierarchy preserved;
- EMPTY unchanged.

## D. Geometry/input invariants

PASS requires:
- 5/6 slot geometry unchanged;
- slot spawn anchors unchanged;
- supply front hit rects unchanged/non-overlapping;
- one gesture = one activation;
- preview non-interactive.

## E. Regression / governance

FAIL if Claude edits `TASKS.md`.

Required:
- focused C004 PASS;
- M28/M29/M39/M43/M52 relevant PASS;
- M55 long-session PASS;
- root suite PASS;
- only previously documented M21 baseline non-zero results may remain;
- `git diff --check` clean.

## F. Evidence

PASS requires refreshed visual evidence clearly showing:
- same-color top face + lower base;
- light color example;
- dark color example;
- 5-slot;
- 6-slot;
- supply.

## G. Owner gate

Technical PASS does not close SB-M28-C002-021.

Owner rechecks only the corrected base color.

If owner confirms the lower base now matches the batch color, SB-M28-C002-021 closes and the project moves to SB-M29-010 Gameplay Tempo Retune.
