# M28-C002-C004 — CHATGPT INDEPENDENT AUDIT V01

Date: 2026-09-29
Auditor: ChatGPT
Repository: `Sekiph82/Scrubbots`
Audited implementation: `f85e698835d3673410372dc100aaed0c098f1fa4`
Parent: `c01eb3a1a493ff2acfbf52a146ee755ab1093774`
Prompt: `coordination/sessions/M28-C002-C004/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/M28-C002-C004/CHATGPT_AUDIT_CRITERIA_V01.md`
Owner authority: `coordination/OWNER_M28_COLOR_BATCH_TILE_VISUAL_V01.md`

## Verdict

**AUDITED_PASS / OWNER VISUAL ACCEPTANCE REQUIRED**

The technical implementation satisfies the M28-C002-C004 criteria, including the blocking owner correction that slot count numbers are geometrically centered in the colored top face.

SB-M28-C002-021 remains OPEN until owner visual acceptance.

## Audit method

This is an independent repository audit, not acceptance of Claude's self-report.

Verified directly from GitHub:

- exact implementation commit and parent;
- complete changed-file list;
- all production-code diffs;
- the shared tile implementation;
- slot and Batch Supply integration;
- focused centering/invariant tests;
- updated legacy presentation assertions;
- implementation matrix and regression log;
- committed measurement evidence;
- fresh binary evidence-file presence;
- prior independent baseline for the two historical M21 non-zero suites;
- governance: root `TASKS.md` is absent from the implementation commit.

The connected repository interface exposes committed PNG/MP4 files as repository assets but does not provide their pixels as model-visible image bytes. Therefore technical geometry/data checks are independently audited here; final visual taste and perceived centering remain correctly reserved for the OWNER gate.

## A. Shared tile architecture

**PASS.**

`scripts/ui/color_batch_tile.gd` is the single shared tile presentation authority.

Direct inspection confirms:

- every `BatchSlotView` owns one `ColorBatchTile`;
- every Batch Supply row owns one `ColorBatchTile`;
- both paths preload the same `scripts/ui/color_batch_tile.gd`;
- color and count are injected dynamically through `set_batch(Color, String)`;
- state presentation is controlled through `set_active`, `set_preview`, and `set_empty`;
- no per-color or per-count bitmap assets are introduced;
- the component is native Godot UI only: panels + one label.

The focused suite explicitly verifies script identity for all slot and supply tiles.

## B. Owner-approved 3D tile structure

**PASS technically / OWNER VISUAL REVIEW REQUIRED.**

Code inspection confirms the requested structure:

- rounded colored `Face`;
- face background uses the passed authoritative palette Color exactly;
- thin darker same-hue face rim;
- restrained top highlight band;
- visible white/light-gray `Base`;
- base bottom edge and compact shadow;
- large white count with dark outline;
- ACTIVE uses a cyan rim/glow and stronger highlight, with no ACTIVE word;
- WAITING uses the normal occupied tile, with no WAITING word;
- EMPTY removes face/base/count;
- Batch Supply preview rows remain dimmed and non-interactive.

The central face remains the canonical color; the highlight does not cover its center.

Final balance of base height, shadow, glow and highlight is visual taste and remains an owner gate.

## C. Exact numeric centering — BLOCKING

**PASS.**

This criterion is satisfied structurally, not by an approximate screenshot-only assertion.

`ColorBatchTile` builds:

`Face -> Count`

and the count Label:

- is a direct child of `Face`;
- uses `PRESET_FULL_RECT`;
- has zero face-relative offsets;
- uses horizontal CENTER;
- uses vertical CENTER.

Therefore the count-label rect and colored-face rect are the same rectangle by construction.

Direct test inspection confirms the focused suite compares:

`count_rect.center - face_rect.center`

rather than comparing against the whole tile or base.

### Required cases

Covered:

- 1-digit;
- 2-digit;
- 3-digit;
- ACTIVE;
- WAITING;
- five-slot;
- temporary sixth slot;
- phone;
- narrow phone;
- short phone;
- tall phone;
- tablet;
- live resize.

The focused tolerance is <= 1 px; committed measurement evidence reports layout deltas of exactly `(0.00, 0.00)` for all submitted runtime shots.

### Colored face vs lower base

The focused suite separately proves:

- face height is shorter than the whole tile;
- the base extends below the face;
- count rect equals face rect;
- count center differs from whole-tile center.

Therefore the white/light lower base is not part of the centering box.

### Hidden state-line spacer

`StateLineReserve` is a sibling of the tile, not an ancestor of the Face/Count hierarchy.

The focused test intentionally mutates that reserve to a hostile 400x400 minimum size and even gives it visible `WAITING` text; the face rect remains unchanged and the count remains centered.

This is strong evidence that the compatibility spacer cannot bias numeric centering.

### Digit-specific offsets

No per-digit positional offsets exist.

Font size may shrink to fit width, but position remains the same full-face centered layout.

### Rendered glyph ink

The evidence tool additionally measures the pure-white rendered glyph bounding box. Submitted measurements show approximately 0–2 px optical side-bearing differences depending on glyphs, while layout centering remains exactly zero.

