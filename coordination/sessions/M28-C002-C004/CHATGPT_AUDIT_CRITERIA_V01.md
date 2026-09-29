# M28-C002-C004 — CHATGPT AUDIT CRITERIA V01

Date: 2026-09-29
Auditor: ChatGPT

Owner authority:
`coordination/OWNER_M28_COLOR_BATCH_TILE_VISUAL_V01.md`

Expected technical verdict if clean:

`AUDITED_PASS / OWNER VISUAL ACCEPTANCE REQUIRED`

## A. Shared tile architecture

PASS requires:
- slot and Batch Supply use one shared visual component/helper/style authority rather than divergent duplicated implementations;
- runtime color/count remain data-driven;
- no baked per-color/per-count texture explosion;
- presentation remains lightweight.

## B. Owner-approved 3D tile visual structure

PASS requires:
- rounded colored top face;
- canonical Palette v3 face identity;
- restrained highlight/depth;
- visible white/light-gray lower base;
- compact shadow/depth cue;
- white count with strong dark outline;
- no visible WAITING/ACTIVE words;
- EMPTY clearly distinct;
- preview state lower emphasis/non-interactive.

Final aesthetic quality remains owner-reviewed.

## C. Exact numeric centering — BLOCKING

This is a hard PASS/FAIL criterion.

For every occupied slot tile, the player-facing count must be geometrically centered in the explicit COLORED TOP FACE.

PASS requires:

- count center X == colored-face center X within layout/render tolerance;
- count center Y == colored-face center Y within layout/render tolerance;
- centering uses the face rect, not the full tile including lower base;
- lower 3D base cannot shift the number;
- invisible state-line/spacer cannot shift the number;
- 1-, 2- and 3-digit values are centered without value-specific offsets;
- ACTIVE and WAITING retain the same centering;
- temporary sixth slot retains the same centering;
- responsive/narrow/tablet layouts retain centering.

Preferred automated proof:
- direct comparison of face rect center and count label rect center;
- canonical reference tolerance <= 1 px after final layout;
- responsive proof may use mathematically equivalent anchor/full-face centering with bounded rounding tolerance.

Visible "looks roughly centered" without geometry proof is insufficient for technical PASS.

## D. Slot invariants

PASS requires:
- displayed count truth remains `remaining_to_clear - committed`;
- five/six capacity unchanged;
- ACTIVE/WAITING internal state unchanged;
- no slot input added;
- outer slot geometry and Scrubbot spawn anchor do not drift;
- slot housing/rail remains separate.

## E. Batch Supply invariants

PASS requires:
- 3/4/5 columns;
- exactly 3 visible rows;
- only row 0 interactive;
- row 1/2 preview only;
- deeper queue hidden;
- front gesture de-dup remains correct;
- hit rects remain valid/non-overlapping;
- FIFO/player snapshot semantics unchanged.

## F. Responsive / readability

PASS requires:
- phone + narrow phone + tablet coverage;
- 1–3 digit counts fit;
- white/dark-outline count stays readable on light and dark Palette v3 colors;
- no clipping or overlap;
- sixth slot remains usable/readable.

## G. Scope / regressions

FAIL for:
- `TASKS.md` edited by Claude;
- gameplay logic drift;
- routing/origin drift;
- target/claim/reservation drift;
- supply/slot truth drift;
- economy/speed/Home/solver changes unrelated to tile presentation.

Required regression evidence includes M28/M29/M39/M43/M52, origin/routing geometry, responsive/touch, root suite and `git diff --check`.

## H. Evidence

PASS requires fresh runtime evidence for:
- 5 slots;
- 6 slots;
- 3/4/5-column supply;
- ACTIVE/WAITING/EMPTY/preview;
- light/dark colors;
- narrow/tablet;
- close-up 1/2/3-digit centered slot counts.

## I. Owner gate

Technical PASS does not close SB-M28-C002-021.

Owner visual acceptance is required for:
- overall 3D tile appearance;
- base/shadow/highlight balance;
- count visual weight;
- exact perceived centering;
- front vs preview hierarchy.

Only owner acceptance closes M28-C002-C004.
