# M28-C002-C004 — COLOR / BATCH TILE VISUAL POLISH — REMEDIATION PROMPT V02

Date: 2026-09-29
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Status: READY FOR CLAUDE

Owner authority:
`coordination/OWNER_M28_COLOR_BATCH_TILE_VISUAL_V01.md`

Prior implementation:
`f85e698835d3673410372dc100aaed0c098f1fa4`

Independent audit:
`coordination/sessions/M28-C002-C004/CHATGPT_AUDIT_V01.md`

V01 technical verdict:
`AUDITED_PASS / OWNER VISUAL ACCEPTANCE REQUIRED`

## Owner review result

Owner accepted all V01 visual points except ONE:

PASS / KEEP AS-IS:
- tile height;
- shadow;
- top highlight;
- count weight, including 120 / 250;
- perceived count centering;
- ACTIVE / WAITING distinction;
- supply front / preview hierarchy;
- EMPTY appearance.

REMEDIATION REQUIRED:
- the lower 3D base is currently white/light gray;
- owner requires the lower base fill to be **exactly the same canonical Palette v3 batch color as the top face**.

## Mission

Make ONLY this narrow visual correction.

For every occupied `ColorBatchTile`:

`Base fill color == Face canonical batch color`

The visible lower platform must no longer be white/light gray.

Examples:
- C03 face -> C03 base;
- C08 face -> C08 base;
- C12 face -> C12 base;
- every C01..C16 tile follows the same rule.

No approximate lighter version, no generic white base, no alternate palette color.

## Preserve exactly

Do NOT redesign anything else.

Preserve:
- current base height / `BASE_FRACTION`;
- current tile geometry;
- current face geometry;
- current shadow size, opacity and offset;
- current top highlight;
- current rounded corners;
- current white count + dark outline;
- exact face-centering architecture;
- current 1/2/3-digit sizing;
- ACTIVE glow/rim;
- WAITING appearance;
- preview dimming;
- EMPTY behavior;
- slot outer geometry;
- slot spawn anchors;
- supply input/hit rects;
- 5/6 slot behavior;
- 3/4/5-column supply behavior.

A darker edge/border and black/neutral shadow may remain as depth treatment, but the **visible base body/fill itself must equal the exact batch color**.

## Implementation expectation

The simplest acceptable fix is to make the occupied base style use `_color` as its background/fill instead of the fixed `BASE_COLOR`.

If `BASE_COLOR` becomes unused, remove it cleanly.

Do not add per-color mappings or new textures.

## Required tests

Update/add focused proof that:

1. for every C01..C16 occupied tile:
   - `Face StyleBoxFlat.bg_color == canonical palette color`;
   - `Base StyleBoxFlat.bg_color == the same canonical palette color`;
   - base and face fill colors are exactly equal;
2. white/light-gray base fill is gone for occupied tiles;
3. EMPTY behavior is unchanged;
4. count centering remains exact;
5. base geometry/height is unchanged;
6. shadow remains present;
7. highlight remains present;
8. ACTIVE / WAITING / preview behavior remains unchanged;
9. slot spawn anchors remain unchanged;
10. supply hitboxes/input remain unchanged.

Re-run:
- M28-C002-C004 focused suite;
- relevant M28 visual suites;
- M29 input/presentation;
- M39 +1 Slot;
- M43 overlay/modal;
- M52 slot/supply;
- M55 long-session;
- root suite;
- `git diff --check`.

## Evidence

Refresh only the evidence needed to verify the owner correction, at minimum:

- tile gallery with representative/all Palette v3 colors showing same-color face + base;
- normal 5-slot runtime;
- 6-slot runtime;
- Batch Supply runtime;
- one light palette example;
- one dark palette example.

Do not regenerate unrelated evidence unless needed.

## Governance

Do not edit root `TASKS.md`.

Do not change gameplay/economy/routing/solver/Home/level data.

## Required outputs

Update/create:

- `coordination/sessions/M28-C002-C004/CLAUDE_LOG_V02.md`
- `coordination/sessions/M28-C002-C004/REMEDIATION_MATRIX_V02.md`
- refreshed evidence as needed.

Commit/push to `main`.

Finish exactly:

`AWAITING_CHATGPT_AUDIT / M28-C002-C004 SAME-COLOR BASE REMEDIATION V02`