That is consistent with font glyph metrics, not a layout-position defect. Final perceived centering remains owner-reviewed.

## D. Slot invariants

**PASS.**

Verified:

- slot display truth remains `remaining_to_clear - committed`;
- snapshot input remains detached;
- ACTIVE/WAITING/EMPTY internal truth remains unchanged;
- no player-input behavior was added to slot views;
- five/six capacity implementation remains in `FiveSlotStrip`;
- temporary sixth slot uses the same tile component;
- slot housing/rail remains separate from the colored tile;
- `get_spawn_anchor_global()` semantics are unchanged.

The implementation preserves old outer slot geometry through a non-rendering reserve sibling while sizing the colored tile to the baked slot interior.

The focused suite pins outer slot rects and spawn anchors across ten viewport/capacity configurations to pre-C004 measurements with 0.01 px tolerance.

No routing/claim/target code is touched by this commit.

## E. Batch Supply invariants

**PASS.**

Production diff preserves the existing row-panel input authority.

Verified:

- 3/4/5 supply columns remain supported;
- exactly three visible rows remain;
- row 0 remains the only input surface;
- rows 1/2 have no input handler;
- tile itself ignores input;
- front mouse/touch dedup logic is unchanged;
- hit-area construction is unchanged;
- deeper supply truth is not exposed;
- count/color continue to come from detached player snapshots.

Focused proof additionally checks:

- hit rects do not overlap;
- hit rects enclose the front tile;
- rebinding counts does not move hit rects;
- one routed press/release produces one activation;
- preview-row activation produces none.

## F. Responsive / readability

**PASS technically / OWNER VISUAL REVIEW REQUIRED.**

Focused coverage includes:

- 1080x2160;
- 720x1600;
- 1080x1920;
- 1290x2796;
- 1536x2048;
- five and six slots;
- 3/4/5-column supply examples;
- 1/2/3-digit counts.

The count-fit test covers tile sizes down to 48 px and values through 999.

The font-size algorithm changes only font size, never position, and uses a bounded width fraction to preserve margin for outline.

Light/dark palette identity and white + dark-outline text are asserted.

Three-digit visual weight/tightness remains an owner review item.

## G. Scope / regressions / governance

**PASS.**

The implementation commit changes only:

- new shared tile presentation;
- slot presentation wiring;
- Batch Supply presentation wiring;
- one shell tile-size handoff in FiveSlotStrip;
- focused tests/evidence;
- two prior presentation tests updated from old per-panel StyleBox assertions to the new shared tile state.

Not changed:

- `TASKS.md`;
- routing;
- target selection;
- claims/reservations;
- BoardState;
- grid/bevel;
- speed;
- economy;
- Heart/booster rules;
- M23/M24 truth;
- Home;
- solver/difficulty;
- level data.

The two updated historical tests preserve their original semantic checks: ACTIVE remains visually distinct, WAITING remains distinct, front supply remains primary and preview remains dimmed.

### M55 warm-up issue

Claude reports an intermediate `m55_long_session` failure caused by generating many font-cache sizes. The final code uses arithmetic sizing quantized in 4 px steps with a shared `FontVariation`, and the final submitted regression records M55 long-session PASS.

No M55 test was weakened or modified in the implementation commit.

### Regression evidence

Submitted final regression:

- focused M28-C002-C004: 16/16 PASS;
- root: 5323/5323 PASS;
- M28/M29/M30/M39/M40/M42/M43/M52/M55 and routing/solver suites PASS;
- `git diff --check` clean;
- 113/115 standalone suites exit 0.

The two non-zero suites are:

- `m21_v08_corridor_validation`: historical C/043, C/047;
- `m21_v09_direct_evidence_reconciliation`: historical B.

These exact findings are already documented in the prior independent M28 audits and predate this implementation, so they remain non-blocking baseline findings.

## H. Evidence

**PASS for technical evidence presence and measurement data.**

Repository contains fresh evidence for:

- 5-slot runtime;
- 6-slot runtime;
- 3/4/5-column supply;
- narrow phone;
- tablet;
- ACTIVE/WAITING/EMPTY/front/preview;
- light/dark Palette v3 examples;
- 1/2/3-digit close-ups;
- all-16-color tile gallery;
- `measurements.txt`.

The evidence-generation tool itself is auditable and records both:

- layout center delta;
- rendered white-ink center delta.

The debug center overlays exist only in generated evidence and are not shipping UI.

## I. Owner visual gate

**REQUIRED.**

Technical PASS does not close SB-M28-C002-021.

Owner should visually inspect in the real runtime:

1. overall colored-face / white-base 3D look;
2. base height and shadow strength;
3. highlight/glow strength;
4. ACTIVE rim versus WAITING appearance;
5. front-supply versus preview hierarchy;
6. 1-, 2- and especially 3-digit count weight;
7. perceived centering of the count;
8. EMPTY slot/supply appearance against the baked shell.

Particular owner-review note: submitted implementation reports that outlines on some three-digit values such as `120` and `250` can visually touch. This is not a technical centering failure, but owner may prefer a slightly smaller three-digit font after visual inspection.

## Final

**AUDITED_PASS / OWNER VISUAL ACCEPTANCE REQUIRED**
